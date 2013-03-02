
ddoc =
  _id: '_design/codegrams'
  language: 'javascript'
  views: {}
  lists: {}
  shows: {}
#  rewrites:
#    from: '', to: 'static/index.html'
#    from: 'static/', to: 'static/index.html'
#    from: '*', to: '../'

module.exports = ddoc

ddoc.views.code_ngrams =
  map: (doc) ->

    if doc.type != 'code' then return

    # n-gram size
    n = 3

    try
      languages = require 'views/lib/languages'
      highlight = require 'views/lib/stratus-color/src/highlight'

      for langName, lang of languages
        emit langName, lang

      chunkify = (tokens, n) ->
        tokens.slice(i-n, i) for i in [n..tokens.length]

      blanks = (n) ->
        new Array(n).join(' ').split ' '

      matchLanguage = (language, fileName, firstLine) ->
        if language.fileTypes?
          language.fileTypeRegex ||= new RegExp '(?:(?:' +
            language.fileTypes.join(')|(?:') + '))$'
        if language.firstLine?
          language.firstLineRegex ||= new RegExp language.firstLine

        (language.fileTypeRegex && language.fileTypeRegex.test fileName) ||
          (language.firstLineRegex && language.firstLineRegex.test firstLine)

      fileToLanguage = (fileName, text) ->
        firstLine = text.substr 0, text.indexOf '\n'
        for langName, language of languages
          return language if matchLanguage language, fileName, firstLine
        return languages.Text

      language = fileToLanguage doc.name, doc.text
      if !highlight.hasScope language.name
        highlight.addScopes language.syntax

      # todo: make this not necessary
      newlineToken =
        type: 'newline'
        text: '\n'

      tokensByLine = highlight doc.text, language.name, format: 'json'
      tokens = if n < 2 then [] else (newlineToken for [2..n])
      for tokensOnLine in tokensByLine
        tokens.push.apply tokens, tokensOnLine
        tokens.push newlineToken
      if n > 2 then tokens.push newlineToken for [3..n]
      emit doc.name, tokens

      # do ngrams for token types
      for chunk in chunkify tokens, n
        tokenTypes = (token.type for token in chunk)
        emit [0, language.name].concat tokenTypes

      # do ngrams for text in tokens
      for token in tokens
        # tokenize the text of this token
        # mark start and end of text with ""
        textTokens = token.text.split /(?=\s+)/
        padding = blanks n-1
        textTokens = (padding.concat textTokens).concat padding
        for chunk in chunkify textTokens, n
          emit [1, language.name, token.type].concat chunk

    catch e
      emit 'error', e

  reduce: '_count'

# Pick a random ngram weighted by frequency.
ddoc.lists.pick_ngram = (head, req) ->
  provides 'json', ->
    allowEmpty = !('nonempty' in req.query)

    # Two modes. If chosenIndex is null, read all rows and pick a random
    # one. If chosenIndex is a number, read up to the row with that
    # cumulative value, and return it.
    chosenNgram = null
    chosenIndex = req.query.i
    random = chosenIndex == null

    total = 0
    rows = []
    while row = getRow()
      if allowEmpty || row.key.some Boolean
        total += row.value
        if random
          row.cumulative = total
          rows.push row
        else if total > chosenIndex
          chosenNgram = row.key
          break

    if !chosenNgram
      chosenIndex = Math.random() * total
      for row in rows
        if row.cumulative > chosenIndex
          chosenNgram = row.key
          break

    JSON.stringify chosenNgram
    #JSON.stringify [rows, total, chosenIndex, row, random, chosenNgram]

###
ddoc.lists.people = (head, req) ->
  start
    headers: "Content-type": "text/html"
  send "<ul id='people'>\n"
  while row = getRow()
    send "\t<li class='person name'>" + row.key + "</li>\n"
  send "</ul>\n"

ddoc.shows.person = (doc, req) ->
  headers: "Content-type": "text/html"
  body: "<h1 id='person' class='name'>" + doc.name + "</h1>\n"

ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->
  require(field, message) ->
    message ||= "Document must have a " + field
    if !newDoc[field] then throw forbidden: message

  if newDoc.type == "person"
    require "name"

couchapp.loadAttachments ddoc, (path.join __dirname, '_attachments')
###
