#!/usr/bin/env ruby

# ------------------------------------------------------------------------------
# SCRIPT:
#	export-workspace-attachments.rb
#
# PURPOSE:
#	Used to export all the attachments of a Rally subscription into individual
#	files for archival.
#
# USAGE:
#	1) Change these four variables below to match your environment:
#		- $my_base_url
#		- $my_username
#		- $my_password
#		- $my_workspace_oid
#
#               - Notes:
#               - Note 1: you may find your current/default workspace OID in your Subscription by visiting the following REST URL:
#               - https://rally1.rallydev.com/slm/webservice/v2.0/workspace/
#               - To get a list of all Workspace OIDs in your Subscription, visit:
#               - https://rally1.rallydev.com/slm/doc/webservice/jsonDisplay.jsp?uri=https://rally1.rallydev.com/slm/webservice/v2.0/subscription&fetch=true
#               - Then click on the link that looks similar to the following:
#               - https://rally1.rallydev.com/slm/webservice/v2.0/Subscription/12345678914/Workspaces
#               - Note 2: It's recommended to run this script as a Subscription Administrator, to ensure that access to all Workspaces/Projects/Artifacts of interest
#
#	2) Invoke the script:
#		./export-workspace-attachments.rb
#
#	3) All attachments found will be saved in:
#		- ./Saved_Attachments/WS####/FormattedIDs/attachment-###.<type>.<ext>
#	   Where:
#		WS### - is the ordinal workspace number found (1 based).
#		FormattedIDs - is the combination of the FormattedID(s) of the Artifact,
#			TestCaseResult or TestSet to which the attachment
#			belongs.
#		attachment-### - is the ordinal attachment number found in a
#			given workspace (1 based).
#		<type> - is the type of file, either "METADATA" or "DATA".
#		<ext> - is the file extension found on the attachment. Used on
#			the DATA <type> file only.
#       
# API DOCS:
#       http://dev.developer.rallydev.com/developer/ruby-toolkit-rally-rest-api-json
#       https://github.com/RallyTools/RallyRestToolkitForRuby
#
# RUBY REQUIREMENTS:
#	Tested on Ruby Versions:
#		ruby-1.9.3-p194
#		ruby-1.9.3-p327
#	Required Gems:
#		rally_api (0.9.2)
#		httpclient (2.3.2) -- Usually included with the rally_api gem
#
# ------------------------------------------------------------------------------

$my_base_url	       = "https://rally1.rallydev.com/slm"
$my_username	       = "user@company.com"
$my_password	       = "topsecret"
$my_api_version        = "1.43"
$my_workspace_oid      = "12345678910"
$my_vars	       = "./my_vars.rb"


if FileTest.exist?( $my_vars ); puts "Loading variables from #{$my_vars}..."; require $my_vars; end

require "rally_api"
require "base64"
require "pp"


# ------------------------------------------------------------------------------
# Check for proper args.
#
def fixup_args ()

	print "Using Ruby version: #{RUBY_VERSION}-p#{RUBY_PATCHLEVEL}\n"

	if $my_base_url[-4..-1] != "/slm" && $my_base_url[-5..-1] != "/slm/"
		print "Fixup: Modifing URL from #{$my_base_url}."
		if $my_base_url[-1..-1] == "/"
			$my_base_url.concat("slm")
		else
			$my_base_url.concat("/slm")
		end
		print " to #{$my_base_url}\n"
  end

end


# ------------------------------------------------------------------------------
# Connect to Rally.
#
def connect_to_rally ()
	custom_headers		= RallyAPI::CustomHttpHeader.new()
	custom_headers.name	= "export-workspace-attachments"
	custom_headers.vendor   = "Rally Labs"
	custom_headers.version  = "0.50"

	config	= {	:base_url	=> $my_base_url,
			:username	=> $my_username,
			:password	=> $my_password,
			:workspace	=> nil,
			:project	=> nil,
			:version	=> $my_api_version,
			:headers	=> custom_headers}

	print "Attempting connection to Rally as username: #{config[:username]} at URL: #{$my_base_url}...\n"
	@rally = RallyAPI::RallyRestJson.new(config)
	print "Connection to Rally succeeded.\n"
