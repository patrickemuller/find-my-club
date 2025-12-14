require 'rails_helper'

RSpec.describe "User Registrations", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end

  describe "sign up" do
    it "user can sign up with valid phone number" do
      visit new_user_registration_path

      fill_in "First name", with: "John"
      fill_in "Last name", with: "Doe"
      fill_in "Email", with: "john.doe@example.com"
      select "United States (+1)", from: "Country"
      fill_in "Phone Number", with: "4155551234"
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"

      click_button "Sign up"

      user = User.find_by(email: "john.doe@example.com")
      expect(user).to be_present
      expect(user.phone_number).to be_present
      expect(user.country_code).to eq("us")
    end

    it "user cannot sign up with invalid phone number" do
      visit new_user_registration_path

      fill_in "First name", with: "Jane"
      fill_in "Last name", with: "Smith"
      fill_in "Email", with: "jane.smith@example.com"
      select "United States (+1)", from: "Country"
      fill_in "Phone Number", with: "123" # Invalid phone number
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"

      click_button "Sign up"

      expect(page).to have_content("Phone number is invalid for selected country")
      expect(User.find_by(email: "jane.smith@example.com")).to be_nil
    end

    it "user cannot sign up without phone number" do
      visit new_user_registration_path

      fill_in "First name", with: "Bob"
      fill_in "Last name", with: "Johnson"
      fill_in "Email", with: "bob.johnson@example.com"
      select "Canada (+1)", from: "Country"
      # Don't fill in phone number
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"

      click_button "Sign up"

      expect(page).to have_content("Phone number can't be blank")
      expect(User.find_by(email: "bob.johnson@example.com")).to be_nil
    end
  end

  describe "edit account" do
    let(:user) { create(:user, phone_number: '+14155551234', country_code: 'us') }

    before do
      sign_in user
    end

    it "user can update phone number" do
      visit edit_user_registration_path

      select "Canada (+1)", from: "Country"
      fill_in "Phone Number", with: "4165551234"
      fill_in "Current password", with: "password"

      click_button "Update"

      expect(page).to have_content("Your account has been updated successfully")
      user.reload
      expect(user.country_code).to eq("ca")
      expect(user.phone_number).to be_present
    end

    it "user can upload avatar" do
      visit edit_user_registration_path

      attach_file "Avatar", Rails.root.join('app', 'assets', 'images', 'avatar-example.png')
      fill_in "Current password", with: "password"

      click_button "Update"

      expect(page).to have_content("Your account has been updated successfully")
      user.reload
      expect(user.avatar).to be_attached
    end
  end
end
