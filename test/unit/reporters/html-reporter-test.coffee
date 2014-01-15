{assert} = require 'chai'
sinon = require 'sinon'
proxyquire = require('proxyquire').noCallThru()

{EventEmitter} = require 'events'
loggerStub = require '../../../src/logger'
fsStub = require 'fs'

HtmlReporter = proxyquire '../../../src/reporters/html-reporter', {
  './../logger' : loggerStub
  'fs' : fsStub
}

emitter = new EventEmitter()
stats =
  tests: 0
  failures: 0
  errors: 0
  passes: 0
  skipped: 0
  start: 0
  end: 0
  duration: 0
tests = []
htmlReporter = new HtmlReporter(emitter, stats, tests)

describe 'HtmlReporter', () ->

  test = {}

  it 'should call the start method', (done) ->
    emitter.emit 'start'
    done()

  describe 'when starting', () ->

    describe 'when file exists', () ->
      before () ->
        sinon.stub fsStub, 'existsSync', (path) ->
          return true
        sinon.stub fsStub, 'unlinkSync'

      after () ->
        fsStub.existsSync.restore()
        fsStub.unlinkSync.restore()
        emitter.removeAllListeners()

      it 'should delete the existing file', (done) ->
        reporter = new HtmlReporter(emitter, {}, {}, "test.html")
        assert.ok fsStub.unlinkSync.calledOnce
        done()

    describe 'when file does not exist', () ->

      before () ->
        sinon.stub fsStub, 'existsSync', (path) ->
          return false
        sinon.stub fsStub, 'unlinkSync'

      after () ->
        fsStub.existsSync.restore()
        fsStub.unlinkSync.restore()
        emitter.removeAllListeners()

      it 'should delete the existing file', (done) ->
        reporter = new HtmlReporter(emitter, {}, {}, "test.html")
        assert.ok fsStub.unlinkSync.notCalled
        done()

  describe 'when ending', () ->

    before () ->
      stats.tests = 1

    beforeEach () ->
      sinon.stub fsStub, 'writeFile', (path, data, callback) ->
        callback()

    afterEach () ->
      fsStub.writeFile.restore()

    it 'should write the file', (done) ->
      reporter = new HtmlReporter(emitter, {}, {}, "test.html")
      emitter.emit 'end', () ->
        done()

  describe 'when test passes', () ->

    before () ->
      test =
        status: 'pass'
        title: 'Passing Test'

    it 'should call the pass event', (done) ->
      reporter = new HtmlReporter(emitter, {}, {}, "test.html")
      emitter.emit 'test start', test
      emitter.emit 'test pass', test
      assert.ok ~reporter.buf.indexOf 'Pass'
      done()

    describe 'when details=true', () ->

      it 'should write details for passing tests', (done) ->
        reporter = new HtmlReporter(emitter, {}, {}, "test.html")
        reporter.details = true
        emitter.emit 'test pass', test
        assert.ok ~reporter.buf.indexOf 'Request'
        done()

  describe 'when test is skipped', () ->
    before () ->
      test =
        status: 'skipped'
        title: 'Skipped Test'

    it 'should call the skip event', (done) ->
      reporter = new HtmlReporter(emitter, {}, {}, "test.html")
      emitter.emit 'test start', test
      emitter.emit 'test skip', test
      assert.ok ~reporter.buf.indexOf 'Skip'
      done()

  describe 'when test fails', () ->

    before () ->
      test =
        status: 'failed'
        title: 'Failed Test'

    it 'should call the fail event', (done) ->
      reporter = new HtmlReporter(emitter, {}, {}, "test.html")
      emitter.emit 'test start', test
      emitter.emit 'test fail', test
      assert.ok ~reporter.buf.indexOf 'Fail'
      done()

  describe 'when test errors', () ->

    before () ->
      test =
        status: 'error'
        title: 'Errored Test'

    it 'should call the error event', (done) ->
      reporter = new HtmlReporter(emitter, {}, {}, "test.html")
      emitter.emit 'test start', test
      emitter.emit 'test error', new Error('Error'), test
      assert.ok ~reporter.buf.indexOf 'Error'
      done()

