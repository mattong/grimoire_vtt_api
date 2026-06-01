# Grimoire VTT API Contract

> **Source of Truth** — This document defines the canonical contract between the Grimoire VTT backend (Rails 8.1, Devise JWT) and all frontend clients. Both sides must conform to the shapes, field names, status codes, and error formats documented here.

---

## Table of Contents

1. [General Conventions](#general-conventions)
2. [Authentication](#authentication)
3. [Serialized Response Objects](#serialized-response-objects)
4. [Endpoints](#endpoints)
   - [Auth](#auth)
   - [Games](#games)
   - [Resource Templates](#resource-templates)
   - [Resources](#resources)
5. [Error Responses Reference](#error-responses-reference)
6. [CORS](#cors)
7. [Open Questions](#open-questions)

---

## General Conventions

### Base URL

All endpoints are prefixed with `/api`.

```
https://<host>/api/...
```

### Content Type

All requests and responses use `Content-Type: application/json`.

### Authentication

Protected endpoints require a Bearer JWT in the `Authorization` header:

```
Authorization: Bearer <jwt_token>
```

- JWT expires **24 hours** after issuance.
- Tokens are dispatched via the `Authorization` header on successful signup and login.
- Tokens are revoked server-side on logout.

### Field Naming

All JSON fields use **snake_case** in both requests and responses. Frontends must consume/produce snake_case. No camelCase translation is performed at the API layer.

### Soft Deletes

All `DELETE` endpoints perform a **soft delete**: the record's `archived_at` column is set to the current timestamp. Records are **not** hard-deleted from the database. The `archived_at` field is **excluded from all serialized responses**.

### Pagination

Currently, no endpoints implement pagination. All list endpoints return the complete set of results. This is subject to change.

### Update Method

All update endpoints use `PATCH`, not `PUT`.

---

## Authentication

### Error Shapes

The API uses two standardized error shapes:

| Shape | When | Fields |
|-------|------|--------|
| Single error | Auth failures, 404, 403 | `{ "error": "string" }` |
| Validation errors | 422 Unprocessable Entity | `{ "errors": ["string", ...] }` |

---

## Serialized Response Objects

These are the canonical JSON shapes returned by the API. Every endpoint response is composed from these objects.

### UserObject

Returned in auth responses and nested in memberships/resources.

```json
{
  "id": "uuid",
  "username": "string"
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | string (UUID) | no | User's UUID |
| `username` | string | no | Display/username |

---

### GameMembershipObject

Returned nested within `GameObject`.

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "game_id": "uuid",
  "role": "player|gm",
  "user": {
    "id": "uuid",
    "username": "string"
  }
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | string (UUID) | no | Membership UUID |
| `user_id` | string (UUID) | no | User's UUID |
| `game_id` | string (UUID) | no | Game's UUID |
| `role` | string (enum) | no | `"player"` or `"gm"` |
| `user` | UserObject | no | Nested user info |

---

### GameObject

Returned by game endpoints.

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string|null",
  "system": "string|null",
  "created_at": "ISO8601",
  "game_memberships": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "game_id": "uuid",
      "role": "player|gm",
      "user": {
        "id": "uuid",
        "username": "string"
      }
    }
  ]
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | string (UUID) | no | Game UUID |
| `title` | string | no | Game title |
| `description` | string | **yes** | Game description (nullable) |
| `system` | string | **yes** | Game system/ruleset (nullable) |
| `created_at` | string (ISO8601) | no | Timestamp of creation |
| `game_memberships` | array of GameMembershipObject | no | Members with roles; always an array (may be empty) |

---

### ResourceTemplateObject

Returned by resource template endpoints.

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "name": "string",
  "template_type": "character|item|status|npc|custom",
  "schema": {
    "fields": [
      {
        "field_key": "string",
        "label": "string",
        "input_type": "string"
      }
    ]
  },
  "creatable_by": "gm|all"
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | string (UUID) | no | Template UUID |
| `game_id` | string (UUID) | no | Parent game UUID |
| `name` | string | no | Template display name |
| `template_type` | string (enum) | no | One of: `character`, `item`, `status`, `npc`, `custom` |
| `schema` | object | no | JSON Schema defining resource data fields |
| `schema.fields` | array of FieldObject | no | Array of field definitions |
| `schema.fields[].field_key` | string | no | Machine key for the field |
| `schema.fields[].label` | string | no | Human-readable label |
| `schema.fields[].input_type` | string | no | UI hint for input rendering |
| `creatable_by` | string (enum) | no | `"gm"` or `"all"` |

---

### ResourceObject

Returned by resource endpoints.

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "resource_template_id": "uuid",
  "player_id": "uuid|null",
  "name": "string",
  "data": {},
  "created_at": "ISO8601",
  "resource_template": {
    "id": "uuid",
    "name": "string",
    "template_type": "string",
    "schema": {
      "fields": []
    }
  },
  "player": {
    "id": "uuid",
    "username": "string"
  }
}
```

> **Note:** `player` is `null` when the resource is not associated with a player (e.g., NPC resources or game-level resources). The frontend must handle `player: null`.

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `id` | string (UUID) | no | Resource UUID |
| `game_id` | string (UUID) | no | Parent game UUID |
| `resource_template_id` | string (UUID) | no | Template UUID this resource instantiates |
| `player_id` | string (UUID) | **yes** | Owning player UUID (nullable) |
| `name` | string | no | Resource display name |
| `data` | object | no | JSON data conforming to the template schema; may be empty `{}` |
| `created_at` | string (ISO8601) | no | Timestamp of creation |
| `resource_template` | (nested) | no | Lightweight template info including schema so frontend can render `data` fields |
| `player` | UserObject | **yes** | Owning player user info; `null` if unowned |

---

## Endpoints

---

### Auth

---

#### POST /api/auth/signup — Register

**Authentication:** None (public)

**Request:**

```
Content-Type: application/json
```

```json
{
  "user": {
    "username": "string (required)",
    "password": "string (required, min 6 characters)",
    "password_confirmation": "string (required)"
  }
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `user.username` | string | yes | Must be unique |
| `user.password` | string | yes | Minimum 6 characters |
| `user.password_confirmation` | string | yes | Must match `password` |

**Response — 201 Created:**

```
Authorization: Bearer <jwt_token>
```

```json
{
  "message": "Signed up successfully.",
  "user": {
    "username": "string"
  }
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `message` | string | no | Success message |
| `user.username` | string | no | The newly registered username |

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Username can't be blank", "Password is too short (minimum is 6 characters)", "Password confirmation doesn't match Password"]
}
```

---

#### POST /api/auth/login — Login

**Authentication:** None (public)

**Request:**

```json
{
  "user": {
    "username": "string (required)",
    "password": "string (required)"
  }
}
```

**Response — 200 OK:**

```
Authorization: Bearer <jwt_token>
```

```json
{
  "message": "Logged in successfully.",
  "user": {
    "username": "string"
  }
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "Invalid username or password."
}
```

---

#### DELETE /api/auth/logout — Logout (revoke JWT)

**Authentication:** Bearer JWT **required**

**Request:**

```
Authorization: Bearer <jwt_token>
```

No body.

**Response — 200 OK:**

```json
{
  "message": "Logged out successfully."
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

### Games

---

#### GET /api/games — List user's active games

**Authentication:** Bearer JWT **required**

**Request:** No body.

**Response — 200 OK:**

```json
[
  {
    "id": "uuid",
    "title": "string",
    "description": "string|null",
    "system": "string|null",
    "created_at": "ISO8601",
    "game_memberships": [
      {
        "id": "uuid",
        "user_id": "uuid",
        "game_id": "uuid",
        "role": "player|gm",
        "user": {
          "id": "uuid",
          "username": "string"
        }
      }
    ]
  }
]
```

Returns only games where the current user has an active (non-archived) membership.

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### POST /api/games — Create game

**Authentication:** Bearer JWT **required**

**Request:**

```json
{
  "game": {
    "title": "string (required)",
    "description": "string (optional)",
    "system": "string (optional)"
  }
}
```

| Field | Type | Required | Default |
|-------|------|----------|---------|
| `game.title` | string | yes | — |
| `game.description` | string | no | `null` |
| `game.system` | string | no | `null` |

On success, the current user is automatically added as a GM member.

**Response — 201 Created:**

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string|null",
  "system": "string|null",
  "created_at": "ISO8601",
  "game_memberships": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "game_id": "uuid",
      "role": "gm",
      "user": {
        "id": "uuid",
        "username": "string"
      }
    }
  ]
}
```

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Title can't be blank", "..."]
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### GET /api/games/:id — Show game

**Authentication:** Bearer JWT **required**; current user must be a member of the game.

**Request:** No body.

**Response — 200 OK:**

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string|null",
  "system": "string|null",
  "created_at": "ISO8601",
  "game_memberships": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "game_id": "uuid",
      "role": "player|gm",
      "user": {
        "id": "uuid",
        "username": "string"
      }
    }
  ]
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Game not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### PATCH /api/games/:id — Update game

**Authentication:** Bearer JWT **required**; current user must have the `gm` role in this game.

**Request:**

```json
{
  "game": {
    "title": "string (optional)",
    "description": "string (optional)",
    "system": "string (optional)"
  }
}
```

All fields are optional. Only supplied fields are updated.

**Response — 200 OK:**

```json
{
  "id": "uuid",
  "title": "string",
  "description": "string|null",
  "system": "string|null",
  "created_at": "ISO8601",
  "game_memberships": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "game_id": "uuid",
      "role": "player|gm",
      "user": {
        "id": "uuid",
        "username": "string"
      }
    }
  ]
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "Only a GM can do that!"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Game not found"
}
```

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Title can't be blank", "..."]
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### DELETE /api/games/:id — Archive game (soft-delete)

**Authentication:** Bearer JWT **required**; current user must have the `gm` role in this game.

**Request:** No body.

**Response — 200 OK:**

```json
{
  "message": "Game archived successfully",
  "archived_at": "ISO8601"
}
```

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `message` | string | no | Success message |
| `archived_at` | string (ISO8601) | no | Timestamp of archival |

**Response — 403 Forbidden:**

```json
{
  "error": "Only a GM can do that!"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Game not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

### Resource Templates

> All resource template endpoints are nested under `/api/games/:game_id/`.

---

#### GET /api/games/:game_id/resource_templates — List templates

**Authentication:** Bearer JWT **required**; current user must be a member of the game.

**Request:** No body.

**Response — 200 OK:**

```json
[
  {
    "id": "uuid",
    "game_id": "uuid",
    "name": "string",
    "template_type": "character|item|status|npc|custom",
    "schema": {
      "fields": [
        {
          "field_key": "string",
          "label": "string",
          "input_type": "string"
        }
      ]
    },
    "creatable_by": "gm|all"
  }
]
```

**Response — 404 Not Found:**

```json
{
  "error": "Game not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### POST /api/games/:game_id/resource_templates — Create template

**Authentication:** Bearer JWT **required**; current user must have the `gm` role in this game.

**Request:**

```json
{
  "resource_template": {
    "name": "string (required)",
    "template_type": "string (required, one of: character, item, status, npc, custom)",
    "schema": {
      "fields": [
        {
          "field_key": "string",
          "label": "string",
          "input_type": "string"
        }
      ]
    },
    "creatable_by": "string (optional, default: \"gm\", one of: gm, all)"
  }
}
```

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `resource_template.name` | string | yes | — | — |
| `resource_template.template_type` | string | yes | — | One of: `character`, `item`, `status`, `npc`, `custom` |
| `resource_template.schema` | object | yes | — | Must contain `fields` array |
| `resource_template.schema.fields` | array | yes | — | Array of field definition objects |
| `resource_template.schema.fields[].field_key` | string | yes | — | Machine key |
| `resource_template.schema.fields[].label` | string | yes | — | Human-readable label |
| `resource_template.schema.fields[].input_type` | string | yes | — | UI hint for input type |
| `resource_template.creatable_by` | string | no | `"gm"` | One of: `gm`, `all` |

**Response — 201 Created:**

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "name": "string",
  "template_type": "character|item|status|npc|custom",
  "schema": {
    "fields": [
      {
        "field_key": "string",
        "label": "string",
        "input_type": "string"
      }
    ]
  },
  "creatable_by": "gm|all"
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "Only a GM can do that!"
}
```

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Name can't be blank", "Template type is not included in the list", "..."]
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### GET /api/games/:game_id/resource_templates/:id — Show template

**Authentication:** Bearer JWT **required**; current user must be a member of the game.

**Request:** No body.

**Response — 200 OK:**

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "name": "string",
  "template_type": "character|item|status|npc|custom",
  "schema": {
    "fields": [
      {
        "field_key": "string",
        "label": "string",
        "input_type": "string"
      }
    ]
  },
  "creatable_by": "gm|all"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource template not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### PATCH /api/games/:game_id/resource_templates/:id — Update template

**Authentication:** Bearer JWT **required**; current user must have the `gm` role in this game.

**Request:**

```json
{
  "resource_template": {
    "name": "string (optional)",
    "template_type": "string (optional, one of: character, item, status, npc, custom)",
    "schema": {
      "fields": [
        {
          "field_key": "string",
          "label": "string",
          "input_type": "string"
        }
      ]
    },
    "creatable_by": "string (optional, one of: gm, all)"
  }
}
```

All fields are optional. Only supplied fields are updated. When `schema` is supplied, the entire `fields` array is replaced.

**Response — 200 OK:**

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "name": "string",
  "template_type": "character|item|status|npc|custom",
  "schema": {
    "fields": [
      {
        "field_key": "string",
        "label": "string",
        "input_type": "string"
      }
    ]
  },
  "creatable_by": "gm|all"
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "Only a GM can do that!"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource template not found"
}
```

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Name can't be blank", "..."]
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### DELETE /api/games/:game_id/resource_templates/:id — Archive template (soft-delete)

**Authentication:** Bearer JWT **required**; current user must have the `gm` role in this game.

**Request:** No body.

**Response — 200 OK:**

```json
{
  "message": "Resource template archived successfully",
  "archived_at": "ISO8601"
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "Only a GM can do that!"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource template not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

### Resources

> All resource endpoints are nested under `/api/games/:game_id/`.

---

#### GET /api/games/:game_id/resources — List resources

**Authentication:** Bearer JWT **required**; current user must be a member of the game.

**Request:** No body.

**Response — 200 OK:**

```json
[
  {
    "id": "uuid",
    "game_id": "uuid",
    "resource_template_id": "uuid",
    "player_id": "uuid|null",
    "name": "string",
    "data": {},
    "created_at": "ISO8601",
    "resource_template": {
      "id": "uuid",
      "name": "string",
      "template_type": "string",
      "schema": {
        "fields": []
      }
    },
    "player": {
      "id": "uuid",
      "username": "string"
    }
  }
]
```

> **Important:** `player` is `null` when the resource has no owner. Frontends must handle this case.

**Response — 404 Not Found:**

```json
{
  "error": "Game not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### POST /api/games/:game_id/resource_templates/:template_id/resources — Create resource from template

**Authentication:** Bearer JWT **required**; current user must satisfy the template's `creatable_by` constraint (GM always passes; non-GM users are checked against `creatable_by: "all"`).

**Request:**

```json
{
  "resource": {
    "name": "string (required)",
    "data": {},
    "player_id": "uuid (optional, GM only override)"
  }
}
```

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `resource.name` | string | yes | Display name |
| `resource.data` | object | no | Merged with schema defaults; may be omitted or empty |
| `resource.player_id` | string (UUID) | no | Only accepted if current user is a GM; associates the resource with a player |

**Response — 201 Created:**

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "resource_template_id": "uuid",
  "player_id": "uuid|null",
  "name": "string",
  "data": {},
  "created_at": "ISO8601",
  "resource_template": {
    "id": "uuid",
    "name": "string",
    "template_type": "string",
    "schema": {
      "fields": []
    }
  },
  "player": {
    "id": "uuid",
    "username": "string"
  }
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "You are not authorized to create resources from this template"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource template not found"
}
```

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Name can't be blank", "..."]
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### GET /api/games/:game_id/resources/:id — Show resource

**Authentication:** Bearer JWT **required**; current user must be a member of the game.

**Request:** No body.

**Response — 200 OK:**

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "resource_template_id": "uuid",
  "player_id": "uuid|null",
  "name": "string",
  "data": {},
  "created_at": "ISO8601",
  "resource_template": {
    "id": "uuid",
    "name": "string",
    "template_type": "string",
    "schema": {
      "fields": []
    }
  },
  "player": {
    "id": "uuid",
    "username": "string"
  }
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### PATCH /api/games/:game_id/resources/:id — Update resource

**Authentication:** Bearer JWT **required**; current user must be the resource owner (`player_id` matches current user) **or** a GM of the game.

**Request:**

```json
{
  "resource": {
    "name": "string (optional)",
    "data": {},
    "player_id": "uuid (optional, GM only override)"
  }
}
```

All fields are optional. Only supplied fields are updated.

**Response — 200 OK:**

```json
{
  "id": "uuid",
  "game_id": "uuid",
  "resource_template_id": "uuid",
  "player_id": "uuid|null",
  "name": "string",
  "data": {},
  "created_at": "ISO8601",
  "resource_template": {
    "id": "uuid",
    "name": "string",
    "template_type": "string",
    "schema": {
      "fields": []
    }
  },
  "player": {
    "id": "uuid",
    "username": "string"
  }
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "Forbidden"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource not found"
}
```

**Response — 422 Unprocessable Entity:**

```json
{
  "errors": ["Name can't be blank", "..."]
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

#### DELETE /api/games/:game_id/resources/:id — Archive resource (soft-delete)

**Authentication:** Bearer JWT **required**; current user must be the resource owner (`player_id` matches current user) **or** a GM of the game.

**Request:** No body.

**Response — 200 OK:**

```json
{
  "message": "Resource archived successfully",
  "archived_at": "ISO8601"
}
```

**Response — 403 Forbidden:**

```json
{
  "error": "Forbidden"
}
```

**Response — 404 Not Found:**

```json
{
  "error": "Resource not found"
}
```

**Response — 401 Unauthorized:**

```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

---

## Error Responses Reference

### Standardized Error Shapes

| Status Code | Shape | Description |
|-------------|-------|-------------|
| `401` | `{ "error": "string" }` | Missing, expired, or invalid JWT |
| `403` | `{ "error": "string" }` | Authenticated but not authorized |
| `404` | `{ "error": "string" }` | Resource not found |
| `422` | `{ "errors": ["string", ...] }` | Validation failure |

### Complete Error Message Inventory

#### 401 Unauthorized

| Context | Error Message |
|---------|---------------|
| Any protected endpoint | `"You need to sign in or sign up before continuing."` |
| Login failure | `"Invalid username or password."` |

#### 403 Forbidden

| Context | Error Message |
|---------|---------------|
| Game update/delete (non-GM) | `"Only a GM can do that!"` |
| Template create/update/delete (non-GM) | `"Only a GM can do that!"` |
| Resource create (creatable_by mismatch) | `"You are not authorized to create resources from this template"` |
| Resource update/delete (not owner or GM) | `"Forbidden"` |

#### 404 Not Found

| Context | Error Message |
|---------|---------------|
| Game not found | `"Game not found"` |
| Resource template not found | `"Resource template not found"` |
| Resource not found | `"Resource not found"` |

### Single Error Response Shape

```json
{
  "error": "Human-readable error message"
}
```

### Validation Error Response Shape

```json
{
  "errors": ["Field-level error 1", "Field-level error 2"]
}
```

---

## CORS

**CORS is NOT currently configured.**

The `rack-cors` gem is present in the Gemfile but the initializer is commented out. Any frontend running on a different origin (including `localhost` on a different port) will encounter CORS errors in development.

**Required action** before any frontend can connect: Configure `config/initializers/cors.rb` to allow the frontend origin(s). For development this typically means:

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173' # or whatever your frontend dev server uses
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
```

---

## Open Questions

These items require human sign-off or further discussion:

1. **Pagination** — List endpoints currently return all results. Should pagination be added before a frontend connects? If so, what format (page-based, cursor-based)?
2. **CORS origins** — Which origin(s) need to be allowed? Until `cors.rb` is configured, no external frontend can connect.
3. **Error message internationalization** — Error messages are currently hardcoded English strings. Any plans for i18n?
4. **Template schema validation** — The `schema.fields` array requires `field_key`, `label`, and `input_type`. Are there additional constraints or validations needed (e.g., uniqueness of `field_key` within a template)?
5. **Resource `data` defaults** — When creating a resource without supplying `data`, should the API auto-populate default values from the template schema? Currently documented as merged with schema defaults — but what constitutes a "default" is not yet defined.
6. **`creatable_by` enforcement** — When `creatable_by: "all"`, non-GM users should be able to create resources. Is the `player_id` auto-assigned to the current user in that case, or left null?

---

## Key Decisions

1. **snake_case everywhere** — Both request and response field names use snake_case. No camelCase conversion at the API boundary.
2. **Soft deletes are silent** — `archived_at` is excluded from all serialized output. The only way to detect a soft-delete is that the record no longer appears in lists or show responses.
3. **`player` can be null** — The `player` field in ResourceObject is nullable. Frontends must guard against `player: null`.
4. **Error shapes are consistent** — Two shapes only: `{ "error" }` for auth/403/404, `{ "errors" }` for 422 validation.
5. **JWT in Authorization header** — Token is always delivered and consumed via the `Authorization: Bearer` header, never in cookies or response bodies.
6. **GM-only actions** — Game update/delete, template CRUD, and player_id overrides are restricted to users with `role: "gm"` in the game.
7. **Resource owner edits** — Resource update/delete is permitted for either the resource owner (`player_id`) or a GM.
