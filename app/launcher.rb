 #!/usr/bin/env ruby
require 'config'
require 'dotenv/load'
require 'octokit'
require 'chatwork'

class Launcher
  attr_accessor :git_client, :chatwork_client
  def initialize
    puts "Launching"

    puts "Load Github Configs"
    @git_client = Octokit::Client.new(:access_token => ENV["GITHUB_API_KEY"])

    puts "Load Repo Configs"
    Config.load_and_set_settings("config.yml")

    puts "Load Chatwork"
    ChatWork.api_key = ENV["CHATWORK_API_KEY"]

    puts "Loading... done!\n"
  end
end

launcher = Launcher.new
loop do
  Settings.Repos.each do |repo|
    notis = launcher.git_client.repository_notifications(repo.url)
    # TODO: mark notification read
    # launcher.git_client.mark_repo_notifications_as_read(repo.url)
    next if notis.empty?

    puts "New Notification in #{repo.display_name}"

    notis.each do |noti|
      event = launcher.git_client.get(noti.subject.latest_comment_url)
      message = MessageGenerator.gen noti, event
      ChatWork::Message.create(room_id: repo.chatwork_box, body: message)
    end
  end
  sleep 300
end
