class RbioFeed
  def initialize(options)
    @redis = Redis.new
    @nick = options[:nick]
    @bus = Bus.new
    @on_entry = nil
  end

  def on_entry(&proc)
    @on_entry = proc
  end

  def subscriptions
    Superfeedr.subscriptions do |page, feeds|
      @on_entry.call feeds.join ", "
    end
  end

  def connect
    username, password = @redis.get("superfeedr_auth:#{@nick}").split ":"
    raise "no credentials" if username.nil? || password.nil?
    Superfeedr.connect("#{username}@superfeedr.com", password) do
      Superfeedr.on_notification do |notification|
        puts "The feed #{notification.feed_url} has been fetched (#{notification.http_status}: #{notification.message_status}) and will be fetched again in #{(notification.next_fetch - Time.now)/60} minutes."
        notification.entries.each do |e|

          @on_entry.call "#{e.title}  #{e.links.map { |link| link.href if link.rel == "alternate" }.compact} was published (#{e.published})  #{e.summary} #{e.content.gsub(/<.*?>/, "")}"
        end
      end
    end
  end
end