end


# ------------------------------------------------------------------------------
# Query for Workspace information.
#
def get_workspace()
#
#	# https://github.com/RallyTools/RallyRestToolkitForRuby/blob/master/lib/rally_api/rally_query.rb
#	# Query options:	Example:			Default if nil:
#	# --------------------	------------------------------	----------------------------------------
#	# .type			:Defect, :Story, etc		---
#	# .query_string		"(State = \"Closed\")"		---
#	# .fetch		"Name,State,etc"		---
#	# .workspace		workspace json object or ref	workspace passed in RallyRestJson.new
#	# .project		project   json object or ref	project   passed in RallyRestJson.new
#	# .project_scope_up	true, false			false
#	# .project_scope_down	true, false			false
#	# .order		"ObjectID asc"			---
#	# .page_size		50, 100				200
#	# .limit		1000, 2000			99999
#	# --------------------	------------------------------	----------------------------------------
#
        query = RallyAPI::RallyQuery.new()
        query.type = :workspace
        query.fetch = "Name"

        query.workspace = {"_ref" => "https://rally1.rallydev.com/slm/webservice/#{$my_api_version}/workspace/#{$my_workspace_oid}.js" } #use your Workspace OID in place of 1234567890
        @my_workspace = @rally.find(query)

        print "Query returned the Workspace: #{@my_workspace.first}\n"

end


# ------------------------------------------------------------------------------
# Create a directory (with caveats).
#
DIR_NEW = 0	# Directory must be new (exit if it exists)
DIR_CAN_BE_OLD = 1	# Use existing directory if it already exists

def create_export_dir (dir_name, state)

	if Dir.exists?(dir_name) && state == DIR_NEW
		puts "ERROR-01: Directory already exists: #{dir_name}\n"
		exit
	end

	if Dir.exists?(dir_name)
		return
	else
		Dir.mkdir (dir_name)
		if ! Dir.exists?(dir_name)
			puts "ERROR-02: Could not create directory: #{dir_name}\n"
			exit
		end
	end
end


# ------------------------------------------------------------------------------
# Get a count of the number of OPEN Projects in this Workspace.
#
def get_open_project_count (this_workspace)
	query			= RallyAPI::RallyQuery.new()
        query.workspace         = this_workspace
	query.project		= nil
	query.project_scope_up	= true
	query.project_scope_down= true
	query.type		= :project
	query.fetch		= "Name"
	query.query_string	= "(State = \"Open\")"

	begin #{
        	all_open_projects	= @rally.find(query)
		open_project_count	= all_open_projects.total_result_count
	rescue Exception => e  
		open_project_count	= 0
	end #}

	return (open_project_count)
end


# ------------------------------------------------------------------------------
# Get all the attachments in a Workspace.
#
def get_all_workspace_attachments (this_workspace)
        query		= RallyAPI::RallyQuery.new()
	query.workspace	= this_workspace
        query.type	= :attachment

        query.fetch	=		"Artifact"
        query.fetch	= query.fetch + ",Build"
        query.fetch	= query.fetch + ",Content"
        query.fetch	= query.fetch + ",ContentType"
        query.fetch	= query.fetch + ",CreationDate"
        query.fetch	= query.fetch + ",Date"
        query.fetch	= query.fetch + ",Description"
        query.fetch	= query.fetch + ",DisplayName"
        query.fetch	= query.fetch + ",EmailAddress"
        query.fetch	= query.fetch + ",FormattedID"
        query.fetch	= query.fetch + ",LastUpdateDate"
        query.fetch	= query.fetch + ",Name"
        query.fetch	= query.fetch + ",ObjectID"
        query.fetch	= query.fetch + ",Size"
        query.fetch	= query.fetch + ",TestCase"
        query.fetch	= query.fetch + ",TestCaseResult"
        query.fetch	= query.fetch + ",TestSet"
        query.fetch	= query.fetch + ",User"

        all_workspace_attachments	= @rally.find(query)

	return (all_workspace_attachments)
end


