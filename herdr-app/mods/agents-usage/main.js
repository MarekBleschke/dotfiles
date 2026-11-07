import { View, div, svg } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { exec, readTextFile, home, appHome, theme } from "herdr";

// Claude Code subscription limits, read from the same endpoint `/usage` uses,
// with the OAuth token Claude Code keeps in the macOS keychain (or ~/.claude).
const URL = "https://api.anthropic.com/api/oauth/usage";
const AUTO_MS = 5 * 60 * 1000;
const HOUR = 3600 * 1000;
const WINDOWS = [
  { key: "five_hour", label: "Session", span: "5 hours", ms: 5 * HOUR },
  { key: "seven_day", label: "Weekly", span: "7 days", ms: 7 * 24 * HOUR },
  { key: "seven_day_opus", label: "Weekly · Opus", span: "7 days", ms: 7 * 24 * HOUR },
  { key: "seven_day_sonnet", label: "Weekly · Sonnet", span: "7 days", ms: 7 * 24 * HOUR },
];

// Python-style timestamps carry microseconds; trim to milliseconds for Date.
const parseTime = (s) => (s ? Date.parse(String(s).replace(/(\.\d{3})\d+/, "$1")) : NaN);

function duration(ms) {
  if (!(ms > 0)) return "now";
  const m = Math.round(ms / 60000), d = Math.floor(m / 1440), h = Math.floor((m % 1440) / 60), min = m % 60;
  if (d) return `${d}d ${h}h`;
  if (h) return `${h}h ${min}m`;
  return `${Math.max(1, min)}m`;
}

function clock(ms, withDay) {
  const d = new Date(ms), pad = (n) => String(n).padStart(2, "0");
  const time = `${pad(d.getHours())}:${pad(d.getMinutes())}`;
  return withDay ? `${["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][d.getDay()]} ${time}` : time;
}

async function credentials() {
  let raw = null;
  try {
    const r = await exec("security", ["find-generic-password", "-s", "Claude Code-credentials", "-w"]);
    if (r.code === 0) raw = r.stdout;
  } catch {}
  if (!raw) {
    try { raw = await readTextFile(`${home()}/.claude/.credentials.json`); } catch {}
  }
  if (!raw) throw new Error("No Claude Code login found. Run `claude` and log in.");
  const oauth = JSON.parse(raw).claudeAiOauth;
  if (!oauth?.accessToken) throw new Error("Claude Code isn't logged in with a subscription.");
  return oauth;
}

export default class ClaudeUsage extends View {
  init(_props, cx) {
    this.data = null; this.error = null; this.loading = false; this.updated = null; this.plan = null;
    this.codex = { data: null, error: null, loading: false, updated: null, plan: null };
    this.refresh(cx);
    this.refreshCodex(cx);
    cx.timer.every(AUTO_MS, (cx) => { this.refresh(cx); this.refreshCodex(cx); });
    // Keeps "resets in" and "updated ago" current; once a minute is all they change.
    cx.timer.every(60000, (cx) => cx.notify());
  }

  refreshCodex(cx) {
    const state = this.codex;
    if (state.loading) return;
    state.loading = true; cx.notify();
    cx.spawn(async (cx) => {
      try {
        // Run through the login shell so node (mise/brew) is on PATH even when the app was launched from Finder.
        const script = `${appHome()}/mods/agents-usage/codex-usage.cjs`;
        const res = await exec("/bin/zsh", ["-lic", 'node "$0"', script]);
        const line = String(res.stdout ?? "").split("\n").reverse().find((l) => l.trim().startsWith("{"));
        if (!line) {
          const why = String(res.stderr ?? "").trim().split("\n").pop()?.slice(0, 120);
          throw new Error(`Could not read Codex usage (exit ${res.code}). ${why || "Check that Node.js and Codex are installed."}`);
        }
        const result = JSON.parse(line);
        if (result.error) throw new Error(result.error);
        state.data = result.limits; state.plan = result.plan ?? null;
        state.updated = Date.now(); state.error = null;
      } catch (e) {
        state.error = String(e?.message ?? e);
      }
      state.loading = false;
      cx.notify();
    });
  }

