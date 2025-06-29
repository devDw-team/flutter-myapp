-- OneMoment+ 데이터베이스 스키마 테스트
-- Supabase SQL Editor에서 실행할 수 있는 간단한 테스트

-- 1. 기존 테이블 확인
SELECT 
    table_name, 
    table_type 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('moment_entries', 'user_profiles', 'moment_media')
ORDER BY table_name;

-- 2. moment_entries 테이블 구조 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'moment_entries' 
ORDER BY ordinal_position;

-- 3. 간단한 테이블 생성 테스트 (user_profiles)
CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    bio TEXT,
    birth_date DATE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 4. 생성된 테이블 확인
SELECT 'user_profiles 테이블 생성됨' as status;

-- 5. RLS 활성화 확인
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename IN ('moment_entries', 'user_profiles')
AND schemaname = 'public';

-- 6. 인덱스 존재 확인
SELECT 
    indexname,
    tablename,
    indexdef
FROM pg_indexes 
WHERE tablename = 'moment_entries'
AND schemaname = 'public'
ORDER BY indexname;