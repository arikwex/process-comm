# Spawn Communication Library
## Purpose
Sometimes, you want your node application to spawn child processes.  This library makes communication with child processes easy with familiar API calls.

## API
### spawn (String command, String[ ] arguments, Object options)
Spawns a child process and returns a special "worker" object.  This API call routes directly to the child_process.spawn method.

### worker.on (String event, Function(payload) callback)
Registers an event listener for events emitted from the worker process.  The payload passed to the callback function is a parsed JSON object.

### worker.emit (String event, Object payload)
Triggers an event on the worker process with the given payload.  The payload is serialized as JSON.

### worker.write (Object message)
Syntactic sugar for worker.emit('data', message).

### worker.promise (String command, Object payload)
Makes a deferred call with given payload to the worker process and returns a promise object

### on (String event, Function(payload) callback)
Listens to events from the parent process.  The payload passed to the callback function is a parsed JSON object.

### emit (String event, Object payload)
Triggers an event on the parent process with the given payload.

### write (Object message)
Syntatic sugar for emit('data', message)

### defer (String command, Function(defer, payload) callback)
Configures this process to receive deferred requests for a particular command.  The callback will provide the deferred object for resolution, rejection, or notification, and the request payload.

### Reserved Events Names
- **data** is used by the "write" convenience method
- **close** is used to indicate that the worker process has exited
- **promise** is used to signal promise resolutions
- **defer** is used to signal deferred request
- **error** is published via the stderr stream of the worker process

## Examples
### Echo Client
```coffeescript
### PARENT PROCESS ###
IPC = require('process-comm')
worker = IPC.spawn('node', ['worker.js'], cwd: process.cwd())

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
  worker = IPC.spawn('node', ['worker.js'], cwd: process.cwd())
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
worker = IPC.spawn('node', ['worker.js'], cwd: process.cwd())

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
