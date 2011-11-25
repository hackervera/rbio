class LoqiAuth < Sinatra::Base
  config = YAML.load_file File.dirname(__FILE__) + "/geoloqi.yaml"
  host = config["host"]
  client = config["client"]
  secret = config["secret"]

  redis = Redis.new
  uuid = UUID.new
  token_redirect = "#{host}/auth"


  get "/auth" do

    nick = redis.get "nick:#{request.params["state"]}"
    code = request.params["code"]
    token_response = Typhoeus::Request.post("https://api.geoloqi.com/1/oauth/token", :params => {:grant_type => "authorization_code", :code => code, :redirect_uri => token_redirect, :client_id => client, :client_secret => secret})
      json_token = JSON.parse token_response.body

    #session = Geoloqi::Session.new :auth => json_token

    redis.set "session:#{nick}", token_response.body

    access_token = json_token["access_token"]
    Typhoeus::Request.post("http://api.geoloqi.com/1/group/join/hH8rzSh_i?oauth_token=#{access_token}")
    "Auth step over, you can close this tab"
  end

end


Thread.new do
  LoqiAuth.run!
end