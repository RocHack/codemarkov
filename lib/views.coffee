views = module.exports

views.code_ngrams =
  map: (doc) ->
    if doc.type == 'code' && !doc.ignore
      ngrams = require 'views/lib/ngrams'
      ngrams.map doc
  reduce: '_count'
