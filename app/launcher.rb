 #!/usr/bin/env ruby
require 'config'
require 'dotenv/load'
require 'octokit'
require 'chatwork'
require_relative 'message_generator'

class Launcher
  attr_accessor :git_client, :chatwork_client
  def initialize
    puts "Launching..."

    puts "Load Github Configs"
    @git_client = Octokit::Client.new(:access_token => ENV["GITHUB_API_KEY"])

    puts "Load Repo Configs"
    Config.load_and_set_settings("config.yml")

    puts "Load Chatwork"
    ChatWork.api_key = ENV["CHATWORK_API_KEY"]

    puts "Load Stored File"
    if File.file?('data.txt')
      File.open('data.txt', 'r') do |file|
        @last_event_id = file.gets.to_i
      end
    else
      @last_event_id = 0
    end

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
    puts "Shutting down..."
    File.open('data.txt', 'w') do |file|
      file.puts @max_event_id
    end
    puts "Done!"
  end
end

launcher = Launcher.new
launcher.check_new_event
launcher.shutdown
