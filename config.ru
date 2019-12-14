require 'dotenv'
Dotenv.load

require 'dashing'

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  helpers do
    def protected!
     # Put any authentication code you want in here.
     # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

if ENV['TEAMCITY_BASE_URL'] != nil then
  require 'teamcity'
  TeamCity.configure do |config|
    config.endpoint = ENV['TEAMCITY_BASE_URL'] + '/app/rest'
    if ENV['TEAMCITY_USER'] != nil then
      config.http_user = ENV['TEAMCITY_USER']
      config.http_password = ENV['TEAMCITY_TOKEN']
    end
  end
end

run Sinatra::Application
