import { View, div } from "gpui-kit";
import { v_flex, h_flex } from "gpui-base";
import { appHome, readTextFile, setShared, shared, theme } from "herdr";
import {
  ALL, STARRED, canNext, liveStars, next, setActiveSet, start, toggleStar,
} from "./selection.js";

// install.sh links quotes.json to data/quotes.json in the quotes repo.
const DATABASE = "mods/quotes/quotes.json";
const STARS = "quotes.starred";

const storedStars = () => shared(STARS) ?? [];
// The datasets keep line-wrap spacing inside some quotes.
const tidy = (text) => text.replace(/\s+/g, " ").trim();

export default class Quotes extends View {
  init(_props, cx) {
    this.quotes = null; this.authors = {}; this.ids = []; this.error = null; this.state = null; this.detailsShown = false;
    cx.spawn(async (cx) => {
      try {
        const raw = await readTextFile(`${appHome()}/${DATABASE}`);
        if (raw === null) throw new Error(`Quotes database not found at ${DATABASE}.`);
        const db = JSON.parse(raw);
        this.quotes = new Map(db.quotes.map((q) => [q.id, q]));
        this.authors = db.authors;
        this.ids = [...this.quotes.keys()];
        this.state = start(this.ids);
      } catch (e) {
        this.error = String(e?.message ?? e);
      }
      cx.notify();
    });
  }

  starred() {
    return liveStars(storedStars(), this.quotes);
  }

  update(state, cx) {
    this.state = state;
    cx.notify();
  }

  segment(id, label, t) {
    const on = this.state?.activeSet === id;
    return div().id(`set-${id}`).h(24).px(9).flex().items_center().rounded(5).text_size(12).cursor_pointer()
      .bg(on ? t.selected : t.background).text_color(on ? t.foreground : t.muted)
      .hover((s) => s.bg(t.hover))
      .on_click((_e, cx) => this.update(setActiveSet(this.state, id, this.starred()), cx))
      .child(label);
  }

  // Hovering the Author opens Details beneath it. The bio is inside the hover area,
  // so the pointer can move onto it without closing it.
  author(quote, author, t) {
    const shown = this.detailsShown;
    const about = [author?.school, author?.era].filter(Boolean).join(" · ");
    return v_flex().id("author").gap(2)
      .on_hover((hovered, cx) => { this.detailsShown = hovered; cx.notify(); })
      .child(div().text_size(13).font_semibold().text_color(shown ? t.accent : t.foreground).child(author?.name ?? quote.author))
      .when(Boolean(about), (el) => el.child(div().text_size(11.5).text_color(t.dim).child(about)))
      .when(shown && Boolean(author?.bio), (el) => el.child(div().pt(6).text_size(12.5).line_height("19px").text_color(t.muted).child(author.bio)))
      .when(shown && Boolean(quote.explanation), (el) => el.child(div().pt(6).text_size(12.5).line_height("19px").text_color(t.foreground).child(quote.explanation)));
  }

  quote(quote, t) {
    return v_flex().gap(14)
      .child(div().text_size(17).line_height("26px").child(`“${tidy(quote.text)}”`))
      .child(this.author(quote, this.authors[quote.author], t));
  }

  message(text, color) {
    return div().p(4).text_size(13).text_color(color).child(text);
  }

  body(t) {
    if (this.error) return this.message(this.error, t.ansi1);
    if (!this.state) return this.message("Loading quotes…", t.dim);
    if (this.state.blank) return this.message("No starred quotes yet", t.dim);
    return this.quote(this.quotes.get(this.state.currentId), t);
  }

  actions(t) {
    const stars = this.state ? this.starred() : [];
    const blank = !this.state || this.state.blank;
    const id = this.state?.currentId;
    const isStarred = stars.includes(id);
    const nextOn = this.state && canNext(this.state, this.ids, stars);
    return h_flex().gap(4).items_center()
      .when(!blank, (el) => el.child(div().id("star").size(24).flex().items_center().justify_center().rounded(5).text_size(14).cursor_pointer()
        .text_color(isStarred ? t.accent : t.muted)
        .hover((s) => s.bg(t.hover))
        .on_click(() => setShared(STARS, toggleStar(storedStars(), id)))
        .child(isStarred ? "★" : "☆")))
      .child(div().id("next").h(24).px(9).flex().items_center().rounded(5).text_size(12)
        .bg(nextOn ? t.raised : t.background).text_color(nextOn ? t.foreground : t.dim)
        .when(nextOn, (el) => el.cursor_pointer().hover((s) => s.bg(t.hover))
          .on_click((_e, cx) => this.update(next(this.state, this.ids, this.starred()), cx)))
        .child("Next"));
  }

  render() {
    const t = theme();
    const count = this.quotes ? this.starred().length : 0;
    return v_flex().id("quotes").size_full().min_h(0).rounded(10).overflow_hidden().bg(t.background).border_1().border_color(t.border).text_color(t.foreground).text_size(13)
      .child(h_flex().h(42).flex_none().px(14).gap(4).items_center().border_b(1).border_color(t.border)
        .child(div().font_semibold().child("Quotes"))
        .child(div().flex_1())
        .child(this.segment(ALL, "All", t))
        .child(this.segment(STARRED, count ? `Starred ${count}` : "Starred", t))
        .child(div().w(1).h(16).mx(4).bg(t.border))
        .child(this.actions(t)))
      .child(v_flex().id("quotes-body").flex_1().min_h(0).overflow_y_scrollbar().p(14).child(this.body(t)));
  }
}
