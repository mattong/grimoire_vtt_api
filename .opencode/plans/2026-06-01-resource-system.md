# Resource System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add CRUD for Resources (concrete game entities instantiated from ResourceTemplates) with role-based creation permissions.

**Architecture:** A single `Api::ResourcesController` using a `ResourceFromTemplateBuilder` service object for schema-aware instantiation. Following the existing patterns: `GameAuthenticatable` concern, soft-delete via `archived_at`, thin controllers.

**Tech Stack:** Rails 8.1 API, RSpec, FactoryBot, PostgreSQL JSONB

**Design spec:** `docs/superpowers/specs/2026-06-01-resource-system-design.md`

---

### Task 1: Add `creatable_by` migration

**Files:**
- Create: `db/migrate/TIMESTAMP_add_creatable_by_to_resource_templates.rb`
- Modify: `spec/factories/resource_templates.rb`

- [ ] **Step 1: Generate the migration**

Run: `rails generate migration AddCreatableByToResourceTemplates creatable_by:string`

- [ ] **Step 2: Edit the migration to add default and null constraint**

```ruby
# db/migrate/20260601000001_add_creatable_by_to_resource_templates.rb
class AddCreatableByToResourceTemplates < ActiveRecord::Migration[8.0]
  def change
    add_column :resource_templates, :creatable_by, :string, default: "gm", null: false
  end
end
```

- [ ] **Step 3: Run the migration**

Run: `rails db:migrate`

Expected: Schema updated with new column

- [ ] **Step 4: Update the factory**

In `spec/factories/resource_templates.rb`, add:

```ruby
factory :resource_template do
  # existing attributes...
  creatable_by { "gm" }

  trait :creatable_by_all do
    creatable_by { "all" }
  end
end
```

- [ ] **Step 5: Commit**

```bash
git add db/migrate/ spec/factories/
git commit -m "feat: add creatable_by to resource_templates"
```

---

### Task 2: Model changes

**Files:**
- Modify: `app/models/resource_template.rb`
- Modify: `app/models/resource.rb`
- Modify: `spec/models/resource_spec.rb`

- [ ] **Step 1: Write the failing ResourceTemplate model spec for `creatable_by`**

In `spec/models/resource_template_spec.rb`, add:

```ruby
describe "creatable_by" do
  it "defaults to 'gm'" do
    template = create(:resource_template)
    expect(template.creatable_by).to eq("gm")
  end

  it "is valid with 'gm'" do
    template = build(:resource_template, creatable_by: "gm")
    expect(template).to be_valid
  end

  it "is valid with 'all'" do
    template = build(:resource_template, creatable_by: "all")
    expect(template).to be_valid
  end

  it "is invalid with other values" do
    template = build(:resource_template, creatable_by: "player")
    expect(template).not_to be_valid
  end
end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/models/resource_template_spec.rb -e "creatable_by" --format documentation`

Expected: 1 failure — no validation for `creatable_by`

- [ ] **Step 3: Add validation to ResourceTemplate**

In `app/models/resource_template.rb`, add:

```ruby
validates :creatable_by, inclusion: { in: %w[gm all] }
```

- [ ] **Step 4: Run to confirm pass**

Run: `bundle exec rspec spec/models/resource_template_spec.rb -e "creatable_by" --format documentation`

Expected: 4 passing

- [ ] **Step 5: Write the failing Resource model specs**

Replace `spec/models/resource_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Resource, type: :model do
  describe "validations" do
    it "requires a name" do
      resource = build(:resource, name: nil)
      expect(resource).not_to be_valid
    end
  end

  describe "associations" do
    let(:resource) { create(:resource) }

    it "belongs to a resource_template" do
      expect(resource.resource_template).to be_a(ResourceTemplate)
    end

    it "belongs to a game" do
      expect(resource.game).to be_a(Game)
    end

    it "can have a player (user)" do
      user = create(:user)
      resource = create(:resource, player: user)
      expect(resource.player).to eq(user)
    end

    it "can have no player" do
      resource = create(:resource, player: nil)
      expect(resource.player).to be_nil
    end
  end
end
```

- [ ] **Step 6: Run to confirm failure**

Run: `bundle exec rspec spec/models/resource_spec.rb --format documentation`

Expected: 3 failures — factory not set up, no name validation

- [ ] **Step 7: Add name validation to Resource**

In `app/models/resource.rb`:

```ruby
class Resource < ApplicationRecord
  belongs_to :resource_template
  belongs_to :game
  belongs_to :player, class_name: "User", optional: true

  validates :name, presence: true
end
```

- [ ] **Step 8: Build out the Resource factory**

In `spec/factories/resources.rb`:

```ruby
FactoryBot.define do
  factory :resource do
    name { Faker::Games::DnD.item }
    data { {} }
    association :resource_template
    association :game
  end
end
```

