-- OneMoment+ 완전한 데이터베이스 스키마
-- 2024-06-29 생성
-- 기존 moment_entries 테이블을 기반으로 확장

-- =====================================================
-- 1. 사용자 관련 테이블
-- =====================================================

-- 사용자 프로필 상세 정보 (auth.users와 연동)
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

-- 사용자 통계 정보
CREATE TABLE IF NOT EXISTS user_statistics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    total_moments INTEGER DEFAULT 0,
    total_media INTEGER DEFAULT 0,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    avg_mood_score DECIMAL(3,2) DEFAULT 0.00,
    monthly_stats JSONB DEFAULT '{}',
    last_calculated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- =====================================================
-- 2. 기존 moment_entries 테이블 확장
-- =====================================================

-- moment_entries 테이블에 새로운 컬럼 추가
DO $$ 
BEGIN
    -- user_id 컬럼 추가 (기존 데이터 처리 필요)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'user_id') THEN
        ALTER TABLE moment_entries ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- 기분/감정 관련 컬럼
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'mood') THEN
        ALTER TABLE moment_entries ADD COLUMN mood VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'mood_score') THEN
        ALTER TABLE moment_entries ADD COLUMN mood_score DECIMAL(3,2) CHECK (mood_score >= 0 AND mood_score <= 10);
    END IF;
    
    -- 날씨 관련 컬럼
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'weather') THEN
        ALTER TABLE moment_entries ADD COLUMN weather VARCHAR(50);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'temperature') THEN
        ALTER TABLE moment_entries ADD COLUMN temperature DECIMAL(5,2);
    END IF;
    
    -- 프라이버시 설정
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'privacy_level') THEN
        ALTER TABLE moment_entries ADD COLUMN privacy_level VARCHAR(20) DEFAULT 'private' 
            CHECK (privacy_level IN ('private', 'friends', 'public'));
    END IF;
    
    -- 메타데이터
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'metadata') THEN
        ALTER TABLE moment_entries ADD COLUMN metadata JSONB DEFAULT '{}';
    END IF;
    
    -- 실제 일기 작성 시간 (created_at과 구분)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'moment_entries' AND column_name = 'moment_date') THEN
        ALTER TABLE moment_entries ADD COLUMN moment_date TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- =====================================================
-- 3. 멀티미디어 및 위치 정보 테이블
-- =====================================================

-- 멀티미디어 파일 관리
CREATE TABLE IF NOT EXISTS moment_media (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    moment_id UUID REFERENCES moment_entries(id) ON DELETE CASCADE,
    media_type VARCHAR(20) NOT NULL CHECK (media_type IN ('image', 'video', 'audio')),
    file_path VARCHAR(500) NOT NULL,
    original_filename VARCHAR(255),
    file_size BIGINT,
    metadata JSONB DEFAULT '{}', -- 해상도, 촬영 정보 등
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 위치 정보 테이블
CREATE TABLE IF NOT EXISTS moment_locations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    moment_id UUID REFERENCES moment_entries(id) ON DELETE CASCADE,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_name VARCHAR(255),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100),
    place_id VARCHAR(255), -- Google Places API ID
    location_metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(moment_id)
);

-- =====================================================
-- 4. 태그 및 카테고리 시스템
-- =====================================================

-- 태그 시스템
CREATE TABLE IF NOT EXISTS tags (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(7) DEFAULT '#007AFF', -- HEX 색상
    icon VARCHAR(50),
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- 일기-태그 연결 테이블
CREATE TABLE IF NOT EXISTS moment_tags (
    moment_id UUID REFERENCES moment_entries(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (moment_id, tag_id)
);

-- 카테고리 시스템
CREATE TABLE IF NOT EXISTS categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    color VARCHAR(7) DEFAULT '#007AFF',
    icon VARCHAR(50),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, name)
);

