# SmasingSingleStatusSprintInformation

Smashing widget to view the information of a sprint status

## Usage

To use the widget place the files in your smashing project accordingly to the repository folders structure.

To include the widget in a dashboard, add the following snippet to the dashboard layout file:

```
<li data-row="2" data-col="1" data-sizex="1" data-sizey="1">
  <div data-id="singleStatusTodo" data-view="JiraSprintIssueStatus"></div>
</li>
```

Check the configuration section to know the id you should use.

## Settings

You should set up the following parameters inside the job file (jira_sprint_issue_status.rb):
* JIRA_URI: Jira Url
* STORY_POINTS_CUSTOMFIELD_CODE: The code of the customfield for the story points of the issue
* BOARD_ID: The identifier of the board to obtain the active sprint
* JIRA_AUTH: Credentials for using Jira
* SPRINT_STATUSES: Complex object to define the different statuses used in your sprint
  * statusid: Your Jira status identifier for the current srpint status
