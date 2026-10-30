import test from 'node:test';
import assert from 'node:assert/strict';
import { attendanceWindow, recoveryClasses, percentage } from '../src/lib/attendance.mjs';
const start = '2026-10-30T05:00:00Z';
test('attendance opens at period start, never before, and locks exactly 24 hours later', () => {
  assert.equal(attendanceWindow(start, '2026-10-30T04:59:59.999Z'), 'upcoming');
  assert.equal(attendanceWindow(start, start), 'open');
  assert.equal(attendanceWindow(start, '2026-10-31T04:59:59.999Z'), 'open');
  assert.equal(attendanceWindow(start, '2026-10-31T05:00:00Z'), 'locked');
  assert.equal(attendanceWindow('invalid'), 'locked');
});
test('recovery calculator rounds up and handles empty records', () => {
  assert.equal(recoveryClasses(6, 10, 75), 6);
  assert.equal(recoveryClasses(9, 10, 75), 0);
  assert.equal(recoveryClasses(1, 2, 100), null);
  assert.equal(percentage(0, 0), null);
});
