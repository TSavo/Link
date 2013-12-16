Search = (db) ->
  db.search = (keyword, callback) ->
    results = []
    stream = db.createValueStream()
    pattern=new RegExp(".*" + keyword + ".*", "ig")
    stream.on 'data', (data) ->
      for key, value of data
        if pattern.test value
          results.push data
          break
    stream.on "close", ()->
      callback results

exports.search = Search