fs = require 'fs'
async = require '../packages/modules/node_modules/async'
utils = (require '../packages/modules/node_modules/kanso-utils').utils

dir = 'syntax'

# Load syntax files into design document for the tokenizer view
module.exports =
  after: 'modules'
  run: (root, path, settings, doc, callback) ->
    utils.find dir, /syntax\.json$/, (err, files) ->
      if (err) then return callback err, doc
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
          contents = 'module.exports = ' + JSON.stringify syntax
          doc.views.lib.languages = contents
        callback err, doc
