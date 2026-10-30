-- ============================================================
-- University of Sindh — Full Demo Seed
-- Run this in: https://supabase.com/dashboard/project/mfikbalqckbzqqsuexxf/sql/new
-- ============================================================

-- ── 0. Temporarily silence the signup trigger ─────────────────
-- We bypass it by inserting directly into auth.users (service role can do this via SQL)

DO $$
DECLARE
  cs_dept  uuid := '2d738020-e825-4be3-b38b-df7c4f0b49b2';
  it_dept  uuid := '75fdd805-ee6f-4c60-81d6-f75557faa22f';
  se_dept  uuid := '218966dd-a07c-4858-9841-0daf7ca6602d';
  bba_dept uuid := '88393cff-5a6e-4bb0-89f5-a121c36348a8';

  t_cs  uuid; t_it uuid; t_se uuid; t_bba uuid;
  c_ds  uuid; c_os uuid; c_dsl uuid;
  c_wt  uuid; c_ns uuid;
  c_se1 uuid; c_bm uuid;
  s1 uuid; s2 uuid; s3 uuid; s4 uuid;

  mon1 date; mon2 date; mon3 date; mon4 date;
  d date; sess_id uuid;
BEGIN

-- ── 1. Teachers (insert directly bypassing trigger) ───────────
-- Dr. Ahmed Ali — CS
INSERT INTO auth.users(id,instance_id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,role,aud)
VALUES(gen_random_uuid(),'00000000-0000-0000-0000-000000000000','dr.ahmed.ali@usindh.edu.pk',
  crypt('Teacher@Demo2026!',gen_salt('bf')),now(),
  '{"provider":"email","providers":["email"],"portal_role":"teacher"}'::jsonb,
  jsonb_build_object('full_name','Dr. Ahmed Ali','department_id',cs_dept),
  now(),now(),'authenticated','authenticated')
ON CONFLICT(email) DO NOTHING RETURNING id INTO t_cs;

IF t_cs IS NULL THEN SELECT id INTO t_cs FROM auth.users WHERE email='dr.ahmed.ali@usindh.edu.pk'; END IF;

INSERT INTO public.profiles(id,email,full_name,role,department_id,verification)
VALUES(t_cs,'dr.ahmed.ali@usindh.edu.pk','Dr. Ahmed Ali','teacher',cs_dept,'approved')
ON CONFLICT(id) DO UPDATE SET role='teacher',verification='approved';

-- Dr. Sara Khan — IT
INSERT INTO auth.users(id,instance_id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,role,aud)
VALUES(gen_random_uuid(),'00000000-0000-0000-0000-000000000000','dr.sara.khan@usindh.edu.pk',
  crypt('Teacher@Demo2026!',gen_salt('bf')),now(),
  '{"provider":"email","providers":["email"],"portal_role":"teacher"}'::jsonb,
  jsonb_build_object('full_name','Dr. Sara Khan','department_id',it_dept),
  now(),now(),'authenticated','authenticated')
ON CONFLICT(email) DO NOTHING RETURNING id INTO t_it;

IF t_it IS NULL THEN SELECT id INTO t_it FROM auth.users WHERE email='dr.sara.khan@usindh.edu.pk'; END IF;

INSERT INTO public.profiles(id,email,full_name,role,department_id,verification)
VALUES(t_it,'dr.sara.khan@usindh.edu.pk','Dr. Sara Khan','teacher',it_dept,'approved')
ON CONFLICT(id) DO UPDATE SET role='teacher',verification='approved';

-- Mr. Usman Raza — SE
INSERT INTO auth.users(id,instance_id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,role,aud)
VALUES(gen_random_uuid(),'00000000-0000-0000-0000-000000000000','mr.usman.raza@usindh.edu.pk',
  crypt('Teacher@Demo2026!',gen_salt('bf')),now(),
  '{"provider":"email","providers":["email"],"portal_role":"teacher"}'::jsonb,
  jsonb_build_object('full_name','Mr. Usman Raza','department_id',se_dept),
  now(),now(),'authenticated','authenticated')
ON CONFLICT(email) DO NOTHING RETURNING id INTO t_se;

IF t_se IS NULL THEN SELECT id INTO t_se FROM auth.users WHERE email='mr.usman.raza@usindh.edu.pk'; END IF;

