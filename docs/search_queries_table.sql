-- Enhanced search_queries table structure
-- Run this SQL in your Supabase SQL editor

-- First, create the extension if it doesn't exist
create extension if not exists "uuid-ossp";

-- Drop the existing table if you want to recreate it with new structure
-- DROP TABLE IF EXISTS public.search_queries;

-- Create the enhanced search_queries table
create table if not exists public.search_queries (
  id uuid primary key default uuid_generate_v4(),
  username text not null,
  query_text text not null,
  result_type text, -- 'location', 'place', 'history_search', 'suggested_search'
  result_name text, -- name of the clicked result
  executed_at timestamptz not null default now(),
  created_at timestamptz default now()
);

-- Add indexes for better query performance
create index if not exists idx_search_queries_username on public.search_queries(username);
create index if not exists idx_search_queries_executed_at on public.search_queries(executed_at desc);
create index if not exists idx_search_queries_result_type on public.search_queries(result_type);

-- Enable Row Level Security (RLS)
alter table public.search_queries enable row level security;

-- Create policies for RLS (optional - adjust based on your app's security needs)
-- Users can only see their own search queries
create policy "Users can view own search queries" on public.search_queries
  for select using (auth.uid()::text in (
    select uid from public.users where username = search_queries.username
  ));

-- Users can insert their own search queries
create policy "Users can insert own search queries" on public.search_queries
  for insert with check (auth.uid()::text in (
    select uid from public.users where username = search_queries.username
  ));

-- Function to get popular searches (optional)
create or replace function get_popular_searches(search_limit int default 10)
returns table(query_text text, search_count bigint)
language sql
as $$
  select 
    sq.query_text,
    count(*) as search_count
  from public.search_queries sq
  where sq.executed_at >= now() - interval '30 days'
    and sq.result_type in ('location', 'place')
  group by sq.query_text
  order by search_count desc
  limit search_limit;
$$;

-- Function to get user search analytics (optional)
create or replace function get_user_search_analytics(target_username text)
returns table(
  total_searches bigint,
  unique_queries bigint,
  most_searched_query text,
  last_search_date timestamptz
)
language sql
as $$
  select 
    count(*) as total_searches,
    count(distinct query_text) as unique_queries,
    (
      select query_text 
      from public.search_queries 
      where username = target_username 
      group by query_text 
      order by count(*) desc 
      limit 1
    ) as most_searched_query,
    max(executed_at) as last_search_date
  from public.search_queries
  where username = target_username;
$$;
