# Backend Slugs Design

> **Date:** 2026-06-01
> **Status:** Design (pre-implementation)
> **Version:** 0.6.0-alpha target

**Goal:** Replace UUIDs in URL paths with human-readable slugs for Game, ResourceTemplate, and Resource. This obfuscates internal UUIDs and improves URL readability.

**Parent-scoped uniqueness rules:**
- **Game:** `slug` is unique per `gm_id` (creator). A GM cannot own two games with the same slug. Different GMs can have the same slug.
- **ResourceTemplate:** `slug` is unique per `game_id`. Two templates in the same game cannot share a slug.
- **Resource:** `slug` is unique per `game_id`. Two resources in the same game cannot share a slug.

---

## Approach: `friendly_id` Gem

Use the `friendly_id` gem for slug generation, collision handling, and scoped lookups.

---

## Migration Changes

### Game

```ruby
add_column :games, :slug, :string
# No unique global index — slug is unique per gm_id
add_index :games, [:gm_id, :slug], unique: true
```

### ResourceTemplate

```ruby
add_column :resource_templates, :slug, :string
add_index :resource_templates, [:game_id, :slug], unique: true
```

### Resource

```ruby
add_column :resources, :slug, :string
add_index :resources, [:game_id, :slug], unique: true
```

### Game: Track Creator with `gm_id`

The `Game` model needs to track who the GM/creator is for slug scoping. Add:

```ruby
add_reference :games, :gm, foreign_key: { to_table: :users }, null: false
```

**Existing records:** Backfill `gm_id` for existing games by finding the membership with `role: "gm"`:

```ruby
Game.find_each do |game|
  gm_membership = game.game_memberships.find_by(role: :gm)
  game.update_column(:gm_id, gm_membership.user_id) if gm_membership
end
```

On new game creation, `current_user` is set as `gm`. The existing `GamesController#create` transaction needs the addition:

```ruby
def create
  @game = Game.new(game_params.merge(gm: current_user))
  ActiveRecord::Base.transaction do
    @game.save!
    @game.game_memberships.create!(user: current_user, role: :gm)
    # ...rest unchanged
  end
end
```

The `gm_id` is different from the memberships — it's the owner of the game, not necessarily a membership role (though in practice the creator is always a GM member).

---

## Model Changes

### Shared Concern: `Sluggable`

```ruby
# app/models/concerns/sluggable.rb
module Sluggable
  extend ActiveSupport::Concern

  included do
    extend FriendlyId
    friendly_id :source_for_slug, use: :scoped, scope: :slug_scope
  end

  def source_for_slug
    respond_to?(:title) ? :title : :name
  end

  def slug_scope
    # Override in each model
    raise NotImplementedError
  end
end
```

### Game Model

```ruby
class Game < ApplicationRecord
  include Sluggable

  belongs_to :gm, class_name: 'User', foreign_key: :gm_id

  def slug_scope
    gm_id
  end

  private

  def source_for_slug
    :title
  end
end
```

### ResourceTemplate Model

```ruby
class ResourceTemplate < ApplicationRecord
  include Sluggable

  def slug_scope
    game_id
  end

  private

  def source_for_slug
    :name
  end
end
```

### Resource Model

```ruby
class Resource < ApplicationRecord
  include Sluggable

  def slug_scope
    game_id
  end

  private

  def source_for_slug
    :name
  end
end
```

---

## Controller Changes

**Pattern:** Replace `find(params[:id])` with `find_by!(slug: params[:id])` in every controller action.

```ruby
# Api::GamesController
before_action :set_game, only: [:show, :update, :destroy]

def set_game
  @game = current_user.games.active.find_by!(slug: params[:id])
rescue ActiveRecord::RecordNotFound
  render json: { error: "Game not found" }, status: :not_found
end
```

```ruby
# Api::ResourceTemplatesController
def set_template
  @template = @game.resource_templates.active.find_by!(slug: params[:id])
end
```

```ruby
# Api::ResourcesController
def set_resource
  @resource = @game.resources.active.includes(:resource_template, :player)
                    .find_by!(slug: params[:id])
end
```

**`params[:id]` still works because `friendly_id` creates `finders` that accept both slugs and UUIDs.** However, for the frontend we only send slugs in URLs.

---

## Routes

No route changes needed. The `params[:id]` in `resources :games` becomes a slug. The routes remain:

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

---

## Testing

- **Model spec:** slug generation on create, slug scoping, collision handling (duplicate name appends `--2`)
- **Request spec:** requests use slugs in URLs (e.g., `GET /api/games/curse-of-strahd`), confirm lookups work
- **Request spec:** confirm UUID-based lookups still work during transition (or intentionally broken — document choice)

**Decision:** After the slug migration, the API will **only accept slugs**. UUID-based lookups will return 404. This keeps the contract clean.

---

## Collision Behavior

When `friendly_id` detects a slug collision within the scope, it appends `--2`, `--3`, etc.:

- GM creates "Curse of Strahd" → slug: `curse-of-strahd`
- GM creates "Curse of Strahd" again → slug: `curse-of-strahd--2`

The frontend should handle this gracefully — display the name/title, not the slug, in the UI.
