-- name: CreateSession :one
INSERT INTO authenserver_service.sessions (
    id, session_token, user_id, expires, created_at
) VALUES (
    $1, $2, $3, $4, NOW()
)
RETURNING *;

-- name: GetSessionByToken :one
SELECT * FROM authenserver_service.sessions
WHERE session_token = $1 AND expires > NOW()
LIMIT 1;

-- name: DeleteSession :exec
DELETE FROM authenserver_service.sessions
WHERE session_token = $1;

-- name: DeleteExpiredSessions :exec
DELETE FROM authenserver_service.sessions
WHERE expires < NOW();

-- name: DeleteUserSessions :exec
DELETE FROM authenserver_service.sessions
WHERE user_id = $1;
