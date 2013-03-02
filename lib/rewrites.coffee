module.exports = [
  from: ''
  to: 'static/index.html'
,
  from: 'static/*'
  to: 'static/*'
,
  from: 'theme/*'
  to: 'theme/*'
,
  from: 'ngrams/:thing'
  to: '_list/:thing/code_ngrams'
]
