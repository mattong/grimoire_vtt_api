module AuthHelpers
  def auth_headers(user)
    Devise::JWT::TestHelpers.auth_headers({}, user)
  end
end
