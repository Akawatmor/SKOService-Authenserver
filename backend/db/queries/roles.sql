-- name: GetRoleByID :one
SELECT * FROM authenserver_service.roles
WHERE id = $1 LIMIT 1;

-- name: GetRoleByName :one
SELECT * FROM authenserver_service.roles
WHERE name = $1 LIMIT 1;

-- name: ListRoles :many
SELECT * FROM authenserver_service.roles
ORDER BY name;

-- name: CreateRole :one
INSERT INTO authenserver_service.roles (name, description)
VALUES ($1, $2)
RETURNING *;

-- name: GetUserRoles :many
SELECT r.* FROM authenserver_service.roles r
INNER JOIN authenserver_service.user_roles ur ON r.id = ur.role_id
WHERE ur.user_id = $1;

-- name: AssignRoleToUser :exec
INSERT INTO authenserver_service.user_roles (user_id, role_id)
VALUES ($1, $2)
ON CONFLICT DO NOTHING;

-- name: RemoveRoleFromUser :exec
DELETE FROM authenserver_service.user_roles
WHERE user_id = $1 AND role_id = $2;

-- name: GetRolePermissions :many
SELECT p.* FROM authenserver_service.permissions p
INNER JOIN authenserver_service.role_permissions rp ON p.id = rp.permission_id
WHERE rp.role_id = $1;

-- name: GetUserPermissions :many
SELECT DISTINCT p.* FROM authenserver_service.permissions p
INNER JOIN authenserver_service.role_permissions rp ON p.id = rp.permission_id
INNER JOIN authenserver_service.user_roles ur ON rp.role_id = ur.role_id
WHERE ur.user_id = $1;
