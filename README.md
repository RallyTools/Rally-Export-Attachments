## License

Copyright (c) Rally Software Development Corp. 2013 Distributed under the MIT License.

## Warranty

Rally-Export-Attachments is available on an as-is basis. Rally Software does not provide any support for this utility.

## Introduction

The Rally-Export-Attachments is a Ruby script to export all attachments from a specified Rally Workspace for archival purposes

### Script

export-workspace-attachments.rb

### Purpose

Used to export all the attachments of a Rally subscription into individual files for archival.

### Usage

1) Change the following four variables found in the code to match your environment. Alternatively, add them to a file called
my_vars.rb located in the same directory. The script will automatically look for, and load the variables
from this file if found.

<pre>
$my_base_url       = "https://rally1.rallydev.com/slm"
$my_username       = "user@company.com"
$my_password       = "topsecret"
$my_workspace_oid  = "12345678910" # (ObjectID of the workspace you wish to export attachments from.)
</pre>

Notes
- you may find your current/default workspace OID in your Subscription by visiting the following REST URL:
  - https://rally1.rallydev.com/slm/webservice/v2.0/workspace/
  - To get a list of all Workspace OIDs in your Subscription, visit:
  - https://rally1.rallydev.com/slm/doc/webservice/jsonDisplay.jsp?uri=https://rally1.rallydev.com/slm/webservice/v2.0/subscription&fetch=true
  - Then click on the link that looks similar to the following:
  - https://rally1.rallydev.com/slm/webservice/v2.0/Subscription/12345678914/Workspaces
- It's recommended to run this script as a Subscription Administrator, to ensure that access to all Workspaces/Projects/Artifacts of interest

2) Invoke the script:
	<pre> c:\> ruby export-workspace-attachments.rb </pre>

3) All attachments found will be saved in:
<pre> ./Saved_Attachments/WS####/FormattedIDs/attachment-###.{type}.{ext} </pre>

   Where:
<pre>   
WS### - is the ordinal workspace number found (1 based).
FormattedIDs - is the combination of the FormattedID(s) of the Artifact, TestCaseResult or TestSet to which the attachment belongs.
attachment-### - is the ordinal attachment number found in a given workspace (1 based).
{type} - is the type of file, either "METADATA" or "DATA".
{ext} - is the file extension found on the attachment. Used on the DATA {type} file only.
</pre>

### API Documentation

- http://prod.help.rallydev.com/developer/ruby-toolkit-rally-rest-api-json
- https://github.com/RallyTools/RallyRestToolkitForRuby

### Ruby Requirements 

Tested on Ruby Versions:
- ruby-1.9.3-p194
- ruby-1.9.3-p327
Required Gems:
- rally_api (0.9.2)
- httpclient (2.3.2) -- Usually included with the rally_api gem
