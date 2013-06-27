Rally-Export-Attachments
========================

Ruby script to export all attachments from a specified Rally Workspace for archival purposes

SCRIPT:
export-workspace-attachments.rb

PURPOSE:
Used to export all the attachments of a Rally subscription into individual
files for archival.

USAGE:
1) Change these four variables found in the code to match your environment:
- $my_base_url
- $my_username
- $my_password
- $my_workspace_oid # (ObjectID of the workspace you wish to export attachments from.)

- Notes:
- Note 1: you may find a list of your current/defaul workspace OID in your Subscription by visiting the following REST URL:
- https://rally1.rallydev.com/slm/webservice/v2.0/workspaces/
- To get a list of all Workspace OIDs in your Subscription, visit:
- https://rally1.rallydev.com/slm/doc/webservice/jsonDisplay.jsp?uri=https://rally1.rallydev.com/slm/webservice/v2.0/subscription&fetch=true
- Then click on the link that looks similar to the following:
- https://rally1.rallydev.com/slm/webservice/v2.0/Subscription/12345678914/Workspaces
- Note 2: It's recommended to run this script as a Subscription Administrator, to ensure that access to all Workspaces/Projects/Artifacts of interest

2) Invoke the script:
	./export-workspace-attachments.rb

3) All attachments found will be saved in:
	- ./Saved_Attachments/WS####/FormattedIDs/attachment-###.<type>.<ext>
   Where:
- WS### - is the ordinal workspace number found (1 based).
- FormattedIDs - is the combination of the FormattedID(s) of the Artifact, TestCaseResult or TestSet to which the attachment belongs.
- attachment-### - is the ordinal attachment number found in a given workspace (1 based).
- <type> - is the type of file, either "METADATA" or "DATA".
- <ext> - is the file extension found on the attachment. Used on the DATA <type> file only.

API DOCS:
- http://dev.developer.rallydev.com/developer/ruby-toolkit-rally-rest-api-json
- https://github.com/RallyTools/RallyRestToolkitForRuby

RUBY REQUIREMENTS:
Tested on Ruby Versions:
- ruby-1.9.3-p194
- ruby-1.9.3-p327
Required Gems:
- rally_api (0.9.2)
- httpclient (2.3.2) -- Usually included with the rally_api gem