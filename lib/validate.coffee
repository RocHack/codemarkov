valid_roles = ['_admin', 'codemarkov']

module.exports = (newDoc, oldDoc, userCtx) ->

  if !valid_roles.some ((role) -> role in userCtx.roles)
    throw unauthorized: 'No permission'

  if newDoc.type == 'code' && !newDoc._deleted
    name = newDoc.name
    if !name
      throw forbidden: 'Document must have a name'

    if !newDoc.text
      throw forbidden: 'Document must have a text'

    id = newDoc._id
    if id.lastIndexOf(name) != id.length - name.length && !newDoc._deleted
      throw forbidden: 'Document id must end in name'

