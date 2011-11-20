require 'cinch'
require 'redis'
require 'json'
require 'uuid'

require './bus'


bus = Bus.new
uuid = UUID.new
redis = Redis.new


bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = ["#pdxbots", "#pdxwebdev"]
    c.nick = "rbio"
  end

  #on :message do |m|
  #  bus.send "rbio::irc::got_msg", :user => m.user.nick, :message => m.message, :channel => m.channel.name
  #end

  on :privmsg do |m|
    bus.send "rbio::irc::got_priv_msg", :user => m.user.nick, :message => m.message
  end


end


bus.add "rbio::irc::send_msg_chan" do |msg_data|

  channel = bot.channel_manager.find(msg_data["channel"])
  begin
    channel.send msg_data["message"]
  rescue => e
    bus.send "rbio::errors", e
  end
end

bus.add "rbio::irc::send_msg_user" do |msg_data|
  user = bot.user_manager.find(msg_data["user"])
  user.send msg_data["message"]
end


bus.add "rbio::irc::join_chan" do |chan_data|
  bot.join(chan_data["channel"])
end

bus.add "rbio::irc::part_chan" do |chan_data|
  bot.part(chan_data["channel"])
end




bus.add "rbio::irc::verify" do |bus_data|


  user_info = bot.user_manager.find(bus_data["user"])
  authed = user_info.authed?

end


bot.start
