sysPath = require 'path'
fs = require 'fs'

SIMPLE_FILE = fs.realpathSync(sysPath.join __dirname, 'app', 'simple.yml')
COMPLEX_FILE = fs.realpathSync(sysPath.join __dirname, 'app', 'complex.yml')
DEEP_FILE = fs.realpathSync(sysPath.join __dirname, 'app', 'config', 'deeper', 'other.yml')
LOADER_FILE = fs.realpathSync(sysPath.join __dirname, '..', 'src', 'loader.js')
LOADER_SOURCE = fs.readFileSync LOADER_FILE, encoding: 'utf8'

f = (file) -> fs.readFileSync file, encoding: 'utf8'


fake = (source, context = {}) ->
  module = {}
  eval "(function () { #{LOADER_SOURCE} #{source} return context; }).apply(context);"
  module


describe 'Basic plugin behavdiour', ->
  it 'should be defined', ->
    expect(Plugin).to.be.ok

  it 'should not fail if no config', ->
    expect(-> new Plugin).to.not.throw()

  it 'should have correct default settings', ->
    plugin = new Plugin()
    expect(plugin.jsPathForFile).to.be.a 'function'
    expect(plugin.jsPathForFile 'app/hello.yml', ['app', 'hello']).to.be.null

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
  setOnContext = null

  beforeEach ->
    setOnContext = no
    plugin = new Plugin extendedYaml: jsPathForFile: (path, parts) -> if setOnContext then parts else null

  afterEach ->
    plugin = null


  it 'should define the data on the window with just altering window', (done) ->
    setOnContext = yes
    plugin.compile f(SIMPLE_FILE), SIMPLE_FILE, (error, compiled) ->
      expect(compiled).to.equal 'module.exports=this.yamlBrunch("test.app.simple", {"config":true});\n'
      checker = {}
      oldWin = win = {check: checker}
      mod = fake compiled, win
      expect(win).to.have.property 'yamlBrunch'
      expect(win).to.equal oldWin
      expect(win).to.have.deep.property 'test.app.simple', mod.exports
      expect(win.check).to.equal checker
      done()


  it 'should not define the data on the window, just on module.exports', (done) ->
    plugin.compile f(SIMPLE_FILE), SIMPLE_FILE, (error, compiled) ->
      expect(compiled).to.equal 'module.exports=this.yamlBrunch(null, {"config":true});\n'
      win = {}
      mod = fake compiled, win
      # be sure it has only the yamlBrunch property
      expect(win).to.be.an 'object'
      expect(Object.keys win).to.eql ['yamlBrunch']
      expect(mod.exports).to.have.property 'config', yes
      done()


  it 'should compile simple files', (done) ->
    plugin.compile f(SIMPLE_FILE), SIMPLE_FILE, (error, compiled) ->
      expect(compiled).to.equal 'module.exports=this.yamlBrunch(null, {"config":true});\n'
      mod = fake compiled
      expect(mod.exports).to.have.property 'config', yes
      done()

  it 'should compile deeper files', (done) ->
    setOnContext = yes
    plugin.compile f(DEEP_FILE), DEEP_FILE, (error, compiled) ->
      expect(compiled).to.equal 'module.exports=this.yamlBrunch("test.app.config.deeper.other", {"just":{"some":"yaml"}});\n'
      win = {}
      mod = fake compiled, win
      expect(mod.exports).to.have.deep.property 'just.some', 'yaml'
      expect(win).to.have.deep.property 'test.app.config.deeper.other.just.some', 'yaml'
      done()

  it 'should compile complex yaml files', (done) ->
    plugin.compile f(COMPLEX_FILE), COMPLEX_FILE, (error, compiled) ->
      expect(compiled).to.equal 'module.exports=this.yamlBrunch(null, {"all":{"someArray":["registered","canSendEmails"],"someBool":true,"someDate":new Date("2001-12-15T02:59:43.100Z"),"someString":"hello","someFunction":function anonymous() {\n\n  return \'hello\';\n\n},"someRegexp":/^hello$/i,"someUndefined":undefined}});\n'
      mod = fake compiled
      expect(mod.exports).to.have.property 'all'
      complex = mod.exports.all
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
      expect(Object.keys complex).to.include 'someUndefined'
      expect(complex.someUndefined).to.be.undefined
      done()
