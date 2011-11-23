require 'redis'
require 'cinch'
require 'yaml'
require 'json'
require 'uuid'
require 'sinatra/base'
require 'geoloqi'
require 'typhoeus'
require 'oauth'
require 'tweetstream'

require 'yajl'
require 'tweetstream'

require_relative 'rbio/services/irc/irc'
require_relative 'rbio/services/twitter/twitter'
require_relative 'rbio/services/geoloqi/geoloqi'
require_relative 'rbio/services/geoloqi/loqi_auth'
require_relative 'rbio/services/twitter/twitter_auth'
require_relative 'rbio/bus'
require_relative 'rbio/user'

bot = RbioBot.new

users = {}

bot.on_connect do

end


bot.on_privmsg do |options|
  unless user = users[options[:nick]]
    user = User.new :nick => options[:nick], :bot => bot
    users[options[:nick]] = user
  end

  next if user.authed_name.nil?

  load "../examples/bot.rb"
  load "../lib/rbio/user.rb"
  load "../lib/rbio/services/geoloqi/geoloqi.rb"
  load "../lib/rbio/services/twitter/twitter.rb"
  options.merge! :user => user

  check_command options
end


Thread.new do
  LoqiAuth.run!
end
Thread.stop