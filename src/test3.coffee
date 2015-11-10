IPC = require('./index')
worker = IPC.spawn('node', ['dist/worker3.js'], cwd: process.cwd())

worker.on('log', (data) ->
  console.log(data)
)

p = worker.promise('add',
  A: 123
  B: 456
)

console.log('I can multitask!')

q = worker.promise('mul',
  A: 123
  B: 456
)

p.then((data) ->
  console.log("response add: #{data}")
).catch((err) ->
  console.log("error add: #{err}")
).notify((progress) ->
  console.log("notify add: #{progress}")
)

q.then((data) ->
  console.log("response mul: #{data}")
).catch((err) ->
  console.log("error mul: #{err}")
).notify((progress) ->
  console.log("notify mul: #{progress}")
)