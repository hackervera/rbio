class User
  attr_accessor :authed_name

  def initialize(options)
    @loqiuser = RbioLoqi.new :nick => options[:nick]
    @ircuser = options[:bot].user :nick => options[:nick]
    @twitteruser = RbioTwitter.new :nick => options[:nick], :user => self
    @feeduser = RbioFeed.new :nick => options[:nick]
    @authed_name = @ircuser.authname if @ircuser.authed?
    @twitteruser.on_status do |response|
      @ircuser.send "@#{response}"
    end
    @feeduser.on_entry do |response|
      @ircuser.send response
    end
    @redis = Redis.new
    @nick = options[:nick]
  end

  def need_auth
  end

  def friends
    @loqiuser.friends
  end

  def send(message)
    @ircuser.send message
  end

  def loqi_auth_url
    @loqiuser.auth_url
  end

  def dms
    @twitteruser.dms
  end

  def twitter_auth_url
    @twitteruser.auth_url
  end

  def tweet(message)
    @twitteruser.update_status message
  end

  def timeline
    @twitteruser.toggle_timeline
  end

  def check_timeline
    @twitteruser.check_timeline
  end



  def superfeedr_auth(credentials)
    @redis.set "superfeedr_auth:#{@nick}",  credentials
  end

  def connect
    @feeduser.connect
  end

  def subscriptions
    @feeduser.subscriptions
  end

end