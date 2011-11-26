class RbioLogger < Sinatra::Base
  redis = Redis.new
  get "/:channel" do
    puts "log:##{params[:channel]}"
    @entries = redis.smembers "log:##{params[:channel]}"
    erb :logs
  end
end

Thread.abort_on_exception=true
Thread.new do
  RbioLogger.run! :port => 4569
end