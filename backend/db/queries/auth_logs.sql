-- name: CreateAuthLog :one
INSERT INTO authenserver_service.auth_logs (
    id, "userId", action, "ipAddress", "userAgent", timestamp
) VALUES (
    $1, $2, $3, $4, $5, NOW()
)
RETURNING id, "userId", action, "ipAddress", "userAgent", timestamp;

-- name: GetAuthLogsByUser :many
SELECT id, "userId", action, "ipAddress", "userAgent", timestamp
FROM authenserver_service.auth_logs
WHERE "userId" = $1
ORDER BY timestamp DESC
LIMIT $2 OFFSET $3;

-- name: GetRecentAuthLogs :many
SELECT id, "userId", action, "ipAddress", "userAgent", timestamp
FROM authenserver_service.auth_logs
ORDER BY timestamp DESC
LIMIT $1 OFFSET $2;
