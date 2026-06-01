FactoryBot.define do
  factory :resource do
    association :player, factory: :user
    resource_template
    game
    name { "MyString" }
    data { {} }

    after(:build) do |resource|
      if resource.resource_template.game != resource.game
        resource.resource_template.game = resource.game
      end
    end
  end
end
