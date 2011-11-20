require 'redis'
require 'json'
Thread.abort_on_exception=true
class Bus
  def initialize
    @threads = []
    at_exit { @threads.each(&:join) }
  end

  def on(channel, &proc)
    #@listeners ||= []

    listener = Redis.new
    @threads << Thread.new do
      listener.subscribe channel do |on|
        on.message do |chan, message|
          proc.(JSON.parse message)
        end
      end
    end
  rescue => e
    puts e
    return

  end

  def send(channel, data)
    sender = Redis.new
    sender.publish channel, data.to_json
  end
end