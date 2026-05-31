# Backend Game Role Filtering Design

> **Date:** 2026-06-01
> **Status:** Design (pre-implementation)
> **Version:** 0.6.0-alpha target

**Goal:** Add role-based filtering to `GET /api/games` so the frontend can distinguish between games the current user GMs and games they play in. This enables the tabbed game list UI (GMing tabs vs Playing tabs).

---

## Approach: Query Parameter

Add an optional `role` query parameter to `GET /api/games`:

```
GET /api/games          → returns all active games (current behavior)
GET /api/games?role=gm  → returns only games where user has gm role
GET /api/games?role=player → returns only games where user has player role
```

---

## Controller Change

```ruby
# app/controllers/api/games_controller.rb
def index
  games = current_user.games.active.includes(game_memberships: :user)

  games = case params[:role]
          when 'gm'     then games.where(game_memberships: { role: :gm })
          when 'player' then games.where(game_memberships: { role: :player })
          else games
          end

  render json: GameSerializer.new(games).serialize, status: :ok
end
```

The query uses the existing `has_many :games, through: :game_memberships` association. Filtering by `game_memberships.role` scopes to the requested role.

---

## Response Shape

Unchanged — same `GameObject` array as the current endpoint. No new fields needed.

---

## Testing

- **Request spec:** `GET /api/games?role=gm` returns only GM games
- **Request spec:** `GET /api/games?role=player` returns only player games
- **Request spec:** User who is GM in one game and player in another gets the correct split per endpoint
- **Request spec:** `GET /api/games` (no filter) returns all games (backward compatible)

---

## No Model Changes

The existing `Game`, `GameMembership`, and `User` models are adequate. This is purely a controller- and query-level change.

---

## Future Considerations

- **Pagination:** If the number of games grows, `role` filtering composes naturally with page-based or cursor-based pagination.
- **Sorting:** Could add `sort_by` query param later (e.g., `sort_by=created_at&order=desc`).
