require 'cinch'
require 'redis'
require 'json'
require 'uuid'
require 'yaml'

require_relative '../../lib/bus'

config = YAML.load_file File.dirname(__FILE__) + "/irc.yaml"

NICK = config["nick"]
PASSWORD = config["password"]
SERVER = config["server"]
CHANNELS = config["channels"]

bus = Bus.new
uuid = UUID.new
redis = Redis.new


bot = Cinch::Bot.new do
  configure do |c|
    c.server = SERVER
    c.channels = CHANNELS
    c.password = PASSWORD
    c.nick = NICK
  end


  on :privmsg do |m|
    bus.send "rbio::irc::got_priv_msg", :user => m.user.nick, :message => m.message
  end


end

verify = lambda do |user|
  this_user = bot.user_manager.find(user)
  if this_user.authed?
    {:val => true, :nick => this_user.authname}
  else
    {:val => false}
  end
end


bus.on "rbio::irc::send_msg_chan" do |msg_data|

  channel = bot.channel_manager.find(msg_data["channel"])
  begin
    channel.send msg_data["message"]
  rescue => e
    bus.send "rbio::errors", e
  end
end

bus.on "rbio::irc::send_msg_user" do |msg_data|
  user = bot.user_manager.find(msg_data["user"])
  user.send msg_data["message"]
end


bus.on "rbio::irc::join_chan" do |chan_data|
  bot.join(chan_data["channel"])
end

bus.on "rbio::irc::part_chan" do |chan_data|
  bot.part(chan_data["channel"])
end


bus.on "rbio::irc::send_auth_url_geoloqi" do |bus_data|
  verified = verify.call bus_data["user"]
  if verified[:val]
    bus.send "rbio::geoloqi::send_auth_url", :user => verified[:nick], :current_user => bus_data["user"]
  else
    bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => "Sorry but you're not authed to nickserv"
  end
end


bus.on "rbio::irc::send_auth_url_twitter" do |bus_data|
  verified = verify.call bus_data["user"]
  if verified[:val]
    bus.send "rbio::twitter::send_auth_url", :user => verified[:nick], :current_user => bus_data["user"]
  else
    bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => "Sorry but you're not authed to nickserv"
  end
end


bus.on "rbio::irc::send_friends_geoloqi" do |bus_data|
  verified = verify.call bus_data["user"]
  if verified[:val]
    bus.send "rbio::geoloqi::send_friends", :user => verified[:nick], :current_user => bus_data["user"]
  else
    bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => "Sorry but you're not authed to nickserv"
  end
end

bus.on "rbio::irc::send_geonote" do |bus_data|
  verified = verify.call bus_data["user"]
  if verified[:val]
    bus.send "rbio::geoloqi::send_geonote", :user => verified[:nick], :current_user => bus_data["user"], :place => bus_data["place"], :note_user => bus_data["note_user"], :message => bus_data["message"],
  else
    bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => "Sorry but you're not authed to nickserv"
  end
end


bus.on "rbio::irc::timeline" do |bus_data|
  verified = verify.call bus_data["user"]
  if verified[:val]
    bus.send "rbio::twitter::timeline", :user => verified[:nick], :current_user => bus_data["user"], :place => bus_data["place"], :note_user => bus_data["note_user"], :message => bus_data["message"],
  else
    bus.send "rbio::irc::send_msg_user", :user => bus_data["user"], :message => "Sorry but you're not authed to nickserv"
  end
end

Thread.new do
  bot.start
end
