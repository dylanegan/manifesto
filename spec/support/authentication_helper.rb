# Use with integration tests on the full stack
def login_with_google_apps
  mock_google_apps_auth
  visit "/auth/google_apps"
end

def mock_google_apps_auth
  OmniAuth.config.mock_auth[:google_apps] = user_attributes
end

def request_env
  @request_env ||= {
    'rack.session' => {}
  }
end

# Use with controller tests to fake the auth
def stub_google_apps_auth
  user = user_attributes['info']
  email = user['email'].is_a?(Array) ? user['email'].first : user['email']
  request_env['rack.session']['user'] = {
    'identity_url' => user_attributes['uid'],
    'email' => email,
    'first_name' => user['first_name'],
    'last_name' => user['last_name']
  }
  request_env["omniauth.auth"] = user_attributes
end

def user_attributes
  {
    "provider" => "google_apps",
    "uid" => "http://example.com/openid?id=1234567890",
    "info" => {
      "email" => "nika@example.com",
      "first_name" => "Nika",
      "last_name" => "the Dog",
      "name" => "Nika the Dog"
    }
  }
end
