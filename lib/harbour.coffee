fs = require 'fs-plus'
path = require 'path'
os = require 'os'
_ = require 'underscore-plus'
ExePath = require('./util/exepath').ExePath

module.exports =
class Harbour
  name: '' # Name of this harbour
  exe: ''
  version: ''
  hbroot: '' # env's HB_ROOT
  env: false # Copy of the environment
  exePath: null

  constructor: (@executable, options) ->
    @name = options.name if options?.name?
    if os.platform() is 'win32'
      #console.log( "win32 exe" )
      @exe = ".exe"
    @version = options.version if options?.version?
    @hbroot = options.hbroot if options?.hbroot?
    @exePath = new ExePath()

  description: ->
    return @name? + ' (@ ' + @hbroot? + ')'

  harbour: ->
    # console.log( "harbour executable", @executable )
    return false unless @executable? and @executable isnt ''
    return false unless fs.existsSync(@executable)
    return fs.realpathSync(@executable)

  hbformat: ->
    exe = atom.config.get('harbour-plus.harbourFormatExe')
    exe = @exePath.full(exe)
    return exe unless exe isnt false

    # confg not defined, path based ond HB_ROOT
    if @hbroot? and @hbroot isnt ''
      result = path.join(@hbroot, 'bin', 'hbformat' + @exe)
      #console.log "hbformat exec? :", result
      return false unless fs.existsSync(exe)
      return exe
