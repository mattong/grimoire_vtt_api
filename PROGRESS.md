# 📜 Progress Report: Grimoire VTT (MVP Phase 1)

**Current Status:** 🔵 Resource Template System Complete
**Date:** April 5, 2026
**Build Version:** 0.4.0-alpha (Resource Templates)

---

## ✅ Completed Milestones

### 1. Infrastructure & Identity

- **Rails 8 API Core:** Configured in API-only mode.
- **UUID Integration:** All primary keys use UUIDs for obfuscated IDs.
- **User Model:** Username-only (Privacy-focused).
- **Authentication:** Devise + JWT fully implemented.
- **Revocation:** JTI "Kill Switch" strategy for secure logouts.

### 2. Core API Handshake

- **Registration:** `POST /api/auth/signup` (Returns 201 Created + JWT).
- **Login:** `POST /api/auth/login` (Returns 200 OK + JWT).
- **Logout:** `DELETE /api/auth/logout` (Invalidates JTI + Returns 200 OK).

### 3. Games API

- **Create:** `POST /api/games` — Creates game and auto-assigns creator as GM via transaction (Returns 201 Created).
- **List:** `GET /api/games` — Returns only active games the user is a member of.
- **Show:** `GET /api/games/:id` — Member-scoped; returns 404 for non-member or archived games.
- **Update:** `PATCH /api/games/:id` — GM-only (Returns 200 OK).
- **Archive:** `DELETE /api/games/:id` — GM-only soft-delete via `archived_at` timestamp (Returns 200 OK).

### 4. Resource Template System

- **Model:** `ResourceTemplate` with JSONB `schema` field; validates `name` (unique per game), `template_type` (`character`, `item`, `status`, `npc`, `custom`), and deep schema structure (field keys and input types).
- **Soft-delete:** `archived_at` scope matching the Games pattern.
- **`GameAuthenticatable` concern:** Extracted shared `set_game` and `ensure_gm!` into a reusable controller concern.
- **Create:** `POST /api/games/:game_id/resource_templates` — GM-only (Returns 201 Created).
- **List:** `GET /api/games/:game_id/resource_templates` — All members; returns only active templates.
- **Show:** `GET /api/games/:game_id/resource_templates/:id` — All members; returns 404 for archived/missing.
- **Update:** `PATCH /api/games/:game_id/resource_templates/:id` — GM-only (Returns 200 OK).
- **Archive:** `DELETE /api/games/:game_id/resource_templates/:id` — GM-only soft-delete (Returns 200 OK).

### 5. Testing Coverage

- **47 passing specs** across model and request layers.
- **Model Specs:** User, Game, GameMembership, and ResourceTemplate validations.
- **Auth Request Specs:** 7 specs covering signup, login, and logout flows.
- **Games Request Specs:** 12 specs covering CRUD, authorization, and membership scoping.
- **Resource Template Request Specs:** 14 specs covering CRUD, GM vs. player access, and archiving.

---

## ⏳ Remaining MVP Requirements

### High Priority: Resource System

- [ ] **Resource:** Logic for instantiating templates into actual items/characters (table exists, model/controller pending).
- [ ] **GameInvitation:** Invitation model and shareable token logic.

### Medium Priority: Narrative Tools

- [ ] **Scenario:** Sequential campaign journal with Markdown support.

---

## 📉 Technical Debt / Refinements

- [ ] **Serialization:** Select and implement a JSON serializer (Jbuilder or Fast_JSONAPI).
- [ ] **Error Handling:** Implement global exception handling for `ActiveRecord` errors.

---

## 📂 Past Reports

| Date                                          | Status                                      |
| :-------------------------------------------- | :------------------------------------------ |
| [March 31, 2026](docs/progress/2026-03-31.md) | 🔵 Games CRUD & Authorization Complete      |
| [March 22, 2026](docs/progress/2026-03-22.md) | 🔵 Authentication & Identity Layer Complete |
| [March 20, 2026](docs/progress/2026-03-20.md) | 🟢 Data Layer Foundation Complete           |