- [ ] **Step 9: Run to confirm pass**

Run: `bundle exec rspec spec/models/resource_spec.rb --format documentation`

Expected: 5 passing (1 name validation + 4 associations)

- [ ] **Step 10: Commit**

```bash
git add app/models/ spec/models/ spec/factories/
git commit -m "feat: add creatable_by validation and resource model specs"
```

---

### Task 3: Routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Verify current routes**

Run: `rails routes`

Expected: current routes listing games and resource_templates

- [ ] **Step 2: Add resource routes**

Inside `namespace :api` block:

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

- [ ] **Step 3: Verify new routes**

Run: `rails routes`

Expected output includes:
```
POST   /api/games/:game_id/resource_templates/:resource_template_id/resources
GET    /api/games/:game_id/resources
GET    /api/games/:game_id/resources/:id
PATCH  /api/games/:game_id/resources/:id
DELETE /api/games/:game_id/resources/:id
```

- [ ] **Step 4: Commit**

```bash
git add config/routes.rb
git commit -m "feat: add resource routes"
```

---

### Task 4: ResourceFromTemplateBuilder service

**Files:**
- Create: `app/services/resource_from_template_builder.rb`
- Create: `spec/services/resource_from_template_builder_spec.rb`

- [ ] **Step 1: Write the failing service specs**

Create `spec/services/resource_from_template_builder_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe ResourceFromTemplateBuilder do
  let(:game) { create(:game) }
  let(:gm) { game.gm }
  let(:player) { create(:user) }
  let!(:membership) { create(:game_membership, user: player, game: game, role: :player) }
  let(:template) do
    create(:resource_template, :creatable_by_all, game: game, schema: {
      "fields" => [
        { "field_key" => "strength", "input_type" => "number" },
        { "field_key" => "alignment", "input_type" => "text" }
      ]
    })
  end

  describe ".call" do
    it "pre-populates data with nil defaults for each schema field" do
      result = described_class.call(template: template, current_user: gm, params: {})
      expect(result.resource.data).to eq({ "strength" => nil, "alignment" => nil })
    end

    it "merges client-provided data over the defaults" do
      result = described_class.call(
        template: template, current_user: gm,
        params: { data: { "strength" => 18 } }
      )
      expect(result.resource.data).to eq({ "strength" => 18, "alignment" => nil })
    end

    it "sets player_id to the current_user by default" do
      result = described_class.call(template: template, current_user: player, params: {})
      expect(result.resource.player_id).to eq(player.id)
    end

    it "allows GM to override player_id" do
      other_user = create(:user)
      result = described_class.call(
        template: template, current_user: gm,
        params: { player_id: other_user.id }
      )
      expect(result.resource.player_id).to eq(other_user.id)
    end

    it "sets name from params" do
      result = described_class.call(
        template: template, current_user: gm,
        params: { name: "Sir Galahad" }
      )
      expect(result.resource.name).to eq("Sir Galahad")
    end

    it "associates resource with template and game" do
      result = described_class.call(
        template: template, current_user: gm,
        params: { name: "Test" }
      )
      expect(result.resource.resource_template).to eq(template)
      expect(result.resource.game).to eq(game)
    end

    context "when creatable_by is 'gm'" do
      let(:gm_template) do
        create(:resource_template, game: game, creatable_by: "gm", schema: { "fields" => [] })
      end

      it "allows GM to create" do
        result = described_class.call(template: gm_template, current_user: gm, params: { name: "NPC" })
        expect(result.success?).to be true
      end

      it "rejects player with forbidden status" do
        result = described_class.call(template: gm_template, current_user: player, params: { name: "NPC" })
        expect(result.success?).to be false
        expect(result.status).to eq(:forbidden)
      end
    end
  end
end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/services/resource_from_template_builder_spec.rb --format documentation`

Expected: All fail — service class not defined

- [ ] **Step 3: Write the service implementation**

Create `app/services/resource_from_template_builder.rb`:

```ruby
class ResourceFromTemplateBuilder
  Result = Struct.new(:success?, :resource, :error, :status, keyword_init: true)

  def self.call(template:, current_user:, params: {})
    new(template, current_user, params).call
  end

  def initialize(template, current_user, params)
    @template = template
    @current_user = current_user
    @params = params
  end

  def call
    return forbidden_result unless creator_allowed?

    resource = @template.resources.new(
      game: @template.game,
      name: @params[:name],
      player_id: resolved_player_id,
      data: merged_data
    )

    Result.new(success?: true, resource: resource)
  end

  private

  def creator_allowed?
    return true if @template.creatable_by == "all"
    @template.game.gm?(@current_user)
  end

  def resolved_player_id
    return @params[:player_id] if @params[:player_id] && @template.game.gm?(@current_user)
    @current_user.id
  end

  def merged_data
    defaults = {}
    schema_fields = @template.schema&.dig("fields") || []
    schema_fields.each { |f| defaults[f["field_key"]] = nil }
    return defaults unless @params[:data].is_a?(Hash)
    defaults.merge(@params[:data])
  end

  def forbidden_result
    Result.new(success?: false, error: "Only a GM can create resources from this template", status: :forbidden)
  end
end
```

