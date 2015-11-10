# Spawn Communication Library

## Examples
### Echo Client
```coffeescript
### PARENT PROCESS ###
IPC = require('process-comm')
worker = IPC.spawn('node', ['dist/worker.js'], cwd: process.cwd())

worker.on('data', (data) ->
  console.log("Worker process says: #{data}")
)
worker.write('hello')
```
```coffeescript
### WORKER PROCESS ###
IPC = require('process-comm')
IPC.on('data', (data) ->
  IPC.write("#{data} to you too!")
)
```

### Events
```coffeescript
### PARENT PROCESS ###
IPC = require('process-comm')

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
```
```coffeescript
### WORKER PROCESS ###
IPC = require('process-comm')
open = false

setTimeout(->
  open = true
  IPC.emit('open', 1000)
, 500)

IPC.on('apply_data', (data) ->
  if open
    IPC.emit('log', "Sent: #{data}")
)

setTimeout(->
  process.exit()
, 2000)
```

### Promises
```coffeescript
### PARENT PROCESS ###
IPC = require('process-comm')
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
```
```coffeescript
### WORKER PROCESS ###
IPC = require('process-comm')

IPC.defer('add', (defer, params) ->
  for i in [1..10]
    defer.notify("#{i * 10}%")
  defer.resolve(params.A + params.B)
)

IPC.defer('mul', (defer, params) ->
  for i in [1..10]
    defer.notify("#{i * 10}%")
  defer.resolve(params.A * params.B)
)
```
