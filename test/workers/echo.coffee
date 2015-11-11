IPC = require('../../process-comm')

IPC.on('data', (data) ->
  IPC.write(data)
)