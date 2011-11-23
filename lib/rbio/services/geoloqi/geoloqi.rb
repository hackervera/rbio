class RbioLoqi
  def initialize(options)
    config = YAML.load_file File.dirname(__FILE__) + "/geoloqi.yaml"
    @host = config["host"]
    @uuid = UUID.new
    @client = config["client"]
    @secret = config["secret"]
    @redis = Redis.new
    @auth_redirect = "#{@host}/auth"
    @nick = options[:nick]
  end

  def session
    Geoloqi::Session.new :auth => JSON.parse(@redis.get "session:#{@nick}"), :config => {:client_id => @client, :client_secret => @secret}
  end

  def auth_url
    uuid = @uuid.generate
    @redis.set "nick:#{uuid}", @nick
    "https://geoloqi.com/oauth/authorize?response_type=code&client_id=#{@client}&redirect_uri=#{@auth_redirect}&state=#{uuid}"

  end

  def save_session
    @redis.set "session:#{@nick}", session.auth.to_json
  end

  def friends
    group_response = session.get "/group/last/hH8rzSh_i"
    save_session
    peeps = group_response["locations"].map do |location|
      "#{location["username"]} was last seen http://google.com/maps?z=15&q=#{location["location"]["position"]["latitude"]},#{location["location"]["position"]["longitude"]} on #{location["date"]}"
    end
    peeps.join("\n")
  end


  def set_genote(options)

    places = {}
    session.get("/place/list")["places"].each { |place| places[place["name"]] = place["place_id"] }
    save_session
    place = bus_data["place"]
    geonote_response = session.post "/geonote/create", :text => bus_data["message"], :place_id => places[place]
  end

end

