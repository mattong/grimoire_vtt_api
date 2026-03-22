require 'rails_helper'

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires a username" do
      user = User.new(username: nil)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include("can't be blank")
    end

    it("requires a password") do
      user = User.new(password: nil)

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it("requires a password to be at least 6 characters long") do
      user = User.new(password: "short")

      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("is too short (minimum is 6 characters)")
    end
  end

  describe "uniqueness" do
    it "requires a username to be unique" do
      existing_user = create(:user, username: "iexist@existing.com")
      duplicated_user = build(:user, username: existing_user.username)

      expect(duplicated_user).not_to be_valid
      expect(duplicated_user.errors[:username]).to include("has already been taken")
    end
  end
end
