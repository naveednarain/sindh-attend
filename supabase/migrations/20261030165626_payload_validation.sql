-- Explicit null checks prevent a NULL payload from submitting an empty roster.
create or replace function private.save_attendance(sid uuid, marks jsonb) returns void language plpgsql security definer set search_path='' as $$
 declare sess public.class_sessions; item jsonb; student uuid; mark public.attendance_state; previous jsonb;
 begin
 select * into sess from public.class_sessions where id=sid for update;
 if sess.id is null or not private.teaches(sess.course_id) then raise exception 'Assigned teacher access required'; end if;
 if sess.cancelled or clock_timestamp()<sess.starts_at or clock_timestamp()>=sess.starts_at+interval '24 hours' then raise exception 'Attendance is available only from period start until 24 hours later'; end if;
 if marks is null or jsonb_typeof(marks)<>'array' then raise exception 'A complete roster is required'; end if;
 if jsonb_array_length(marks)=0 then raise exception 'A complete roster is required'; end if;
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
