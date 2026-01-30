-- name: CreateAuthLog :one
INSERT INTO authenserver_service.auth_logs (
    id, user_id, action, ip_address, user_agent, timestamp, metadata
) VALUES (
    $1, $2, $3, $4, $5, NOW(), $6
)
RETURNING *;

-- name: GetAuthLogsByUser :many
SELECT * FROM authenserver_service.auth_logs
WHERE user_id = $1
ORDER BY timestamp DESC
LIMIT $2 OFFSET $3;

-- name: GetRecentAuthLogs :many
SELECT * FROM authenserver_service.auth_logs
ORDER BY timestamp DESC
LIMIT $1 OFFSET $2;
