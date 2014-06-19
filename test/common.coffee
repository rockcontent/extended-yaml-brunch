chai = require 'chai'
sinonChai = require 'sinon-chai'
global.sinon = require 'sinon'

chai.use sinonChai
global.expect = chai.expect
global.Plugin = require '../index'
