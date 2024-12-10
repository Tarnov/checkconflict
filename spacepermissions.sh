#!bin/bash

set -o nounset
set -o errexit
set -o pipefail
set -o errtrace
set -o functrace


# -----------------
# --- VARIABLES ---
# -----------------
# Start time
START_TIME=$(date +%s)

# Work directory
WORK_DIR=$(mktemp -d)

# Credenrials
USER=<name>
PASSWD=<password>

# CURL configuration
CURL="curl -s -u $USER:$PASSWD -X GET"
HEADER='Content-Type: application/json; charset=UTF-8'
JIRA_URL='http://jira.mara.local'
CFL_URL="http://cfl.mara.local"
BAMBOO_URL="http://build.mara.local"
STASH_URL="http://git.mara.local"

# Target user info
SEARCH_USER_LOGIN=$1
SEARCH_USER_NAME="$($CURL -H "$HEADER" $JIRA_URL/rest/api/2/user?username=$1 | ./JSON.sh | egrep '\["displayName' | gsed -r 's|.*"(.*)"$|\1|')"

# Progress bar configuration
COLS=$(tput cols)


# ------------
# --- TRAP ---
# ------------
trap "
    rm -rf $WORK_DIR
" INT TERM ERR EXIT


# -----------------
# --- FUNCTIONS ---
# -----------------
# Draw progress bar
# bar <0-100%> <message>
function bar
{
	message="${2:-}"
	if [ "$message" != "" ]
	then
		offset=$(echo $message | wc -m)
	fi
	bar_len=$(($(tput cols)-$offset-9))
	mod=$((bar_len*$1/100))
	echo -n "$message ["
	# full
	for ((i=1; i<=$mod; i++))
	do
		echo -n '#'
	done
	# empty
	for ((j=1; j<=$((bar_len-$mod)); j++))
	do
		echo -n ' '
	done
	echo -n "] "
	printf "%4s" "$1%"
	return 0
}


function show_time
{
	num=$1
	min=0
	if((num>59))
	then
		((sec=num%60))
		((min=num/60))
	else
		((sec=num))
	fi
	echo "$min:$(printf "%02d" $(echo $sec))"
}


# Get all projects from JIRA
function get_all_jira_projects
{
	echo -n "1. Getting all projects..."
	$CURL -H "$HEADER" $JIRA_URL/rest/api/2/project | ./JSON.sh | egrep '^\[[0-9]+,"key"\]' | gsed -r 's|.*"([A-Z]+)"|\1|' > $WORK_DIR/project_key_list
	PROJECT_KEY_LIST_COUNT=$(cat $WORK_DIR/project_key_list | wc -l | gsed -r 's|^[\ ]+||')
	echo -e " Done. Found \e[93m$PROJECT_KEY_LIST_COUNT\e[0m project(s)."
}


# Search through every project's roles for target user
function get_all_jira_roles_actors
{
	message="2. Searching for user '$SEARCH_USER_NAME' in projects' roles:"
	k=1
	tput sc
	bar 0 "$message"
	cat $WORK_DIR/project_key_list | while read project
	do
		$CURL -H "$HEADER" $JIRA_URL/rest/api/2/project/$project/role | ./JSON.sh | egrep '^\["[A-Z]' | gsed -r 's|\["(.*)"].*/([0-9]+)"|\1:\2|' > $WORK_DIR/roles
		cat $WORK_DIR/roles | while read role
		do
			role_name="$(echo $role | cut -f1 -d:)"
			role_id="$(echo $role | cut -f2 -d:)"
			$CURL -H "$HEADER" $JIRA_URL/rest/api/2/project/$project/role/$role_id | ./JSON.sh | egrep -q "\[\"actors\",[0-9]+,\"displayName\".*$SEARCH_USER_NAME\"" || exit_code=$(echo $?)
			if [ "$exit_code" -eq "141" ]
			then
				echo "$project:$role_name" >> $WORK_DIR/projects-roles-permissions
			fi
		done
		tput el1
		tput rc
		bar "$((100*$k/$PROJECT_KEY_LIST_COUNT))" "$message"
		k=$(($k+1))
	done
	echo
	last_project=""
	cat $WORK_DIR/projects-roles-permissions | while read string
	do
		project=$(echo $string | cut -f1 -d:)
		role=$(echo $string | cut -f2 -d:)
		if [ "$last_project" != "$project" ]
		then
			if [ "$last_project" != "" ]
			then
				echo ")"
			fi
			echo -n "   $project ($role"
		else
			echo -n ", $role"
		fi
		last_project=$project
	done
	echo ")"
}


