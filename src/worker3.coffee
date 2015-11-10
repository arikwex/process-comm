IPC = require('./index')

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