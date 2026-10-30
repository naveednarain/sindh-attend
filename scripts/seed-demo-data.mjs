// Full demo seed for University of Sindh attendance portal.
// Populates:
// 1. Departments: Sindh University (CS, IT, SE, BBA)
// 2. Teachers: Dr. Ahmed Ali (CS), Demo Teacher (CS), Dr. Sara Khan (IT), Mr. Usman Raza (SE), Ms. Nadia Shah (BBA)
// 3. Students: Ali Hassan, Fatima Noor, Bilal Ahmed, Zara Hussain, Jeewan
// 4. Courses & Enrollments
// 5. Mon-Fri Timetable Schedule (Saturday & Sunday strictly OFF)
// 6. Past submitted attendance records + upcoming timetable sessions

import { createClient } from '@supabase/supabase-js';

const url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL;
const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!url || !key) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
  process.exit(1);
}

const db = createClient(url, key, { auth: { persistSession: false, autoRefreshToken: false } });

// Helper to format ISO strings in PKT (UTC+5)
function pkt(dateStr, hh, mm) {
  return new Date(`${dateStr}T${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}:00+05:00`).toISOString();
}

// ─── 1. Departments ──────────────────────────────────────────────────────────
console.log('📌 Verifying University of Sindh departments...');
const { data: depts, error: deptErr } = await db.from('departments').select('id, code, name');
if (deptErr) throw deptErr;
const dept = Object.fromEntries(depts.map(d => [d.code, d.id]));
console.log('   Available:', depts.map(d => `${d.name} (${d.code})`).join(', '));

// ─── 2. Teachers ─────────────────────────────────────────────────────────────
console.log('\n👩‍🏫 Verifying teachers...');
const teacherList = [
  { email: 'ahmedali@usindh.edu.pk',  name: 'Dr. Ahmed Ali',   dept: dept.CS },
  { email: 'teacher@usindh.edu.pk',   name: 'Demo Teacher',    dept: dept.CS },
  { email: 'sarakhan@usindh.edu.pk',  name: 'Dr. Sara Khan',   dept: dept.IT },
  { email: 'usmanraza@usindh.edu.pk', name: 'Mr. Usman Raza',  dept: dept.SE },
  { email: 'nadiashah@usindh.edu.pk', name: 'Ms. Nadia Shah',  dept: dept.BBA },
];

const teacherMap = {};
for (const t of teacherList) {
  const { data: existing } = await db.from('profiles').select('id, full_name').eq('email', t.email).maybeSingle();
  if (existing) {
    teacherMap[t.email] = existing.id;
    console.log(`   ✓ ${t.name} (${t.email}) is ready`);
    continue;
  }

  const roll = t.email.split('@')[0];
  const { data, error } = await db.auth.admin.createUser({
    email: t.email,
    password: 'Teacher@Demo2026!',
    email_confirm: true,
    user_metadata: { roll_number: roll, full_name: t.name, department_id: t.dept, portal_role: 'teacher' }
  });

  if (error) {
    console.error(`   ✗ Error creating ${t.email}:`, error.message);
    continue;
  }

  const uid = data.user.id;
  await db.from('profiles').update({
    role: 'teacher',
    roll_number: null,
    full_name: t.name,
    department_id: t.dept,
    verification: 'approved'
  }).eq('id', uid);

  await db.auth.admin.updateUserById(uid, {
    app_metadata: { portal_role: 'teacher' }
  });

  teacherMap[t.email] = uid;
  console.log(`   ✓ Created ${t.name} (${t.email})`);
}

// ─── 3. Students ─────────────────────────────────────────────────────────────
console.log('\n🎓 Verifying students...');
const studentList = [
  { roll: '2k24cs001',  email: '2k24cs001@usindh.edu.pk',  name: 'Ali Hassan',   dept: dept.CS },
  { roll: '2k24cs002',  email: '2k24cs002@usindh.edu.pk',  name: 'Fatima Noor',  dept: dept.CS },
  { roll: '2k24it001',  email: '2k24it001@usindh.edu.pk',  name: 'Bilal Ahmed',  dept: dept.IT },
  { roll: '2k24se001',  email: '2k24se001@usindh.edu.pk',  name: 'Zara Hussain', dept: dept.SE },
  { roll: '2k26bba117', email: '2k26bba117@usindh.edu.pk', name: 'Jeewan',       dept: dept.BBA },
];

