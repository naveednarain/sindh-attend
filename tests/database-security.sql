-- Run against the development project using an administrative SQL connection.
-- Every fixture is rolled back. No email is sent and no test identity persists.
begin;
create temp table fixture as select
 gen_random_uuid() teacher,gen_random_uuid() student,gen_random_uuid() other_teacher,gen_random_uuid() admin,
 gen_random_uuid() teacher_session,gen_random_uuid() student_session,gen_random_uuid() other_session,gen_random_uuid() admin_session,
 gen_random_uuid() course,gen_random_uuid() period_open,gen_random_uuid() period_future,gen_random_uuid() period_closed,gen_random_uuid() period_boundary,
 (select id from public.departments order by code limit 1) dept;
grant select on fixture to authenticated;
create temp table test_results (test text,passed boolean);
grant insert,select on test_results to authenticated;
insert into auth.users(id,email,email_confirmed_at,raw_app_meta_data,raw_user_meta_data)
select teacher,'test-faculty@usindh.edu.pk',now(),'{"portal_role":"teacher"}'::jsonb,jsonb_build_object('full_name','Test Teacher','department_id',dept) from fixture
union all select other_teacher,'test-other-faculty@usindh.edu.pk',now(),'{"portal_role":"teacher"}'::jsonb,jsonb_build_object('full_name','Other Teacher','department_id',dept) from fixture
union all select admin,'test-administrator@usindh.edu.pk',now(),'{"portal_role":"admin"}'::jsonb,jsonb_build_object('full_name','Test Administrator','department_id',dept) from fixture
union all select student,'test-roll-900@usindh.edu.pk',now(),'{}'::jsonb,jsonb_build_object('full_name','Test Student','roll_number','test-roll-900','department_id',dept) from fixture;
update public.profiles set verification='approved' where id=(select student from fixture);
insert into auth.sessions(id,user_id,created_at,updated_at,aal)
select teacher_session,teacher,now(),now(),'aal1'::auth.aal_level from fixture union all select student_session,student,now(),now(),'aal1'::auth.aal_level from fixture union all select other_session,other_teacher,now(),now(),'aal1'::auth.aal_level from fixture union all select admin_session,admin,now(),now(),'aal1'::auth.aal_level from fixture;
insert into public.courses(id,department_id,title,code,teacher_id,section,semester,kind) select course,dept,'Security Test','__SECURITY_TEST__',teacher,'__test_section__',1,'Theory' from fixture;
insert into public.enrollments select course,student from fixture;
insert into public.class_sessions(id,course_id,starts_at,ends_at,room)
 select period_open,course,now()-interval '2 hours',now()-interval '1 hour','__test_room__' from fixture
 union all select period_future,course,now()+interval '1 hour',now()+interval '2 hours','__test_room__' from fixture
 union all select period_closed,course,now()-interval '26 hours',now()-interval '25 hours','__test_room__' from fixture
 union all select period_boundary,course,now()-interval '24 hours',now()-interval '23 hours','__test_room__' from fixture;
select set_config('request.jwt.claims',(select jsonb_build_object('sub',teacher,'session_id',teacher_session,'role','authenticated')::text from fixture),true);
set local role authenticated;
do $$declare f record; m jsonb; target uuid; blocked boolean; begin
 select * into f from fixture;
 if not public.touch_session() then raise exception 'Teacher session rejected';end if;
 m:=jsonb_build_array(jsonb_build_object('student_id',f.student,'status','present'));
 perform public.save_attendance(f.period_open,m);
 insert into test_results values('assigned teacher can submit inside 24 hours',true);
 foreach target in array array[f.period_future,f.period_closed,f.period_boundary] loop
 blocked:=false;
 begin perform public.save_attendance(target,m);exception when others then if sqlerrm like 'Attendance is available only%' then blocked:=true;else raise;end if;end;
 if not blocked then raise exception 'Time restriction was bypassed';end if;
 end loop;
 insert into test_results values('before start, after 24 hours, and exact cutoff are blocked',true);
 blocked:=false;begin perform public.save_attendance(f.period_open,'[]');exception when others then blocked:=true;end;
 if not blocked then raise exception 'Empty roster accepted';end if;
 insert into test_results values('incomplete roster rejected',true);
 blocked:=false;begin perform public.save_attendance(f.period_open,null);exception when others then blocked:=true;end;
 if not blocked then raise exception 'NULL roster accepted';end if;
 insert into test_results values('NULL roster rejected',true);
 if not public.consume_assistant_quota() then raise exception 'Initial assistant quota rejected';end if;
 if public.consume_assistant_quota() then raise exception 'Assistant cooldown bypassed';end if;
 insert into test_results values('assistant quota and cooldown enforced',true);
