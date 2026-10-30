-- University attendance. All times stored as timestamptz; display Asia/Karachi.
create schema if not exists private;
revoke all on schema private from public;
create type public.portal_role as enum ('student','teacher','admin');
create type public.review_state as enum ('pending','approved','rejected');
create type public.attendance_state as enum ('present','absent','late','excused');
create table public.departments (id uuid primary key default gen_random_uuid(), name text unique not null, code text unique not null);
create table public.profiles (
 id uuid primary key references auth.users on delete cascade,
 full_name text not null check(length(full_name) between 2 and 100), email text unique not null,
 roll_number text unique, department_id uuid references public.departments,
 role public.portal_role not null default 'student', verification public.review_state not null default 'pending',
 reviewed_by uuid references auth.users, reviewed_at timestamptz, created_at timestamptz not null default now(),
 check(role <> 'student' or roll_number is not null)
);
create table public.courses (
 id uuid primary key default gen_random_uuid(), department_id uuid not null references public.departments,
 title text not null, code text not null unique, teacher_id uuid not null references public.profiles,
 section text not null, semester integer not null check(semester between 1 and 12),
 kind text not null check(kind in ('Theory','Practical')), threshold integer not null default 75 check(threshold between 1 and 99),
 created_at timestamptz not null default now()
);
create table public.enrollments (course_id uuid references public.courses on delete cascade, student_id uuid references public.profiles, primary key(course_id,student_id));
create table public.class_sessions (
 id uuid primary key default gen_random_uuid(), course_id uuid not null references public.courses,
 starts_at timestamptz not null, ends_at timestamptz not null, room text not null,
 cancelled boolean not null default false, submitted_at timestamptz,
 unique(course_id,starts_at), check(ends_at > starts_at and ends_at <= starts_at + interval '12 hours')
);
create table public.attendance (
 session_id uuid not null references public.class_sessions, student_id uuid not null references public.profiles,
 status public.attendance_state not null, marked_by uuid not null references public.profiles,
 updated_at timestamptz not null default now(), primary key(session_id,student_id)
);
create table public.correction_requests (
 id uuid primary key default gen_random_uuid(), session_id uuid not null, student_id uuid not null,
 requested_status public.attendance_state not null, reason text not null check(length(reason) between 10 and 1000),
 state public.review_state not null default 'pending', resolution text, created_at timestamptz not null default now(),
 foreign key(session_id,student_id) references public.attendance,
 unique(session_id,student_id)
);
create table public.audit_logs (
 id bigint generated always as identity primary key, actor_id uuid references auth.users,
 action text not null, entity text not null, record_id text not null, old_value jsonb, new_value jsonb,
 created_at timestamptz not null default now()
);
create table private.portal_sessions (
 session_id uuid primary key, user_id uuid not null references auth.users on delete cascade,
 started_at timestamptz not null default now(), last_seen timestamptz not null default now(), revoked boolean not null default false
);
-- JWT session ID is signed by Supabase. Expiry is enforced in every data policy,
-- including direct Data API requests. Browser activity cannot resurrect expired sessions.
create function private.actor() returns uuid language sql stable security definer set search_path='' as $$
 select s.user_id from private.portal_sessions s join auth.sessions a on a.id=s.session_id
 where s.session_id=(auth.jwt()->>'session_id')::uuid and s.user_id=auth.uid()
 and not s.revoked and s.last_seen > now()-interval '30 minutes'
 and a.created_at > now()-interval '8 hours' and s.started_at > now()-interval '8 hours'
 and (a.not_after is null or a.not_after>now())
