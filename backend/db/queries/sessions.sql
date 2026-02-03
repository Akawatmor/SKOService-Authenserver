-- name: CreateSession :one
INSERT INTO authenserver_service.sessions (
    id, session_token, user_id, expires
) VALUES (
    $1, $2, $3, $4
)
RETURNING id, session_token, user_id, expires;

-- name: GetSessionByToken :one
SELECT id, session_token, user_id, expires
FROM authenserver_service.sessions
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
