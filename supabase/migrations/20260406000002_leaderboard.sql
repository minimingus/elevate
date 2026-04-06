-- User profiles: opt-in display name for leaderboard
create table if not exists user_profiles (
  user_id      uuid references auth.users primary key,
  display_name text not null check (char_length(display_name) between 2 and 30),
  created_at   timestamptz default now()
);

alter table user_profiles enable row level security;

-- Anyone can read profiles (needed to show leaderboard)
create policy "profiles are public read"
  on user_profiles for select using (true);

-- Users can only insert/update/delete their own profile
create policy "users manage own profile"
  on user_profiles for all using (auth.uid() = user_id);

-- RPC: weekly leaderboard (top 20 by steps this calendar week)
create or replace function weekly_leaderboard()
returns table(display_name text, weekly_steps bigint, rank bigint)
language sql
security definer
stable
as $$
  select
    p.display_name,
    coalesce(sum(s.steps), 0)::bigint as weekly_steps,
    rank() over (order by coalesce(sum(s.steps), 0) desc) as rank
  from user_profiles p
  left join climb_sessions s
    on s.user_id = p.user_id
    and s.start_date >= date_trunc('week', current_timestamp at time zone 'utc')
  group by p.display_name
  order by weekly_steps desc
  limit 20;
$$;
