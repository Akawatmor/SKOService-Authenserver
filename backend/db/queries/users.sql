-- name: GetUserByID :one
SELECT * FROM authenserver_service.users
WHERE id = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM authenserver_service.users
WHERE email = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO authenserver_service.users (
    id, name, email, email_verified, image, password, created_at, updated_at
) VALUES (
    $1, $2, $3, $4, $5, $6, NOW(), NOW()
)
RETURNING *;

-- name: UpdateUser :one
UPDATE authenserver_service.users
SET
    name = COALESCE($2, name),
    email = COALESCE($3, email),
    email_verified = COALESCE($4, email_verified),
    image = COALESCE($5, image),
    updated_at = NOW()
WHERE id = $1
RETURNING *;

-- name: UpdateUserPassword :exec
UPDATE authenserver_service.users
SET password = $2, updated_at = NOW()
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM authenserver_service.users
WHERE id = $1;

-- name: ListUsers :many
SELECT * FROM authenserver_service.users
ORDER BY created_at DESC
LIMIT $1 OFFSET $2;

-- name: CountUsers :one
SELECT COUNT(*) FROM authenserver_service.users;