const studentMap = {};
for (const s of studentList) {
  const { data: existing } = await db.from('profiles').select('id, full_name, verification').eq('email', s.email).maybeSingle();
  if (existing) {
    if (existing.verification !== 'approved') {
      await db.from('profiles').update({ verification: 'approved' }).eq('id', existing.id);
    }
    studentMap[s.roll] = existing.id;
    console.log(`   ✓ Student ${s.name} (${s.roll}) is ready`);
    continue;
  }

  const { data, error } = await db.auth.admin.createUser({
    email: s.email,
    password: 'Student@Demo2026!',
    email_confirm: true,
    user_metadata: { roll_number: s.roll, full_name: s.name, department_id: s.dept }
  });

  if (error) {
    console.error(`   ✗ Error creating student ${s.email}:`, error.message);
    continue;
  }

  const uid = data.user.id;
  await db.from('profiles').update({ verification: 'approved' }).eq('id', uid);
  studentMap[s.roll] = uid;
  console.log(`   ✓ Created student ${s.name} (${s.roll})`);
}

// ─── 4. Courses ──────────────────────────────────────────────────────────────
console.log('\n📚 Setting up courses...');
const courseDefs = [
  { title: 'Data Structures',           code: 'CS301', kind: 'Theory',    section: 'BSCS · Part III · Morning', semester: 5, threshold: 75, department_id: dept.CS, teacher_id: teacherMap['ahmedali@usindh.edu.pk'] },
  { title: 'Operating Systems',         code: 'CS401', kind: 'Theory',    section: 'BSCS · Part III · Morning', semester: 5, threshold: 75, department_id: dept.CS, teacher_id: teacherMap['teacher@usindh.edu.pk'] || teacherMap['ahmedali@usindh.edu.pk'] },
  { title: 'Data Structures Lab',       code: 'CS301L',kind: 'Practical', section: 'BSCS · Part III · Morning', semester: 5, threshold: 75, department_id: dept.CS, teacher_id: teacherMap['ahmedali@usindh.edu.pk'] },
  { title: 'Web Technologies',          code: 'IT302', kind: 'Theory',    section: 'BSIT · Part III · Morning', semester: 5, threshold: 75, department_id: dept.IT, teacher_id: teacherMap['sarakhan@usindh.edu.pk'] },
  { title: 'Network Security',          code: 'IT401', kind: 'Theory',    section: 'BSIT · Part III · Morning', semester: 5, threshold: 75, department_id: dept.IT, teacher_id: teacherMap['sarakhan@usindh.edu.pk'] },
  { title: 'Software Requirements Eng', code: 'SE301', kind: 'Theory',    section: 'BSSE · Part III · Morning', semester: 5, threshold: 75, department_id: dept.SE, teacher_id: teacherMap['usmanraza@usindh.edu.pk'] },
  { title: 'Business Management',       code: 'BBA301',kind: 'Theory',    section: 'BBA · Part III · Morning',  semester: 5, threshold: 75, department_id: dept.BBA,teacher_id: teacherMap['nadiashah@usindh.edu.pk'] },
];

const courseMap = {};
for (const c of courseDefs) {
  const { data: existing } = await db.from('courses').select('id, code, teacher_id').eq('code', c.code).maybeSingle();
  if (existing) {
    if (existing.teacher_id !== c.teacher_id && c.teacher_id) {
      await db.from('courses').update({ teacher_id: c.teacher_id }).eq('id', existing.id);
    }
    courseMap[c.code] = existing.id;
    console.log(`   ✓ Course ${c.code} (${c.title}) ready`);
    continue;
  }

  const { data, error } = await db.from('courses').insert(c).select('id').single();
  if (error) {
    console.error(`   ✗ Error creating course ${c.code}:`, error.message);
    continue;
  }
  courseMap[c.code] = data.id;
  console.log(`   ✓ Created course ${c.code} (${c.title})`);
}

// ─── 5. Enrollments ──────────────────────────────────────────────────────────
console.log('\n📋 Enrolling students in respective courses...');
async function enroll(studentId, courseId) {
  if (!studentId || !courseId) return;
  const { data: ex } = await db.from('enrollments').select('course_id').eq('student_id', studentId).eq('course_id', courseId).maybeSingle();
  if (ex) return;
  const { error } = await db.from('enrollments').insert({ student_id: studentId, course_id: courseId });
  if (error) console.error(`   ✗ Enroll error: ${error.message}`);
}

