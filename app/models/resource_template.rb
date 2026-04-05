class ResourceTemplate < ApplicationRecord
  belongs_to :game

  has_many :resources, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :game_id }
  validates :template_type, inclusion: { in: %w[character item status npc custom] }

  validate :validate_schema_structure

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  private

  def validate_schema_structure
    if schema.blank?
      errors.add(:schema, "must be a JSON object with a 'fields' array")
      return
    end

    # Schema should be an object with "fields" key that is an array
    unless schema.is_a?(Hash) && schema["fields"].is_a?(Array)
      errors.add(:schema, "must be a JSON object with a 'fields' array")
      return
    end

    schema["fields"].each_with_index do |field, index|
      unless field.is_a?(Hash)
        errors.add(:schema, "field at index #{index} must be a JSON object")
        next
      end

      if field["field_key"].blank?
        errors.add(:schema, "field at index #{index} is missing 'field_key'")
      end

      if field["input_type"].blank?
        errors.add(:schema, "field at index #{index} is missing 'input_type'")
      end
    end

    # Ensure field_keys are unique within the template
    field_keys = schema["fields"].select { |f| f.is_a?(Hash) }.map { |f| f["field_key"] }
    if field_keys.uniq.length != field_keys.length
      errors.add(:schema, "field_keys must be unique within the template")
    end
  end
end
