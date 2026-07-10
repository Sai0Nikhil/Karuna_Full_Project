CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id)
);

CREATE TABLE IF NOT EXISTS ngo_volunteers (
    ngo_id BIGINT NOT NULL,
    volunteer_id BIGINT NOT NULL,
    PRIMARY KEY (ngo_id, volunteer_id)
);

CREATE TABLE IF NOT EXISTS case_volunteers (
    case_id BIGINT NOT NULL,
    volunteer_id BIGINT NOT NULL,
    PRIMARY KEY (case_id, volunteer_id)
);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_users_location') THEN
        ALTER TABLE users ADD CONSTRAINT fk_users_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_animals_last_known_location') THEN
        ALTER TABLE animals ADD CONSTRAINT fk_animals_last_known_location FOREIGN KEY (last_known_location_id) REFERENCES locations(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ngos_headquarters_location') THEN
        ALTER TABLE ngos ADD CONSTRAINT fk_ngos_headquarters_location FOREIGN KEY (headquarters_location_id) REFERENCES locations(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_volunteers_user') THEN
        ALTER TABLE volunteers ADD CONSTRAINT fk_volunteers_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_volunteers_service_location') THEN
        ALTER TABLE volunteers ADD CONSTRAINT fk_volunteers_service_location FOREIGN KEY (service_location_id) REFERENCES locations(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_veterinarians_user') THEN
        ALTER TABLE veterinarians ADD CONSTRAINT fk_veterinarians_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_veterinarians_clinic_location') THEN
        ALTER TABLE veterinarians ADD CONSTRAINT fk_veterinarians_clinic_location FOREIGN KEY (clinic_location_id) REFERENCES locations(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_cases_location') THEN
        ALTER TABLE cases ADD CONSTRAINT fk_cases_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_cases_animal') THEN
        ALTER TABLE cases ADD CONSTRAINT fk_cases_animal FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_cases_ngo') THEN
        ALTER TABLE cases ADD CONSTRAINT fk_cases_ngo FOREIGN KEY (ngo_id) REFERENCES ngos(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_cases_primary_volunteer') THEN
        ALTER TABLE cases ADD CONSTRAINT fk_cases_primary_volunteer FOREIGN KEY (primary_volunteer_id) REFERENCES volunteers(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_donations_case') THEN
        ALTER TABLE donations ADD CONSTRAINT fk_donations_case FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_adoptions_animal') THEN
        ALTER TABLE adoption_applications ADD CONSTRAINT fk_adoptions_animal FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_adoptions_decided_by') THEN
        ALTER TABLE adoption_applications ADD CONSTRAINT fk_adoptions_decided_by FOREIGN KEY (decided_by_id) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_treatments_animal') THEN
        ALTER TABLE treatments ADD CONSTRAINT fk_treatments_animal FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE RESTRICT;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_treatments_case') THEN
        ALTER TABLE treatments ADD CONSTRAINT fk_treatments_case FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_treatments_veterinarian') THEN
        ALTER TABLE treatments ADD CONSTRAINT fk_treatments_veterinarian FOREIGN KEY (veterinarian_id) REFERENCES veterinarians(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_notifications_recipient') THEN
        ALTER TABLE notifications ADD CONSTRAINT fk_notifications_recipient FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_audit_logs_actor') THEN
        ALTER TABLE audit_logs ADD CONSTRAINT fk_audit_logs_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_refresh_tokens_user') THEN
        ALTER TABLE refresh_tokens ADD CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_user') THEN
        ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_user_roles_role') THEN
        ALTER TABLE user_roles ADD CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ngo_volunteers_ngo') THEN
        ALTER TABLE ngo_volunteers ADD CONSTRAINT fk_ngo_volunteers_ngo FOREIGN KEY (ngo_id) REFERENCES ngos(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_ngo_volunteers_volunteer') THEN
        ALTER TABLE ngo_volunteers ADD CONSTRAINT fk_ngo_volunteers_volunteer FOREIGN KEY (volunteer_id) REFERENCES volunteers(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_case_volunteers_case') THEN
        ALTER TABLE case_volunteers ADD CONSTRAINT fk_case_volunteers_case FOREIGN KEY (case_id) REFERENCES cases(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'fk_case_volunteers_volunteer') THEN
        ALTER TABLE case_volunteers ADD CONSTRAINT fk_case_volunteers_volunteer FOREIGN KEY (volunteer_id) REFERENCES volunteers(id) ON DELETE CASCADE;
    END IF;
END $$;
