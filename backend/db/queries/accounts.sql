-- name: CreateAccount :one
INSERT INTO authenserver_service.accounts (
    id, user_id, type, provider, provider_account_id,
    refresh_token, access_token, expires_at, token_type,
    scope, id_token, session_state
) VALUES (
    $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12
)
RETURNING id, user_id, type, provider, provider_account_id, refresh_token, access_token, expires_at, token_type, scope, id_token, session_state;

-- name: GetAccountByProvider :one
SELECT id, user_id, type, provider, provider_account_id, refresh_token, access_token, expires_at, token_type, scope, id_token, session_state
FROM authenserver_service.accounts
WHERE provider = $1 AND provider_account_id = $2
LIMIT 1;

-- name: GetUserAccounts :many
SELECT id, user_id, type, provider, provider_account_id, refresh_token, access_token, expires_at, token_type, scope, id_token, session_state
FROM authenserver_service.accounts
WHERE user_id = $1;

-- name: UpdateAccountTokens :exec
UPDATE authenserver_service.accounts
SET
    refresh_token = $2,
    access_token = $3,
    expires_at = $4
WHERE id = $1;

-- name: DeleteAccount :exec
DELETE FROM authenserver_service.accounts
WHERE id = $1;
