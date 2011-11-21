require_relative '../../lib/bus'
require 'uuid'
require 'redis'
require 'sinatra/base'
require 'typhoeus'
require 'geoloqi'
require 'yaml'

config = YAML.load_file File.dirname(__FILE__) + "/geoloqi.yaml"

HOST = config["host"]
CLIENT = config["client"]
SECRET = config["secret"]

class LoqiAuth < Sinatra::Base

  token_redirect = "#{HOST}/token"
  token_url = "https://api.geoloqi.com/1/oauth/token"
  redis = Redis.new
  bus = Bus.new
  configure do
    Geoloqi.config :client_id => CLIENT, :client_secret => SECRET
  end
  get "/auth" do

    this_user = redis.get "uuid:#{request.params["state"]}"
    code = request.params["code"]
    token_response = Typhoeus::Request.post("#{token_url}", :params => {:grant_type => "authorization_code", :code => code, :redirect_uri => token_redirect, :client_id => CLIENT, :client_secret => SECRET})
    json_token = JSON.parse token_response.body

    redis.set "auth:#{this_user}", token_response.body
    access_token = json_token["access_token"]
    refresh_token = json_token["refresh_token"]
    group_response = Typhoeus::Request.post("http://api.geoloqi.com/1/group/join/hH8rzSh_i?oauth_token=#{access_token}")
    redis.set "token:#{this_user}", access_token
    redis.set "refresh:#{this_user}", refresh_token
    "Auth step over, you can close this tab"
  end

end


Thread.new do
  LoqiAuth.run!
end


bus = Bus.new
authorize_url = "https://geoloqi.com/oauth/authorize"
auth_redirect = "#{HOST}/auth"
uuid = UUID.new
redis = Redis.new

bus.on "rbio::geoloqi::send_auth_url" do |bus_data|
  this_uuid = uuid.generate
  redis.set "uuid:#{this_uuid}", bus_data["user"]
  auth_url = "#{authorize_url}?response_type=code&client_id=#{CLIENT}&redirect_uri=#{auth_redirect}&state=#{this_uuid}"

  bus.send "rbio::irc::send_msg_user", :user => bus_data["current_user"], :message => auth_url
end

bus.on "rbio::geoloqi::send_friends" do |bus_data|
  auth = redis.get "auth:#{bus_data["user"]}"
  session = Geoloqi::Session.new :auth =>JSON.parse(auth)

  #access_token = redis.get "token:#{bus_data["user"]}"
  group_response = session.get "/group/last/hH8rzSh_i"

  peeps = group_response["locations"].map do |location|

    "#{location["username"]} was last seen http://google.com/maps?z=15&q=#{location["location"]["position"]["latitude"]},#{location["location"]["position"]["longitude"]}"
  end

  bus.send "rbio::irc::send_msg_user", :user => bus_data["current_user"], :message => peeps.join("\n")

  redis.set "auth:#{bus_data["user"]}", session.auth.to_json

end


bus.on "rbio::geoloqi::send_geonote" do |bus_data|
  auth = redis.get "auth:#{bus_data["note_user"]}"
  begin
    session = Geoloqi::Session.new :auth =>JSON.parse(auth)
  rescue
    bus.send "rbio::irc::send_msg_user", :user => bus_data["current_user"], :message => "Sorry, but we can't find auth token for #{bus_data["note_user"]}"
    next
  end

  places = {}
  session.get("/place/list")["places"].each { |place| places[place["name"]] = place["place_id"] }
  session = Geoloqi::Session.new :auth =>JSON.parse(auth)
  place = bus_data["place"]
  geonote_response = session.post "/geonote/create", :text => bus_data["message"], :place_id => places[place]
  bus.send "rbio::irc::send_msg_user", :user => bus_data["current_user"], :message => "Sending geonote to #{bus_data["note_user"]}"
  redis.set "auth:#{bus_data["user"]}", session.auth.to_json
end

