require 'oauth'
class TwitterAuth < Sinatra::Base
  config = YAML.load_file File.dirname(__FILE__) + "/twitter.yaml"


  TOKEN = config["token"]
  TOKENSECRET = config["token_secret"]
  enable :sessions
  consumer = OAuth::Consumer.new config["client"], config["secret"], :site => "http://api.twitter.com"

  get "/" do

    request_token = consumer.get_request_token(:oauth_callback => "#{config["host"]}/store_access")
    session[:request_token] = request_token

    redirect request_token.authorize_url
  end

  redis = Redis.new
  get "/auth" do

    this_user = redis.get "uuid:#{request.params["state"]}"
    code = request.params["code"]
    token_response = Typhoeus::Request.post("#{token_url}", :params => {:grant_type => "authorization_code", :code => code, :redirect_uri => token_redirect, :client_id => CLIENT, :client_secret => SECRET})
    json_token = JSON.parse token_response.body

    redis.set "auth:#{this_user}", token_response.body
    access_token = json_token["access_token"]
    refresh_token = json_token["refresh_token"]
    group_response = Typhoeus::Request.post("http://api.geoloqi.com/1/group/join/hH8rzSh_i?oauth_token=#{access_token}")
    bus.send "rbio::irc::send_msg_user", :user => this_user, :message => access_token
    redis.set "token:#{this_user}", access_token
    redis.set "refresh:#{this_user}", refresh_token
    "Auth step over, you can close this tab"
  end


  get "/store_access" do
    user = request.params["user"]
    request_token = Marshal.load(redis.get("request_token:#{user}"))
    access_token = request_token.get_access_token
    redis.set "access_token:#{user}", Marshal.dump(access_token)
    "Access token set, you may close tab"
  end

end


Thread.new do
  TwitterAuth.run! :port => 4568
end