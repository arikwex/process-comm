IPC = require('./index')

IPC.on('data', (data) ->
  IPC.write("#{data} to you too!")
)