-- Verification tokens for:
--  - EMAIL_VERIFICATION
--  - PASSWORD_RESET
--
-- Stored as token_hash only; raw tokens are never persisted.

CREATE TABLE IF NOT EXISTS verification_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type VARCHAR(60) NOT NULL,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP NULL,
    revoked_at TIMESTAMP NULL,
    created_by_ip VARCHAR(80) NULL,

    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    created_by VARCHAR(100) NULL,
    updated_by VARCHAR(100) NULL,
    version BIGINT NOT NULL
);

ALTER TABLE verification_tokens
    ADD CONSTRAINT uk_verification_tokens_token_hash UNIQUE (token_hash);

CREATE INDEX IF NOT EXISTS idx_verification_tokens_user_id_type
    ON verification_tokens(user_id, type);

CREATE INDEX IF NOT EXISTS idx_verification_tokens_expires_at
    ON verification_tokens(expires_at);
