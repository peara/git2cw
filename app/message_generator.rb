class MessageGenerator
  def self.noti2message repo, noti, event
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

  def self.event2message event
    repo = event.repo
    title = ''
    url = ''
    user = event.actor.login
    body = ''
    action = ''

    case event.type
    when 'PullRequestEvent'
      title = "#{event.actor.login} #{event.payload.action} pull request #{event.payload.pull_request.number}"
      url = event.payload.pull_request.html_url
      body = event.payload.pull_request.title
      action = '(merged)' unless event.payload.pull_request.merged_at.nil?
    when 'IssuesEvent'
      title = "#{event.actor.login} #{event.payload.action} issue #{event.payload.issue.number}"
      url = event.payload.issue.html_url
      body = event.payload.issue.title
    when 'IssueCommentEvent'
      title = "#{event.actor.login} #{event.payload.action} comment in issue #{event.payload.issue.number}"
      url = event.payload.comment.html_url
      body = "[code]\n#{event.payload.comment.body}\n[/code]"
      action = '(commented)'
    when 'PullRequestReviewCommentEvent'
      title = "#{event.actor.login} #{event.payload.action} comment in pull request #{event.payload.pull_request.number}"
      url = event.payload.comment.html_url
      body = "[code]\n#{event.payload.comment.body}\n[/code]"
      action = '(commented)'
    else
      return nil
    end


    message = <<~MSG
      [info][title][Github] #{repo.name}  #{action}[/title]
      ■ #{title}
      #{url}
      Body: #{body}
      [/info]
    MSG

    message
  end
end
