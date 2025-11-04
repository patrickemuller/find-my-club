require 'rails_helper'

RSpec.describe "Header Navigation", type: :system do
  let(:user) { create(:user) }

  describe "when user is signed in" do
    before do
      login_as user
    end

    describe "and window is desktop zie" do
      it "displays the user dropdown menu on desktop" do
        visit root_path

        expect(page).to have_content(user.first_name)
        expect(page).to have_css('div[data-controller="dropdown"]')
      end
    end

    describe "and window is mobile size" do
      before do
        visit root_path
        page.current_window.resize_to(375, 667)
        find('button[aria-label="Toggle menu"]').click
      end

      it "includes Profile link in mobile menu" do
        within('[data-mobile-menu-target="menu"]') do
          expect(page).to have_link("Profile", href: user_path(user))
        end
      end

      it "includes Account link in mobile menu" do
        within('[data-mobile-menu-target="menu"]') do
          expect(page).to have_link("Account", href: edit_user_registration_path)
        end
      end

      it "includes Sign out button in mobile menu" do
        within('[data-mobile-menu-target="menu"]') do
          expect(page).to have_button("Sign out")
        end
      end
    end
  end

  describe "when user is not signed in" do
    before { visit root_path }

    it "displays Log in and Sign up links" do
      expect(page).to have_link("Log in", href: new_user_session_path, visible: :all)
      expect(page).to have_link("Sign up", href: new_user_registration_path, visible: :all)
    end

    it "does not display user dropdown" do
      expect(page).not_to have_css('div[data-controller="dropdown"]')
    end
  end
end
