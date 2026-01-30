-- name: GetUserByID :one
SELECT id, name, email, "emailVerified", image, password, "createdAt", "updatedAt"
FROM authenserver_service.users
WHERE id = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT id, name, email, "emailVerified", image, password, "createdAt", "updatedAt"
FROM authenserver_service.users
WHERE email = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO authenserver_service.users (
    id, name, email, "emailVerified", image, password, "createdAt", "updatedAt"
) VALUES (
    $1, $2, $3, $4, $5, $6, NOW(), NOW()
)
RETURNING id, name, email, "emailVerified", image, password, "createdAt", "updatedAt";

-- name: UpdateUser :one
UPDATE authenserver_service.users
SET
    name = COALESCE($2, name),
    email = COALESCE($3, email),
    "emailVerified" = COALESCE($4, "emailVerified"),
    image = COALESCE($5, image),
    "updatedAt" = NOW()
WHERE id = $1
RETURNING id, name, email, "emailVerified", image, password, "createdAt", "updatedAt";

-- name: UpdateUserPassword :exec
UPDATE authenserver_service.users
SET password = $2, "updatedAt" = NOW()
WHERE id = $1;

-- name: DeleteUser :exec
DELETE FROM authenserver_service.users
WHERE id = $1;

-- name: ListUsers :many
SELECT id, name, email, "emailVerified", image, password, "createdAt", "updatedAt"
FROM authenserver_service.users
ORDER BY "createdAt" DESC
LIMIT $1 OFFSET $2;

-- name: CountUsers :one
SELECT COUNT(*) FROM authenserver_service.users;
