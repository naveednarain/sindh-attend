create index portal_sessions_user on private.portal_sessions(user_id);
-- Serialize scheduling checks, including concurrent inserts for the same teacher,
-- section, or room. New sessions cannot race past conflict detection.
create or replace function private.check_timetable() returns trigger language plpgsql security definer set search_path='' as $$
 declare teacher uuid; section_name text; department uuid; lock_key bigint;
 begin
 if new.cancelled then return new; end if;
 select teacher_id,section,department_id into teacher,section_name,department from public.courses where id=new.course_id;
 for lock_key in select distinct hashtextextended(v,0) from unnest(array['teacher:'||teacher,'section:'||department||':'||section_name,'room:'||lower(trim(new.room))]) v order by 1 loop perform pg_advisory_xact_lock(lock_key); end loop;
 if exists(select 1 from public.class_sessions s join public.courses c on c.id=s.course_id where s.id<>new.id and not s.cancelled and tstzrange(s.starts_at,s.ends_at,'[)')&&tstzrange(new.starts_at,new.ends_at,'[)') and (c.teacher_id=teacher or (c.section=section_name and c.department_id=department) or lower(trim(s.room))=lower(trim(new.room)))) then raise exception 'Timetable conflict: teacher, section, or room is already booked'; end if;
 return new;
 end $$;
-- A primary key prevents duplicates; this trigger preserves a submitted roster.
create function private.protect_enrollment() returns trigger language plpgsql security definer set search_path='' as $$
 declare cid uuid:=coalesce(new.course_id,old.course_id);
 begin
 if exists(select 1 from public.class_sessions where course_id=cid and submitted_at is not null) then raise exception 'Enrollment changes after attendance submission require academic office review'; end if;
 if tg_op='DELETE' then return old; end if;return new;
 end $$;
create trigger preserve_submitted_roster before insert or update or delete on public.enrollments for each row execute function private.protect_enrollment();
revoke execute on function private.protect_enrollment() from public,anon,authenticated;
-- Public schemas created later should not accidentally expose new tables/functions.
alter default privileges in schema public revoke execute on functions from public;
