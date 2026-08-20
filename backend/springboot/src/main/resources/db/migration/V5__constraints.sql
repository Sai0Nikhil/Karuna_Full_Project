UPDATE users SET role = UPPER(role) WHERE role IS NOT NULL;
UPDATE cases SET status = UPPER(status) WHERE status IS NOT NULL;
UPDATE cases SET severity = UPPER(severity) WHERE severity IS NOT NULL;
UPDATE donations SET status = UPPER(status) WHERE status IS NOT NULL;
UPDATE adoption_applications SET status = UPPER(status) WHERE status IS NOT NULL;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_users_role') THEN
        ALTER TABLE users ADD CONSTRAINT chk_users_role CHECK (role IN ('CITIZEN', 'NGO', 'VOLUNTEER', 'VET', 'ADMIN'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_roles_name') THEN
        ALTER TABLE roles ADD CONSTRAINT chk_roles_name CHECK (name IN ('CITIZEN', 'NGO', 'VOLUNTEER', 'VET', 'ADMIN'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_locations_latitude') THEN
        ALTER TABLE locations ADD CONSTRAINT chk_locations_latitude CHECK (latitude IS NULL OR (latitude >= -90 AND latitude <= 90));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_locations_longitude') THEN
        ALTER TABLE locations ADD CONSTRAINT chk_locations_longitude CHECK (longitude IS NULL OR (longitude >= -180 AND longitude <= 180));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_animals_species') THEN
        ALTER TABLE animals ADD CONSTRAINT chk_animals_species CHECK (species IN ('DOG', 'CAT', 'COW', 'BIRD', 'GOAT', 'OTHER', 'UNKNOWN'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_animals_condition') THEN
        ALTER TABLE animals ADD CONSTRAINT chk_animals_condition CHECK (condition IN ('UNKNOWN', 'STABLE', 'INJURED', 'CRITICAL', 'RECOVERING', 'HEALTHY', 'DECEASED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_volunteers_status') THEN
        ALTER TABLE volunteers ADD CONSTRAINT chk_volunteers_status CHECK (status IN ('AVAILABLE', 'BUSY', 'OFFLINE', 'SUSPENDED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cases_status') THEN
        ALTER TABLE cases ADD CONSTRAINT chk_cases_status CHECK (status IN ('REPORTED', 'ASSIGNED', 'COLLECTED', 'AT_CLINIC', 'IN_TREATMENT', 'DISCHARGED', 'ADOPTED', 'RELEASED', 'CANCELLED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_cases_severity') THEN
        ALTER TABLE cases ADD CONSTRAINT chk_cases_severity CHECK (severity IS NULL OR severity IN ('LOW', 'MEDIUM', 'HIGH', 'URGENT', 'CRITICAL', 'ROUTINE'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_donations_status') THEN
        ALTER TABLE donations ADD CONSTRAINT chk_donations_status CHECK (status IS NULL OR status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED', 'CANCELLED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_donations_amount_positive') THEN
        ALTER TABLE donations ADD CONSTRAINT chk_donations_amount_positive CHECK (amount > 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_adoptions_status') THEN
        ALTER TABLE adoption_applications ADD CONSTRAINT chk_adoptions_status CHECK (status IS NULL OR status IN ('SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'COMPLETED', 'WITHDRAWN'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_treatments_status') THEN
        ALTER TABLE treatments ADD CONSTRAINT chk_treatments_status CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'FOLLOW_UP_REQUIRED', 'CANCELLED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_treatments_cost_amount') THEN
        ALTER TABLE treatments ADD CONSTRAINT chk_treatments_cost_amount CHECK (cost_amount IS NULL OR cost_amount >= 0);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_notifications_type') THEN
        ALTER TABLE notifications ADD CONSTRAINT chk_notifications_type CHECK (type IN ('CASE_CREATED', 'CASE_ASSIGNED', 'CASE_STATUS_CHANGED', 'DONATION_RECEIVED', 'ADOPTION_UPDATED', 'TREATMENT_UPDATED', 'SYSTEM'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_notifications_status') THEN
        ALTER TABLE notifications ADD CONSTRAINT chk_notifications_status CHECK (status IN ('PENDING', 'SENT', 'READ', 'FAILED', 'ARCHIVED'));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_refresh_tokens_expiry') THEN
        ALTER TABLE refresh_tokens ADD CONSTRAINT chk_refresh_tokens_expiry CHECK (expires_at > created_at);
    END IF;
END $$;