-- 일기-카테고리 연결 테이블
CREATE TABLE IF NOT EXISTS moment_categories (
    moment_id UUID REFERENCES moment_entries(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (moment_id, category_id)
);

-- =====================================================
-- 5. 부가 기능 테이블
-- =====================================================

-- 기분 추적 테이블
CREATE TABLE IF NOT EXISTS mood_tracking (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    mood_name VARCHAR(50) NOT NULL,
    mood_score DECIMAL(3,2) CHECK (mood_score >= 0 AND mood_score <= 10),
    notes TEXT,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 백업 세션 관리
CREATE TABLE IF NOT EXISTS backup_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    backup_type VARCHAR(20) NOT NULL CHECK (backup_type IN ('full', 'incremental', 'media_only')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    file_path VARCHAR(500),
    file_size BIGINT,
    metadata JSONB DEFAULT '{}',
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 알림 시스템
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL, -- 'reminder', 'backup', 'system', etc.
    title VARCHAR(255) NOT NULL,
    message TEXT,
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    scheduled_at TIMESTAMP WITH TIME ZONE,
    sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 동기화 로그
CREATE TABLE IF NOT EXISTS sync_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id VARCHAR(100),
    sync_type VARCHAR(20) NOT NULL CHECK (sync_type IN ('upload', 'download', 'conflict_resolution')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'failed')),
    changes JSONB DEFAULT '{}',
    sync_started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sync_completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 6. 성능 최적화 인덱스
-- =====================================================

-- 사용자 관련 인덱스
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_statistics_user_id ON user_statistics(user_id);

-- 일기 엔트리 최적화 인덱스
CREATE INDEX IF NOT EXISTS idx_moment_entries_user_id ON moment_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_moment_entries_created_at ON moment_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moment_entries_moment_date ON moment_entries(moment_date DESC);
CREATE INDEX IF NOT EXISTS idx_moment_entries_user_created ON moment_entries(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_moment_entries_user_mood ON moment_entries(user_id, mood);
CREATE INDEX IF NOT EXISTS idx_moment_entries_privacy ON moment_entries(privacy_level);

-- 전문 검색 인덱스
CREATE INDEX IF NOT EXISTS idx_moment_entries_title_search ON moment_entries USING gin(to_tsvector('english', title));
CREATE INDEX IF NOT EXISTS idx_moment_entries_content_search ON moment_entries USING gin(to_tsvector('english', content));
CREATE INDEX IF NOT EXISTS idx_moment_entries_combined_search ON moment_entries USING gin(to_tsvector('english', title || ' ' || content));

-- 미디어 파일 인덱스
CREATE INDEX IF NOT EXISTS idx_moment_media_moment_id ON moment_media(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_media_type ON moment_media(media_type);
CREATE INDEX IF NOT EXISTS idx_moment_media_display_order ON moment_media(moment_id, display_order);

-- 위치 정보 인덱스
CREATE INDEX IF NOT EXISTS idx_moment_locations_moment_id ON moment_locations(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_locations_coordinates ON moment_locations(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_moment_locations_city ON moment_locations(city);

-- 태그 시스템 인덱스
CREATE INDEX IF NOT EXISTS idx_tags_user_id ON tags(user_id);
CREATE INDEX IF NOT EXISTS idx_tags_name ON tags(user_id, name);
CREATE INDEX IF NOT EXISTS idx_tags_usage_count ON tags(usage_count DESC);
CREATE INDEX IF NOT EXISTS idx_moment_tags_moment_id ON moment_tags(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_tags_tag_id ON moment_tags(tag_id);

-- 카테고리 인덱스
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON categories(user_id);
CREATE INDEX IF NOT EXISTS idx_categories_sort_order ON categories(user_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_moment_categories_moment_id ON moment_categories(moment_id);

-- 기분 추적 인덱스
CREATE INDEX IF NOT EXISTS idx_mood_tracking_user_id ON mood_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_mood_tracking_recorded_at ON mood_tracking(user_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_mood_tracking_mood_score ON mood_tracking(user_id, mood_score);

-- 알림 시스템 인덱스
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_at) WHERE scheduled_at IS NOT NULL;

-- 동기화 로그 인덱스
CREATE INDEX IF NOT EXISTS idx_sync_logs_user_device ON sync_logs(user_id, device_id);
CREATE INDEX IF NOT EXISTS idx_sync_logs_status ON sync_logs(status, sync_started_at);

-- =====================================================
-- 7. 트리거 및 함수
-- =====================================================

-- 업데이트 타임스탬프 자동 관리 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 각 테이블에 트리거 적용
DO $$
BEGIN
    -- user_profiles 트리거
    DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
    CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    -- moment_entries 트리거
    DROP TRIGGER IF EXISTS update_moment_entries_updated_at ON moment_entries;
    CREATE TRIGGER update_moment_entries_updated_at BEFORE UPDATE ON moment_entries
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    -- tags 트리거
    DROP TRIGGER IF EXISTS update_tags_updated_at ON tags;
    CREATE TRIGGER update_tags_updated_at BEFORE UPDATE ON tags
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    -- categories 트리거
    DROP TRIGGER IF EXISTS update_categories_updated_at ON categories;
    CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

    -- user_statistics 트리거
    DROP TRIGGER IF EXISTS update_user_statistics_updated_at ON user_statistics;
    CREATE TRIGGER update_user_statistics_updated_at BEFORE UPDATE ON user_statistics
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
END $$;

-- 태그 사용 횟수 자동 업데이트
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE tags SET usage_count = GREATEST(usage_count - 1, 0) WHERE id = OLD.tag_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trigger_update_tag_usage ON moment_tags;
CREATE TRIGGER trigger_update_tag_usage
    AFTER INSERT OR DELETE ON moment_tags
    FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();

-- 사용자 통계 자동 업데이트
CREATE OR REPLACE FUNCTION update_user_statistics_on_moment_change()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_statistics (user_id, total_moments, last_calculated_at)
        VALUES (NEW.user_id, 1, NOW())
        ON CONFLICT (user_id) DO UPDATE SET
            total_moments = user_statistics.total_moments + 1,
            last_calculated_at = NOW();
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE user_statistics SET
            total_moments = GREATEST(total_moments - 1, 0),
            last_calculated_at = NOW()
        WHERE user_id = OLD.user_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS trigger_update_user_stats_moments ON moment_entries;
CREATE TRIGGER trigger_update_user_stats_moments
    AFTER INSERT OR DELETE ON moment_entries
    FOR EACH ROW EXECUTE FUNCTION update_user_statistics_on_moment_change();

-- =====================================================
-- 8. Row Level Security (RLS) 정책
-- =====================================================

-- 모든 테이블에 RLS 활성화
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_statistics ENABLE ROW LEVEL SECURITY;
ALTER TABLE moment_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE moment_media ENABLE ROW LEVEL SECURITY;
ALTER TABLE moment_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE moment_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE moment_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE backup_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_logs ENABLE ROW LEVEL SECURITY;

-- 사용자 프로필 정책
DROP POLICY IF EXISTS "Users can manage own profile details" ON user_profiles;
CREATE POLICY "Users can manage own profile details" ON user_profiles
    FOR ALL USING (auth.uid() = user_id);

-- 일기 엔트리 정책
DROP POLICY IF EXISTS "Users can manage own moments" ON moment_entries;
CREATE POLICY "Users can manage own moments" ON moment_entries
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public moments are viewable" ON moment_entries;
CREATE POLICY "Public moments are viewable" ON moment_entries
    FOR SELECT USING (privacy_level = 'public');

-- 미디어 파일 정책
DROP POLICY IF EXISTS "Users can manage own moment media" ON moment_media;
CREATE POLICY "Users can manage own moment media" ON moment_media
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM moment_entries 
            WHERE id = moment_media.moment_id 
            AND user_id = auth.uid()
        )
    );

-- 위치 정보 정책
DROP POLICY IF EXISTS "Users can manage own moment locations" ON moment_locations;
CREATE POLICY "Users can manage own moment locations" ON moment_locations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM moment_entries 
            WHERE id = moment_locations.moment_id 
            AND user_id = auth.uid()
        )
    );

-- 태그 시스템 정책
DROP POLICY IF EXISTS "Users can manage own tags" ON tags;
CREATE POLICY "Users can manage own tags" ON tags
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own moment tags" ON moment_tags;
CREATE POLICY "Users can manage own moment tags" ON moment_tags
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM moment_entries 
            WHERE id = moment_tags.moment_id 
            AND user_id = auth.uid()
        )
    );

-- 카테고리 정책
DROP POLICY IF EXISTS "Users can manage own categories" ON categories;
CREATE POLICY "Users can manage own categories" ON categories
    FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own moment categories" ON moment_categories;
CREATE POLICY "Users can manage own moment categories" ON moment_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM moment_entries 
            WHERE id = moment_categories.moment_id 
            AND user_id = auth.uid()
        )
    );

