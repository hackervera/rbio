class RbioBot
  def initialize
    config = YAML.load_file File.dirname(__FILE__) + "/irc.yaml"


    @uuid = UUID.new
    @redis = Redis.new
    @bot = Cinch::Bot.new do
      configure do |c|
        c.server = config["server"]
        c.channels =config["channels"]
        c.password = config["password"]
        c.nick = config["nick"]
      end


    end


    Thread.new do
      @bot.start
    end

  end

  def on_join
    @bot.on :join do |m|
      puts m
    end
  end

  def on_connect
    @bot.on :connect do
      yield
    end
  end

  def on_privmsg
    @bot.on :private do |m|
      yield :nick => m.user.nick, :message => m.message unless m.user.nil?
    end
  end

  def on_chanmsg
    @bot.on :channel do |m|
      yield :channel => m.channel.name, :nick => m.user.nick, :message => m.message
    end
  end



  def send_msg_chan(options)
    channel = @bot.channel_manager.find(options[:channel])
    channel.send options[:message]
  end

  def user(options)
    @bot.User options[:nick]
  end



  def send_msg_user(options)
    user = @bot.user_manager.find(options[:user])
    user.send options[:message]
  end


  def join_chan(options)
    @bot.join(options[:channel])
  end

  def part_chan(options)
    @bot.part(options[:channel])
  end

  def verify_nick(options)
    user = @bot.user_manager.find(options[:nick])
    user.authed?
  end

end

