lists = module.exports

# Pick a random ngram weighted by frequency.
lists.pick = (head, req) ->
  provides 'json', ->
    allowEmpty = !('nonempty' in req.query)

    # Two modes. If chosenIndex is null, read all rows and pick a random
    # one. If chosenIndex is a number, read up to the row with that
    # cumulative value, and return it.
    chosenNgram = null
    chosenIndex = req.query.i
    random = chosenIndex == null

    total = 0
    rows = []
    while row = getRow()
      if allowEmpty || row.key.some Boolean
        total += row.value
        if random
          row.cumulative = total
          rows.push row
        else if total > chosenIndex
          chosenNgram = row.key
          break

    if !chosenNgram
      chosenIndex = Math.random() * total
      for row in rows
        if row.cumulative > chosenIndex
          chosenNgram = row.key
          break

    JSON.stringify chosenNgram

# Count ngrams
lists.count = (head, req) ->
  provides 'json', ->
    (+getRow()?.value || 0).toString()

