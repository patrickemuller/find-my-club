require "test_helper"

class MembershipMailerTest < ActionMailer::TestCase
  test "approved" do
    membership = FactoryBot.create(:membership)
    mail = MembershipMailer.approved(membership)
    assert_equal "You've been approved to join #{membership.club.name}!", mail.subject
    assert_equal [ membership.user.email ], mail.to
    assert_equal [ "from@example.com" ], mail.from
    assert_match "Hi", mail.body.encoded
  end
end
