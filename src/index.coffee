fs = require 'fs'
sysPath = require 'path'
yaml = require 'js-yaml'



isSubclassOf = (subclass, baseClass) ->
  Boolean(subclass?.prototype instanceof baseClass)

TYPE_MAP = {}
for name in 'Boolean Number String Function Array Date RegExp Object'.split(' ')
  TYPE_MAP["[object #{name}]"] = name.toLowerCase()

toString = Object::toString

typeOf = (item) ->
  ret = if (item is null or item is `undefined`) then String(item) else TYPE_MAP[toString.call item] or 'object'
  if ret is 'function'
    ret = 'class' if isSubclassOf(item, Object)
  else if ret is 'object'
    if item instanceof Error
      ret = 'error'
    else if item instanceof Date
      ret = 'date'
  ret


class YamlCompiler
  @instance: null

  brunchPlugin: yes
  type: 'javascript'
  extension: 'yml'
  pattern: /\.ya?ml$/

  destination: null
  jsPathForFile: null



  constructor: (@config = {}) ->
    YamlCompiler.instance = @
    conf = @config.yaml ? {}
    dst = conf.destination ? ''
    dst = dst.split('.').slice(1).join('.') if /^window(?:\.|$)/.test(dst)
    @destination = (part for part in dst.split('.') when part isnt '')
    @jsPathForFile = conf.jsPathForFile ? (path) -> path


  serialize: (object) ->
    type = typeOf object
    switch type
      when 'null', 'undefined' then type
      when 'number', 'string' then JSON.stringify object
      when 'date' then "new Date(#{JSON.stringify object.toISOString()})"
      when 'regexp' then object.toString()
      when 'error' then "new Error(#{JSON.stringify object.message})"
      when 'array' then "[#{(@serialize item for item in object).join ','}]"
      when 'object' then '{' + ("#{JSON.stringify key}:#{@serialize value}" for key, value of object).join(',') + '}'
      else object.toString()


  include: ->
    [sysPath.join __dirname, 'loader.js']


  rootPath: ->
    @_rootPath ?= fs.realpathSync(process.cwd())


  pathToArray: (path) ->
    path.split('.').slice(0, -1).join('.').substr(@rootPath().length + 1).split sysPath.sep


  compile: (data, path, callback) ->
    dst = @destination.concat @jsPathForFile(@pathToArray path)
    doc = yaml.load data, strict: yes
    callback null, "!this.yamlBrunch(#{JSON.stringify dst.join('.')}, #{@serialize doc});\n"


module.exports = YamlCompiler