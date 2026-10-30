create table private.assistant_usage(user_id uuid references auth.users on delete cascade, day date not null, requests integer not null default 0, last_request timestamptz not null default now(), primary key(user_id,day));
create function private.consume_assistant_quota() returns boolean language plpgsql security definer set search_path='' as $$
 declare actor uuid:=private.actor(); used integer;
 begin
 if actor is null or not private.is_approved() then return false;end if;
 insert into private.assistant_usage(user_id,day,requests) values(actor,(now() at time zone 'Asia/Karachi')::date,1)
 on conflict(user_id,day) do update set requests=private.assistant_usage.requests+1,last_request=now()
 where private.assistant_usage.requests<10 and private.assistant_usage.last_request<now()-interval '15 seconds'
 returning requests into used;
 return used is not null;
 end $$;
create function public.consume_assistant_quota() returns boolean language sql security invoker set search_path='' as $$select private.consume_assistant_quota()$$;
revoke execute on function private.consume_assistant_quota(),public.consume_assistant_quota() from public,anon;
grant execute on function private.consume_assistant_quota(),public.consume_assistant_quota() to authenticated;
