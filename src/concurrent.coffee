class ThreadBarrier
  constructor: (@parties, @block) ->
    
  join: (args...)->
    --@parties
    if @parties < 1
      @block args...
    

class Semaphore
  constructor: ->
    @waiting = []
    @inUse = false

  acquire: (block) ->
    if @inUse
      @waiting.push block
    else
      @inUse = true
      block()
      
  release: ->
    if @waiting.length > 0
      @waiting.shift()()
    else
      @inUse = false
   
exports.ThreadBarrier = ThreadBarrier
exports.Semaphore = Semaphore