export function attendanceWindow(startsAt, now = new Date()) {
  const start = new Date(startsAt).getTime();
  const current = new Date(now).getTime();
  if (!Number.isFinite(start) || !Number.isFinite(current)) return 'locked';
  return current < start ? 'upcoming' : current < start + 86400000 ? 'open' : 'locked';
}
export function recoveryClasses(present, total, threshold = 75) {
  if (threshold <= 0 || threshold >= 100 || present < 0 || total < present) return null;
  return Math.max(0, Math.ceil((threshold * total - 100 * present) / (100 - threshold)));
}
export function percentage(present, total) { return total ? Math.round(present / total * 100) : null; }