function get_all_cfl_spaces
{
	echo -n "1. Getting all spaces..."
	size="100"
	start="0"
	while [ $size = "100" ]
	do 
		$CURL -H "$HEADER" "$CFL_URL/rest/api/space?start=$start&limit=100" | ./JSON.sh > $WORK_DIR/cfl_spaces_list.json
		cat $WORK_DIR/cfl_spaces_list.json | egrep '\["results",[0-9]+,"key"\]' | egrep -v '"~' | gsed -r 's|.*"([a-zA-Z0-9]+)"|\1|' | sort -u >> $WORK_DIR/cfl_spaces_list
		size="$(cat $WORK_DIR/cfl_spaces_list.json | egrep '\["size"\]' | gsed -r 's|.*\t([0-9]+)|\1|')"
		start=$(($start+$size))
	done
	SPACE_KEY_LIST_COUNT=$(cat $WORK_DIR/cfl_spaces_list | wc -l | gsed -r 's|^[\ ]+||')
	echo -e " Done. Found \e[93m$SPACE_KEY_LIST_COUNT\e[0m space(s)."
}


function get_all_cfl_spaces_permissions
{
	message="2. Searching for user '$SEARCH_USER_NAME' in spaces' permissions views:"
	k=1
	tput sc
	bar 0 "$message"
	cat $WORK_DIR/cfl_spaces_list | while read space
	do
		$CURL -H "$HEADER" "$CFL_URL/spaces/spacepermissions.action?key=$space" | egrep "$SEARCH_USER_NAME" &>/dev/null && echo "   $space" >> $WORK_DIR/spaces || true
		tput el1
		tput rc
		bar "$((100*$k/$SPACE_KEY_LIST_COUNT))" "$message"
		k=$(($k+1))
	done
	echo
	cat $WORK_DIR/spaces
}


function get_all_stash_projects
{
	echo -n "1. Getting all projects..."
	$CURL -H "$HEADER" "$STASH_URL/rest/api/1.0/projects?limit=1000" | ./JSON.sh | egrep '\["values",[0-9]+,"key"\]' | gsed -r 's|.*"([0-9A-Z\-]+)"|\1|' > $WORK_DIR/stash_projects_list
	STASH_PROJECT_LIST_COUNT=$(cat $WORK_DIR/stash_projects_list | wc -l | gsed -r 's|^[\ ]+||')
	echo -e " Done. Found \e[93m$STASH_PROJECT_LIST_COUNT\e[0m plan(s)."
}


