require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  def setup
    set_net_stubs
  end
  
  test 'correct secret link is generated' do
    assert_equal 'is_a_valid_secret', users(:has_secret_not_active).secret_link.secret
  end

  describe 'greeting helper' do
    it 'returns name if it exists' do
      assert_equal 'Bob Bobola', users(:user_with_name).displayable_greeting
    end
    
    it 'returns email if phone doesn\'t exist' do
      assert_equal 'just_a_user1@valid.com'[0..20] + '...', users(:user_1).displayable_greeting
    end

    it "doesn't add ellipse when not necessary" do
      assert_equal users(:short_email).email, users(:short_email).displayable_greeting
    end
    
    it 'returns phone if it exists' do
      u = users(:user_2)
      assert_equal u.phone_number, u.displayable_greeting
    end
  end

  test 'new user gets a secret link' do
    assert_difference('SecretLink.count', 1) do
      User.new(email: 'email@email.com', password: 'admin123', phone_number: '2125556666').save!
    end
  end
end
