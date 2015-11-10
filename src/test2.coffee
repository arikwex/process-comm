IPC = require('./index')

makeWorker = ->
  console.log('Requesting new worker...')
  _ival = null
  worker = IPC.spawn('node', ['dist/worker2.js'], cwd: process.cwd())
  worker.on('open', ->
    console.log('worker open')
  )
  worker.on('log', (data) ->
    console.log("worker log: #{data}")
  )
  worker.on('close', ->
    console.log('worker closed')
    clearInterval(_ival)
    makeWorker()
  )
  _ival = setInterval(->
    worker.emit('apply_data', ('' + Math.random()).toString(16).substring(2))
  , 250)

makeWorker()