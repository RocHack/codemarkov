module.exports = [
  from: ''
  to: '_list/home/code_ngrams'
  query:
    group_level: '2'
    startkey: [0]
    endkey: [1]
    stale: 'ok'
,
  from: 'static/*'
  to: 'static/*'
,
  from: 'theme/*'
  to: 'theme/*'
,
  from: 'ngrams/:thing'
  to: '_list/:thing/code_ngrams'
,
  method: 'PUT'
  from: 'code/:id'
  to: '_update/code/:id'
]
