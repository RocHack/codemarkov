views = module.exports

views.code_ngrams =
  map: (doc) ->

    if doc.type != 'code' then return

    # n-gram size
    n = 4

    try
      languages = require 'views/lib/languages'
      highlight = require 'views/lib/stratus-color/src/highlight'

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
      #emit doc.name, tokens

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

