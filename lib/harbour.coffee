fs = require 'fs-plus'
path = require 'path'
os = require 'os'
_ = require 'underscore-plus'

module.exports =
class Harbour
  name: '' # Name of this harbour
  exe: ''
  version: ''
  hbroot: '' # env's HB_ROOT
  env: false # Copy of the environment

  constructor: (@executable, @pathexpander, options) ->
    @name = options.name if options?.name?
    @os = options.os if options?.os?
    @exe = options.exe if options?.exe?

    @version = options.version if options?.version?
    @hbroot = options.hbroot if options?.hbroot?


  description: ->
    return @name + ' (@ ' + @goroot + ')'

  harbour: ->
    return false unless @executable? and @executable isnt ''
    return false unless fs.existsSync(@executable)
    return fs.realpathSync(@executable)


  hbformat: ->
    return false unless @hbroot? and @hbroot isnt ''
    result = path.join(@hbroot, 'bin', 'hbformat' + @exe)
    return false unless fs.existsSync(result)
    return fs.realpathSync(result)

  format: ->
    @hbrormat()
