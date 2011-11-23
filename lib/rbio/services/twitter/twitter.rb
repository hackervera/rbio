class RbioTwitter
  def initialize(options)
    @redis = Redis.new
    @nick = options[:nick]
    config = YAML.load_file File.dirname(__FILE__) + "/twitter.yaml"
    @client = config["client"]
    @secret = config["secret"]
    @host = config["host"]
    @on_status = nil
    @consumer = OAuth::Consumer.new(config["client"], config["secret"], :site => "http://api.twitter.com")
    bot_access_token = OAuth::AccessToken.from_hash(@consumer, :oauth_token => config["token"], :oauth_token_secret => config["token_secret"])
    bus = Bus.new
    bus.on "test_message" do |bus_data|
      if bus_data["nick"].downcase == @nick.downcase
        @on_status.call bus_data["message"]
      end
    end

    timeline

  end


  def auth_url
    request_token = @consumer.get_request_token(:oauth_callback => "#{@host}/store_access?user=#{@nick}")
    @redis.set "request_token:#{@nick}", Marshal.dump(request_token)
    request_token.authorize_url
  end

  def access_token
    Marshal.load @redis.get "access_token:#{@nick}"
  end


  def dms
    dm_response = access_token.get("http://api.twitter.com/1/direct_messages.json")
    dms_json = JSON.parse dm_response.body
    dms = []
    dms_json.each do |message|
      dms << "#{message["sender_screen_name"]} says #{message["text"]}"
    end
    dms.first(10).join "\n"
  end

  def on_status(&proc)
    @on_status = proc
  end

  def update_status(message)
    update_response = access_token.post "http://api.twitter.com/1/statuses/update.json", :status => message
    ""
  end

  def check_timeline
    if @timeline.nil?
      false
    else
      true
    end
  end

  def toggle_timeline
    if @timeline.nil?
      @timeline = 1
      "timeline is now on"
    else
      @timeline = nil
      "timeline is now off"
    end
  end

  def timeline

    oauth_token = access_token.token
    oauth_token_secret = access_token.secret
    raise "timeline already running" unless @timeline.nil?
    raise "no token" if oauth_token.nil? || oauth_token_secret.nil?
    TweetStream.configure do |c|
      c.consumer_key = @client
      c.consumer_secret = @secret
      c.oauth_token = oauth_token
      c.oauth_token_secret = oauth_token_secret
      c.auth_method = :oauth
      c.parser = :yajl
    end
    client = TweetStream::Client.new
    client.on_timeline_status do |status|
      message = "#{status.user.screen_name} says #{status.text}"
      @on_status.call message  unless @timeline.nil?
      ""
    end
    client.userstream

    ""
  rescue => e
    ""
  end


end


