require 'redis'
require 'json'
require 'cgi'
require_relative 'lib/bus'

bus = Bus.new


r = Redis.new

task :join do
  puts "executing join task"
  data = {:channel => "#geoloqi"}

  r.publish "rbio::irc::join_chan", data.to_json
end

task :part do
  data = {:channel => "#pdxwebdev"}

  r.publish "rbio::irc::part_chan", data.to_json
end

task :say_hello do
  data = {:channel => "#pdxbots", :message => "hello world"}
  r.publish "rbio::irc::send_msg_chan", data.to_json
end

task :say_pdxwebdev do
  data = {:channel => "#pdxwebdev", :message => "this is a test of the gillies rbio message bus"}
  r.publish "rbio::irc::send_msg_chan", data.to_json
end

task :get_users do
  data = {:channel => "#pdxwebdev", :message => "this is a test of the gillies rbio message bus"}
  r.publish "rbio::irc::get_users", data.to_json
end

task :track_apples do
  data = {:track_word => "apples"}.to_json
  r.publish "rbio::twitter::track", data
end

task :track_rww do
  data = {:track_word => "rww"}.to_json
  r.publish "rbio::twitter::track", data
end


task :twitter_test do
  bus.send "rbio::twitter::publish_message",  :message => "Sending test to twitter"
end


task :get_gx_layer do
  bus.send "rbio::geoloqi::get_layer_info", :layer => "1SC"
end


task :verify_user do
  bus.send "rbio::irc::verify_user", :nick => 'tjgillies'
end

task :msg_tyler do
 bus.send "rbio::irc::send_msg_user", :user => "tjgillies", :message => "yo dawg"
end


task :check_dms do
  bus.send "rbio::twitter::check_dms", :foo => :bar
end


