def check_command(options)
  user = options[:user]
  match = options[:message]

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

  if match =~ /rehash twitter/
    load "../lib/rbio/services/twitter/twitter.rb"
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

end