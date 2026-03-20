require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires an email" do
    user = User.new(email: nil)

    expect(user).not_to be_valid
    expect(user.errors[:email]).to include("can't be blank")
    end

    it "requires a username" do
      user =    User.new(username: nil)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    it("requires a password") do
      user = User.new(password: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end
  end

  describe "uniqueness" do
    it "requires an email to be unique" do
      existing_user = create(:user, email: "iexist@existing.com")
      duplicated_user = User.new(email: existing_user.email)

      expect(duplicated_user).not_to be_valid
      expect(duplicated_user.errors[:email]).to include("has already been taken")
    end
  end
end