-- 기분 추적 정책
DROP POLICY IF EXISTS "Users can manage own mood tracking" ON mood_tracking;
CREATE POLICY "Users can manage own mood tracking" ON mood_tracking
    FOR ALL USING (auth.uid() = user_id);

-- 통계 정책
DROP POLICY IF EXISTS "Users can view own statistics" ON user_statistics;
CREATE POLICY "Users can view own statistics" ON user_statistics
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can update statistics" ON user_statistics;
CREATE POLICY "System can update statistics" ON user_statistics
    FOR UPDATE USING (auth.uid() = user_id);

-- 백업 세션 정책
DROP POLICY IF EXISTS "Users can manage own backups" ON backup_sessions;
CREATE POLICY "Users can manage own backups" ON backup_sessions
    FOR ALL USING (auth.uid() = user_id);

-- 알림 정책
DROP POLICY IF EXISTS "Users can manage own notifications" ON notifications;
CREATE POLICY "Users can manage own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);

-- 동기화 로그 정책
DROP POLICY IF EXISTS "Users can view own sync logs" ON sync_logs;
CREATE POLICY "Users can view own sync logs" ON sync_logs
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System can create sync logs" ON sync_logs;
CREATE POLICY "System can create sync logs" ON sync_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 9. 유용한 뷰 생성
-- =====================================================

