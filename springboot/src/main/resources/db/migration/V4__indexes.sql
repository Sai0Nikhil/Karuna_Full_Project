CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique ON users (email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_number_unique ON users (phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users (created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_roles_name_unique ON roles (name);
CREATE INDEX IF NOT EXISTS idx_locations_city_state ON locations (city, state);

CREATE INDEX IF NOT EXISTS idx_animals_species ON animals (species);
CREATE INDEX IF NOT EXISTS idx_animals_condition ON animals (condition);
CREATE INDEX IF NOT EXISTS idx_animals_created_at ON animals (created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ngos_registration_number_unique ON ngos (registration_number);
CREATE UNIQUE INDEX IF NOT EXISTS idx_ngos_email_unique ON ngos (email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ngos_created_at ON ngos (created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_volunteers_user_unique ON volunteers (user_id);
CREATE INDEX IF NOT EXISTS idx_volunteers_status ON volunteers (status);
CREATE INDEX IF NOT EXISTS idx_volunteers_created_at ON volunteers (created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_veterinarians_user_unique ON veterinarians (user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_veterinarians_license_unique ON veterinarians (license_number);

CREATE INDEX IF NOT EXISTS idx_cases_status ON cases (status);
CREATE INDEX IF NOT EXISTS idx_cases_ngo_id ON cases (ngo_id);
CREATE INDEX IF NOT EXISTS idx_cases_primary_volunteer_id ON cases (primary_volunteer_id);
CREATE INDEX IF NOT EXISTS idx_cases_animal_id ON cases (animal_id);
CREATE INDEX IF NOT EXISTS idx_cases_created_at ON cases (created_at);

CREATE INDEX IF NOT EXISTS idx_case_volunteers_case_id ON case_volunteers (case_id);
CREATE INDEX IF NOT EXISTS idx_case_volunteers_volunteer_id ON case_volunteers (volunteer_id);
CREATE INDEX IF NOT EXISTS idx_ngo_volunteers_ngo_id ON ngo_volunteers (ngo_id);
CREATE INDEX IF NOT EXISTS idx_ngo_volunteers_volunteer_id ON ngo_volunteers (volunteer_id);

CREATE INDEX IF NOT EXISTS idx_donations_case_id ON donations (case_id);
CREATE INDEX IF NOT EXISTS idx_donations_donor_id ON donations (donor_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations (status);
CREATE INDEX IF NOT EXISTS idx_donations_created_at ON donations (created_at);
CREATE UNIQUE INDEX IF NOT EXISTS idx_donations_payment_reference_unique ON donations (payment_reference) WHERE payment_reference IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_adoptions_case_id ON adoption_applications (case_id);
CREATE INDEX IF NOT EXISTS idx_adoptions_animal_id ON adoption_applications (animal_id);
CREATE INDEX IF NOT EXISTS idx_adoptions_applicant_id ON adoption_applications (applicant_id);
CREATE INDEX IF NOT EXISTS idx_adoptions_status ON adoption_applications (status);
CREATE INDEX IF NOT EXISTS idx_adoptions_created_at ON adoption_applications (created_at);

CREATE INDEX IF NOT EXISTS idx_treatments_animal_id ON treatments (animal_id);
CREATE INDEX IF NOT EXISTS idx_treatments_case_id ON treatments (case_id);
CREATE INDEX IF NOT EXISTS idx_treatments_veterinarian_id ON treatments (veterinarian_id);
CREATE INDEX IF NOT EXISTS idx_treatments_status ON treatments (status);
CREATE INDEX IF NOT EXISTS idx_treatments_created_at ON treatments (created_at);

CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON notifications (recipient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications (status);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications (type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications (created_at);

CREATE INDEX IF NOT EXISTS idx_audit_logs_actor_user_id ON audit_logs (actor_user_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON audit_logs (created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash_unique ON refresh_tokens (token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at ON refresh_tokens (expires_at);
