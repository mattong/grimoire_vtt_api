FactoryBot.define do
  factory :game_membership do
    association :user
    association :game
    role { "player" }

    trait :gm do
      role { "gm" }
    end
  end
end
