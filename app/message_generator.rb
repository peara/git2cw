class MessageGenerator
  def self.gen repo, noti, event
    description = event.body

    message = <<~MSG
      [info][title][Github] #{repo.display_name} [/title]
      Title: #{noti.subject.title}
      Url: #{event.html_url}
      User: #{event.user.login}
      Comment: #{description}
      [/info]
    MSG

    message
  end
end
