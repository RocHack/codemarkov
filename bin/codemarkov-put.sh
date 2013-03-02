#!/bin/bash
# codemarkov-put.sh
# Put files from a git repo to a codemarkov db
#
# Usage:
#
# Put all files in a repo:
# codemarkov-put.sh ls
#
# Put updates from last merge:
# codemarkov-put.sh post-merge

BASE='https://user:pass@localhost:6984/codemarkov/_design/codemarkov/_rewrite/'

update="${BASE}code/"

case $1 in
	post-merge)
		getfiles='git diff --name-only --diff-filter=MAD HEAD@{1} HEAD'
		;;
	ls-files)
		getfiles='git ls-files'
		;;
	*)
		echo "Usage: `basename $0` [post-merge|ls-files]" >&2
		exit 1
esac

put_doc() {
	curl -T "$file" "$update$1"
}

delete_doc() {
	curl -X PUT -H 'Content-Length: 0' "$update$1"
}

dir=`basename $PWD`

# may need to handle renames and copies here
$getfiles | while read file
do
	doc_id="$dir:${file//\//:}"
	if [[ -f "$file" && -r "$file" && -s "$file" ]]
	then
		echo PUT $file $doc_id
		put_doc "$doc_id"
	else
		echo DELETE $file $doc_id
		delete_doc "$doc_id"
	fi
done