- [ ] **Step 4: Run to confirm pass**

Run: `bundle exec rspec spec/services/resource_from_template_builder_spec.rb --format documentation`

Expected: All passing (8 examples)

- [ ] **Step 5: Verify no existing tests broken**

Run: `bundle exec rspec`

Expected: All existing tests still pass

- [ ] **Step 6: Commit**

```bash
git add app/services/ spec/services/
git commit -m "feat: add ResourceFromTemplateBuilder service"
```

---

### Task 5: ResourcesController and request specs

**Files:**
- Create: `app/controllers/api/resources_controller.rb`
- Create: `spec/requests/api/resources_spec.rb`

- [ ] **Step 1: Write the failing request specs**

Create `spec/requests/api/resources_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe "Api::Resources", type: :request do
  let(:game) { create(:game) }
  let(:gm) { game.gm }
  let(:player) { create(:user) }
  let!(:membership) { create(:game_membership, user: player, game: game, role: :player) }
  let(:template) { create(:resource_template, :creatable_by_all, game: game, schema: { "fields" => [] }) }
  let(:gm_template) { create(:resource_template, game: game, creatable_by: "gm", schema: { "fields" => [] }) }

  describe "POST create" do
    let(:resource_params) { { name: "Aragorn", data: { "class" => "ranger" } } }

    context "when template allows all members" do
      it "allows GM to create" do
        post "/api/games/#{game.id}/resource_templates/#{template.id}/resources",
             params: { resource: resource_params }, headers: auth_headers(gm)
        expect(response).to have_http_status(:created)
        expect(json["name"]).to eq("Aragorn")
        expect(json["data"]["class"]).to eq("ranger")
        expect(json["player_id"]).to eq(gm.id)
      end

      it "allows player to create" do
        post "/api/games/#{game.id}/resource_templates/#{template.id}/resources",
             params: { resource: resource_params }, headers: auth_headers(player)
        expect(response).to have_http_status(:created)
        expect(json["player_id"]).to eq(player.id)
      end

      it "allows GM to override player_id" do
        other_user = create(:user)
        post "/api/games/#{game.id}/resource_templates/#{template.id}/resources",
             params: { resource: resource_params.merge(player_id: other_user.id) },
             headers: auth_headers(gm)
        expect(response).to have_http_status(:created)
        expect(json["player_id"]).to eq(other_user.id)
      end

      it "returns 422 with blank name" do
        post "/api/games/#{game.id}/resource_templates/#{template.id}/resources",
             params: { resource: { name: "" } }, headers: auth_headers(gm)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 401 without auth" do
        post "/api/games/#{game.id}/resource_templates/#{template.id}/resources",
             params: { resource: resource_params }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when template is GM-only" do
      it "allows GM to create" do
        post "/api/games/#{game.id}/resource_templates/#{gm_template.id}/resources",
             params: { resource: resource_params }, headers: auth_headers(gm)
        expect(response).to have_http_status(:created)
      end

      it "rejects player with 403" do
        post "/api/games/#{game.id}/resource_templates/#{gm_template.id}/resources",
             params: { resource: resource_params }, headers: auth_headers(player)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET index" do
    let!(:res1) { create(:resource, game: game, resource_template: template, name: "Res1") }
    let!(:res2) { create(:resource, game: game, resource_template: template, name: "Res2") }
    let!(:archived) { create(:resource, game: game, resource_template: template, archived_at: Time.current) }

    it "returns active resources for members" do
      get "/api/games/#{game.id}/resources", headers: auth_headers(player)
      expect(response).to have_http_status(:ok)
      names = json.map { |r| r["name"] }
      expect(names).to include("Res1", "Res2")
      expect(names).not_to include(archived.name)
    end

    it "returns 404 for non-member" do
      outsider = create(:user)
      get "/api/games/#{game.id}/resources", headers: auth_headers(outsider)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET show" do
    let!(:resource) { create(:resource, game: game, resource_template: template, name: "Excalibur") }

    it "returns resource for a member" do
      get "/api/games/#{game.id}/resources/#{resource.id}", headers: auth_headers(player)
      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("Excalibur")
    end

    it "returns 404 for non-member" do
      outsider = create(:user)
      get "/api/games/#{game.id}/resources/#{resource.id}", headers: auth_headers(outsider)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH update" do
    let!(:resource) { create(:resource, game: game, resource_template: template, player: player, name: "Old") }

    it "allows GM to update" do
      patch "/api/games/#{game.id}/resources/#{resource.id}",
            params: { resource: { name: "GM Upd" } }, headers: auth_headers(gm)
      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("GM Upd")
    end

    it "allows owning player to update" do
      patch "/api/games/#{game.id}/resources/#{resource.id}",
            params: { resource: { name: "Player Upd" } }, headers: auth_headers(player)
      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("Player Upd")
    end

    it "rejects non-owning player with 403" do
      other = create(:user)
      create(:game_membership, user: other, game: game, role: :player)
      patch "/api/games/#{game.id}/resources/#{resource.id}",
            params: { resource: { name: "Hack" } }, headers: auth_headers(other)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 with blank name" do
      patch "/api/games/#{game.id}/resources/#{resource.id}",
            params: { resource: { name: "" } }, headers: auth_headers(gm)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE destroy" do
    let!(:resource) { create(:resource, game: game, resource_template: template, player: player) }

    it "allows GM to archive" do
      delete "/api/games/#{game.id}/resources/#{resource.id}", headers: auth_headers(gm)
      expect(response).to have_http_status(:ok)
      expect(resource.reload.archived_at).to be_present
    end

    it "allows owning player to archive" do
      delete "/api/games/#{game.id}/resources/#{resource.id}", headers: auth_headers(player)
      expect(response).to have_http_status(:ok)
      expect(resource.reload.archived_at).to be_present
    end

    it "rejects non-owning player with 403" do
      other = create(:user)
      create(:game_membership, user: other, game: game, role: :player)
      delete "/api/games/#{game.id}/resources/#{resource.id}", headers: auth_headers(other)
      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for non-member" do
      outsider = create(:user)
      delete "/api/games/#{game.id}/resources/#{resource.id}", headers: auth_headers(outsider)
      expect(response).to have_http_status(:not_found)
    end
  end
end
```

