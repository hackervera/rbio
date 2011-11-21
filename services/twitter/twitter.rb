require 'redis'
require 'json'
require 'oauth'
require 'yaml'
require_relative '../../lib/bus'
bus = Bus.new
redis = Redis.new


config = YAML.load_file File.dirname(__FILE__) + "/twitter.yaml"
CLIENT = config["client"]
SECRET = config["secret"]
HOST = config["host"]

TOKEN = config["token"]
TOKENSECRET = config["token_secret"]

require 'sinatra/base'
class TwitterAuth < Sinatra::Base
  enable :sessions
  consumer = OAuth::Consumer.new CLIENT, SECRET, :site => "http://api.twitter.com"

  get "/" do

    request_token = consumer.get_request_token(:oauth_callback => "#{HOST}/store_access")
    session[:request_token] = request_token

    redirect request_token.authorize_url
  end

  redis = Redis.new
  bus = Bus.new
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


consumer = OAuth::Consumer.new(CLIENT, SECRET, :site => "http://api.twitter.com")
bot_access_token = OAuth::AccessToken.from_hash(consumer, :oauth_token => TOKEN, :oauth_token_secret => TOKENSECRET)


bus.on "rbio::twitter::send_auth_url" do |bus_data|
  request_token = consumer.get_request_token(:oauth_callback => "#{HOST}/store_access?user=#{bus_data["user"]}")
  redis.set "request_token:#{bus_data["user"]}", Marshal.dump(request_token)
  bus.send "rbio::irc::send_msg_user", :user => bus_data["current_user"], :message => request_token.authorize_url
end


bus.on "rbio::twitter::check_dms" do |bus_data|
  dm_response = bot_access_token.get("http://api.twitter.com/1/direct_messages.json")
  dms_json = JSON.parse dm_response.body
  dms_json.each do |message|
    id = redis.get "dm_id:#{message["id_str"]}"
    if id.nil?
      bus.send "rbio::irc::send_msg_user", :user => "tjgillies_", :message => "#{message["sender_screen_name"]} says #{message["text"]}"
    end
    redis.set "dm_id:#{message["id_str"]}", 1
  end
  ""
end


bus.on "rbio::twitter::timeline" do |bus_data|
  access_token = Marshal.load(redis.get "access_token:#{bus_data["user"]}")
  client = TweetStream::Client.new
  client.oauth_token = access_token.token
  client.oauth_token_secret = access_token.secret
  client.on_timeline_status do |status|
    puts status.text
    message =  "#{status.user.screen_name}: #{status.text}"
    bus.send "rbio::irc::send_msg_user", :user => bus_data["current_user"], :message =>  message
  end
  client.userstream
  ""
end

require 'yajl'
require 'tweetstream'

TweetStream.configure do |config|
  config.consumer_key = CLIENT
  config.consumer_secret = SECRET
  config.auth_method = :oauth
  config.parser = :yajl
end

client = TweetStream::Client.new
client.oauth_token = TOKEN
client.oauth_token_secret = TOKENSECRET

client.on_error do |message|
  puts message
end

client.on_direct_message do |direct_message|
  puts direct_message.text
  bus.send "rbio::irc::send_msg_chan", :channel => "#pdxwebdev", :message => "DM from @#{direct_message.sender_screen_name} (#{direct_message.sender.followers_count} followers): #{direct_message.text}"
end

#client.on_timeline_status do |status|
#  puts status.text
#end

Thread.new do
  client.userstream
end


puts "foo"


