Search = (db) ->
  db.search = (keyword, callback) ->
    results = []
    console.log keyword
    stream = db.createValueStream()
    pattern=new RegExp(".*" + keyword + ".*", "ig")
    stream.on 'data', (data) ->
      console.log data
      for key, value of data
        if pattern.test value
          callback data
          break

exports.search = Search