# ------------------------------------------------------------------------------
# Main code starts here.
#
fixup_args()
connect_to_rally()
get_workspace()

#get_all_workspaces()
total_all_workspaces = @my_workspace.count


# ------------------------------------------------------------------------------
# Create a new directory to hold all attachments.
#
root_dir = "./Saved_Attachments"
print "Creating the root directory for saving attachments: #{root_dir}\n"
create_export_dir(root_dir, DIR_NEW)


# ------------------------------------------------------------------------------
# Loop through, processing each Workspace we found.
#
count_all_attachments = 0
total_bytes = 0
type_hash = Hash.new (0)

@my_workspace.each_with_index do | this_workspace, count_workspace | #{

	# Debugging code ... don't do them all
	#if count_workspace != 10531 then
	#	next
	#end

	print "Workspace [%03d of %03d] Name=#{this_workspace.Name}  State=#{this_workspace.State}"%[count_workspace+1,total_all_workspaces]
	if this_workspace.State == "Closed"
		print "...  being skipped.\n"
		next
	end


	# ----------------------------------------------------------------------
	# Only process Workspaces which have at least one OPEN Project.
	#
	open_project_count = get_open_project_count(this_workspace)
	print "  OPEN projects=#{open_project_count}"
	if open_project_count < 1 #{
		print "...  being skipped.\n"
		next
	end #} of "if open_project_count < 1"


	# ----------------------------------------------------------------------
	# Get all attachments in the Workspace.
	#
	all_workspace_attachments = get_all_workspace_attachments(this_workspace)
	print "  Attachments=#{all_workspace_attachments.total_result_count}"
	if all_workspace_attachments.total_result_count < 1 #{
		print "...  being skipped.\n"
		next
	end
	print ".\n"


	# ----------------------------------------------------------------------
	# Loop through and process each Attachment.
	#
	all_workspace_attachments.each_with_index do |this_workspace_attachment, count_workspace_attachments| #{
		count_all_attachments += 1

		print "     %05d - Attachment[%03d] Size=#{this_workspace_attachment.Size}\n"%[count_all_attachments, count_workspace_attachments + 1 ]
		# Debugging code ... don't do them all
		#if count_all_attachments != 35 then
		#	next
		#end


		# --------------------------------------------------------------
		# Create a new directory within our root_dir for each ordinal
		# Workspace number.
		#
		dir_name_workspace = root_dir + "/WS%03d/"%[ count_workspace + 1 ]
		if count_workspace_attachments == 0
			print "Create a workspace directory within the root_dir for saving attachments: #{dir_name_workspace}\n"
			create_export_dir(dir_name_workspace, DIR_NEW)
		end
		dir_name_artifact = dir_name_workspace


		# --------------------------------------------------------------
		# Save Artifact information (if any) from this attachment.
		#
		total_bytes = total_bytes + this_workspace_attachment.Size
		if this_workspace_attachment.Artifact != nil #{
			artifact_formatted_id = this_workspace_attachment.Artifact.FormattedID
			artifact_creation_date = this_workspace_attachment.Artifact.CreationDate
			artifact_last_update_date = this_workspace_attachment.Artifact.LastUpdateDate
			dir_name_artifact = dir_name_artifact + artifact_formatted_id
		else
			artifact_formatted_id = "(n/a)"
			artifact_creation_date = "(n/a)"
			artifact_last_update_date = "(n/a)"
		end #} of "if this_workspace_attachment.Artifact != nil"


		# --------------------------------------------------------------
		# Save TestCaseResult information (if any) from this attachment.
		#
		test_set_formatted_id = "(n/a)"
		if this_workspace_attachment.TestCaseResult != nil #{
			test_case_result_date = this_workspace_attachment.TestCaseResult.Date
			test_case_result_build = this_workspace_attachment.TestCaseResult.Build
			test_case_formatted_id = "#{this_workspace_attachment.TestCaseResult.TestCase.FormattedID}"
			dir_name_artifact = dir_name_artifact + test_case_formatted_id

			# ------------------------------------------------------
			# Does this Attachment.TestCaseResult also have a TestSet?
			if this_workspace_attachment.TestCaseResult.TestSet != nil
				test_set_formatted_id = "#{this_workspace_attachment.TestCaseResult.TestSet.FormattedID}"
				dir_name_artifact = dir_name_artifact + "-" + test_set_formatted_id
			end
		else
			test_case_result_date = test_case_result_build = test_case_formatted_id = "(n/a)"
			# ------------------------------------------------------
			# Does Attachment have neither an Artifact or a TestCaseResult?
			if artifact_formatted_id == "(n/a)"
				print "WARNING: Orphaned attachment found (has no Artifact or TestCaseResult).\n"
				dir_name_artifact = dir_name_artifact + "-Orphaned"
			end
		end #} of "if this_workspace_attachment.TestCaseResult != nil"


		# --------------------------------------------------------------
		# Create a new directory within our Workspace directory for each
		# artifact or testcase or testset.
		#
		print "Create an artifact directory within the workspace directory for saving attachments: #{dir_name_artifact}\n"
		create_export_dir(dir_name_artifact, DIR_CAN_BE_OLD)


		# --------------------------------------------------------------
		# Create a META-data file.
		#
		file_name_meta = dir_name_artifact + "/attachment-%03d.META.txt"%[count_workspace_attachments+1]
		print         "           Creating METADATA: filename=#{file_name_meta}\n"
		file_meta = File.new(file_name_meta,"wb")

		file_meta.syswrite "Attachment.Artifact.FormattedID                : #{artifact_formatted_id}\n"
		file_meta.syswrite "Attachment.Artifact.CreationDate               : #{artifact_creation_date}\n"
		file_meta.syswrite "Attachment.Artifact.LastUpdateDate             : #{artifact_last_update_date}\n"
		file_meta.syswrite "Attachment.TestCaseResult.Date                 : #{test_case_result_date}\n"
		file_meta.syswrite "Attachment.TestCaseResult.Build                : #{test_case_result_build}\n"
		file_meta.syswrite "Attachment.TestCaseResult.TestCase.FormattedID : #{test_case_formatted_id}\n"
		file_meta.syswrite "Attachment.TestCaseResult.TestSet.FormattedID  : #{test_set_formatted_id}\n"
		file_meta.syswrite "Attachment.ContentType                         : #{this_workspace_attachment.ContentType}\n"
		file_meta.syswrite "Attachment.Description                         : #{this_workspace_attachment.Description}\n"
		file_meta.syswrite "Attachment.Name                                : #{this_workspace_attachment.Name}\n"
		file_meta.syswrite "Attachment.Size                                : #{this_workspace_attachment.Size}\n"
		file_meta.syswrite "Attachment.User.EmailAddress                   : #{this_workspace_attachment.User.EmailAddress}\n"
		file_meta.syswrite "Attachment.User.DisplayName                    : #{this_workspace_attachment.User.DisplayName}\n"

		file_meta.close


		# --------------------------------------------------------------
		# Create a real data file which contains the decoded (from Base64)
		# Attachment content.
		#
		file_name_data = dir_name_artifact + "/attachment-%03d.DATA"%[count_workspace_attachments+1]

		if this_workspace_attachment.Content == nil
			# Yes it is possible to have an attachment with no content
			extension = ".empty"
			file_data = File.new(file_name_data + extension,"wb")
		else
			extension = "." + this_workspace_attachment.Name.split(".")[-1]
			file_data = File.new(file_name_data + extension,"wb")
			this_content = this_workspace_attachment.Content.read 
			file_data.syswrite(Base64.decode64(this_content.Content))
		end
		type_hash[extension.downcase] += 1
		print         "           Wrote DATA filename=#{file_name_data}  Size=#{this_workspace_attachment.Size}\n"

		file_data.close

	end #} of "all_workspace_attachments.each_with_index do |this_workspace_attachment,count_workspace_attachments|}

end #} of "all_workspaces.each_with_index do |this_workspace, count_workspace|"

byte_string = total_bytes.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
print "Found a total of #{count_all_attachments} attachments in ALL WORKSPACES; total bytes = %s.\n"%[byte_string]
pp type_hash.sort

#end#