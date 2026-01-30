-- name: CreateSession :one
INSERT INTO authenserver_service.sessions (
    id, "sessionToken", "userId", expires
) VALUES (
    $1, $2, $3, $4
)
RETURNING id, "sessionToken", "userId", expires;

-- name: GetSessionByToken :one
SELECT id, "sessionToken", "userId", expires
FROM authenserver_service.sessions
WHERE "sessionToken" = $1 AND expires > NOW()
LIMIT 1;

-- name: DeleteSession :exec
DELETE FROM authenserver_service.sessions
WHERE "sessionToken" = $1;

-- name: DeleteExpiredSessions :exec
DELETE FROM authenserver_service.sessions
WHERE expires < NOW();

-- name: DeleteUserSessions :exec
DELETE FROM authenserver_service.sessions
WHERE "userId" = $1;
