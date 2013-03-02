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
  r.send null

encodeObject = (arg) ->
  encodeURIComponent JSON.stringify arg

encodeForm = (obj) ->
  (encodeURIComponent(key) + '=' + encodeURIComponent JSON.stringify val \
    for own key, val of obj) .join "&"

stopped = false

# Pick a file name and language
generateFileType = (cb) ->
  # Pick random language
  pickNgram [0], (langName) ->
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
        lineEl = document.createElement 'li'
        codeEl.appendChild lineEl
        (gutter.appendChild document.createElement 'span')
        .appendChild document.createTextNode lineNum++

    # start first line
    newLines()

    # pick tokens
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
        pickTokenWords langName, tokenType, n, (word) ->
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
  loadJSON '../_view/code_ngrams',
    startkey: prefix
    endkey: endkey
  , (res) ->
    max = res?.rows[0]?.value
    index = max * Math.random()

    # Optimization: if the index is in the second half, reverse the
    # query and we will iterate on average half as far
    descending = index > max/2
    if descending
      tmp = startkey
      startkey = endkey
      endkey = tmp
      index = max - index

    loadJSON '../_list/pick_ngram/code_ngrams',
      group_level: prefix.length+1
      i: index
      startkey: startkey
      endkey: endkey
      descending: descending
    , (ngram) -> cb ngram?[ngram.length-1]

# Pick a sequence of token types (n>=1)
pickTokenTypes = (language, n, tokenCb) ->
  next = (prevTokenTypes) ->
    pickTokenType language, n, prevTokenTypes, (tokenType) ->
      tokenCb tokenType
      nextTokenTypes = prevTokenTypes[1..].concat tokenType
      # continue generating tokens until reached n-1 newlines
      if !stopped and !nextTokenTypes.every isNewline
        next nextTokenTypes
  startTokens = if n < 2 then [] else [0..n-2].map -> 'newline'
  next startTokens

# Pick a sequence of words for token contents
pickTokenWords = (language, tokenType, n, wordCb) ->
  next = (prevWords) ->
    pickTokenWord language, tokenType, n, prevWords, (word) ->
      wordCb word if word
      nextWords = prevWords[1..].concat word
      # continue generating words until reached n-1 blanks
      if !stopped and nextWords.some Boolean
        next nextWords
  startWords = if n < 2 then [] else [0..n-2].map -> ''
  next startWords

# Pick a token type n-gram
pickTokenType = (language, n, prevTokens, cb) ->
  #console.log(language, prevTokens)
  start = [0, language].concat prevTokens
  pickNgram start, cb

# Pick a word n-gram for token text
pickTokenWord = (language, tokenType, n, prevWords, cb) ->
  #console.log(tokenType, prevWords)
  start = [1, language, tokenType].concat prevWords
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

form = document.getElementById 'generate'
nSelect = document.getElementById 'n-select'
themeSelect = document.getElementById 'theme-select'
themeLink = document.getElementById 'theme-link'
codes = document.getElementById 'codes'

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
  themeLink.href = "../theme/#{this.value}.css"
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

