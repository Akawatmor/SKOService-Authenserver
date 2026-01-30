-- Create schema
CREATE SCHEMA IF NOT EXISTS authenserver_service;

-- Set search path
SET search_path TO authenserver_service;

-- Users table (Core authentication)
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    email_verified TIMESTAMP,
    image VARCHAR(500),
    password VARCHAR(255), -- bcrypt hash
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Add missing columns to users table if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'users' 
                   AND column_name = 'name') THEN
        ALTER TABLE users ADD COLUMN name VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'users' 
                   AND column_name = 'email_verified') THEN
        ALTER TABLE users ADD COLUMN email_verified TIMESTAMP;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'users' 
                   AND column_name = 'image') THEN
        ALTER TABLE users ADD COLUMN image VARCHAR(500);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'users' 
                   AND column_name = 'password') THEN
        ALTER TABLE users ADD COLUMN password VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'users' 
                   AND column_name = 'created_at') THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'users' 
                   AND column_name = 'updated_at') THEN
        ALTER TABLE users ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
END $$;

-- OAuth Accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_account_id VARCHAR(255) NOT NULL,
    refresh_token TEXT,
    access_token TEXT,
    expires_at BIGINT,
    token_type VARCHAR(50),
    scope TEXT,
    id_token TEXT,
    session_state VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE(provider, provider_account_id)
);

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'accounts' 
        AND constraint_name = 'accounts_user_id_fkey'
    ) THEN
        ALTER TABLE accounts ADD CONSTRAINT accounts_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Sessions table (PASETO token storage)
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(255) PRIMARY KEY,
    session_token VARCHAR(500) UNIQUE NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    expires TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Add foreign key constraint if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'sessions' 
        AND constraint_name = 'sessions_user_id_fkey'
    ) THEN
        ALTER TABLE sessions ADD CONSTRAINT sessions_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Verification tokens (email verification, password reset)
CREATE TABLE IF NOT EXISTS verification_tokens (
    identifier VARCHAR(255) NOT NULL,
    token VARCHAR(500) UNIQUE NOT NULL,
    expires TIMESTAMP NOT NULL,
    PRIMARY KEY (identifier, token)
);

-- Roles table
CREATE TABLE IF NOT EXISTS roles (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Add missing columns to roles table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'roles' 
                   AND column_name = 'description') THEN
        ALTER TABLE roles ADD COLUMN description TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'roles' 
                   AND column_name = 'created_at') THEN
        ALTER TABLE roles ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'roles' 
                   AND column_name = 'updated_at') THEN
        ALTER TABLE roles ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
END $$;

-- Permissions table
CREATE TABLE IF NOT EXISTS permissions (
    id SERIAL PRIMARY KEY,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Add missing columns to permissions table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'permissions' 
                   AND column_name = 'description') THEN
        ALTER TABLE permissions ADD COLUMN description TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'permissions' 
                   AND column_name = 'created_at') THEN
        ALTER TABLE permissions ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
END $$;

-- Role-Permission junction table
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id INTEGER NOT NULL,
    permission_id INTEGER NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);

-- Add foreign key constraints if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'role_permissions' 
        AND constraint_name = 'role_permissions_role_id_fkey'
    ) THEN
        ALTER TABLE role_permissions ADD CONSTRAINT role_permissions_role_id_fkey 
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'role_permissions' 
        AND constraint_name = 'role_permissions_permission_id_fkey'
    ) THEN
        ALTER TABLE role_permissions ADD CONSTRAINT role_permissions_permission_id_fkey 
        FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;
    END IF;
END $$;

-- User-Role junction table
CREATE TABLE IF NOT EXISTS user_roles (
    user_id VARCHAR(255) NOT NULL,
    role_id INTEGER NOT NULL,
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id)
);

-- Add foreign key constraints and missing columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'user_roles' 
                   AND column_name = 'assigned_at') THEN
        ALTER TABLE user_roles ADD COLUMN assigned_at TIMESTAMP NOT NULL DEFAULT NOW();
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'user_roles' 
        AND constraint_name = 'user_roles_user_id_fkey'
    ) THEN
        ALTER TABLE user_roles ADD CONSTRAINT user_roles_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'user_roles' 
        AND constraint_name = 'user_roles_role_id_fkey'
    ) THEN
        ALTER TABLE user_roles ADD CONSTRAINT user_roles_role_id_fkey 
        FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Auth logs (audit trail)
CREATE TABLE IF NOT EXISTS auth_logs (
    id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255),
    action VARCHAR(50) NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    metadata JSONB
);

-- Add missing columns to auth_logs table
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'authenserver_service' 
                   AND table_name = 'auth_logs' 
                   AND column_name = 'metadata') THEN
        ALTER TABLE auth_logs ADD COLUMN metadata JSONB;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'authenserver_service' 
        AND table_name = 'auth_logs' 
        AND constraint_name = 'auth_logs_user_id_fkey'
    ) THEN
        ALTER TABLE auth_logs ADD CONSTRAINT auth_logs_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
END $$;

-- Create indexes for performance (IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires);
CREATE INDEX IF NOT EXISTS idx_auth_logs_user_id ON auth_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_auth_logs_timestamp ON auth_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);

-- Insert default roles
INSERT INTO roles (name, description) VALUES
    ('admin', 'System administrator with full access'),
    ('user', 'Standard user with basic access'),
    ('moderator', 'User with moderation capabilities')
ON CONFLICT (name) DO NOTHING;

-- Insert default permissions
INSERT INTO permissions (slug, description) VALUES
    ('user.read', 'Read user information'),
    ('user.write', 'Create and update users'),
    ('user.delete', 'Delete users'),
    ('role.read', 'Read role information'),
    ('role.write', 'Create and update roles'),
    ('role.delete', 'Delete roles'),
    ('permission.read', 'Read permission information'),
    ('permission.write', 'Create and update permissions'),
    ('admin.access', 'Access admin panel')
ON CONFLICT (slug) DO NOTHING;

-- Assign permissions to admin role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'admin'
ON CONFLICT DO NOTHING;

-- Assign basic permissions to user role
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
CROSS JOIN permissions p
WHERE r.name = 'user' AND p.slug IN ('user.read', 'role.read')
ON CONFLICT DO NOTHING;
