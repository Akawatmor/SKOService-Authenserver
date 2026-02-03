-- name: CreateAuthLog :one
INSERT INTO authenserver_service.auth_logs (
    id, user_id, action, ip_address, user_agent, timestamp
) VALUES (
    $1, $2, $3, $4, $5, NOW()
)
RETURNING id, user_id, action, ip_address, user_agent, timestamp;

-- name: GetAuthLogsByUser :many
SELECT id, user_id, action, ip_address, user_agent, timestamp
FROM authenserver_service.auth_logs
WHERE user_id = $1
ORDER BY timestamp DESC
LIMIT $2 OFFSET $3;

-- name: GetRecentAuthLogs :many
SELECT id, user_id, action, ip_address, user_agent, timestamp
FROM authenserver_service.auth_logs
ORDER BY timestamp DESC
LIMIT $1 OFFSET $2;
