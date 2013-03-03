
ddoc =
  views: require './views'
  lists: require './lists'
  rewrites: require './rewrites'
  updates: require './updates'
  validate_doc_update: require './validate'

module.exports = ddoc

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

couchapp.loadAttachments ddoc, (path.join __dirname, '_attachments')
###

