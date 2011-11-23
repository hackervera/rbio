require 'redis'
require 'json'
#Thread.abort_on_exception=true
class Bus
  def initialize
  end

  def on(channel, &proc)
    #@listeners ||= []

    listener = Redis.new
    Thread.new do
      listener.subscribe channel do |on|
        on.message do |chan, message|
          begin
            proc.(JSON.parse message)
          rescue

          end
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

  def self.dependencies(service_array)
    dirname = File.dirname(__FILE__)
    redis = Redis.new
    service_array.each do |service|
      pid = redis.get "pid:#{service}"
      if pid.nil?
        `ruby #{dirname}/../services/#{service}/#{service}.rb>#{service}.log&`
        pid = $?.pid.to_i + 1
        redis.set "pid:#{service}", pid

      end


    end

  end
end