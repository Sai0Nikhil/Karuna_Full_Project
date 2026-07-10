# Karuna Database Design Notes

## Scope

Milestone 2 defines the data model only. It does not add controllers, services, repositories, authentication flows, AI integration, notification delivery, WebSocket messaging, or file upload behavior.

## Entity-to-Table Mapping

| Entity | Table | Notes |
| --- | --- | --- |
| `BaseEntity` | mapped superclass | Provides `id`, audit timestamps, audit users, and optimistic `version`. |
| `User` | `users` | Keeps the V1 user table, adds phone, location, soft delete, and normalized role relation support. |
| `Role` | `roles` | Stores normalized role names from `UserRole`. |
| `Location` | `locations` | Shared location model for users, animals, NGOs, volunteers, vets, and cases. |
| `Animal` | `animals` | Represents a rescued or tracked animal independently from a case. |
| `RescueCase` | `cases` | Extends the V1 case table with animal, NGO, volunteer, and location references. |
| `NGO` | `ngos` | Represents partner NGOs coordinating rescue work. |
| `Volunteer` | `volunteers` | One-to-one profile for a user acting as a volunteer. |
| `Veterinarian` | `veterinarians` | One-to-one profile for a user acting as a veterinarian. |
| `Donation` | `donations` | Extends V1 donations with case, payment reference, provider, message, and status model. |
| `AdoptionApplication` | `adoption_applications` | Extends V1 applications with animal, applicant contact, decision, and status fields. |
| `Treatment` | `treatments` | Tracks veterinary treatment records for animals and cases. |
| `Notification` | `notifications` | Stores notification records only; no delivery implementation is included. |
| `AuditLog` | `audit_logs` | Stores durable audit events tied optionally to an actor user. |
| `RefreshToken` | `refresh_tokens` | Stores token metadata only; no authentication flow is implemented. |

## Relationship Explanation

| Relationship | Type | Implementation |
| --- | --- | --- |
| User to Role | Many-to-many | `user_roles(user_id, role_id)` |
| User to Volunteer | One-to-one | `volunteers.user_id` |
| User to Veterinarian | One-to-one | `veterinarians.user_id` |
| User to RescueCase | One-to-many | `cases.reporter_id` |
| User to Donation | One-to-many | `donations.donor_id` |
| User to AdoptionApplication | One-to-many | `adoption_applications.applicant_id` |
| User to Notification | One-to-many | `notifications.recipient_id` |
| NGO to RescueCase | One-to-many | `cases.ngo_id` |
| NGO to Volunteer | Many-to-many | `ngo_volunteers(ngo_id, volunteer_id)` |
| Volunteer to RescueCase | Many-to-many | `case_volunteers(case_id, volunteer_id)` |
| Volunteer to RescueCase primary assignment | One-to-many | `cases.primary_volunteer_id` |
| Animal to RescueCase | One-to-many | `cases.animal_id` |
| Animal to Treatment | One-to-many | `treatments.animal_id` |
| Animal to AdoptionApplication | One-to-many | `adoption_applications.animal_id` |
| Veterinarian to Treatment | One-to-many | `treatments.veterinarian_id` |
| RescueCase to Donation | One-to-many | `donations.case_id` |
| RescueCase to Treatment | One-to-many | `treatments.case_id` |
| Location to domain records | One-to-many | Nullable foreign keys from users, animals, NGOs, volunteers, veterinarians, and cases. |

## Enumerations

String status and role values are modeled as enums in Java and constrained in PostgreSQL:

| Enum | Usage |
| --- | --- |
| `UserRole` | User primary role and normalized roles. |
| `CaseStatus` | Rescue case lifecycle. |
| `AnimalCondition` | Current animal condition. |
| `AnimalSpecies` | Animal species classification. |
| `DonationStatus` | Donation payment state. |
| `AdoptionStatus` | Adoption application review state. |
| `TreatmentStatus` | Treatment lifecycle. |
| `NotificationType` | Notification event category. |
| `NotificationStatus` | Notification delivery/read state. |
| `PriorityLevel` | Case urgency/severity. |
| `VolunteerStatus` | Volunteer availability. |

## Indexing Strategy

Indexes were added for future query paths:

| Query Path | Indexes |
| --- | --- |
| User lookup | `email`, `phone_number`, `created_at` |
| Case filtering | `status`, `ngo_id`, `primary_volunteer_id`, `animal_id`, `created_at` |
| NGO lookup | `registration_number`, `email`, `created_at` |
| Volunteer lookup | `user_id`, `status`, `created_at` |
| Donation lookup | `case_id`, `donor_id`, `status`, `created_at`, `payment_reference` |
| Adoption lookup | `case_id`, `animal_id`, `applicant_id`, `status`, `created_at` |
| Treatment lookup | `animal_id`, `case_id`, `veterinarian_id`, `status`, `created_at` |
| Notification lookup | `recipient_id`, `status`, `type`, `created_at` |
| Audit lookup | `actor_user_id`, `entity_type/entity_id`, `created_at` |
| Refresh token lookup | `token_hash`, `user_id`, `expires_at` |

## Constraints and Cascade Choices

Foreign key cascade rules are conservative:

| Relationship | Delete Behavior |
| --- | --- |
| User to volunteer/veterinarian profile | `ON DELETE CASCADE` because the profile cannot exist without the user. |
| User to refresh tokens and notifications | `ON DELETE CASCADE` because records are user-owned infrastructure records. |
| Location references | `ON DELETE SET NULL` to avoid deleting domain records when a location is removed. |
| Case references to animal, NGO, volunteer | `ON DELETE SET NULL` to preserve case history. |
| Treatment to animal | `ON DELETE RESTRICT` because treatment history requires an animal. |
| Treatment to case/veterinarian | `ON DELETE SET NULL` to preserve treatment history. |
| Many-to-many join tables | `ON DELETE CASCADE` for join rows only. |

Check constraints enforce enum values, positive donation amounts, non-negative treatment costs, valid coordinates, and refresh-token expiration after creation.

## Soft Delete

Soft delete is applied where historical continuity matters:

| Entity | Soft Delete Fields |
| --- | --- |
| `User` | `active`, `deleted_at` |
| `Animal` | `active`, `deleted_at` |
| `RescueCase` | `active`, `deleted_at` |
| `NGO` | `active`, `deleted_at` |
| `Volunteer` | `active`, `deleted_at` |
| `Veterinarian` | `active`, `deleted_at` |

Soft delete is not applied to every table. Donations, treatments, audit logs, notifications, and refresh tokens retain explicit state fields instead.

## Migration Plan

| Migration | Purpose |
| --- | --- |
| `V1__initial_schema.sql` | Existing baseline users, cases, donations, and adoption applications. |
| `V2__create_core_tables.sql` | Adds audit/version columns to V1 tables and creates core domain tables. |
| `V3__relationships.sql` | Adds relationship foreign keys and many-to-many join tables. |
| `V4__indexes.sql` | Adds query indexes and unique indexes. |
| `V5__constraints.sql` | Normalizes enum text and adds check constraints. |

