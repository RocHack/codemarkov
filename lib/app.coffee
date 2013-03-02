
ddoc =
  views: require './views'
  lists: require './lists'
  rewrites: require './rewrites'

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

ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->
  require(field, message) ->
    message ||= "Document must have a " + field
    if !newDoc[field] then throw forbidden: message

  if newDoc.type == "person"
    require "name"

couchapp.loadAttachments ddoc, (path.join __dirname, '_attachments')
###

