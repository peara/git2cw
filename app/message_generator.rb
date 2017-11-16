class MessageGenerator
  def self.gen noti, event
    title = ''
    description = ''

    case noti.reason
    when 'assign'
      title = "#{noti.owner.login} assigns "
    when 'mention'
      title = "#{noti.owner.login} mentions "
    when 'comment'
      description = event.body
    else
      title = "#{noti.reason}"
    end

    message = <<~MSG
      [info][title][Github] #{title} [/title]Project: #{repo.display_name}
      Title: #{noti.subject.title} - #{noti.reason}
      Url: #{event.html_url}
      Comment: #{description}
      [/info]
    MSG
    return message
  end
end
