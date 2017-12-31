# Displays the board name, sprint name and remaining days for the active sprint for a specific board in Jira Agile

require 'net/http'
require 'json'
require 'time'
require 'yaml'

# Loads configuration file
config = YAML.load_file('config.yml')
USERNAME = config['jira']['username']
PASSWORD = config['jira']['password']
JIRA_URI = config['jira']['url']
STORY_POINTS_CUSTOMFIELD_CODE = config['jira']['customfield']['storypoints']
VIEW_ID = config['jira']['view']

SPECIAL_STATUS_REOPENED = '6'
SPRINT_STATUSES = {
  'single_status_todo' => {
      'code' => 1,
      'name' => 'To do',
      'statusid' => '1'
  },
  'single_status_progress' => {
      'code' => 2,
      'name' => 'In progress',
      'statusid' => '2'
  },
  'single_status_review' => {
      'code' => 3,
      'name' => 'In review',
      'statusid' => '3'
  },
  'single_status_test' => {
      'code' => 4,
      'name' => 'In test',
      'statusid' => '4'
  },
  'single_status_done' => {
      'code' => 5,
      'name' => 'Done',
      'statusid' => '5'
  }
}

# gets the view for a given view id
def get_view_for_viewid(view_id)
  http = create_http
  request = create_request("/rest/greenhopper/1.0/rapidviews/list")
  response = http.request(request)
  views = JSON.parse(response.body)['views']
  views.each do |view|
    if view['id'] == view_id
      return view
    end
  end
end

# gets the active sprint for the view
def get_active_sprint_for_view(view_id)
  http = create_http
  request = create_request("/rest/greenhopper/1.0/sprintquery/#{view_id}")
  response = http.request(request)
  sprints = JSON.parse(response.body)['sprints']
  sprints.each do |sprint|
    if sprint['state'] == 'ACTIVE'
      return sprint
    end
  end
end

# gets issues in each status
def get_issues_per_status(view_id, sprint_id, issue_count_array, issue_sp_count_array)
  current_start_at = 0

  begin
    response = get_response("/rest/agile/1.0/board/#{view_id}/sprint/#{sprint_id}/issue?startAt=#{current_start_at}")
    page_result = JSON.parse(response.body)
    issue_array = page_result['issues']

    issue_array.each do |issue|
      accumulate_issue_information(issue, issue_count_array, issue_sp_count_array)
    end

    current_start_at = current_start_at + page_result['maxResults']
  end while current_start_at < page_result['total']
end

# accumulate issue information
def accumulate_issue_information(issue, issue_count_array, issue_sp_count_array)
  case issue['fields']['status']['id']
  when SPRINT_STATUSES['single_status_todo']['statusid'], SPECIAL_STATUS_REOPENED
    if !issue['fields']['issuetype']['subtask']
      issue_count_array[0] = issue_count_array[0] + 1
    end
    if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
      issue_sp_count_array[0] = issue_sp_count_array[0] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
    end
  when SPRINT_STATUSES['single_status_progress']['statusid']
    if !issue['fields']['issuetype']['subtask']
      issue_count_array[1] = issue_count_array[1] + 1
    end
    if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
      issue_sp_count_array[1] = issue_sp_count_array[1] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
    end
  when SPRINT_STATUSES['single_status_review']['statusid']
    if !issue['fields']['issuetype']['subtask']
      issue_count_array[2] = issue_count_array[2] + 1
    end
    if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
      issue_sp_count_array[2] = issue_sp_count_array[2] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
    end
  when SPRINT_STATUSES['single_status_test']['statusid']
    if !issue['fields']['issuetype']['subtask']
      issue_count_array[3] = issue_count_array[3] + 1
    end
    if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
      issue_sp_count_array[3] = issue_sp_count_array[3] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
    end
  when SPRINT_STATUSES['single_status_done']['statusid']
    if !issue['fields']['issuetype']['subtask']
      issue_count_array[4] = issue_count_array[4] + 1
    end
    if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
      issue_sp_count_array[4] = issue_sp_count_array[4] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
    end
  else
    puts "ERROR: wrong issue status"
  end

  issue_count_array[5] = issue_count_array[5] + 1
  if !issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE].nil?
    issue_sp_count_array[5] = issue_sp_count_array[5] + issue['fields'][STORY_POINTS_CUSTOMFIELD_CODE]
  end
end

# create HTTP
def create_http
  http = Net::HTTP.new(JIRA_URI.host, JIRA_URI.port)
  if ('https' == JIRA_URI.scheme)
    http.use_ssl     = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  return http
end

# create HTTP request for given path
def create_request(path)
  request = Net::HTTP::Get.new(JIRA_URI.path + path)
  if USERNAME
    request.basic_auth(USERNAME, PASSWORD)
  end
  return request
end

# gets the response after a request
def get_response(path)
  http = create_http
  request = create_request(path)
  response = http.request(request)

  return response
end

SCHEDULER.every '1h', :first_in => 0 do
  # Last position is for the accumulated values
  issue_count_array = Array.new(6, 0)
  issue_sp_count_array = Array.new(6, 0)

  view_json = get_view_for_viewid(VIEW_ID)
  if (view_json)
    sprint_json = get_active_sprint_for_view(view_json['id'])
    if (sprint_json)
      get_issues_per_status(view_json['id'], sprint_json['id'], issue_count_array, issue_sp_count_array)
    end
  end

  SPRINT_STATUSES.keys.each_with_index do |status_name, index|
    send_event(status_name, {
      code: SPRINT_STATUSES[status_name]['code'],
      name: SPRINT_STATUSES[status_name]['name'],
      count: issue_count_array[index],
      storyPoints: issue_sp_count_array[index],
      value: (issue_sp_count_array[index] * 100 / issue_sp_count_array[5]).round(1)
    })
  end
end
