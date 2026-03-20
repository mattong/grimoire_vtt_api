# 📜 Progress Report: Grimoire VTT (MVP Phase 1)

**Current Status:** 🟢 Data Layer Foundation Complete
**Date:** March 20, 2026
**Build Version:** 0.1.0-alpha (Infrastructure)

---

## ✅ Completed Milestones

### 1. Project Infrastructure

- **Rails 8 API Core:** Set up in API-only mode.
- **PostgreSQL Integration:** Fully configured with `pgcrypto` for UUID support.
- **Test Suite:** RSpec initialized with FactoryBot and Faker.
- **Global Configuration:** Default primary keys set to `:uuid` for all future generators.

### 2. Core Data Models

| Model              | Status      | Features                                                                        |
| :----------------- | :---------- | :------------------------------------------------------------------------------ |
| **User**           | ✅ Complete | UUIDs, BCrypt (`has_secure_password`), Uniqueness validations (email/username). |
| **Game**           | ✅ Complete | UUIDs, Soft-delete (`archived_at`), Title validation.                           |
| **GameMembership** | ✅ Complete | Many-to-Many Join table, **Role Enum** (GM vs Player), Scoped uniqueness.       |

### 3. Testing Coverage

- **Model Specs:** 9 passing tests covering validations, associations, and enum logic.
- **Factories:** Dynamic blueprints for `User`, `Game`, and `GameMembership` using Faker.

---

## 🚧 Current Work-in-Progress

- **Documentation:** Finalizing the data schema and preparing for API implementation.

---

## ⏳ Remaining MVP Requirements (Phase 1)

### High Priority: API & Authentication

- [ ] **Routing:** Define the `namespace :api` and resource mapping in `routes.rb`.
- [ ] **JWT Implementation:** Set up Devise/JWT or a custom JWT handler for token issuance.
- [ ] **Auth Controllers:** `POST /api/auth/register` and `POST /api/auth/login`.
- [ ] **Games Controller:** Implement CRUD for Games (ensuring creator becomes GM).

### Medium Priority: Resource System

- [ ] **GameInvitation:** Invitation model and shareable token logic.
- [ ] **ResourceTemplate:** JSONB schema implementation for flexible character sheets.
- [ ] **Resource:** Logic for instantiating templates into actual items/characters.

### Feature Parity: Narrative Tools

- [ ] **Scenario:** Sequential campaign journal with Markdown support.
- [ ] **Archiving Logic:** Controller-level soft-delete for Games.

---

## 📉 Technical Debt / Refinements

- **Serialization:** Select and implement a JSON serializer (Jbuilder or Fast_JSONAPI).
- **Error Handling:** Implement global exception handling for `ActiveRecord` errors.
