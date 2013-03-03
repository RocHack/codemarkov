Codemarkov
==========

*Random code generation using Markov chains and CouchDB*

Codemarkov uses the
[stratus-color](https://github.com/stratuseditor/stratus-color) syntax
highlighter to tokenize code input and output it as n-grams into a CouchDB
map-reduce view. n-grams are output for token types and words in tokens. We can
query the view one n-gram at a time to build a Markov chain of token types, and
then for each token type query one word at a time to form some text contents for
the token. In this way a piece of code can be constructed which somewhat
resembles real code.

## Requirements

* [kanso](http://kan.so/)

## Installation

    git submodule init
    git submodule update
    kanso install
    kanso push http://yourcouch:5984/db

## Usage

* Add some content to the database, in documents of this form:

```json
{
    "_id": "path:example.ja",
    "type": "code",
    "name": "example.js",
    "text": "the text"
}
```

* Navigate to `yourdb/_design/codemarkov/static/index.html` to try out the code
generator.

### Syncing git repositories

Codemarkov needs some code files to base the random code on.

Two rudimentary scripts are included for uploading the contents of a git repo
to a Codemarkov DB.

* `codemarkov-put.sh`

Used in a git repository, this script uploads files to a codemarkov db.  Edit
the file to set the database URL. Use the script with argument `ls-files` to
upload all files in the repo, or with argument `post-merge` to upload all files
changed in the last merge.

* `codemarkov-github-sync.sh`

This script clones or updates all of a GitHub user or organization's
repositories. It adds a post-merge hook for `codemarkov-put.sh` to upload the
contents to Codemarkov. To use, edit the script and set the directory to store
the repos, the user or org name, and location of `codemarkov-put.sh`.

