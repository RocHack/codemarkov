Codemarkov
==========

Random code generation using Markov chains and CouchDB

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
    
    {
        "_id": "...",
        "type": "code",
        "name": "example.js",
        "text": "the text"
    }

* Navigate to `yourdb/_design/codemarkov/static/index.html` to try out the code
generator.
