IPC = require('./index')
worker = IPC.spawn('node', ['dist/worker.js'], cwd: process.cwd())

worker.on('data', (data) ->
  console.log("Worker process says: #{data}")
)
worker.write('hello')