  refresh(cx) {
    if (this.loading) return;
    this.loading = true; cx.notify();
    cx.spawn(async (cx) => {
      try {
        const oauth = await credentials();
        this.plan = oauth.subscriptionType ?? null;
        const res = await fetch(URL, { headers: {
          Authorization: `Bearer ${oauth.accessToken}`,
          "anthropic-beta": "oauth-2025-04-20",
          "Content-Type": "application/json",
        } });
        if (res.status === 401) throw new Error("Login token expired. Run any `claude` command to refresh it.");
        if (res.status === 429) throw new Error("Rate limited by the usage endpoint; will retry.");
        if (!res.ok) throw new Error(`Usage request failed (HTTP ${res.status}).`);
        this.data = await res.json();
        this.updated = Date.now(); this.error = null;
      } catch (e) {
        this.error = String(e?.message ?? e);
      }
      this.loading = false;
      cx.notify();
    });
  }

  levelColor(pct, t) {
    if (pct >= 90) return t.ansi1;
    if (pct >= 70) return t.blocked;
    return t.accent;
  }

  card(w, info, t) {
    const pct = Math.max(0, Math.min(100, Number(info.utilization) || 0));
    const reset = parseTime(info.resets_at), now = Date.now();
    const left = reset - now;
    const elapsed = Number.isFinite(reset) && w.ms > 0 ? Math.max(0, Math.min(100, ((w.ms - left) / w.ms) * 100)) : null;
    const color = this.levelColor(pct, t);
    const pace = elapsed === null ? null : pct - elapsed;
    const paceText = pace === null ? "" : Math.abs(pace) < 3 ? "on pace" : pace > 0 ? `${Math.round(pace)}% ahead of pace` : `${Math.round(-pace)}% under pace`;
    return v_flex().id(`card-${w.key}`).flex_none().p(14).gap(10).rounded(10).bg(t.surface).border_1().border_color(t.border)
      .child(h_flex().items_center().gap(8)
        .child(v_flex().gap(1)
          .child(div().font_semibold().text_size(13).child(w.label))
          .child(div().text_size(11).text_color(t.dim).child(w.span ? `rolling ${w.span}` : "subscription limit")))
        .child(div().flex_1())
        .child(h_flex().items_end().gap(1)
          .child(div().text_size(26).font_semibold().text_color(pct >= 70 ? color : t.foreground).child(String(Math.round(pct))))
          .child(div().text_size(13).text_color(t.muted).pb(4).child("%"))))
      // Bar: usage fill, plus a thin tick for how far through the window we are.
      .child(div().relative().w_full().h(10).rounded(5).bg(t.raised).overflow_hidden()
        .child(div().absolute().top(0).left(0).h_full().w(`${pct}%`).rounded(5).bg(color))
        .when(elapsed !== null, (el) => el.child(div().absolute().top(0).h_full().w(2).left(`${elapsed}%`).bg(t.foreground).opacity(0.55))))
      .child(h_flex().items_center().gap(6).text_size(11.5)
        .child(div().text_color(t.muted).child(Number.isFinite(reset) ? `Resets in ${duration(left)}` : "No reset scheduled"))
        .when(Number.isFinite(reset), (el) => el.child(div().text_color(t.dim).child(`· ${clock(reset, left > 20 * HOUR)}`)))
        .child(div().flex_1())
        .when(Boolean(paceText), (el) => el.child(div().text_color(pace > 3 ? t.blocked : t.dim).child(paceText))))
      .child(h_flex().gap(6).text_size(11).text_color(t.dim)
        .child(div().child(`${Math.round(100 - pct)}% left`))
        .when(elapsed !== null, (el) => el.child(div().child(`· ${Math.round(elapsed)}% of window elapsed`))));
  }

