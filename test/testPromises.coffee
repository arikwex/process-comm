assert = require('chai').assert
IPC = require('../process-comm')

describe('Deferred spawn requests', ->
  worker = null

  beforeEach( ->
    worker = IPC.spawn('node', ['dist/test/workers/promiser.js'])
  )

  afterEach( ->
     worker?.free()
  )

  it('can be resolved', (done) ->
    worker.promise('resolving-request')
      .then(-> done())
      .catch(-> done('Should have been resolved'))
  )

  it('can be rejected', (done) ->
    worker.promise('rejecting-request')
      .then(-> done('Should have been rejected'))
      .catch(-> done())
  )

  it('can receive progress notifications', (done) ->
    count = 0
    worker.promise('notifying-request')
      .then(->
        assert.equal(count, 3, 'Expected 3 notifications before resolution')
        done()
      ).catch(->
        done('error')
      ).notify((data) ->
        count++
      )
  )

  it('will reject unregistered deferred requests', (done) ->
    worker.promise('unregistered-request')
      .then(-> done('Should have been rejected'))
      .catch(-> done())
  )

  it('will reject promises if the spawn closes', (done) ->
    worker.promise('early-stop')
      .then(-> done('Should have been rejected'))
      .catch(-> done())
  )
)