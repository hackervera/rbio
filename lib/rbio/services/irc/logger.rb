def log(options)
  puts options
    redis=Redis.new
  redis.sadd "log:#{options[:channel]}", {:time => Time.now, :nick => options[:nick], :message => options[:message]}.to_json
end