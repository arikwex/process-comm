q = require('q')
{spawn} = require('child_process')
{EventEmitter} = require('events')

processEvents = new EventEmitter()
processDefers = {}

# Spawn child process and return a special process-comm wrapped object
exports.spawn = (command, args, options) ->
  connectionOpen = true
  workerSpawn = spawn(command, args, options)
  workerEvents = new EventEmitter()
  workerDefers = {}
  workerDeferCode = 0

  emitLines(workerSpawn.stdout)
  emitLines(workerSpawn.stderr)
  workerSpawn.stdout.on('line', (buf) ->
    pkg = openPackage(String(buf))
    if pkg?
      workerEvents.emit(pkg.type, pkg.params, pkg.code)
    return
  )
  workerSpawn.stderr.on('line', (buf) ->
    if buf.length > 0
      workerEvents.emit('error', String(buf))
    return
  )
  workerSpawn.stdout.on('close', ->
    workerEvents.emit('close')
    connectionOpen = false
    workerEvents.removeAllListeners()
  )

  worker =
    write: (msg) ->
      worker.emit('data', msg)
      return
    on: (type, callback) ->
      if connectionOpen
        workerEvents.on(type, callback)
      return
    emit: (type, msg) ->
      if connectionOpen
        pkg = makePackage(type, msg)
        workerSpawn.stdin.write(pkg + '\n')
      return
    promise: (cmd, params) ->
      d = q.defer()
      if connectionOpen
        workerDefers[workerDeferCode] = d
        worker.emit('defer',
          code: workerDeferCode
          cmd: cmd
          params: params
        )
        workerDeferCode++
      else
        d.reject('spawn closed')
      p = {}
      notifyCallback = ->
      p.notify = (callback) ->
        notifyCallback = callback
        return p
      p.then = (callback) ->
        d.promise.then(callback)
        return p
      p.catch = (callback) ->
        d.promise.catch(callback)
        return p
      p.always = (callback) ->
        d.promise.then(callback)
        d.promise.catch(callback)
        return p
      d.promise.then(null, null, (msg) ->
        notifyCallback(msg)
      )
      return p

  worker.on('promise', (msg) ->
    code = msg.code
    cmd = msg.cmd
    if workerDefers[code]?
      if cmd == 'resolve'
        workerDefers[code].resolve(msg.params)
        delete workerDefers[code]
      else if cmd == 'reject'
        workerDefers[code].reject(msg.params)
        delete workerDefers[code]
      else if cmd == 'notify'
        workerDefers[code].notify(msg.params)
      else
        worker.emit('error', "Invalid promise command '#{cmd}' for code #{code}")
    else
      worker.emit('error', "Promise code #{code} is not identified")
    return
  )
  return worker

# Publish a message to the stdout stream
exports.write = (msg) ->
  exports.emit('data', msg)
  return

# Register an event listener for stdin stream
exports.on = (type, callback) ->
  processEvents.on(type, callback)
  return

# Emit an event on stdout stream
exports.emit = (type, payload) ->
  pkg = makePackage(type, payload)
  process.stdout.write(pkg + '\n')
  return

# Configures a deferred listener
exports.defer = (cmd, callback) ->
  processDefers[cmd] = callback
  return

# Acquired from:
# http://stackoverflow.com/questions/9962197/node-js-readline-not-waiting-for-a-full-line-on-socket-connections/10012306#10012306
emitLines = (stream) ->
  backlog = ''
  stream.on('data', (data) ->
    backlog += data
    n = backlog.indexOf('\n')
    while ~n
      stream.emit('line', backlog.substring(0, n))
      backlog = backlog.substring(n + 1)
      n = backlog.indexOf('\n')
  )
  stream.on('end', ->
    if backlog
      stream.emit('line', backlog)
  )
  return

# Create an external defer object wrapper
externalDefer = (code) ->
  done = false
  transmit = (type, canClose)->
    return (msg) ->
      if not done
        exports.emit('promise',
          code: code
          cmd: type
          params: msg
        )
        done = canClose
      return
  return {
    resolve: transmit('resolve', true)
    reject: transmit('reject', true)
    notify: transmit('notify', false)
  }

# Packages a json message for a particular channel type
makePackage = (type, msg) ->
  pkg =
    type: type
    params: msg
  return JSON.stringify(pkg)

# Unpacakages a json message
openPackage = (json) ->
  try
    pkg = JSON.parse(json)
    if not pkg.type? or not pkg.params?
      return null
    return pkg
  catch e
    return null

# Configure this process
emitLines(process.stdin)
process.stdin.on('line', (buf) ->
  pkg = openPackage(String(buf))
  if pkg?
    processEvents.emit(pkg.type, pkg.params, pkg.code)
  return
)

# Configure deferred requests
exports.on('defer', (msg) ->
  code = msg.code
  cmd = msg.cmd
  if processDefers[cmd]?
    ed = externalDefer(code)
    processDefers[cmd](ed, msg.params)
  else
    exports.emit('promise',
      code: code
      cmd: 'reject'
      params: "No deferred listener '#{cmd}' configured on remote process"
    )
)



