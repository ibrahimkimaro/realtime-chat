-- ============================================================================
-- Standalone PostgreSQL Schema for Phoenix Realtime Chat & WebRTC Engine
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Minimal Users Table (for foreign key checks and identity resolution)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE,
    username VARCHAR(50) UNIQUE,
    full_name VARCHAR(255),
    is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Profiles for user avatars during calling/presence
CREATE TABLE IF NOT EXISTS profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    avatar_url VARCHAR(500),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Chat Groups
CREATE TABLE IF NOT EXISTS chat_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug VARCHAR(64) NOT NULL UNIQUE,
    name VARCHAR(120) NOT NULL,
    topic VARCHAR(200) NOT NULL DEFAULT '',
    avatar_url VARCHAR(300),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Chat Group Members (invitation and roles)
CREATE TABLE IF NOT EXISTS chat_group_members (
    group_id UUID NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(10) NOT NULL DEFAULT 'member',  -- 'admin' | 'member'
    status VARCHAR(10) NOT NULL DEFAULT 'invited', -- 'invited' | 'member' | 'declined'
    invited_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    joined_at TIMESTAMPTZ,
    PRIMARY KEY (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS ix_chat_group_members_user ON chat_group_members(user_id, status);

-- 3. Chat Messages (Persisted Chat History for Groups and 1-on-1 DMs)
CREATE TABLE IF NOT EXISTS chat_messages (
    id BIGSERIAL PRIMARY KEY,
    client_id VARCHAR(64) NOT NULL,
    topic VARCHAR(200) NOT NULL,
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    author_name VARCHAR(255) NOT NULL,
    author_username VARCHAR(50) NOT NULL,
    body TEXT NOT NULL,
    reply_to JSONB,
    recipient_id UUID REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMPTZ,
    attachment JSONB,
    edited_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ,
    inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_chat_messages_author_client UNIQUE (author_id, client_id)
);

CREATE INDEX IF NOT EXISTS ix_chat_messages_topic_id ON chat_messages(topic, id);
CREATE INDEX IF NOT EXISTS ix_chat_messages_unread ON chat_messages(recipient_id) WHERE read_at IS NULL;
CREATE INDEX IF NOT EXISTS ix_chat_messages_topic_attachment ON chat_messages(topic, id) WHERE attachment IS NOT NULL;

-- 4. Chat Clears (per-user delete chat history up to message ID)
CREATE TABLE IF NOT EXISTS chat_clears (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    topic VARCHAR(200) NOT NULL,
    up_to BIGINT NOT NULL,
    cleared_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, topic)
);

-- 5. Optional Uploads verification (for chat file attachments)
CREATE TABLE IF NOT EXISTS uploads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content_type VARCHAR(100) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_uploads_name_owner ON uploads(name, owner_id);

-- 6. Optional Discussions & Members (for discussion room topics: room:disc-<id>)
CREATE TABLE IF NOT EXISTS discussions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    live_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS discussion_members (
    discussion_id UUID NOT NULL REFERENCES discussions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) NOT NULL DEFAULT 'member',
    role VARCHAR(20) NOT NULL DEFAULT 'member', -- 'owner' | 'moderator' | 'member'
    PRIMARY KEY (discussion_id, user_id)
);

-- 7. Notifications table (for cleaning up message badges upon read)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    kind VARCHAR(50) NOT NULL,
    link VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS ix_notifications_user_kind_link ON notifications(user_id, kind, link);
