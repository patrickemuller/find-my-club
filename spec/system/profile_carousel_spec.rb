require 'rails_helper'

RSpec.describe "Profile Clubs Carousel", type: :system, js: true do
  let(:user) { create(:user, password: 'password123') }

  before do
    driven_by(:selenium_chrome_headless)
  end

  context "when user has more than 5 clubs" do
    before do
      # Create 12 public clubs and make user a member
      12.times do |i|
        club = create(:club, public: true, name: "Club #{i + 1}")
        create(:membership, user: user, club: club, status: :active)
      end
    end

    it "displays carousel navigation with 5 clubs per page" do
      visit user_path(user)

      within('.rounded-2xl', text: 'Clubs') do
        # First page should show clubs 1-5
        expect(page).to have_content('Club 1')
        expect(page).to have_content('Club 5')
        expect(page).not_to have_content('Club 6')

        # Navigate to next page
        click_button 'Next'

        # Second page should show clubs 6-10
        expect(page).to have_content('Club 6')
        expect(page).to have_content('Club 10')
        expect(page).not_to have_content('Club 5')
        expect(page).not_to have_content('Club 11')

        # Navigate to third page
        click_button 'Next'

        # Third page should show clubs 11-12
        expect(page).to have_content('Club 11')
        expect(page).to have_content('Club 12')
        expect(page).not_to have_content('Club 10')

        # Navigate back to previous page
        click_button 'Previous'

        # Should be back on second page
        expect(page).to have_content('Club 6')
        expect(page).to have_content('Club 10')
        expect(page).not_to have_content('Club 11')
      end
    end

    it "disables Previous button on first page" do
      visit user_path(user)

      within('.rounded-2xl', text: 'Clubs') do
        prev_button = find_button('Previous', disabled: :all)
        expect(prev_button[:disabled]).to eq('true')
        expect(prev_button[:class]).to include('opacity-50')
      end
    end

    it "disables Next button on last page" do
      visit user_path(user)

      within('.rounded-2xl', text: 'Clubs') do
        # Navigate to last page
        click_button 'Next'
        click_button 'Next'

        next_button = find_button('Next', disabled: :all)
        expect(next_button[:disabled]).to eq('true')
        expect(next_button[:class]).to include('opacity-50')
      end
    end
  end

  context "when user has 5 or fewer clubs" do
    before do
      # Create 3 public clubs
      3.times do |i|
        club = create(:club, public: true, name: "Club #{i + 1}")
        create(:membership, user: user, club: club, status: :active)
      end
    end

    it "does not display carousel navigation" do
      visit user_path(user)

      within('.rounded-2xl', text: 'Clubs') do
        expect(page).to have_content('Club 1')
        expect(page).to have_content('Club 2')
        expect(page).to have_content('Club 3')

        expect(page).not_to have_button('Next')
        expect(page).not_to have_button('Previous')
      end
    end
  end
end
