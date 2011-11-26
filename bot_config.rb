def execute(options)
  match = options[:message]
  user = options[:user]

  match =~ /auth (.*)/
  if $1 == "geoloqi"
    user.send user.loqi_auth_url
  end


  if $1 == "twitter"
    puts "test"
    user.send user.twitter_auth_url
  end

  if match =~ /friends/
    user.send user.friends
  end


  if match =~ /dms/
    user.send user.dms
  end

  if match =~ /tweet (.*)/
    message = $1
    user.tweet message
  end

  if match =~ /^timeline$/
    user.send user.timeline
  end

  if match =~ /timeline\?/
    user.send user.check_timeline
  end

  if match =~ /feeder (.*?) (.*)/
    username = $1
    password = $2
    user.superfeedr_auth "#{username}:#{password}"
  end

  if match =~ /connect/
    user.connect
  end

  if match =~ /tester/
    user.send "woot"
  end

  if match =~ /subscriptions/
    user.subscriptions
  end








end

