require './bus'
require 'uuid'
require 'typhoeus'

bus = Bus.new
uuid = UUID.new
redis = Redis.new

bus.on "rbio::irc::got_priv_msg" do |bus_data|
  if bus_data["message"] =~ /verify me/
    bus.send "rbio::geoloqi::send_auth_url", :user => bus_data["user"]


  end


  if bus_data["message"] =~ /^friends/
    bus.send "rbio::geoloqi::send_friends", :user => bus_data["user"]

  end

  if bus_data["message"]=~ /geonote (.*?)@(.*?) (.*)/
    user = $1
    place = $2
    message = $3
    bus.send "rbio::geoloqi::send_geonote", :place => place, :user => user, :message => message
    bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => "Sending geonote to #{user}"
  end

end

