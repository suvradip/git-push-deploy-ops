#!/bin/bash

#echo shell commands as they are executed, prints a little + sign before the line
set -x
#set -o xtrace

echo "User being used"
(set -x; whoami )

# Application Name:
export DEPLOY_APP_NAME="NAME-OF-THE-APP"

# This is the root deploy dir.
export SANDBOX="/PATH/TO/DEPLOYMENT/DIRECTORY"

# When receiving a new git push, the received branch gets compared to this one.
export DEPLOY_ALLOWED_BRANCH="master"

# You could use this to do a backup before updating to be able to do a quick rollback.
PRE_UPDATE=false

# Use this to do update tasks and maybe service restarts
POST_UPDATE=true

###########################################################################################

export GIT_DIR="/PATH/TO/BARE/REPOSITORY"
export GIT_WORK_TREE="${SANDBOX}"
IP="$(ip addr show eth0 | grep 'inet ' | cut -f2 | awk '{ print $2}')"

echo "GitHook: $(date): Welcome to '$(hostname -f)' (${IP})"
echo


# Loop, because it is possible to push more than one branch at a time. (git push --all)
while read oldrev newrev refname
do

	#export DEPLOY_BRANCH=`echo $refname | cut -d/ -f3`
	export DEPLOY_BRANCH=$(git rev-parse --symbolic --abbrev-ref $refname)
	export DEPLOY_OLDREV="$oldrev"
	export DEPLOY_NEWREV="$newrev"
	export DEPLOY_REFNAME="$refname"

	if [ ! -z "${DEPLOY_ALLOWED_BRANCH}" ]; then
		if [ "${DEPLOY_ALLOWED_BRANCH}" != "$DEPLOY_BRANCH" ]; then
			echo
			echo "GitHook: Branch '$DEPLOY_BRANCH' of '${DEPLOY_APP_NAME}' application will not be deployed. Exiting."
			exit 1
		fi
	fi

    ###########################################################################################

    if $PRE_UPDATE ; then
    	echo
       	echo "GitHook: PRE UPDATE STARTED"
       	## WRITE YOUR DESIRED SCRIPTS TO DO OPERATIONS
       	echo "GitHook: Updating .."


       	echo "GitHook: PRE UPDATE DONE"
    fi

    ###########################################################################################

    # Make sure GIT_DIR and GIT_WORK_TREE is correctly set and 'export'ed. Otherwhise
    # these two environment variables could also be passed as parameters to the git cli
    echo
    echo "GitHook: I will deploy '${DEPLOY_BRANCH}' branch of the '${DEPLOY_APP_NAME}' project to '${SANDBOX}'"
    git checkout -f "${DEPLOY_BRANCH}" || exit 1
    git reset --hard "$DEPLOY_NEWREV" || exit 1
    echo "GitHook: (+) Basic Deploy done."

    echo
    echo "GitHook: submodule update initiated."
    cd $SANDBOX
    git submodule update --init --recursive || exit 1
    echo "GitHook: (+) submodule update done."

    ###########################################################################################

    if $POST_UPDATE ; then
       	echo
       	echo "GitHook: POST UPDATE STARTED"
		## WRITE YOUR DESIRED SCRIPTS TO DO OPERATIONS
    	echo "Correct htaccess file for prod env"


      	echo "GitHook: POST UPDATE DONE"
    fi

done

echo
echo "GitHook: $(date): See you soon at '$(hostname -f)' (${IP})"
exit 0

