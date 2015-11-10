IPC = require('./index')
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