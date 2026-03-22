# 📜 Progress Report: Grimoire VTT (MVP Phase 1)

**Current Status:** 🔵 Authentication & Identity Layer Complete
**Date:** March 22, 2026
**Build Version:** 0.2.0-alpha (Auth)

---

## ✅ Completed Milestones

### 1. Infrastructure & Identity

- **Rails 8 API Core:** Configured in API-only mode.
- **UUID Integration:** All primary keys use UUIDs for obfuscated IDs.
- **User Model:** Migrated to Username-only (Privacy-focused).
- **Authentication:** Devise + JWT fully implemented.
- **Revocation:** JTI "Kill Switch" strategy for secure logouts.

### 2. Core API Handshake

- **Registration:** `POST /api/auth/signup` (Returns 201 Created + JWT).
- **Login:** `POST /api/auth/login` (Returns 200 OK + JWT).
- **Logout:** `DELETE /api/auth/logout` (Invalidates JTI + Returns 200 OK).

### 3. Testing Coverage

- **Identity Specs:** 6 passing request specs for Auth & Registration.
- **Model Specs:** Validations for username and JTI generation.

---

## 🚧 Current Work-in-Progress (Branch: `feat/games-auth`)

- **Authorization:** Implementing `authenticate_user!` on the Games controller.
- **Ownership Logic:** Ensuring game creators are automatically assigned the `game_master` role.

---

## ⏳ Remaining MVP Requirements

### High Priority: Game Logic

- [ ] **Games CRUD:** Create/Update/Archive games.
- [ ] **Member Logic:** Automatically create `GameMembership` on Game creation.
- [ ] **Security:** Prevent unauthorized users from viewing private games.

### Medium Priority: Resource System

- [ ] **GameInvitation:** Shareable token logic.
- [ ] **ResourceTemplate:** JSONB schema for custom character sheets.

---

## 📂 Past Reports

| Date | Status |
| :--- | :----- |
| [March 20, 2026](docs/progress/2026-03-20.md) | 🟢 Data Layer Foundation Complete |

