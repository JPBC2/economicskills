-- Fix Row Level Security policies for user_spreadsheets table
-- This allows authenticated users to manage their own spreadsheet records

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own spreadsheets" ON user_spreadsheets;
DROP POLICY IF EXISTS "Users can insert own spreadsheets" ON user_spreadsheets;
DROP POLICY IF EXISTS "Users can update own spreadsheets" ON user_spreadsheets;
DROP POLICY IF EXISTS "Users can delete own spreadsheets" ON user_spreadsheets;

-- Enable RLS on the table (if not already enabled)
ALTER TABLE user_spreadsheets ENABLE ROW LEVEL SECURITY;

-- Create policies that allow users to manage their own records
CREATE POLICY "Users can view own spreadsheets"
  ON user_spreadsheets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own spreadsheets"
  ON user_spreadsheets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own spreadsheets"
  ON user_spreadsheets FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own spreadsheets"
  ON user_spreadsheets FOR DELETE
  USING (auth.uid() = user_id);
