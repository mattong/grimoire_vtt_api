FactoryBot.define do
  factory :resource_template do
    name { Faker::Books::CultureSeries.unique.book }
    template_type { "character" }
    schema {
      {
        "fields" => [
          { "field_key" => "hp", "label" => "HP", "input_type" => "number" },
          { "field_key" => "name", "label" => "Name", "input_type" => "text" }
        ]
      }
    }
  end
end
