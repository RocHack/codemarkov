#!/bin/bash
# codemarkov-github-sync.sh
# Sync a GitHub user or organization's repos to a Codemarkov DB

# where to put the repos
BASE=/srv/git

# whose repos to sync
OWNER=RocHack
TYPE=org

# location of the codemarkov-put script
PUT='/usr/local/bin/codemarkov-put.sh'

curl -s "https://api.github.com/${TYPE}s/$OWNER/repos" |\
	sed -n 's/^.*"name": "\(.*\)",$/\1/p' | while read repo
do
	if [[ -d "$BASE/$repo" ]]
	then
		echo Updating $repo
		cd "$BASE/$repo"
		git pull --ff-only
		# post-merge hook will put updates to db
	else
		echo Cloning $repo
		cd "$BASE"
		git clone "git://github.com/$OWNER/$repo.git"
		cd "$repo"
		# add post-merge hook to put file updates on git pull/merge
		hook=.git/hooks/post-merge
		echo "#!/bin/sh" > $hook
		echo "exec $PUT post-merge" >> $hook
		chmod +x $hook
		# put initial repo files
		$PUT ls-files
	fi
done

# todo:
# check for deleted repos and delete their contents from the db
