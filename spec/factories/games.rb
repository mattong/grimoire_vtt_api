FactoryBot.define do
  factory :game do
    title { Faker::Books::CultureSeries.book }
    description { Faker::Lorem.paragraph }

    system { "5e" }

    trait :archived do
      archived_at { "2026-03-11 20:21:45" }
    end
  end
end
