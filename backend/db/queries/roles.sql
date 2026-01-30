-- name: GetRoleByID :one
SELECT id, name, description, created_at, updated_at
FROM authenserver_service.roles
WHERE id = $1 LIMIT 1;

-- name: GetRoleByName :one
SELECT id, name, description, created_at, updated_at
FROM authenserver_service.roles
WHERE name = $1 LIMIT 1;

-- name: ListRoles :many
SELECT id, name, description, created_at, updated_at
FROM authenserver_service.roles
ORDER BY name;

-- name: CreateRole :one
INSERT INTO authenserver_service.roles (name, description)
VALUES ($1, $2)
RETURNING id, name, description, created_at, updated_at;

-- name: GetUserRoles :many
SELECT r.id, r.name, r.description, r.created_at, r.updated_at
FROM authenserver_service.roles r
INNER JOIN authenserver_service.user_roles ur ON r.id = ur."roleId"
WHERE ur."userId" = $1;

-- name: AssignRoleToUser :exec
INSERT INTO authenserver_service.user_roles ("userId", "roleId")
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: RemoveRoleFromUser :exec
DELETE FROM authenserver_service.user_roles
WHERE "userId" = $1 AND "roleId" = $2;

-- name: GetRolePermissions :many
SELECT p.id, p.slug, p.description, p.created_at
FROM authenserver_service.permissions p
INNER JOIN authenserver_service.role_permissions rp ON p.id = rp."permissionId"
WHERE rp."roleId" = $1;

-- name: GetUserPermissions :many
SELECT DISTINCT p.id, p.slug, p.description, p.created_at
FROM authenserver_service.permissions p
INNER JOIN authenserver_service.role_permissions rp ON p.id = rp."permissionId"
INNER JOIN authenserver_service.user_roles ur ON rp."roleId" = ur."roleId"
WHERE ur."userId" = $1;
