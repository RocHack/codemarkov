views = module.exports

views.code_ngrams =
  map: (doc) ->

    if doc.type != 'code' || doc.ignore
      return

    # n-gram size
    n = 4

    try
      languages = require 'views/lib/languages'
      highlight = require 'views/lib/stratus-color/src/highlight'

      repeat = (value, n) ->
        if n < 1 then [] else (value for [1..n])

      chunkify = (tokens, n) ->
        tokens.slice(i-n, i) for i in [n..tokens.length]

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
        if !language.syntax
          language.syntax = {}
          language.syntax[language.name] = {}
        highlight.addScopes language.syntax

      # special tokens
      newlineToken =
        type: 'newline'
        text: '\n'
      eofToken =
        type: null
        text: ''

      # prepare contents
      contents = doc.text
      tab = languages.preference?.tab
      contents = contents.replace /\t/g, tab if tab

      # tokenize
      tokensByLine = highlight contents, language.name, format: 'json'
      # convert 2d array of tokens into flat array with newlines and eofs
      tokens = [eofToken]
      for tokensOnLine in tokensByLine
        tokens.push.apply tokens, tokensOnLine
        tokens.push newlineToken
      # remove trailing newline
      tokens.pop()
      # put n-1 eof tokens at the end so that the view can get to eof with any n
      tokens.push.apply tokens, repeat eofToken, n-1
      #emit doc.name, tokens

      # emit ngrams for token types
      for chunk in chunkify tokens, n
        tokenTypes = (token.type for token in chunk)
        emit [0, language.name].concat tokenTypes

      # emit ngrams for text in tokens
      for token in tokens
        if token.type in ['newline', null] then continue
        # tokenize the text of this token
        textTokens = token.text.split /(?=\s+)/
        # mark start and end of text with ""
        textTokens = [''].concat textTokens, repeat '', n-1
        for chunk in chunkify textTokens, n
          emit [1, language.name, token.type].concat chunk

    catch e
      emit 'error', e

  reduce: '_count'

