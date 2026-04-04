FactoryBot.define do
  factory :resource do
    resource_template
    game
    name { "MyString" }
    data { {} }
    player
  end
end
