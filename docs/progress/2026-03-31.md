# 📜 Progress Report: Grimoire VTT (MVP Phase 1)

**Current Status:** 🔵 Games CRUD & Authorization Complete
**Date:** March 31, 2026
**Build Version:** 0.3.0-alpha (Games)

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
- **Update:** `PATCH /api/games/:id` — GM-only; returns 401 for players (Returns 200 OK).
- **Archive:** `DELETE /api/games/:id` — GM-only soft-delete via `archived_at` timestamp (Returns 200 OK).

### 4. Testing Coverage

- **27 passing specs** across model and request layers.
- **Model Specs:** Validations, associations, and enum logic for User, Game, and GameMembership.
- **Auth Request Specs:** 7 specs covering signup, login, and logout flows.
- **Games Request Specs:** 12 specs covering CRUD, authorization, and membership scoping.

---

## ⏳ Remaining MVP Requirements

### High Priority: Resource System

- [ ] **GameInvitation:** Invitation model and shareable token logic.
- [ ] **ResourceTemplate:** JSONB schema implementation for flexible character sheets.
- [ ] **Resource:** Logic for instantiating templates into actual items/characters.

### Medium Priority: Narrative Tools

- [ ] **Scenario:** Sequential campaign journal with Markdown support.
- [ ] **Archiving Logic:** Controller-level soft-delete for Games (UI/admin tooling).

---

## 📉 Technical Debt / Refinements

- [ ] **Serialization:** Select and implement a JSON serializer (Jbuilder or Fast_JSONAPI).
- [ ] **Error Handling:** Implement global exception handling for `ActiveRecord` errors.

---

## 📂 Past Reports

| Date                                          | Status                                      |
| :-------------------------------------------- | :------------------------------------------ |
| [March 22, 2026](docs/progress/2026-03-22.md) | 🔵 Authentication & Identity Layer Complete |
| [March 20, 2026](docs/progress/2026-03-20.md) | 🟢 Data Layer Foundation Complete           |
