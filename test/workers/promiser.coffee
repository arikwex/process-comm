IPC = require('../../process-comm')

IPC.defer('resolving-request', (defer, data) ->
  defer.resolve(data)
)

IPC.defer('rejecting-request', (defer, data) ->
  defer.reject(data)
)

IPC.defer('notifying-request', (defer, data) ->
  defer.notify('33%')
  defer.notify('70%')
  defer.notify('100%')
  defer.resolve(data)
)

IPC.defer('early-stop', (defer, data) ->
  process.exit()
)