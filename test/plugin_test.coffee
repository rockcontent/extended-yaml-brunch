sysPath = require 'path'
fs = require 'fs'

SIMPLE_FILE = fs.realpathSync(sysPath.join __dirname, 'app', 'simple.yml')
COMPLEX_FILE = fs.realpathSync(sysPath.join __dirname, 'app', 'complex.yml')
DEEP_FILE = fs.realpathSync(sysPath.join __dirname, 'app', 'config', 'deeper', 'other.yml')
LOADER_FILE = fs.realpathSync(sysPath.join __dirname, '..', 'src', 'loader.js')
LOADER_SOURCE = fs.readFileSync LOADER_FILE, encoding: 'utf8'

f = (file) -> fs.readFileSync file, encoding: 'utf8'


fake = (source, context = {}) ->
  eval "(function () { #{LOADER_SOURCE} #{source} return context; }).apply(context);"


describe 'Basic plugin behavdiour', ->
  it 'should be defined', ->
    expect(Plugin).to.be.ok

  it 'should not fail if no config', ->
    expect(-> new Plugin).to.not.throw()

  it 'should have correct default settings', ->
    plugin = new Plugin()
    expect(plugin.destination).to.be.an 'array'
    expect(plugin.destination).to.have.length 0
    expect(plugin.jsPathForFile).to.be.a 'function'
    expect(plugin.jsPathForFile ['app', 'hello']).to.eql ['app', 'hello']

  it 'should include the loader', ->
    plugin = new Plugin()
    loader = plugin.include()
    expect(loader).to.be.an 'array'
    expect(loader).to.have.length 1
    loader = loader.pop()
    expect(loader).to.equal LOADER_FILE
    expect(fs.existsSync loader).to.be.true


describe 'Compiling files', ->
  plugin = null

  beforeEach ->
    plugin = new Plugin()

  afterEach ->
    plugin = null

  it 'should compile simple files', (done) ->
    plugin.compile f(SIMPLE_FILE), SIMPLE_FILE, (error, compiled) ->
      expect(compiled).equal '!this.yamlBrunch("test.app.simple", {"config":true});\n'
      win = fake compiled
      expect(win).to.have.property 'yamlBrunch'
      expect(win).to.have.deep.property 'test.app.simple.config', yes
      done()

  it 'should compile deeper files', (done) ->
    plugin.compile f(DEEP_FILE), DEEP_FILE, (error, compiled) ->
      expect(compiled).equal '!this.yamlBrunch("test.app.config.deeper.other", {"just":{"some":"yaml"}});\n'
      win = fake compiled
      expect(win).to.have.property 'yamlBrunch'
      expect(win).to.have.deep.property 'test.app.config.deeper.other.just.some', 'yaml'
      done()

  it 'should compile complex yaml files', (done) ->
    plugin.compile f(COMPLEX_FILE), COMPLEX_FILE, (error, compiled) ->
      expect(compiled).equal '!this.yamlBrunch("test.app.complex", {"all":{"someArray":["registered","canSendEmails"],"someBool":true,"someDate":new Date("2001-12-15T02:59:43.100Z"),"someString":"hello","someFunction":function anonymous() {\n\n  return \'hello\';\n\n},"someRegexp":/^hello$/i,"someUndefined":undefined}});\n'
      win = fake compiled
      expect(win).to.have.property 'yamlBrunch'
      expect(win).to.have.deep.property 'test.app.complex.all'
      complex = win.test.app.complex.all
      expect(complex.someArray).to.be.an 'array'
      expect(complex.someArray).to.eql ["registered","canSendEmails"]
      expect(complex).to.have.property 'someBool', yes
      expect(complex.someDate).to.be.a 'date'
      expect(complex.someDate.getTime()).to.equal 1008385183100
      expect(complex).to.have.property 'someString', 'hello'
      expect(complex.someFunction).to.be.a 'function'
      expect(complex.someFunction()).to.equal 'hello'
      expect(complex.someRegexp).to.be.instanceOf RegExp
      expect(complex.someRegexp.toString()).to.equal '/^hello$/i'
      expect(complex.someUndefined).to.be.undefined
      done()