  section(provider, t) {
    const isCodex = provider === "codex", state = isCodex ? this.codex : this;
    const data = state.data, extra = isCodex ? null : data?.extra_usage;
    const shown = isCodex ? ["primary", "secondary"].flatMap((key) => {
      const info = data?.[key];
      if (!info || !Number.isFinite(info.usedPercent)) return [];
      const mins = info.windowDurationMins;
      const ms = mins > 0 ? mins * 60000 : null;
      const label = mins === 300 ? "Session" : mins === 10080 ? "Weekly" : key === "primary" ? "Primary limit" : "Secondary limit";
      const span = !ms ? null : mins % 1440 === 0 ? `${mins / 1440} days` : mins % 60 === 0 ? `${mins / 60} hours` : `${mins} minutes`;
      return [{ key: `codex-${key}`, label, span, ms, info: {
        utilization: info.usedPercent,
        resets_at: info.resetsAt ? new Date(info.resetsAt * 1000).toISOString() : null,
      } }];
    }) : data ? WINDOWS.filter((w) => data[w.key]).map((w) => ({ ...w, info: data[w.key] })) : [];
    const ago = state.updated ? (Date.now() - state.updated < 60000 ? "just now" : `${duration(Date.now() - state.updated)} ago`) : "never";
    const plan = state.plan ? String(state.plan).replace(/_/g, " ").replace(/\b\w/g, (s) => s.toUpperCase()) : null;
    return v_flex().id(`usage-${provider}`).flex_none().rounded(10).overflow_hidden().border_1().border_color(t.border)
      .child(h_flex().h(42).flex_none().px(14).gap(8).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child(isCodex ? "Codex" : "Claude"))
        .when(Boolean(plan), (el) => el.child(div().px(5).py(1).rounded(4).border_1().border_color(t.border).text_size(10).text_color(t.muted).child(plan)))
        .child(div().flex_1())
        .child(div().id(`usage-refresh-${provider}`).size(26).flex().items_center().justify_center().rounded(6).text_color(t.muted).cursor_pointer()
          .hover((s) => s.bg(t.hover).text_color(t.foreground))
          .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
          .on_click((_e, cx) => isCodex ? this.refreshCodex(cx) : this.refresh(cx))
          .child(state.loading ? svg("mods/agents-usage/spinner.svg").size(14).spin(900) : svg("mods/agents-usage/refresh.svg").size(14))))
      .child(v_flex().id(`usage-body-${provider}`).flex_none().p(10).gap(10)
        .when(Boolean(state.error), (el) => el.child(div().p(10).rounded(8).border_1().border_color(t.ansi1).text_size(12).text_color(t.ansi1).child(state.error)))
        .when(!data && state.loading, (el) => el.child(div().p(8).text_color(t.dim).child("Loading usage…")))
        .when(Boolean(data) && !shown.length, (el) => el.child(div().p(8).text_color(t.dim).child("No usage windows reported for this subscription.")))
        .children(shown.map((w) => this.card(w, w.info, t)))
        .when(isCodex && Boolean(data?.credits), (el) => el.child(div().px(4).text_size(11.5).text_color(t.muted)
          .child(data.credits.unlimited ? "Credits: unlimited" : data.credits.hasCredits ? `Credits remaining: ${data.credits.balance ?? "available"}` : "No extra credits")))
        .when(Boolean(extra?.is_enabled), (el) => el.child(div().px(4).text_size(11.5).text_color(t.muted)
          .child(`Extra usage: ${extra.used_credits ?? 0} / ${extra.monthly_limit ?? "∞"} ${extra.currency ?? ""}`))))
      .child(h_flex().flex_none().h(30).px(14).gap(6).items_center().border_t(1).border_color(t.border).text_size(11).text_color(t.dim)
        .child(div().child(`${state.error && data ? "Last success" : "Updated"} ${ago}`))
        .child(div().flex_1())
        .child(div().child("auto every 5 min")));
  }

  render() {
    const t = theme();
    return v_flex().id("agents-usage").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Usage")))
      .child(v_flex().id("usage-body").flex_1().min_h(0).overflow_y_scrollbar().p(10).gap(16)
        .child(this.section("claude", t))
        .child(this.section("codex", t)));
  }
}
