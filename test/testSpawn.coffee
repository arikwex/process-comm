assert = require('chai').assert
IPC = require('../process-comm')

describe('Worker spawn', ->
  it('can be created', ->
    worker = IPC.spawn('node', ['dist/test/workers/breif.js'])
    assert.isTrue(worker.isAlive(), 'should be alive')
  )

  it('will emit a close event when done working', (done) ->
    worker = IPC.spawn('node', ['dist/test/workers/breif.js'])
    worker.on('close', ->
      assert.ok('Worker spawn finished')
      done()
    )
  )

  it('can be destroyed', ->
    worker = IPC.spawn('node', ['dist/test/workers/spin.js'])
    worker.free()
    assert.isFalse(worker.isAlive(), 'should be destroyed')
  )

  it('will emit a close event when destroyed', (done) ->
    worker = IPC.spawn('node', ['dist/test/workers/spin.js'])
    worker.on('close', ->
      assert.ok('Destroyed worker spawn')
      done()
    )
    worker.free()
  )
)