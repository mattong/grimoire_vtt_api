require 'rails_helper'

RSpec.describe ResourceTemplate, type: :model do
  let(:game) { create(:game) }
  let(:valid_schema) do
    {
      "fields" => [
        { "field_key" => "hp", "label" => "HP", "input_type" => "number" },
        { "field_key" => "name", "label" => "Name", "input_type" => "text" }
      ]
    }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      template = ResourceTemplate.new(game: game, name: "Character", template_type: "character", schema: valid_schema)
      expect(template).to be_valid
    end

    it "is invalid without a name" do
      template = ResourceTemplate.new(game: game, template_type: "character", schema: valid_schema)
      expect(template).not_to be_valid
      expect(template.errors[:name]).to include("can't be blank")
    end

    it "is invalid with a duplicate name within the same game" do
      ResourceTemplate.create!(game: game, name: "Character", template_type: "character", schema: valid_schema)
      duplicate_template = ResourceTemplate.new(game: game, name: "Character", template_type: "character", schema: valid_schema)
      expect(duplicate_template).not_to be_valid
      expect(duplicate_template.errors[:name]).to include("has already been taken")
    end

    it "is invalid with an unsupported template_type" do
      template = ResourceTemplate.new(game: game, name: "Weird Template", template_type: "weird", schema: valid_schema)
      expect(template).not_to be_valid
      expect(template.errors[:template_type]).to include("is not included in the list")
    end

    it "is invalid if schema is not an object with a 'fields' array" do
      template = ResourceTemplate.new(game: game, name: "Bad Schema", template_type: "character", schema: { "not_fields" => [] })
      expect(template).not_to be_valid
      expect(template.errors[:schema]).to include("must be a JSON object with a 'fields' array")
    end

    it "is invalid if any field in the schema is missing 'field_key' or 'input_type'" do
      bad_schema = {
        "fields" => [
          { "label" => "HP", "input_type" => "number" },
          { "field_key" => "name", "label" => "Name" }
        ]
      }
      template = ResourceTemplate.new(game: game, name: "Bad Fields", template_type: "character", schema: bad_schema)
      expect(template).not_to be_valid
      expect(template.errors[:schema]).to include("field at index 0 is missing 'field_key'")
      expect(template.errors[:schema]).to include("field at index 1 is missing 'input_type'")
    end
  end
end
