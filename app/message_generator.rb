class MessageGenerator
  def noti2message repo, noti, event
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

  def event2message event, settings
    repo = event.repo
    title = ''
    url = ''
    user = event.actor.login
    body = ''
    action = ''

    track_events = settings.track_events || []

    case event.type
    when 'PullRequestEvent'
      return nil unless track_events.include? 'pullrequest'

      title = "#{event.actor.login} #{event.payload.action} pull request #{event.payload.pull_request.number}"
      url = event.payload.pull_request.html_url
      body = event.payload.pull_request.title
      action = '(merged)' unless event.payload.pull_request.merged_at.nil?

    when 'IssuesEvent'
      return nil unless track_events.include? 'issue'

      title = "#{event.actor.login} #{event.payload.action} issue #{event.payload.issue.number}"
      url = event.payload.issue.html_url
      body = event.payload.issue.title

    when 'IssueCommentEvent'
      return nil unless track_events.include? 'comment'

      title = "#{event.actor.login} #{event.payload.action} comment in issue #{event.payload.issue.number}"
      url = event.payload.comment.html_url
      body = "[code]\n#{event.payload.comment.body}\n[/code]"
      action = '(commented)'

    when 'PullRequestReviewCommentEvent'
      return nil unless track_events.include? 'comment'

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
