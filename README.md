###########################################
### INTER-PROCESS COMMUNICATION LIBRARY ###
###########################################

##################################
# Example: Inter-process channel #
##################################

### PARENT PROCESS ###
IPC = require('process-comm')
worker = IPC.spawn('node worker.js')

worker.on('data', (data) ->
  console.log("Worker process says: #{data}")
)
worker.write('hello')

### WORKER PROCESS ###
IPC = require('process-comm')
IPC.on('data', (data) ->
  IPC.write("#{data} to you too!")
)

##################################
# Example: Inter-process promise #
##################################

### PARENT PROCESS ###
IPC = require('process-comm')
worker = IPC.spawn('node worker.js')

p = worker.promise('add',
  A: 123
  B: 456
)

q = worker.promise('mul',
  A: 123
  B: 456
)

p.then((data) ->
  console.log("response: #{data}")
).catch((err) ->
  console.log("error: #{err}")
).always((data) ->
  console.log("always: #{data}")
)

q.then((data) ->
  console.log("response: #{data}")
).catch((err) ->
  console.log("error: #{err}")
).always((data) ->
  console.log("always: #{data}")
)

### WORKER PROCESS ###
IPC = require('process-comm')
IPC.on('defer', (defer, cmd, data) ->
  if cmd  == 'add'
    defer.resolve(data.A + data.B)
  else
    defer.reject('fail')
)

########################################
# Example: Inter-process event emitter #
########################################

### PARENT PROCESS ###
IPC = require('process-comm')
serialport = IPC.spawn('node serialport.js')

serialport.on('open', ->
  console.log('serialport open')
)
serialport.on('close', ->
  console.log('serialport closed')
)
serialport.on('data', (data) ->
  console.log("serialport data: #{data}")
)
setTimeout(->
  serialport.emit('finished')
, 5000)

### WORKER PROCESS ###
serialport = require('serialport')
IPC = require('process-comm')

serialport.on('open', -> IPC.emit('open'))
serialport.on('close', -> IPC.emit('close'))
serialport.on('data', (data) -> IPC.trigger('data', data))

serialport.connect('/dev/ttyO0', 9600)

IPC.on('finished', (data) ->
  IPC.write("#{data} to you too!")
)