$$;
create function private.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=private.actor() and role='admin' and verification='approved')
$$;
create function private.is_approved() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles where id=private.actor() and verification='approved')
$$;
create function private.teaches(cid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.is_approved() and exists(select 1 from public.courses where id=cid and teacher_id=private.actor())
$$;
create function private.enrolled(cid uuid) returns boolean language sql stable security definer set search_path='' as $$
 select private.is_approved() and exists(select 1 from public.enrollments where course_id=cid and student_id=private.actor())
$$;
create function public.touch_session() returns boolean language plpgsql security definer set search_path='' as $$
 declare sid uuid := (auth.jwt()->>'session_id')::uuid;
 begin
 if auth.uid() is null or not exists(select 1 from auth.sessions where id=sid and user_id=auth.uid() and created_at>now()-interval '8 hours' and (not_after is null or not_after>now())) then return false; end if;
 if exists(select 1 from private.portal_sessions where session_id=sid and (revoked or last_seen<=now()-interval '30 minutes' or started_at<=now()-interval '8 hours')) then return false; end if;
 insert into private.portal_sessions(session_id,user_id) values(sid,auth.uid()) on conflict(session_id) do update set last_seen=now();
 return true;
 end $$;
create function public.close_session() returns void language sql security definer set search_path='' as $$
 update private.portal_sessions set revoked=true where session_id=(auth.jwt()->>'session_id')::uuid and user_id=auth.uid();
$$;
-- The trigger also protects signup through the Supabase API, not just our form.
create function private.on_signup() returns trigger language plpgsql security definer set search_path='' as $$
 declare roll text := lower(trim(new.raw_user_meta_data->>'roll_number'));
 declare dept uuid := (new.raw_user_meta_data->>'department_id')::uuid;
 begin
 if lower(new.email) in ('admin@usindh.edu.pk','teacher@usindh.edu.pk') then
   raise exception 'Staff accounts must be provisioned by the university administrator';
 end if;
 if lower(split_part(new.email,'@',2)) <> 'usindh.edu.pk' or new.email !~ '^[^@]+@[^@]+$' then raise exception 'University email required'; end if;
 if roll is null or roll !~ '^[a-z0-9-]{3,30}$' or lower(split_part(new.email,'@',1))<>roll then raise exception 'Email must match your roll number'; end if;
 if dept is null or not exists(select 1 from public.departments where id=dept) then raise exception 'Choose a valid department'; end if;
 insert into public.profiles(id,full_name,email,roll_number,department_id)
 values(new.id,trim(new.raw_user_meta_data->>'full_name'),lower(new.email),roll,dept);
 return new;
 end $$;
create trigger portal_signup after insert on auth.users for each row execute function private.on_signup();
-- Staff provisioning uses a trusted dashboard operation, documented in README.
create function public.review_student(student uuid, decision public.review_state) returns void language plpgsql security definer set search_path='' as $$
 declare before_row jsonb;
 begin
 if not private.is_admin() then raise exception 'Administrator access required'; end if;
 if decision='pending' then raise exception 'Choose approve or reject'; end if;
 select to_jsonb(p) into before_row from public.profiles p where id=student and role='student' for update;
 if before_row is null then raise exception 'Student not found'; end if;
 if not exists(select 1 from auth.users where id=student and email_confirmed_at is not null) then raise exception 'Student must confirm their university email first'; end if;
 update public.profiles set verification=decision,reviewed_by=private.actor(),reviewed_at=now() where id=student;
 insert into public.audit_logs(actor_id,action,entity,record_id,old_value,new_value) values(private.actor(),'review','profile',student::text,before_row,jsonb_build_object('verification',decision));
 end $$;
create function public.save_attendance(sid uuid, marks jsonb) returns void language plpgsql security definer set search_path='' as $$
 declare sess public.class_sessions; item jsonb; student uuid; mark public.attendance_state; previous jsonb;
 begin
 select * into sess from public.class_sessions where id=sid for update;
 if sess.id is null or not private.teaches(sess.course_id) then raise exception 'Assigned teacher access required'; end if;
 if sess.cancelled or now()<sess.starts_at or now()>=sess.starts_at+interval '24 hours' then raise exception 'Attendance is available only from period start until 24 hours later'; end if;
 if jsonb_typeof(marks)<>'array' or jsonb_array_length(marks)=0 then raise exception 'A complete roster is required'; end if;
 if jsonb_array_length(marks)<>(select count(*) from public.enrollments where course_id=sess.course_id) then raise exception 'Mark every enrolled student'; end if;
 if (select count(distinct x->>'student_id') from jsonb_array_elements(marks) x)<>jsonb_array_length(marks) then raise exception 'Duplicate students in submission'; end if;
 for item in select * from jsonb_array_elements(marks) loop
   student := (item->>'student_id')::uuid; mark := (item->>'status')::public.attendance_state;
   if mark is null or not exists(select 1 from public.enrollments e join public.profiles p on p.id=e.student_id where e.course_id=sess.course_id and e.student_id=student and p.verification='approved' and p.role='student') then raise exception 'Invalid or unverified student'; end if;
   select to_jsonb(a) into previous from public.attendance a where session_id=sid and student_id=student;
   insert into public.attendance(session_id,student_id,status,marked_by) values(sid,student,mark,private.actor()) on conflict(session_id,student_id) do update set status=excluded.status,marked_by=excluded.marked_by,updated_at=now();
   insert into public.audit_logs(actor_id,action,entity,record_id,old_value,new_value) values(private.actor(),'mark','attendance',sid||'/'||student,previous,jsonb_build_object('status',mark));
 end loop;
 update public.class_sessions set submitted_at=now() where id=sid;
 end $$;
create function public.resolve_correction(request_id uuid, approve boolean, explanation text) returns void language plpgsql security definer set search_path='' as $$
 declare req public.correction_requests; previous jsonb;
 begin
 if not private.is_admin() then raise exception 'Administrator access required'; end if;
 if length(trim(explanation))<10 then raise exception 'Please provide a resolution reason'; end if;
 select * into req from public.correction_requests where id=request_id and state='pending' for update;
 if req.id is null then raise exception 'Pending request not found'; end if;
 select to_jsonb(a) into previous from public.attendance a where session_id=req.session_id and student_id=req.student_id for update;
 if approve then update public.attendance set status=req.requested_status,marked_by=private.actor(),updated_at=now() where session_id=req.session_id and student_id=req.student_id; end if;
 update public.correction_requests set state=case when approve then 'approved'::public.review_state else 'rejected'::public.review_state end,resolution=explanation where id=request_id;
 insert into public.audit_logs(actor_id,action,entity,record_id,old_value,new_value) values(private.actor(),'correction','attendance',req.session_id||'/'||req.student_id,previous,jsonb_build_object('approved',approve,'status',req.requested_status,'reason',explanation));
 end $$;
-- Prevent timetable edits from reopening a completed attendance window.
create function private.protect_session() returns trigger language plpgsql set search_path='' as $$
 begin
 if old.starts_at<=now() and (new.starts_at<>old.starts_at or new.course_id<>old.course_id) then raise exception 'Started sessions cannot be rescheduled; create a makeup session'; end if;
 return new;
 end $$;
create trigger protect_started_session before update on public.class_sessions for each row execute function private.protect_session();
alter table public.departments enable row level security;
alter table public.profiles enable row level security;
alter table public.courses enable row level security;
alter table public.enrollments enable row level security;
alter table public.class_sessions enable row level security;
alter table public.attendance enable row level security;
alter table public.correction_requests enable row level security;
alter table public.audit_logs enable row level security;
create policy departments_read on public.departments for select to anon,authenticated using(true);
create policy departments_admin on public.departments for all to authenticated using(private.is_admin()) with check(private.is_admin());
create policy profiles_read on public.profiles for select to authenticated using(id=private.actor() or private.is_admin() or (private.is_approved() and exists(select 1 from public.enrollments e where e.student_id=profiles.id and private.teaches(e.course_id))));
create policy courses_read on public.courses for select to authenticated using(private.is_admin() or private.teaches(id) or private.enrolled(id));
create policy courses_admin on public.courses for all to authenticated using(private.is_admin()) with check(private.is_admin() and exists(select 1 from public.profiles p where p.id=teacher_id and p.role='teacher' and p.verification='approved'));
create policy enrollments_read on public.enrollments for select to authenticated using(private.is_admin() or private.teaches(course_id) or (student_id=private.actor() and private.is_approved()));
create policy enrollments_admin on public.enrollments for all to authenticated using(private.is_admin()) with check(private.is_admin() and exists(select 1 from public.profiles p join public.courses c on c.department_id=p.department_id where p.id=student_id and c.id=course_id and p.role='student' and p.verification='approved'));
create policy sessions_read on public.class_sessions for select to authenticated using(private.is_admin() or private.teaches(course_id) or private.enrolled(course_id));
create policy sessions_admin on public.class_sessions for all to authenticated using(private.is_admin()) with check(private.is_admin());
create policy attendance_read on public.attendance for select to authenticated using(private.is_admin() or (student_id=private.actor() and private.is_approved()) or exists(select 1 from public.class_sessions s where s.id=session_id and private.teaches(s.course_id)));
create policy corrections_read on public.correction_requests for select to authenticated using(private.is_admin() or (student_id=private.actor() and private.is_approved()));
create policy corrections_create on public.correction_requests for insert to authenticated with check(student_id=private.actor() and private.is_approved() and state='pending' and resolution is null);
create policy audit_read on public.audit_logs for select to authenticated using(private.is_admin());
revoke all on all tables in schema public from anon,authenticated;
grant select on public.departments to anon;
grant select on all tables in schema public to authenticated;
grant insert,update,delete on public.departments,public.courses,public.enrollments,public.class_sessions to authenticated;
grant insert on public.correction_requests to authenticated;
grant usage on schema private to authenticated;
revoke execute on all functions in schema public from public,anon,authenticated;
revoke execute on all functions in schema private from public,anon,authenticated;
grant execute on function private.actor(),private.is_admin(),private.is_approved(),private.teaches(uuid),private.enrolled(uuid) to authenticated;
grant execute on function public.touch_session(),public.close_session(),public.review_student(uuid,public.review_state),public.save_attendance(uuid,jsonb),public.resolve_correction(uuid,boolean,text) to authenticated;
insert into public.departments(name,code) values ('Computer Science','CS'),('Information Technology','IT'),('Software Engineering','SE'),('Business Administration','BBA');
create index courses_teacher on public.courses(teacher_id);
create index enrollment_student on public.enrollments(student_id);
create index sessions_start on public.class_sessions(starts_at);
create index attendance_student on public.attendance(student_id);
create index profiles_department on public.profiles(department_id);
