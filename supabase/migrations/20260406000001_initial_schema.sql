-- Climb sessions: one row per tracked session
create table if not exists climb_sessions (
  id          uuid primary key,
  user_id     uuid references auth.users not null,
  start_date  timestamptz not null,
  end_date    timestamptz not null,
  steps       integer not null default 0,
  floors      integer not null default 0,
  calories    double precision not null default 0,
  created_at  timestamptz default now()
);

alter table climb_sessions enable row level security;

create policy "users can manage own sessions"
  on climb_sessions for all
  using (auth.uid() = user_id);

-- Achievements: one row per (user, achievement) pair
create table if not exists achievements (
  user_id         uuid references auth.users not null,
  achievement_id  text not null,
  unlocked_date   timestamptz not null,
  primary key (user_id, achievement_id)
);

alter table achievements enable row level security;

create policy "users can manage own achievements"
  on achievements for all
  using (auth.uid() = user_id);
