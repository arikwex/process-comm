IPC = require('../../process-comm')

a = undefined
b = undefined

IPC.on('A', (x) -> a = x)
IPC.on('B', (x) -> b = x)
IPC.on('compute', ->
  IPC.emit('result', a + b)
)