FactoryBot.define do
  factory :resource do
    template { nil }
    game { nil }
    name { "MyString" }
    data { "" }
    player { nil }
  end
end