- [ ] **Step 2: Run to confirm failure**

Run: `bundle exec rspec spec/requests/api/resources_spec.rb --format documentation`

Expected: All fail — controller not defined

- [ ] **Step 3: Write the controller**

Create `app/controllers/api/resources_controller.rb`:

```ruby
class Api::ResourcesController < ApplicationController
  include GameAuthenticatable
  before_action :authenticate_user!
  before_action :set_game
  before_action :set_resource, only: [:show, :update, :destroy]
  before_action :ensure_owner_or_gm!, only: [:update, :destroy]

  def index
    resources = @game.resources.active
    render json: resources, status: :ok
  end

  def show
    render json: @resource, status: :ok
  end

  def create
    template = @game.resource_templates.active.find(params[:resource_template_id])
    result = ResourceFromTemplateBuilder.call(
      template: template,
      current_user: current_user,
      params: resource_params
    )

    if result.success?
      if result.resource.save
        render json: result.resource, status: :created
      else
        render json: { errors: result.resource.errors.full_messages }, status: :unprocessable_content
      end
    else
      render json: { error: result.error }, status: result.status
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Template not found" }, status: :not_found
  end

  def update
    if @resource.update(resource_params)
      render json: @resource, status: :ok
    else
      render json: { errors: @resource.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    if @resource.update(archived_at: Time.current)
      render json: { message: "Resource archived successfully", archived_at: @resource.archived_at }, status: :ok
    else
      render json: { errors: ["Could not archive resource"] }, status: :unprocessable_content
    end
  end

  private

  def set_resource
    @resource = @game.resources.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Resource not found" }, status: :not_found
  end

  def ensure_owner_or_gm!
    unless @resource.player == current_user || @game.gm?(current_user)
      render json: { error: "Forbidden" }, status: :forbidden
    end
  end

  def resource_params
    params.require(:resource).permit(:name, :player_id, data: {})
  end
end
```

- [ ] **Step 4: Run to confirm pass**

Run: `bundle exec rspec spec/requests/api/resources_spec.rb --format documentation`

Expected: All passing

- [ ] **Step 5: Verify no existing tests broken**

Run: `bundle exec rspec`

Expected: All tests pass (original ~48 + ~20 new)

- [ ] **Step 6: Commit**

```bash
git add app/controllers/ spec/requests/
git commit -m "feat: add ResourcesController with template instantiation"
```

---

### Task 6: Update progress docs

**Files:**
- Modify: `PROGRESS.md`

- [ ] **Step 1: Update PROGRESS.md to 0.5.0-alpha**

Update the header, add Resource System to completed milestones, remove from remaining.

- [ ] **Step 2: Full test suite verification**

Run: `bundle exec rspec`

Expected: All tests passing

- [ ] **Step 3: Commit**

```bash
git add PROGRESS.md
git commit -m "chore: update progress to 0.5.0-alpha"
```
