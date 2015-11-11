assert = require('chai').assert
IPC = require('../process-comm')

describe('Channel message passing', ->
  it('can send and receive data from spawned process', (done) ->
    worker = IPC.spawn('node', ['dist/test/workers/echo.js'])
    worker.on('data', (data) ->
      assert.equal(data, 'hello', 'Echo text does not match')
      done()
    )
    worker.write('hello')
  )

  it('can invoke custom events on the spawned process', (done) ->
    worker = IPC.spawn('node', ['dist/test/workers/adder.js'])
    worker.on('result', (data) ->
      assert.equal(data, 35, 'Adder worker returned wrong result')
      done()
    )
    worker.emit('A', 15)
    worker.emit('B', 20)
    worker.emit('compute')
  )

  it('can send and receive json payloads', (done) ->
    worker = IPC.spawn('node', ['dist/test/workers/echo.js'])
    msg =
      demo: 123
      colors: ['red', 'green', 'blue']
      coordinates:
        lat: 12.34
        lng: 56.78
    worker.on('data', (data) ->
      assert.deepEqual(msg, data, 'Echo json does not match')
      done()
    )
    worker.emit('data', msg)
  )
)