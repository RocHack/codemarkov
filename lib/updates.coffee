updates = module.exports

updates.code = (doc, req) ->
  if !doc
    if !req.id
      return [null, "missing id\n"]
    doc =
      _id: req.id
      type: 'code'
      name: req.id.substring 1 + req.id.lastIndexOf ':'
  if req.body
    doc.text = req.body
  else
    doc._deleted = true
  return [doc, "ok\n"]

