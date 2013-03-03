numRequests = 0

loadJSON = (url, req, cb) ->
  r = new XMLHttpRequest
  r.open 'GET', url + '?' + encodeForm(req), true
  r.onreadystatechange = ->
    if r.readyState != 4 then return
    try
      data = JSON.parse r.responseText
    catch e
    finally
      cb data
      delete r.onreadystatechange
  numRequests++
  numRequestsText?.nodeValue = numRequests
  r.send null

encodeForm = (obj) ->
  (encodeURIComponent(key) + '=' + encodeURIComponent JSON.stringify val \
    for own key, val of obj) .join "&"

stopped = false
languageSelected = null
reasonable = true

# Get the user's selected language,
# or pick a language randomly
pickLanguage = (cb) ->
  if languageSelected
    cb languageSelected
  else
    pickNgram [0], cb

# Pick a file name and language
generateFileType = (cb) ->
  pickLanguage (langName) ->
    if langName
      # Don't have file names yet
      fileName = langName
      cb null, fileName, langName
    else
      cb new Error 'Unable to pick a file type'

# Generate a file with code
generateCodeFile = (n) ->
  generateFileType (err, fileName, langName) ->
    if err
      alert 'Error: ' + err
      return

    codeEl = makeCodeFileElement fileName
    gutter = codeEl.previousSibling

    lineNum = 1
    lineEl = null
    pendingNewlines = 1
    newLines = ->
      while pendingNewlines
        pendingNewlines--
        # add line number to gutter
        lineEl = document.createElement 'li'
        codeEl.appendChild lineEl
        (gutter.appendChild document.createElement 'span')
        .appendChild document.createTextNode lineNum++

    # start first line
    newLines()

    if reasonable
      # in reasonable mode, each ngram is a word from a token,
      # with the token type
      newToken = (type) ->
        el = document.createElement 'span'
        el.className = tokenTypeToClass type
        lineEl.appendChild el
        el

      # pick tokens
      prevTokenType = null
      tokenEl = null
      pickTokenWords langName, n, (tokenType, word) ->
        if tokenType == 'newline'
          # queue newlines until there is content to follow
          pendingNewlines++
        else
          # print pending newlines
          newLines()
          if tokenType != prevTokenType
            tokenEl = newToken tokenType
            tokenEl.appendChild document.createTextNode word

    else
      # insane mode
      # separate markov chains for token types and words within token text
      pickTokenTypes langName, n, (tokenType) ->
        if tokenType == 'newline'
          # queue newlines until there is content to follow
          pendingNewlines++
        else
          # print pending newlines
          newLines()
          # pick token contents
          tokenEl = document.createElement 'span'
          tokenEl.className = tokenTypeToClass tokenType
          lineEl.appendChild tokenEl
          pickWordTokens langName, tokenType, n, (word) ->
            tokenEl.appendChild document.createTextNode word

# Stop generating code
stopGenerating = ->
  stopped = true

isNewline = (type) -> type == 'newline'

# Pick a random n-gram from the couch with a prefix
pickNgram = (prefix, cb) ->
  startkey = prefix
  endkey = prefix.concat {}
  # Get max rows, pick a value from that, and then find that row
  loadJSON 'ngrams/count',
    startkey: prefix
    endkey: endkey
  , (max) ->
    index = Math.floor max * Math.random()

    # Optimization: if the index is in the second half, reverse the
    # query and we will iterate on average half as far
    descending = index > max/2
    if descending
      tmp = startkey
      startkey = endkey
      endkey = tmp
      index = max - index

    loadJSON 'ngrams/pick',
      group_level: prefix.length+1
      i: index
      startkey: startkey
      endkey: endkey
      descending: descending
    , (ngram) -> cb ngram?[ngram.length-1]

last = (n, array) ->
  if n then array[-n..] else []

