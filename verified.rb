require './bus'
require 'uuid'
require 'typhoeus'

bus = Bus.new
uuid = UUID.new
redis = Redis.new

bus.add "rbio::irc::got_priv_msg" do |bus_data|
  if bus_data["message"] =~ /verify me/
    bus.send "rbio::geoloqi::send_auth_url", :user => bus_data["user"]


  end


  if bus_data["message"] =~ /^friends/
    bus.send "rbio::geoloqi::send_friends", :user => bus_data["user"]

  end

end

