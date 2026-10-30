-- Keep privileged implementations outside the exposed API schema.
alter function public.touch_session() set schema private;
alter function public.close_session() set schema private;
alter function public.review_student(uuid,public.review_state) set schema private;
alter function public.save_attendance(uuid,jsonb) set schema private;
alter function public.resolve_correction(uuid,boolean,text) set schema private;
create function public.touch_session() returns boolean language sql security invoker set search_path='' as $$select private.touch_session()$$;
create function public.close_session() returns void language sql security invoker set search_path='' as $$select private.close_session()$$;
create function public.review_student(student uuid,decision public.review_state) returns void language sql security invoker set search_path='' as $$select private.review_student(student,decision)$$;
create function public.save_attendance(sid uuid,marks jsonb) returns void language sql security invoker set search_path='' as $$select private.save_attendance(sid,marks)$$;
create function public.resolve_correction(request_id uuid,approve boolean,explanation text) returns void language sql security invoker set search_path='' as $$select private.resolve_correction(request_id,approve,explanation)$$;
revoke execute on function public.touch_session(),public.close_session(),public.review_student(uuid,public.review_state),public.save_attendance(uuid,jsonb),public.resolve_correction(uuid,boolean,text) from public,anon;
grant execute on function public.touch_session(),public.close_session(),public.review_student(uuid,public.review_state),public.save_attendance(uuid,jsonb),public.resolve_correction(uuid,boolean,text) to authenticated;
create or replace function private.on_signup() returns trigger language plpgsql security definer set search_path='' as $$
 declare roll text := lower(trim(new.raw_user_meta_data->>'roll_number'));
 declare dept uuid := (new.raw_user_meta_data->>'department_id')::uuid;
 declare staff_role text := new.raw_app_meta_data->>'portal_role';
 begin
 -- app_metadata is written only by trusted Auth administration, never by signUp.
 if staff_role in ('admin','teacher') then
   if lower(split_part(new.email,'@',2))<>'usindh.edu.pk' then raise exception 'University email required'; end if;
   insert into public.profiles(id,full_name,email,role,department_id,verification)
   values(new.id,coalesce(nullif(trim(new.raw_user_meta_data->>'full_name'),''),'University Staff'),lower(new.email),staff_role::public.portal_role,dept,'approved');
   return new;
 end if;
 if lower(new.email) in ('admin@usindh.edu.pk','teacher@usindh.edu.pk') then raise exception 'Staff accounts must be provisioned by the university administrator'; end if;
 if lower(split_part(new.email,'@',2))<>'usindh.edu.pk' or new.email !~ '^[^@]+@[^@]+$' then raise exception 'University email required'; end if;
 if roll is null or roll !~ '^[a-z0-9-]{3,30}$' or lower(split_part(new.email,'@',1))<>roll then raise exception 'Email must match your roll number'; end if;
 if dept is null or not exists(select 1 from public.departments where id=dept) then raise exception 'Choose a valid department'; end if;
 insert into public.profiles(id,full_name,email,roll_number,department_id) values(new.id,trim(new.raw_user_meta_data->>'full_name'),lower(new.email),roll,dept);
 return new;
 end $$;
create function private.check_timetable() returns trigger language plpgsql security definer set search_path='' as $$
 declare teacher uuid; section_name text; department uuid;
 begin
 if new.cancelled then return new; end if;
 select teacher_id,section,department_id into teacher,section_name,department from public.courses where id=new.course_id;
 if exists(select 1 from public.class_sessions s join public.courses c on c.id=s.course_id where s.id<>new.id and not s.cancelled and tstzrange(s.starts_at,s.ends_at,'[)')&&tstzrange(new.starts_at,new.ends_at,'[)') and (c.teacher_id=teacher or (c.section=section_name and c.department_id=department) or lower(trim(s.room))=lower(trim(new.room)))) then raise exception 'Timetable conflict: teacher, section, or room is already booked'; end if;
 return new;
 end $$;
create trigger timetable_conflicts before insert or update on public.class_sessions for each row execute function private.check_timetable();
revoke execute on function private.check_timetable() from public,anon,authenticated;
-- Common FK lookup indexes keep permissions and reports efficient.
create index profiles_reviewer on public.profiles(reviewed_by);
create index courses_department on public.courses(department_id);
create index attendance_marker on public.attendance(marked_by);
create index corrections_student on public.correction_requests(student_id);
create index audit_actor on public.audit_logs(actor_id);
