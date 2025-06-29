-- OneMoment+ 앱을 위한 Supabase 데이터베이스 스키마
-- 이 파일을 Supabase SQL Editor에서 실행하세요

-- moment_entries 테이블 생성
CREATE TABLE IF NOT EXISTS moment_entries (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    image_path VARCHAR(500),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- updated_at 자동 업데이트를 위한 함수 생성
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- updated_at 트리거 생성
CREATE TRIGGER update_moment_entries_updated_at
    BEFORE UPDATE ON moment_entries
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- 인덱스 생성 (성능 최적화)
CREATE INDEX IF NOT EXISTS idx_moment_entries_created_at ON moment_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moment_entries_title ON moment_entries(title);
CREATE INDEX IF NOT EXISTS idx_moment_entries_location ON moment_entries(latitude, longitude);

-- Row Level Security (RLS) 활성화
ALTER TABLE moment_entries ENABLE ROW LEVEL SECURITY;

-- 모든 사용자가 자신의 데이터만 접근할 수 있도록 하는 정책
-- (인증 시스템을 구현할 경우 사용)
-- CREATE POLICY "Users can view their own moments" ON moment_entries
--     FOR SELECT USING (auth.uid() = user_id);

-- CREATE POLICY "Users can insert their own moments" ON moment_entries
--     FOR INSERT WITH CHECK (auth.uid() = user_id);

-- CREATE POLICY "Users can update their own moments" ON moment_entries
--     FOR UPDATE USING (auth.uid() = user_id);

-- CREATE POLICY "Users can delete their own moments" ON moment_entries
--     FOR DELETE USING (auth.uid() = user_id);

-- 임시로 모든 사용자가 접근할 수 있도록 설정 (개발용)
-- 실제 배포 시에는 위의 인증 기반 정책으로 변경하세요
CREATE POLICY "Enable all access for moment_entries" ON moment_entries
    FOR ALL USING (true);

-- 스토리지 버킷 생성 (이미지 저장용)
-- Supabase Dashboard > Storage에서 수동으로 'moment-images' 버킷을 생성하거나
-- 아래 명령어를 사용하세요:
-- INSERT INTO storage.buckets (id, name, public) VALUES ('moment-images', 'moment-images', true);

-- 스토리지 정책 (모든 사용자가 업로드/다운로드 가능하도록 설정)
-- CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'moment-images');
-- CREATE POLICY "Public Upload" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'moment-images'); 