# Pick a sequence of token types (n>=1)
pickTokenTypes = (language, n, tokenCb) ->
  next = (prevTokenTypes) ->
    pickTokenType language, prevTokenTypes, (tokenType) ->
      if stopped or tokenType == null
        return
      tokenCb tokenType
      # continue generating tokens until null token is reached
      nextTokenTypes = last n-1, prevTokenTypes.concat tokenType
      next nextTokenTypes
  startTokens = if n < 2 then [] else [null]
  next startTokens

# Pick a sequence of words for token contents
pickWordTokens = (language, tokenType, n, wordCb) ->
  next = (prevWords) ->
    pickWordToken language, tokenType, prevWords, (word) ->
      wordCb word if word
      nextWords = last n-1, prevWords.concat word
      # continue generating words until reached n-1 blanks
      if !stopped and nextWords.some Boolean
        next nextWords
  startWords = if n < 2 then [] else ['']
  next startWords

# Pick a sequence of token-words
pickTokenWords = (language, n, tokenCb) ->
  next = (prevTokenWords) ->
    pickTokenWord language, prevTokenWords, (tokenWord) ->
      [type, word] = tokenWord
      if stopped or type == null
        return
      tokenCb type, word
      # continue generating tokens until null token is reached
      nextTokenWords = last n-1, prevTokenWords.concat [tokenWord]
      next nextTokenWords
  startTokenWords = if n < 2 then [] else [[null]]
  next startTokenWords

# Pick a token type n-gram
pickTokenType = (language, prevTokens, cb) ->
  #console.log(language, prevTokens)
  start = [0, language].concat prevTokens
  pickNgram start, cb

# Pick a word n-gram for token text
pickWordToken = (language, tokenType, prevWords, cb) ->
  #console.log(tokenType, prevWords)
  start = [1, language, tokenType].concat prevWords
  pickNgram start, cb

# Pick an ngram for a word-token (word of a token type)
pickTokenWord = (language, prevTokenWords, cb) ->
  #console.log(tokenType, prevWords)
  start = [2, language].concat prevTokenWords
  pickNgram start, cb

# css stuff

# Return a space-delimited list of the css classes to apply to the element.
# from stratus-color/src/renderers/html.coffee
tokenTypeToClass = (type) ->
  return "" if !type
  scopes     = type.split "."
  cssClasses = []
  lastClass  = "hi"
  for scope in scopes
    lastClass = "#{ lastClass }-#{ scope }"
    cssClasses.push lastClass
  return cssClasses.join ' '

# form stuff

nSelect = document.getElementById 'n-select'
themeSelect = document.getElementById 'themes'
languagesSelect = document.getElementById 'languages'
reasonableSelect = document.getElementById 'reasonable-select'

form = document.getElementById 'generate'
themeLink = document.getElementById 'theme-link'
codes = document.getElementById 'codes'
reqsCounter = document.getElementById 'reqs-counter'
numRequestsText = reqsCounter.firstChild

form.addEventListener 'submit', (e) ->
  stopped = false
  e.preventDefault()
  generateCodeFile +nSelect?.value || 3
, false

form.addEventListener 'reset', (e) ->
  e.preventDefault()
  stopGenerating()
, false

themeSelect.addEventListener 'change', (e) ->
  themeLink.href = @value
, false

reasonableSelect.addEventListener 'change', (e) ->
  reasonable = @value == 'reasonable'
, false

# make an element for a code file with a given name
# return an element in which to put code
makeCodeFileElement = (name) ->
  outer = document.createElement 'div'
  outer.className = 'code stratus-color hi'

  nameEl = document.createElement 'div'
  nameEl.className = 'name'
  nameEl.appendChild document.createTextNode name
  outer.appendChild nameEl

  gutter = document.createElement 'div'
  gutter.className = 'stratus-color-gutter'
  outer.appendChild gutter

  inner = document.createElement 'ul'
  inner.className = ''
  outer.appendChild inner

  if codes.firstChild
    codes.insertBefore outer, codes.firstChild
  else
    codes.appendChild outer

  inner