-- 사용자 대시보드용 뷰
CREATE OR REPLACE VIEW user_dashboard_view AS
SELECT 
    u.id as user_id,
    u.email,
    up.bio,
    us.total_moments,
    us.current_streak,
    us.avg_mood_score,
    (
        SELECT COUNT(*) 
        FROM moment_entries me 
        WHERE me.user_id = u.id 
        AND me.created_at >= CURRENT_DATE - INTERVAL '30 days'
    ) as moments_this_month,
    (
        SELECT json_agg(
            json_build_object(
                'id', me.id,
                'title', me.title,
                'mood', me.mood,
                'created_at', me.created_at
            ) ORDER BY me.created_at DESC
        )
        FROM moment_entries me 
        WHERE me.user_id = u.id 
        LIMIT 5
    ) as recent_moments
FROM auth.users u
LEFT JOIN user_profiles up ON u.id = up.user_id
LEFT JOIN user_statistics us ON u.id = us.user_id;

-- 월별 통계 뷰
CREATE OR REPLACE VIEW monthly_stats_view AS
SELECT 
    user_id,
    DATE_TRUNC('month', moment_date) as month,
    COUNT(*) as moment_count,
    AVG(mood_score) as avg_mood,
    COUNT(DISTINCT CASE WHEN mm.media_type = 'image' THEN mm.id END) as image_count,
    COUNT(DISTINCT CASE WHEN ml.id IS NOT NULL THEN me.id END) as location_count
