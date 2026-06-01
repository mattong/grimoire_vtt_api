# Resource System Design

**Date:** 2026-06-01
**Status:** Design (pre-implementation)
**Version:** 0.5.0-alpha target

## Overview

Add a Resource controller and service layer to instantiate resources from resource templates. A Resource is a concrete game entity (character, item, etc.) created from a template's schema definition.

## Routes

```ruby
namespace :api do
  resources :games do
    resources :resource_templates do
      resources :resources, only: [:create]
    end
    resources :resources, only: [:index, :show, :update, :destroy]
  end
end
```

- **Create** (`POST /api/games/:game_id/resource_templates/:template_id/resources`) — creation requires a template
- **Index** (`GET /api/games/:game_id/resources`) — game-scoped listing
- **Show / Update / Destroy** — member routes under the game

## Model Changes

### ResourceTemplate — add `creatable_by`

New column `creatable_by` (string, default `"gm"`, not null) with inclusion validation on `%w[gm all]`.

Values:
- `"gm"` — only GMs can create resources from this template
- `"all"` — any game member can create resources from this template

### Resource — no schema validation (deferred)

The `data` JSONB field is not validated against the template schema at the model level. The builder handles data structure on creation; clients are responsible for well-formed data on updates.

## ResourceFromTemplateBuilder

A plain Ruby service object at `app/services/resource_from_template_builder.rb`:

```ruby
class ResourceFromTemplateBuilder
  def self.call(template:, current_user:, params:)
    # Returns a Result struct with:
    #   success? — boolean
    #   resource — unsaved Resource instance (nil on failure)
    #   error    — string message (nil on success)
    #   status   — symbol for HTTP status (:forbidden, :unprocessable_content)
  end
end
```

Behaviors:
- **Permission check:** If `template.creatable_by == "gm"` and current_user is not a GM, return `Result.new(success: false, error: "...", status: :forbidden)`.
- **Data defaults:** For each field in `template.schema["fields"]`, set `{ field_key => nil }`. Deep-merge any `params[:data]` over top.
- **Player assignment:** Defaults to `current_user.id`. If a `player_id` param is present and current_user is GM, use that instead.
- **Success return:** On successful build, return `Result.new(success: true, resource: resource)`. The resource is not yet saved — the controller calls `resource.save`.

## Controller — Api::ResourcesController

Follows the same pattern as `Api::ResourceTemplatesController`.

| Action | Auth | Notes |
|--------|------|-------|
| `index` | All active game members | `@game.resources.active` |
| `show` | All active game members | Scoped to game, 404 if not found |
| `create` | Per template's `creatable_by` | Uses builder, returns 201/422 |
| `update` | GM or owning player | 403 otherwise |
| `destroy` | GM or owning player | Soft-delete via `archived_at` |

Reuses `GameAuthenticatable` concern (`set_game`, `ensure_gm!`) plus a new check:

```ruby
def ensure_owner_or_gm!
  resource = @game.resources.active.find(params[:id])
  unless resource.player == current_user || @game.gm?(current_user)
    render json: { error: "Forbidden" }, status: :forbidden
  end
end
```

## Testing

### Request specs (`spec/requests/api/resources_spec.rb`)

- Create: player with `creatable_by: "all"` succeeds / with `"gm"` gets 403 / GM with `"gm"` succeeds
- Create: invalid data returns 422
- Index: game member sees all resources / non-member gets 404
- Show: member sees resource / non-member gets 404 / archived returns 404
- Update: GM updates any / owning player updates own / non-owning player gets 403
- Destroy: GM archives any / owning player archives own / non-owning player gets 403

### Service specs (`spec/services/resource_from_template_builder_spec.rb`)

- Pre-populates data from schema fields with nil defaults
- Merges client-provided data over the defaults
- Rejects creation when `creatable_by == "gm"` and user is player
- Sets `player_id` to current_user by default
- Sets `player_id` to provided value when GM overrides

### Model specs — add to `spec/models/resource_spec.rb`

- Validates name presence
- Associations (belongs to template, game, player)

## Future Considerations

- **Secret fields:** If a field in the template schema gains a `secret: true` flag, resource data for those fields should be filtered per-player (only the owning player and GM see them).
- **Data validation on update:** Optionally validate that `data` keys match the template schema on future edits.
- **Serializer layer:** Once Jbuilder/jbuild is introduced, include `data` fields dynamically based on the template schema.