INSERT INTO public.profiles(id,email,full_name,role,department_id,verification)
VALUES(t_se,'mr.usman.raza@usindh.edu.pk','Mr. Usman Raza','teacher',se_dept,'approved')
ON CONFLICT(id) DO UPDATE SET role='teacher',verification='approved';

-- Ms. Nadia Shah — BBA
INSERT INTO auth.users(id,instance_id,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,role,aud)
VALUES(gen_random_uuid(),'00000000-0000-0000-0000-000000000000','ms.nadia.shah@usindh.edu.pk',
  crypt('Teacher@Demo2026!',gen_salt('bf')),now(),
  '{"provider":"email","providers":["email"],"portal_role":"teacher"}'::jsonb,
  jsonb_build_object('full_name','Ms. Nadia Shah','department_id',bba_dept),
  now(),now(),'authenticated','authenticated')
ON CONFLICT(email) DO NOTHING RETURNING id INTO t_bba;

IF t_bba IS NULL THEN SELECT id INTO t_bba FROM auth.users WHERE email='ms.nadia.shah@usindh.edu.pk'; END IF;

INSERT INTO public.profiles(id,email,full_name,role,department_id,verification)
VALUES(t_bba,'ms.nadia.shah@usindh.edu.pk','Ms. Nadia Shah','teacher',bba_dept,'approved')
ON CONFLICT(id) DO UPDATE SET role='teacher',verification='approved';

RAISE NOTICE 'Teachers: CS=% IT=% SE=% BBA=%', t_cs, t_it, t_se, t_bba;

-- ── 2. Courses ────────────────────────────────────────────────
INSERT INTO public.courses(title,code,kind,section,semester,threshold,department_id,teacher_id)
VALUES
  ('Data Structures',           'CS301', 'Theory',    'BSCS · Part III · A', 5, 75, cs_dept,  t_cs),
  ('Operating Systems',         'CS401', 'Theory',    'BSCS · Part III · A', 5, 75, cs_dept,  t_cs),
  ('Data Structures Lab',       'CS301L','Practical',  'BSCS · Part III · A', 5, 75, cs_dept,  t_cs),
  ('Web Technologies',          'IT302', 'Theory',    'BSIT · Part III · A', 5, 75, it_dept,  t_it),
  ('Network Security',          'IT401', 'Theory',    'BSIT · Part III · A', 5, 75, it_dept,  t_it),
  ('Software Requirements Eng', 'SE301', 'Theory',    'BSSE · Part III · A', 5, 75, se_dept,  t_se),
  ('Business Management',       'BBA301','Theory',    'BBA · Part III · A',  5, 75, bba_dept, t_bba)
ON CONFLICT DO NOTHING;

SELECT id INTO c_ds  FROM public.courses WHERE code='CS301'  AND section='BSCS · Part III · A';
SELECT id INTO c_os  FROM public.courses WHERE code='CS401'  AND section='BSCS · Part III · A';
SELECT id INTO c_dsl FROM public.courses WHERE code='CS301L' AND section='BSCS · Part III · A';
SELECT id INTO c_wt  FROM public.courses WHERE code='IT302'  AND section='BSIT · Part III · A';
SELECT id INTO c_ns  FROM public.courses WHERE code='IT401'  AND section='BSIT · Part III · A';
SELECT id INTO c_se1 FROM public.courses WHERE code='SE301'  AND section='BSSE · Part III · A';
SELECT id INTO c_bm  FROM public.courses WHERE code='BBA301' AND section='BBA · Part III · A';

RAISE NOTICE 'Courses ready: DS=% OS=% DSL=% WT=% NS=% SE1=% BM=%', c_ds,c_os,c_dsl,c_wt,c_ns,c_se1,c_bm;

-- ── 3. Students ───────────────────────────────────────────────
INSERT INTO auth.users(id,instance_id,email,encrypted_password,email_confirmed_at,raw_user_meta_data,created_at,updated_at,role,aud)
VALUES
  (gen_random_uuid(),'00000000-0000-0000-0000-000000000000','2k24cs001@usindh.edu.pk',crypt('Student@Demo2026!',gen_salt('bf')),now(),jsonb_build_object('full_name','Ali Hassan','roll_number','2k24cs001','department_id',cs_dept),now(),now(),'authenticated','authenticated'),
  (gen_random_uuid(),'00000000-0000-0000-0000-000000000000','2k24cs002@usindh.edu.pk',crypt('Student@Demo2026!',gen_salt('bf')),now(),jsonb_build_object('full_name','Fatima Noor','roll_number','2k24cs002','department_id',cs_dept),now(),now(),'authenticated','authenticated'),
  (gen_random_uuid(),'00000000-0000-0000-0000-000000000000','2k24it001@usindh.edu.pk',crypt('Student@Demo2026!',gen_salt('bf')),now(),jsonb_build_object('full_name','Bilal Ahmed','roll_number','2k24it001','department_id',it_dept),now(),now(),'authenticated','authenticated'),
  (gen_random_uuid(),'00000000-0000-0000-0000-000000000000','2k24se001@usindh.edu.pk',crypt('Student@Demo2026!',gen_salt('bf')),now(),jsonb_build_object('full_name','Zara Hussain','roll_number','2k24se001','department_id',se_dept),now(),now(),'authenticated','authenticated')
