# Database Schema Design
## Database: PostgreSQL
## Schema: authenserver_service

This schema is designed to work seamlessly with **Auth.js (NextAuth)** capabilities while supporting our custom RBAC (Role-Based Access Control) requirements. All tables are located within the `authenserver_service` schema to avoid conflicts.

### 1. ER Diagram (Conceptual)
*   **User**: The central identity.
*   **Account**: Links a User to OAuth providers (Google, GitHub, etc.). One User can have multiple Accounts.
*   **Session**: Active login sessions (for database strategy).
*   **Role**: Define groups of permissions (e.g., 'admin', 'user', 'service_a_viewer').
*   **Permission**: Granular access rights.

### 2. Table Definitions

#### 2.1 Core Auth.js Tables (Standard)

**Table: users**
| Column | Type | Description |
|--------|------|-------------|
| id | UUID / String | PK |
| name | String | Display name |
| email | String | Unique email |
| emailVerified | Timestamp | |
| image | String | Avatar URL |
| password | String (Hash) | Nullable (only for credentials auth) |
| createdAt | Timestamp | |
| updatedAt | Timestamp | |

**Table: accounts** (For SSO Links)
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| userId | UUID | FK -> users.id |
| type | String | (oauth/oidc/email) |
| provider | String | (google/github/cloudflare) |
| providerAccountId | String | ID from the provider side |
| refresh_token | Text | |
| access_token | Text | |
| expires_at | Int | |
| token_type | String | |
| scope | String | |
| id_token | Text | |
| session_state | String | |

**Table: sessions**
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| sessionToken | String | Unique session cookie value |
| userId | UUID | FK -> users.id |
| expires | Timestamp | |

**Table: verification_tokens** (For Magic Links / Password Reset)
| Column | Type | Description |
|--------|------|-------------|
| identifier | String | Email |
| token | String | |
| expires | Timestamp | |

#### 2.2 Custom RBAC Extensions

**Table: roles**
| Column | Type | Description |
|--------|------|-------------|
| id | Int / Serial | PK |
| name | String | Unique role name (e.g., 'admin') |
| description | String | |

**Table: permissions**
| Column | Type | Description |
|--------|------|-------------|
| id | Int / Serial | PK |
| slug | String | Unique code (e.g., 'user.read', 'service.access') |
| description | String | |

**Table: role_permissions** (Many-to-Many)
| Column | Type | Description |
|--------|------|-------------|
| roleId | Int | FK -> roles.id |
| permissionId | Int | FK -> permissions.id |

**Table: user_roles** (Many-to-Many)
| Column | Type | Description |
|--------|------|-------------|
| userId | UUID | FK -> users.id |
| roleId | Int | FK -> roles.id |

#### 2.3 Audit Logging

**Table: auth_logs**
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | PK |
| userId | UUID | FK -> users.id (Nullable if failed login) |
| action | String | (LOGIN, LOGOUT, REGISTER, FAILED_LOGIN) |
| ipAddress | String | Generic IPv4/6 storage |
| userAgent | String | Browser info |
| timestamp | Timestamp | Default NOW() |

### 3. PostgreSQL Specifics
- **Timestamps**: All tables generally include `created_at` and `updated_at`.
- **Indexes**:
  - `users(email)`
  - `sessions(sessionToken)`
  - `auth_logs(timestamp)` for retention policies.
- **Extensions**: `uuid-ossp` (if generating UUIDs in DB).
