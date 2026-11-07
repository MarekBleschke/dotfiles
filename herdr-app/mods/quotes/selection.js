// The panel's selection rules, with no Herdr imports so they run under plain node.
// Stars are passed in rather than held here: they live in Herdr's shared state.

export const ALL = "all";
export const STARRED = "starred";

// A uniform random id, avoiding `currentId` unless it's the only choice.
export function pick(ids, currentId, random = Math.random) {
  const choices = ids.filter((id) => id !== currentId);
  const from = choices.length ? choices : ids;
  return from.length ? from[Math.floor(random() * from.length)] : null;
}

export function start(allIds, random = Math.random) {
  return { activeSet: ALL, currentId: pick(allIds, null, random), blank: false };
}

const activeIds = (state, allIds, starredIds) => (state.activeSet === STARRED ? starredIds : allIds);

export function canNext(state, allIds, starredIds) {
  return activeIds(state, allIds, starredIds).length > 0;
}

export function next(state, allIds, starredIds, random = Math.random) {
  if (!canNext(state, allIds, starredIds)) return state;
  const currentId = pick(activeIds(state, allIds, starredIds), state.currentId, random);
  return { ...state, currentId };
}

export function setActiveSet(state, activeSet, starredIds, random = Math.random) {
  if (activeSet === state.activeSet) return state;
  if (activeSet === ALL) return { ...state, activeSet, blank: false };
  if (!starredIds.length) return { ...state, activeSet, blank: true };
  if (starredIds.includes(state.currentId)) return { ...state, activeSet };
  return { ...state, activeSet, currentId: pick(starredIds, null, random) };
}

export function toggleStar(stored, id) {
  return stored.includes(id) ? stored.filter((s) => s !== id) : [...stored, id];
}

// Stars whose Quote is still in the database. The rest stay stored but are ignored.
export function liveStars(stored, known) {
  return stored.filter((id) => known.has(id));
}
