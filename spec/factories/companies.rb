FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Test Company #{n}" }
    sequence(:fluid_shop) { |n| "shop_#{n}" }
    sequence(:fluid_company_id) { |n| "fc_#{n}" }
    sequence(:authentication_token) { |n| "auth_#{SecureRandom.hex(8)}_#{n}" }
    sequence(:company_droplet_uuid) { |n| "cdr_#{SecureRandom.hex(16)}_#{n}" }
    active { true }

    trait :with_sovos_settings do
      settings do
        {
          "username" => "test_user",
          "password" => "test_pass",
          "hmac_key" => "test_key",
        }
      end
    end

    trait :without_settings do
      settings { nil }
    end

    trait :with_empty_settings do
      settings { {} }
    end
  end
end