ON CONFLICT(email) DO NOTHING;

SELECT id INTO s1 FROM auth.users WHERE email='2k24cs001@usindh.edu.pk';
SELECT id INTO s2 FROM auth.users WHERE email='2k24cs002@usindh.edu.pk';
SELECT id INTO s3 FROM auth.users WHERE email='2k24it001@usindh.edu.pk';
SELECT id INTO s4 FROM auth.users WHERE email='2k24se001@usindh.edu.pk';

INSERT INTO public.profiles(id,email,full_name,role,roll_number,department_id,verification)
VALUES
  (s1,'2k24cs001@usindh.edu.pk','Ali Hassan',  'student','2k24cs001',cs_dept,'approved'),
  (s2,'2k24cs002@usindh.edu.pk','Fatima Noor', 'student','2k24cs002',cs_dept,'approved'),
  (s3,'2k24it001@usindh.edu.pk','Bilal Ahmed', 'student','2k24it001',it_dept,'approved'),
  (s4,'2k24se001@usindh.edu.pk','Zara Hussain','student','2k24se001',se_dept,'approved')
ON CONFLICT(id) DO UPDATE SET verification='approved';

RAISE NOTICE 'Students: s1=% s2=% s3=% s4=%', s1,s2,s3,s4;

-- ── 4. Enrollments ────────────────────────────────────────────
INSERT INTO public.enrollments(student_id,course_id) VALUES
  (s1,c_ds),(s1,c_os),(s1,c_dsl),
  (s2,c_ds),(s2,c_os),(s2,c_dsl),
  (s3,c_wt),(s3,c_ns),
  (s4,c_se1)
ON CONFLICT DO NOTHING;

-- ── 5. Class sessions Mon–Fri (4 weeks: 2 past + 2 upcoming) ─
-- Week offsets: -14, -7, 0(next Mon), +7 days from 2026-11-02
-- Timetable (all PKT = UTC+5):
--   Data Structures   CS301  : Mon,Wed 08:00–09:30  ICT Block · Room 101
--   Operating Systems CS401  : Tue,Thu 09:45–11:15  ICT Block · Room 102
--   DS Lab            CS301L : Fri    11:30–13:30  ICT Block · Lab 01
--   Web Technologies  IT302  : Mon,Wed 11:30–13:00  IT Block · Room 201
--   Network Security  IT401  : Tue,Thu 08:00–09:30  IT Block · Room 202
--   SW Req Eng        SE301  : Mon,Wed,Fri 14:00–15:30  SE Block · Room 301
--   Business Mgmt     BBA301 : Tue,Thu 11:30–13:00  Commerce Block · 101

