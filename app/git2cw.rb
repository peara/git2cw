 #!/usr/bin/env ruby
require 'config'
require 'dotenv/load'
require 'octokit'
require 'chatwork'
require 'redis'
require_relative 'message_generator'
require 'pry'

class Git2CW
  attr_accessor :git_client, :chatwork_client
  def initialize
    puts "Launching..."

    puts "Load Github Configs"
    @git_client = Octokit::Client.new(:access_token => ENV["GITHUB_API_KEY"])

    puts "Load Repo Configs"
    Config.load_and_set_settings("config.yml")

    puts "Load Chatwork"
    ChatWork.api_key = ENV["CHATWORK_API_KEY"]

    puts "Load Redis"
    @redis = Redis.new(url: ENV["REDIS_URL"])
    @last_event_id = @redis.get('last_event_id')&.to_i || 0

    puts "Loading... done!\n\n"
  end

  # TODO: not yet complete
  def check_new_noti
    Settings.Repos.each do |repo|
      notis = @git_client.repository_events(repo.url)
      next if notis.empty?

      puts "New Notification in #{repo.display_name}"

      notis.each do |noti|
        event = launcher.git_client.get(noti.subject.latest_comment_url)
        next unless noti.subject.type == "PullRequest"
        message = MessageGenerator.noti2message repo, noti, event
        ChatWork::Message.create(room_id: repo.chatwork_box, body: message)
      end

      launcher.git_client.mark_repo_notifications_as_read(repo.url) if repo.auto_read
    end
  end

  def check_new_event
    @max_event_id = @last_event_id
    puts "Checking new events"
    Settings.Repos.each do |repo|
      puts "\tRepo: #{repo.display_name}"
      events = @git_client.repository_events(repo.url)

      events.each do |event|
        break if event.id.to_i <= @last_event_id
        message = MessageGenerator.event2message event
        ChatWork::Message.create(room_id: repo.chatwork_box, body: message) unless message.nil?

        if @last_event_id == 0
          @last_event_id = event.id.to_i
        end
      end

      @max_event_id = events[0].id.to_i if events[0].id.to_i > @max_event_id
    end
  end

  def shutdown
    puts "Update Redis..."
    @redis.set("last_event_id", @max_event_id.to_s)
    puts "Done!"
  end
end