// CS students (Ali Hassan, Fatima Noor)
for (const sid of [studentMap['2k24cs001'], studentMap['2k24cs002']]) {
  await enroll(sid, courseMap['CS301']);
  await enroll(sid, courseMap['CS401']);
  await enroll(sid, courseMap['CS301L']);
}
// IT student (Bilal Ahmed)
await enroll(studentMap['2k24it001'], courseMap['IT302']);
await enroll(studentMap['2k24it001'], courseMap['IT401']);
// SE student (Zara Hussain)
await enroll(studentMap['2k24se001'], courseMap['SE301']);
// BBA student (Jeewan)
await enroll(studentMap['2k26bba117'], courseMap['BBA301']);

console.log('   ✓ Student enrollments complete');

// ─── 6. Reset & Re-create Class Sessions (Mon–Fri only! Saturday & Sunday OFF) ──
console.log('\n🗓️  Generating Monday–Friday schedule (Saturday & Sunday OFF)...');

// Clean existing attendance and sessions for a fresh, accurate timetable
await db.from('attendance').delete().neq('student_id', '00000000-0000-0000-0000-000000000000');
await db.from('class_sessions').delete().neq('room', '__none__');

// Weekly timetable definition:
// [courseCode, room, dayOfWeek (0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri), startH, startM, endH, endM, teacherEmail]
const weeklySchedule = [
  // CS301 (Data Structures): Monday & Wednesday 08:30–10:00
  ['CS301',  'IMCS · Room 101',      0,  8, 30, 10,  0, 'ahmedali@usindh.edu.pk'],
  ['CS301',  'IMCS · Room 101',      2,  8, 30, 10,  0, 'ahmedali@usindh.edu.pk'],

  // CS401 (Operating Systems): Tuesday & Thursday 10:15–11:45
  ['CS401',  'IMCS · Room 102',      1, 10, 15, 11, 45, 'teacher@usindh.edu.pk'],
  ['CS401',  'IMCS · Room 102',      3, 10, 15, 11, 45, 'teacher@usindh.edu.pk'],

  // CS301L (Data Structures Lab): Friday 09:00–11:30
  ['CS301L', 'ICT Center · Lab 01',   4,  9,  0, 11, 30, 'ahmedali@usindh.edu.pk'],

  // IT302 (Web Technologies): Monday & Wednesday 10:15–11:45
  ['IT302',  'ICT Center · Room 201', 0, 10, 15, 11, 45, 'sarakhan@usindh.edu.pk'],
  ['IT302',  'ICT Center · Room 201', 2, 10, 15, 11, 45, 'sarakhan@usindh.edu.pk'],

  // IT401 (Network Security): Tuesday & Thursday 08:30–10:00
  ['IT401',  'ICT Center · Room 202', 1,  8, 30, 10,  0, 'sarakhan@usindh.edu.pk'],
  ['IT401',  'ICT Center · Room 202', 3,  8, 30, 10,  0, 'sarakhan@usindh.edu.pk'],

  // SE301 (Software Requirements Eng): Monday, Wednesday & Friday 12:00–13:30
  ['SE301',  'Faculty of Eng. · 301', 0, 12,  0, 13, 30, 'usmanraza@usindh.edu.pk'],
  ['SE301',  'Faculty of Eng. · 301', 2, 12,  0, 13, 30, 'usmanraza@usindh.edu.pk'],
  ['SE301',  'Faculty of Eng. · 301', 4, 12,  0, 13, 30, 'usmanraza@usindh.edu.pk'],

  // BBA301 (Business Management): Tuesday & Thursday 12:00–13:30
  ['BBA301', 'IBA · Executive Hall',  1, 12,  0, 13, 30, 'nadiashah@usindh.edu.pk'],
  ['BBA301', 'IBA · Executive Hall',  3, 12,  0, 13, 30, 'nadiashah@usindh.edu.pk'],
];

// Generates exact Mon(0), Tue(1), Wed(2), Thu(3), Fri(4) YYYY-MM-DD strings for a given Monday
function getWeekdays(mondayDateStr) {
  const [y, m, d] = mondayDateStr.split('-').map(Number);
  return [0, 1, 2, 3, 4].map(offset => {
    const dt = new Date(Date.UTC(y, m - 1, d + offset, 12, 0, 0));
    return dt.toISOString().slice(0, 10);
  });
}

// 4 weeks:
// Past weeks: Monday Oct 19, 2026 & Monday Oct 26, 2026
// Upcoming weeks: Monday Nov 02, 2026 & Monday Nov 09, 2026
const pastWeeks = ['2026-10-19', '2026-10-26'];
const futureWeeks = ['2026-11-02', '2026-11-09'];
const allWeeks = [...pastWeeks, ...futureWeeks];

