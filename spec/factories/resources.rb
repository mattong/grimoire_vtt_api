FactoryBot.define do
  factory :resource do
    association :player, factory: :user
    resource_template
    game
    name { "MyString" }
    data { {} }
  end
end
