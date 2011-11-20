require './bus'
require 'uuid'
require 'redis'
require 'sinatra/base'
require 'typhoeus'
HOST = ENV["LOQIHOST"]

uuid = UUID.new
redis = Redis.new
bus = Bus.new
client_id, client_secret = ENV["LOQICLIENT"].split ":"
bus = Bus.new
token_redirect = "#{HOST}/token"
token_url = "https://api.geoloqi.com/1/oauth/token"
client_id, client_secret = ENV["LOQICLIENT"].split ":"

authorize_url = "https://geoloqi.com/oauth/authorize"

auth_redirect = "#{HOST}/auth"


class LoqiAuth < Sinatra::Base
  redis = Redis.new
  bus = Bus.new
  token_redirect = "#{HOST}/token"
  token_url = "https://api.geoloqi.com/1/oauth/token"
  client_id, client_secret = ENV["LOQICLIENT"].split ":"
  auth_redirect = "#{HOST}/auth"
  get "/auth" do

    this_user = redis.get "uuid:#{request.params["state"]}"
    code = request.params["code"]
    token_response = Typhoeus::Request.post("#{token_url}", :params => {:grant_type => "authorization_code", :code => code, :redirect_uri => token_redirect, :client_id => client_id, :client_secret => client_secret})
    json_token = JSON.parse token_response.body
    access_token = json_token["access_token"]
    refresh_token = json_token["refresh_token"]
    group_response = Typhoeus::Request.post("http://api.geoloqi.com/1/group/join/hH8rzSh_i?oauth_token=#{access_token}")
    bus.send "rbio::irc::send_msg_user", :user => this_user, :message => access_token
    redis.set "token:#{this_user}", access_token
    redis.set "refresh:#{this_user}", refresh_token
    "Auth step over, you can close this tab"
  end

end


Thread.new do
  LoqiAuth.run!
end

puts "FOOOO"


bus.add "rbio::geoloqi::send_auth_url" do |bus_data|
  this_uuid = uuid.generate
  redis.set "uuid:#{this_uuid}", bus_data["user"]
  auth_url = "#{authorize_url}?response_type=code&client_id=#{client_id}&redirect_uri=#{auth_redirect}&state=#{this_uuid}"

  bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => auth_url
end

bus.add "rbio::geoloqi::send_friends" do |bus_data|

  access_token = redis.get "token:#{bus_data["user"]}"
  group_location = Typhoeus::Request.get("http://api.geoloqi.com/1/group/last/hH8rzSh_i?oauth_token=#{access_token}")

  peeps = JSON.parse(group_location.body)["locations"].map do |location|

    "#{location["username"]} was last seen http://google.com/maps?z=15&q=#{location["location"]["position"]["latitude"]},#{location["location"]["position"]["longitude"]}"
  end

  bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => peeps.join("\n")
end