FROM moment_entries me
LEFT JOIN moment_media mm ON me.id = mm.moment_id
LEFT JOIN moment_locations ml ON me.id = ml.moment_id
GROUP BY user_id, DATE_TRUNC('month', moment_date);

-- =====================================================
-- 10. 데이터 마이그레이션 함수 (기존 데이터 처리)
-- =====================================================

-- 기존 위치 데이터 마이그레이션
CREATE OR REPLACE FUNCTION migrate_existing_location_data()
RETURNS INTEGER AS $$
DECLARE
    migrated_count INTEGER := 0;
BEGIN
    INSERT INTO moment_locations (moment_id, latitude, longitude, location_name, created_at)
    SELECT id, latitude, longitude, location_name, created_at
    FROM moment_entries
    WHERE latitude IS NOT NULL 
    AND longitude IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 FROM moment_locations ml WHERE ml.moment_id = moment_entries.id
    );
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    RETURN migrated_count;
END;
$$ LANGUAGE plpgsql;

-- 기존 미디어 데이터 마이그레이션
CREATE OR REPLACE FUNCTION migrate_existing_media_data()
RETURNS INTEGER AS $$
DECLARE
    migrated_count INTEGER := 0;
BEGIN
    INSERT INTO moment_media (moment_id, media_type, file_path, original_filename, created_at)
    SELECT id, 'image', image_path, 
           CASE 
               WHEN image_path LIKE '%/%' THEN split_part(image_path, '/', -1)
               ELSE image_path
           END,
           created_at
    FROM moment_entries
    WHERE image_path IS NOT NULL 
    AND image_path != ''
    AND NOT EXISTS (
        SELECT 1 FROM moment_media mm WHERE mm.moment_id = moment_entries.id
    );
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    RETURN migrated_count;
END;
$$ LANGUAGE plpgsql;

-- 사용자 통계 초기화
CREATE OR REPLACE FUNCTION initialize_user_statistics()
RETURNS INTEGER AS $$
DECLARE
    initialized_count INTEGER := 0;
BEGIN
    INSERT INTO user_statistics (user_id, total_moments, total_media, last_calculated_at)
    SELECT 
        me.user_id,
        COUNT(me.id) as total_moments,
        COALESCE(media_counts.media_count, 0) as total_media,
        NOW()
    FROM moment_entries me
    LEFT JOIN (
        SELECT mm.moment_id, COUNT(*) as media_count
        FROM moment_media mm
        GROUP BY mm.moment_id
    ) media_counts ON me.id = media_counts.moment_id
    WHERE me.user_id IS NOT NULL
    GROUP BY me.user_id, media_counts.media_count
    ON CONFLICT (user_id) DO UPDATE SET
        total_moments = EXCLUDED.total_moments,
        total_media = EXCLUDED.total_media,
        last_calculated_at = NOW();
    
    GET DIAGNOSTICS initialized_count = ROW_COUNT;
    RETURN initialized_count;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 완료 메시지
-- =====================================================

-- 스키마 생성 완료 로그
DO $$
BEGIN
    RAISE NOTICE 'OneMoment+ 데이터베이스 스키마 생성이 완료되었습니다.';
    RAISE NOTICE '- 총 13개 테이블 생성/수정';
    RAISE NOTICE '- 성능 최적화 인덱스 적용';
    RAISE NOTICE '- RLS 보안 정책 설정';
    RAISE NOTICE '- 자동화 트리거 및 함수 생성';
    RAISE NOTICE '- 데이터 마이그레이션 함수 준비';
    RAISE NOTICE '';
    RAISE NOTICE '다음 단계: migrate_existing_location_data() 및 migrate_existing_media_data() 함수를 실행하여 기존 데이터를 마이그레이션하세요.';
END $$;