end$$;
reset role;
select set_config('request.jwt.claims',(select jsonb_build_object('sub',other_teacher,'session_id',other_session,'role','authenticated')::text from fixture),true);
set local role authenticated;
do $$declare f record; blocked boolean:=false;begin
 select * into f from fixture;perform public.touch_session();
 begin perform public.save_attendance(f.period_open,jsonb_build_array(jsonb_build_object('student_id',f.student,'status','absent')));exception when others then if sqlerrm='Assigned teacher access required' then blocked:=true;else raise;end if;end;
 if not blocked then raise exception 'Unassigned teacher wrote attendance';end if;
 if exists(select 1 from public.attendance) then raise exception 'Unassigned teacher read attendance';end if;
 insert into test_results values('unassigned teacher cannot read or write the course',true);
end$$;
reset role;
select set_config('request.jwt.claims',(select jsonb_build_object('sub',student,'session_id',student_session,'role','authenticated')::text from fixture),true);
set local role authenticated;
do $$declare f record; blocked boolean:=false;begin
 select * into f from fixture;perform public.touch_session();
 if (select count(*) from public.attendance)<>1 then raise exception 'Student cannot read own attendance';end if;
 begin insert into public.attendance values(f.period_future,f.student,'present',f.student,now());exception when insufficient_privilege then blocked:=true;end;
 if not blocked then raise exception 'Direct attendance write accepted';end if;
 blocked:=false;begin update public.profiles set role='admin' where id=f.student;exception when insufficient_privilege then blocked:=true;end;
 if not blocked then raise exception 'Self promotion accepted';end if;
 blocked:=false;begin perform public.review_student(f.student,'approved');exception when others then if sqlerrm='Administrator access required' then blocked:=true;else raise;end if;end;
 if not blocked then raise exception 'Student approved an account';end if;
 if exists(select 1 from public.profiles where id<>f.student) then raise exception 'Student read another profile';end if;
 insert into test_results values('student reads own records; direct writes and privilege escalation blocked',true);
end$$;
reset role;
update private.portal_sessions set last_seen=now()-interval '31 minutes' where user_id=(select student from fixture);
set local role authenticated;
do $$begin
 if public.touch_session() then raise exception 'Expired idle session was resurrected';end if;
 if exists(select 1 from public.attendance) then raise exception 'Idle session retained data access';end if;
 insert into test_results values('expired idle sessions cannot refresh or read records',true);
end$$;
reset role;
select set_config('request.jwt.claims',(select jsonb_build_object('sub',teacher,'session_id',teacher_session,'role','authenticated')::text from fixture),true);
update auth.sessions set created_at=now()-interval '8 hours' where id=(select teacher_session from fixture);
set local role authenticated;
do $$begin if public.touch_session() then raise exception '8 hour session was resurrected';end if;if exists(select 1 from public.attendance) then raise exception '8 hour session retained access';end if;insert into test_results values('absolute 8-hour session expiry enforced',true);end$$;
reset role;
do $$declare blocked boolean:=false;f record;begin
 select * into f from fixture;
 begin insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values(gen_random_uuid(),'fake@gmail.com','{}',jsonb_build_object('full_name','Fake User','roll_number','fake','department_id',f.dept));exception when others then if sqlerrm='University email required' then blocked:=true;else raise;end if;end;
 if not blocked then raise exception 'External domain accepted';end if;
 blocked:=false;begin insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values(gen_random_uuid(),'wrong@usindh.edu.pk','{}',jsonb_build_object('full_name','Fake User','roll_number','different','department_id',f.dept));exception when others then if sqlerrm='Email must match your roll number' then blocked:=true;else raise;end if;end;
 if not blocked then raise exception 'Mismatched roll accepted';end if;
 blocked:=false;begin insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data) values(gen_random_uuid(),'teacher@usindh.edu.pk','{}',jsonb_build_object('full_name','Fake Staff','role','admin','department_id',f.dept));exception when others then if sqlerrm like 'Staff accounts must%' then blocked:=true;else raise;end if;end;
 if not blocked then raise exception 'Staff account claimed through signup';end if;
 insert into test_results values('external emails, mismatched rolls, and staff self-registration blocked',true);
 if not exists(select 1 from public.audit_logs where actor_id=f.teacher and action='mark') then raise exception 'Audit record missing';end if;
 insert into test_results values('attendance writes create audit records',true);
end$$;
select * from test_results;
rollback;


