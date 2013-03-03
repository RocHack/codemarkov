fs = require 'fs'
themeToCSS = require '../views/lib/stratus-color/src/theme'
async = require '../packages/modules/node_modules/async'
kUtils = require '../packages/modules/node_modules/kanso-utils'
utils = kUtils.utils
attachments = kUtils.attachments

# where in file system to find theme json
themeDir = 'views/lib/stratus-color/themes'
# where in design doc to put theme css
themeCSSPath = 'theme/'
mainCSSPath = 'theme/main.css'

# root css class for themes
rootClass = 'hi'

# where to find syntax/language json
syntaxDir = 'syntax'

# Build the main CSS file for syntax highlighting
loadMainCSS = (doc, cb) ->
  themeToCSS.mainCSS (mainCSS) ->
    attachments.add doc, mainCSSPath, mainCSSPath, new Buffer mainCSS
    cb null

# Build CSS themes for the syntax highlighting
loadThemeCSS = (doc, cb) ->
  fs.readdir themeDir, (err, files) ->
    doc.themes = []
    # Load the themes
    for file in files
      theme = file.replace /\.json$/, ''
      themePath = themeCSSPath + theme + '.css'
      css = themeToCSS theme, root: rootClass
      if !css then return cb new Error 'Unable to build theme.', null
      attachments.add doc, themePath, themePath, new Buffer css
      # Save theme name and path to design doc for templates
      doc.themes.push
        value: theme
        path: themePath
    cb null

# Load syntax files into design document for the tokenizer view
loadLanguages = (doc, cb) ->
  utils.find syntaxDir, /syntax\.json$/, (err, files) ->
    if (err) then return cb err, doc
    async.map files, utils.readJSON, (err, languages) ->
      if !err
        # I don't think a view can directly access a design doc, but it
        # can require the data from a module in the view
        syntax = {}
        for lang in languages
          # Work around 'currentRules is undefined' bug in stratus-color 
          if lang.syntax?
            lang.syntax[lang.name] = lang.syntax['$']
            delete lang.syntax['$']
          syntax[lang.name] = lang
        # Put the JSON in the design doc as a module
        contents = 'module.exports = ' + JSON.stringify syntax
        doc.views.lib.languages = contents
      cb err, doc

module.exports =
  after: ['modules']
  run: (root, path, settings, doc, callback) ->
    async.parallel ([
      loadMainCSS
      loadThemeCSS
      loadLanguages
    ].map (fn) -> async.apply fn, doc),
    (err, results) ->
      callback err, doc

