require_relative 'lib/rbio'

bot = RbioBot.new
redis = Redis.new
Thread.abort_on_exception=true
users = {}
current = File.dirname(__FILE__)

bot.on_chanmsg do |options|
  load "#{current}/lib/rbio/services/irc/logger.rb"
  log(options)
end

bot.on_privmsg do |options|

  load "#{current}/bot_config.rb"
  load "#{current}/lib/rbio/services/feeds/feeds.rb"
  load "#{current}/lib/rbio/services/geoloqi/geoloqi.rb"
  load "#{current}/lib/rbio/services/twitter/twitter.rb"
  unless user = users[options[:nick]]
    user = User.new :nick => options[:nick], :bot => bot
    users[options[:nick]] = user
  end
  if user.authed_name.nil?
    user.send "Sorry but your nick isn't authed" unless options[:nick].downcase == "nickserv"
    next
  end
  options.merge!(:user => user, :bot => bot)
  execute options

end



Thread.stop