let createdSessions = 0;
let createdAttendance = 0;

for (const mondayDate of allWeeks) {
  const days = getWeekdays(mondayDate); // Guaranteed Mon–Fri only!
  const isPast = pastWeeks.includes(mondayDate);

  for (const [code, room, dayIdx, sh, sm, eh, em, teacherEmail] of weeklySchedule) {
    const courseId = courseMap[code];
    if (!courseId) continue;

    const dateStr = days[dayIdx];
    const starts_at = pkt(dateStr, sh, sm);
    const ends_at = pkt(dateStr, eh, em);

    // Verify day is strictly Monday through Friday in PKT
    const dayOfWeek = new Date(starts_at).getUTCDay(); // starts_at is UTC; let's check PKT day:
    const pktDay = new Date(new Date(starts_at).getTime() + 5 * 3600000).getUTCDay();
    if (pktDay === 0 || pktDay === 6) {
      console.warn(`Skipping weekend day ${pktDay} for ${dateStr}`);
      continue;
    }

    const sessionData = {
      course_id: courseId,
      starts_at,
      ends_at,
      room,
      cancelled: false,
      submitted_at: isPast ? ends_at : null
    };

    const { data: newSess, error: sessErr } = await db.from('class_sessions')
      .insert(sessionData)
      .select('id')
      .single();

    if (sessErr) {
      console.error(`   ✗ Error scheduling ${code} on ${dateStr}:`, sessErr.message);
      continue;
    }
    const sessionId = newSess.id;
    createdSessions++;

    // For past sessions, mark attendance records
    if (isPast && sessionId) {
      const { data: enrollments } = await db.from('enrollments')
        .select('student_id')
        .eq('course_id', courseId);

      if (enrollments && enrollments.length > 0) {
        const teacherId = teacherMap[teacherEmail] || teacherMap['teacher@usindh.edu.pk'];
        // Realistic attendance pattern: mostly present with occasional late/absent
        const markPatterns = ['present', 'present', 'present', 'late', 'absent'];
        
        for (let i = 0; i < enrollments.length; i++) {
          const studentId = enrollments[i].student_id;
          const status = markPatterns[(dayIdx + i) % markPatterns.length];

          const { error: attErr } = await db.from('attendance').upsert({
            session_id: sessionId,
            student_id: studentId,
            status,
            marked_by: teacherId,
          }, { onConflict: 'session_id,student_id' });

          if (!attErr) createdAttendance++;
        }
      }
    }
  }
}

console.log(`\n🎉 SEED SUMMARY:`);
console.log(`   ✓ Sessions Created: ${createdSessions} (Mon–Fri across 4 weeks)`);
console.log(`   ✓ Attendance Entries: ${createdAttendance} submitted past records`);
console.log(`   ✓ Weekend Policy: Saturday & Sunday strictly OFF`);
console.log(`   ✓ Department Schedules Active: Computer Science, IT, SE, BBA`);
console.log('\n--- Teacher Credentials (all @usindh.edu.pk) ---');
console.log('   ahmedali@usindh.edu.pk    -> Teacher@Demo2026!  (Dr. Ahmed Ali, CS)');
console.log('   teacher@usindh.edu.pk     -> Teacher@Demo2026!  (Demo Teacher, CS)');
console.log('   sarakhan@usindh.edu.pk    -> Teacher@Demo2026!  (Dr. Sara Khan, IT)');
console.log('   usmanraza@usindh.edu.pk   -> Teacher@Demo2026!  (Mr. Usman Raza, SE)');
console.log('   nadiashah@usindh.edu.pk   -> Teacher@Demo2026!  (Ms. Nadia Shah, BBA)');
console.log('\n--- Student Credentials (all @usindh.edu.pk) ---');
console.log('   2k24cs001@usindh.edu.pk   -> Student@Demo2026!  (Ali Hassan, CS)');
console.log('   2k24cs002@usindh.edu.pk   -> Student@Demo2026!  (Fatima Noor, CS)');
console.log('   2k24it001@usindh.edu.pk   -> Student@Demo2026!  (Bilal Ahmed, IT)');
console.log('   2k24se001@usindh.edu.pk   -> Student@Demo2026!  (Zara Hussain, SE)');
console.log('   2k26bba117@usindh.edu.pk  -> Student@Demo2026!  (Jeewan, BBA)\n');
