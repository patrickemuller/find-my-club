require 'rails_helper'

RSpec.describe "Header Navigation", type: :system do
  let(:user) { create(:user, password: 'password123') }

  before do
    driven_by(:rack_test)
  end

  describe "when user is signed in" do
    before do
      visit new_user_session_path
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'password123'
      click_button 'Log in'
    end

    it "displays the user dropdown menu on desktop" do
      visit root_path

      expect(page).to have_content(user.first_name)
      expect(page).to have_css('div[data-controller="dropdown"]')
    end

    it "includes Profile link in mobile menu" do
      visit root_path

      within('[data-mobile-menu-target="menu"]') do
        expect(page).to have_link("Profile", href: user_path(user))
      end
    end

    it "includes Account link in mobile menu" do
      visit root_path

      within('[data-mobile-menu-target="menu"]') do
        expect(page).to have_link("Account", href: edit_user_registration_path)
      end
    end

    it "includes Sign out button in mobile menu" do
      visit root_path

      within('[data-mobile-menu-target="menu"]') do
        expect(page).to have_button("Sign out")
      end
    end
  end

  describe "when user is not signed in" do
    it "displays Log in and Sign up links" do
      visit root_path

      expect(page).to have_link("Log in", href: new_user_session_path)
      expect(page).to have_link("Sign up", href: new_user_registration_path)
    end

    it "does not display user dropdown" do
      visit root_path

      expect(page).not_to have_css('div[data-controller="dropdown"]')
    end
  end
end
