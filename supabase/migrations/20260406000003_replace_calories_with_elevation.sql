-- Replace calories with elevation_meters in climb_sessions
alter table climb_sessions
    rename column calories to elevation_meters;

alter table climb_sessions
    alter column elevation_meters set default 0;
