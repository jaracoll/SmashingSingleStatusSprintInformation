class Dashing.JiraSprintIssueStatus extends Dashing.Widget

 onData: (data) ->
  # Handle incoming data
  # You can access the html node of this widget with `@node`
  # Example: $(@node).fadeOut().fadeIn() will make the node flash each time data comes in.

  $(@node).find('div[name=master]').css('background-size', '150px')
  $(@node).find('div[name=master]').css('background-repeat', 'no-repeat')
  $(@node).find('div[name=master]').css('background-position', '5% 0%')

  if data.code == 1
    $(@node).find('div[name=master]').css('background-image', 'url(/assets/jira_sprint_issue_status/todo.png)')
    $(@node).find('svg').attr('id', 'gaugeTodo')
    $(@node).find('svg').attr('value', data.value)
    $(@node).find('svg').trigger("click")

  if data.code == 2
    $(@node).find('div[name=master]').css('background-image', 'url(/assets/jira_sprint_issue_status/progress.png)')
    $(@node).find('svg').attr('id', 'gaugeProgress')
    $(@node).find('svg').attr('value', data.value)
    $(@node).find('svg').trigger("click")
  
  if data.code == 3
    $(@node).find('div[name=master]').css('background-image', 'url(/assets/jira_sprint_issue_status/review.png)')
    $(@node).find('svg').attr('id', 'gaugeReview')
    $(@node).find('svg').attr('value', data.value)
    $(@node).find('svg').trigger("click")
  
  if data.code == 4
    $(@node).find('div[name=master]').css('background-image', 'url(/assets/jira_sprint_issue_status/test.png)')
    $(@node).find('svg').attr('id', 'gaugeTest')
    $(@node).find('svg').attr('value', data.value)
    $(@node).find('svg').trigger("click")
    
  if data.code == 5
    $(@node).find('div[name=master]').css('background-image', 'url(/assets/jira_sprint_issue_status/done.png)')
    $(@node).find('svg').attr('id', 'gaugeDone')
    $(@node).find('svg').attr('value', data.value)
    $(@node).find('svg').trigger("click")
