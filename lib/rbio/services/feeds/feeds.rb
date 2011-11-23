require 'superfeedr'
require_relative '../../lib/bus'


bus = Bus.new

Superfeedr.connect("tjgillies@superfeedr.com", "kidid1th") do
  Superfeedr.on_notification do |notification|
    puts "The feed #{notification.feed_url} has been fetched (#{notification.http_status}: #{notification.message_status}) and will be fecthed again in #{(notification.next_fetch - Time.now)/60} minutes."
    notification.entries.each do |e|

      bus.send "rbio::irc::send_msg_chan", :channel => "#pdxbots", :message =>  "#{e.title}  #{e.links.map{|link| link.href if link.rel == "alternate"}.compact} was published (#{e.published})  #{e.summary} #{e.content.gsub(/<.*?>/,"")}"
    end
  end
end