function get_all_stash_projects_repos_permissions
{
	message="2. Searching for user '$SEARCH_USER_NAME' in projects'/repos' settings:"
	k=1
	tput sc
	bar 0 "$message"
	cat $WORK_DIR/stash_projects_list | while read project
	do
		$CURL -H "$HEADER" "$STASH_URL/rest/api/1.0/projects/$project/permissions/users?limit=1000" | ./JSON.sh | egrep '\["values",[0-9]+,"user","displayName"\]' | egrep "$SEARCH_USER_NAME" &>/dev/null && echo "$project" >> $WORK_DIR/stash_projects || true
		$CURL -H "$HEADER" "$STASH_URL/rest/api/1.0/projects/$project/repos?limit=1000" | ./JSON.sh | egrep '\["values",[0-9]+,"slug"\]' | gsed -r 's|.*"([\.0-9a-z_\-]+)"|\1|' | while read repo
		do
			$CURL -H "$HEADER" "$STASH_URL/rest/api/1.0/projects/$project/repos/$repo/permissions/users?limit=1000" | ./JSON.sh | egrep '\["values",[0-9]+,"slug"\]' | gsed -r 's|.*"([a-z0-9\-]+)"|\1|' | egrep "$SEARCH_USER_NAME" &>/dev/null && echo "$project:$repo:Repository" >> $WORK_DIR/stash_projects || true
			$CURL -H "$HEADER" "$STASH_URL/rest/branch-permissions/1.0/projects/$project/repos/$repo/permitted?limit=1000" | ./JSON.sh | egrep '\["values",[0-9]+,"user","displayName"\]' | gsed -r 's|.*"([a-z0-9\-]+)"|\1|' | egrep "$SEARCH_USER_NAME" &>/dev/null && echo "$project:$repo:Branch" >> $WORK_DIR/stash_projects || true
		done

		tput el1
		tput rc
		bar "$((100*$k/$STASH_PROJECT_LIST_COUNT))" "$message"
		k=$(($k+1))
	done
	echo
	current_project=""
	last_repo=""
	need_close_bracket="false"
	cat $WORK_DIR/stash_projects | while read string
	do
		project="$(echo $string | cut -f1 -d:)"
		repo="$(echo $string | cut -f2 -d:)"
		repo_type="$(echo $string | cut -f3 -d:)"
		if [ "$current_project" != "$project" -a "$need_close_bracket" == "true" ]
		then
			echo ")"
			need_close_bracket="false"
		fi
		if [ "$project" == "$repo" ]
		then
			echo "   $project"
		else
			if [ "$project" != "$current_project" ]
			then
				echo "   $project"
			fi
			if [ "$last_repo" != "$repo" ]
			then
				if [ "$need_close_bracket" == "true" ]
				then
					echo ")"
					need_close_bracket="false"
				fi
				echo -n "      $repo ($repo_type"
				need_close_bracket="true"
			else
				echo ", $repo_type)"
				need_close_bracket="false"
			fi
			last_repo=$repo
		fi
	        current_project=$project
	done
}


function get_all_bamboo_plans
{
        echo -n "1. Getting all plans..."
	$CURL -H "$HEADER" "$BAMBOO_URL/rest/api/latest/plan.json?max-result=1000" | ./JSON.sh | egrep '\["plans","plan",[0-9]+,"planKey","key"\]' | gsed -r 's|.*"([0-9A-Z\-]+)"|\1|' > $WORK_DIR/build_plans_list
	BUILD_PLAN_LIST_COUNT=$(cat $WORK_DIR/build_plans_list | wc -l | gsed -r 's|^[\ ]+||')
	echo -e " Done. Found \e[93m$BUILD_PLAN_LIST_COUNT\e[0m plan(s)."
}


function get_all_bamboo_plans_permissions
{
	message="2. Searching for user '$SEARCH_USER_NAME' in plans' permissions views:"
	k=1
	tput sc
	bar 0 "$message"
	cat $WORK_DIR/build_plans_list | while read key
	do
		$CURL -H "$HEADER" "$BAMBOO_URL/chain/admin/config/editChainPermissions.action?buildKey=$key" | egrep "$SEARCH_USER_NAME" &>/dev/null && { echo "   $key" >> $WORK_DIR/plans; } || true
		tput el1
		tput rc
		bar "$((100*$k/$BUILD_PLAN_LIST_COUNT))" "$message"
		k=$(($k+1))
	done
	echo
	cat $WORK_DIR/plans
}


# ---------------------
# --- START PROGRAM ---
# ---------------------
clear
echo "========================================"
echo "=== GET USER'S EXCLUSIVE PERMISSIONS ==="
echo "========================================"
echo
echo "TARGET USER: $SEARCH_USER_NAME ($SEARCH_USER_LOGIN)"
echo
echo "=== JIRA ==="
get_all_jira_projects
get_all_jira_roles_actors
echo
echo "=== CONFLUENCE ==="
get_all_cfl_spaces
get_all_cfl_spaces_permissions
echo
echo "=== STASH ==="
get_all_stash_projects
get_all_stash_projects_repos_permissions
echo
echo "=== BAMBOO ==="
get_all_bamboo_plans
get_all_bamboo_plans_permissions


FINISH_TIME=$(date +%s)
TIME="$(show_time $(($FINISH_TIME-$START_TIME)))"
echo
echo "Total processing time: ${TIME}."
