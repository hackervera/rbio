require_relative '../lib/bus'

require 'uuid'
require 'typhoeus'

bus = Bus.new
uuid = UUID.new
redis = Redis.new

bus.on "rbio::irc::got_priv_msg" do |bus_data|
  if bus_data["message"] =~ /verify (.*)/
    service = $1
    if service == "geoloqi"
      bus.send "rbio::irc::send_auth_url_geoloqi", :user => bus_data["user"]
    end

    if service == "twitter"
        bus.send "rbio::irc::send_auth_url_twitter", :user => bus_data["user"]
    end
  end


  if bus_data["message"] =~ /^friends/
    bus.send "rbio::irc::send_friends_geoloqi", :user => bus_data["user"]
  end

  if bus_data["message"]=~ /geonote (.*?)@(.*?) (.*)/
    user = $1
    place = $2
    message = $3
    place.gsub!("_", " ")

    bus.send "rbio::irc::send_geonote", :place => place, :note_user => user, :message => message, :user => bus_data["user"]

  end

  if bus_data["message"]=~ /timeline/
    bus.send "rbio::irc::timeline", :user => bus_data["user"]
  end

end



