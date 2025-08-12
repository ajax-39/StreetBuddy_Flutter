-- Add missing columns to existing search_queries table
-- Run this SQL in your Supabase SQL editor

-- Add the missing columns to your existing table
ALTER TABLE public.search_queries 
ADD COLUMN IF NOT EXISTS result_type text,
ADD COLUMN IF NOT EXISTS result_name text,
ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_search_queries_username ON public.search_queries(username);
CREATE INDEX IF NOT EXISTS idx_search_queries_executed_at ON public.search_queries(executed_at DESC);
CREATE INDEX IF NOT EXISTS idx_search_queries_result_type ON public.search_queries(result_type);

-- Update the SearchService insert statement after running this SQL
-- The insert will then include:
-- 'result_type': resultType,
-- 'result_name': resultName,