FOR mon1 IN SELECT generate_series('2026-10-19'::date, '2026-11-09'::date, '7 days'::interval)::date LOOP
  DECLARE is_past bool := mon1 < '2026-11-03';
  BEGIN
  -- Monday sessions
  d := mon1;
  -- CS301 Mon
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_ds, (d||' 03:00:00+00')::timestamptz,(d||' 04:30:00+00')::timestamptz,'ICT Block · Room 101', CASE WHEN is_past THEN (d||' 04:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s1,'present',t_cs),(sess_id,s2,'present',t_cs) ON CONFLICT DO NOTHING;
  END IF;

  -- IT302 Mon
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_wt,(d||' 06:30:00+00')::timestamptz,(d||' 08:00:00+00')::timestamptz,'IT Block · Room 201', CASE WHEN is_past THEN (d||' 08:00:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s3,'present',t_it) ON CONFLICT DO NOTHING;
  END IF;

  -- SE301 Mon
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_se1,(d||' 09:00:00+00')::timestamptz,(d||' 10:30:00+00')::timestamptz,'SE Block · Room 301', CASE WHEN is_past THEN (d||' 10:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s4,'present',t_se) ON CONFLICT DO NOTHING;
  END IF;

  -- Tuesday sessions
  d := mon1 + 1;
  -- CS401 Tue
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_os,(d||' 04:45:00+00')::timestamptz,(d||' 06:15:00+00')::timestamptz,'ICT Block · Room 102', CASE WHEN is_past THEN (d||' 06:15:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s1,'present',t_cs),(sess_id,s2,'absent',t_cs) ON CONFLICT DO NOTHING;
  END IF;

  -- IT401 Tue
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_ns,(d||' 03:00:00+00')::timestamptz,(d||' 04:30:00+00')::timestamptz,'IT Block · Room 202', CASE WHEN is_past THEN (d||' 04:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s3,'late',t_it) ON CONFLICT DO NOTHING;
  END IF;

  -- BBA301 Tue
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_bm,(d||' 06:30:00+00')::timestamptz,(d||' 08:00:00+00')::timestamptz,'Commerce Block · 101', CASE WHEN is_past THEN (d||' 08:00:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING;

  -- Wednesday sessions
  d := mon1 + 2;
  -- CS301 Wed
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_ds,(d||' 03:00:00+00')::timestamptz,(d||' 04:30:00+00')::timestamptz,'ICT Block · Room 101', CASE WHEN is_past THEN (d||' 04:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s1,'present',t_cs),(sess_id,s2,'present',t_cs) ON CONFLICT DO NOTHING;
  END IF;

  -- IT302 Wed
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_wt,(d||' 06:30:00+00')::timestamptz,(d||' 08:00:00+00')::timestamptz,'IT Block · Room 201', CASE WHEN is_past THEN (d||' 08:00:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s3,'absent',t_it) ON CONFLICT DO NOTHING;
  END IF;

  -- SE301 Wed
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_se1,(d||' 09:00:00+00')::timestamptz,(d||' 10:30:00+00')::timestamptz,'SE Block · Room 301', CASE WHEN is_past THEN (d||' 10:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s4,'present',t_se) ON CONFLICT DO NOTHING;
  END IF;

  -- Thursday sessions
  d := mon1 + 3;
  -- CS401 Thu
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_os,(d||' 04:45:00+00')::timestamptz,(d||' 06:15:00+00')::timestamptz,'ICT Block · Room 102', CASE WHEN is_past THEN (d||' 06:15:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s1,'late',t_cs),(sess_id,s2,'present',t_cs) ON CONFLICT DO NOTHING;
  END IF;

  -- IT401 Thu
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_ns,(d||' 03:00:00+00')::timestamptz,(d||' 04:30:00+00')::timestamptz,'IT Block · Room 202', CASE WHEN is_past THEN (d||' 04:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s3,'present',t_it) ON CONFLICT DO NOTHING;
  END IF;

  -- BBA301 Thu
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_bm,(d||' 06:30:00+00')::timestamptz,(d||' 08:00:00+00')::timestamptz,'Commerce Block · 101', CASE WHEN is_past THEN (d||' 08:00:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING;

  -- Friday sessions
  d := mon1 + 4;
  -- CS301L Fri (lab)
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_dsl,(d||' 06:30:00+00')::timestamptz,(d||' 08:30:00+00')::timestamptz,'ICT Block · Lab 01', CASE WHEN is_past THEN (d||' 08:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s1,'present',t_cs),(sess_id,s2,'absent',t_cs) ON CONFLICT DO NOTHING;
  END IF;

  -- SE301 Fri
  INSERT INTO public.class_sessions(course_id,starts_at,ends_at,room,submitted_at)
  VALUES(c_se1,(d||' 09:00:00+00')::timestamptz,(d||' 10:30:00+00')::timestamptz,'SE Block · Room 301', CASE WHEN is_past THEN (d||' 10:30:00+00')::timestamptz ELSE NULL END)
  ON CONFLICT DO NOTHING RETURNING id INTO sess_id;
  IF is_past AND sess_id IS NOT NULL THEN
    INSERT INTO public.attendance(session_id,student_id,status,marked_by) VALUES
      (sess_id,s4,'present',t_se) ON CONFLICT DO NOTHING;
  END IF;

  END;
END LOOP;

RAISE NOTICE 'Seed complete! 4 weeks of Mon–Fri sessions created.';
END $$;
