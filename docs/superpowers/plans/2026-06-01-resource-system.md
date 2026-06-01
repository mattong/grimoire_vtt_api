# Resource System Implementation Plan

**Date:** 2026-06-01
**Target Version:** 0.5.0-alpha

## Tasks

### Task 1: Migration — Add `creatable_by` to ResourceTemplate
- Generate migration: `AddCreatableByToResourceTemplates`
- Add string column `creatable_by` with default `"gm"`, not null
- Run migration
- Update schema.rb

### Task 2: Model Changes
- **ResourceTemplate**: Add `validates :creatable_by, inclusion: { in: %w[gm all] }`
- **Resource**: Add `scope :active, -> { where(archived_at: nil) }`, validate name presence, association specs

### Task 3: Routes
- Add nested resources routes under games for index/show/update/destroy
- Add nested resources routes under resource_templates for create only

### Task 4: Builder Service
- Create `app/services/resource_from_template_builder.rb` with:
  - Permission check (creatable_by + gm check)
  - Data defaults from template schema fields
  - Player assignment (defaults to current_user, GM override)
  - Returns Result struct with success?/resource/error/status

### Task 5: Controller + Request Specs
- Create `app/controllers/api/resources_controller.rb`
- Create `spec/requests/api/resources_spec.rb` (~20 specs)
- Create `spec/services/resource_from_template_builder_spec.rb` (~5 specs)
- Update `spec/models/resource_spec.rb` with validation specs

### Task 6: Progress Update
- Update PROGRESS.md to 0.5.0-alpha
