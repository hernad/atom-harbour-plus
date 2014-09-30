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
    if os.platform() is 'win32'
      console.log( "win32 exe" )
      @exe = ".exe"

    @version = options.version if options?.version?
    @hbroot = options.hbroot if options?.hbroot?


  description: ->
    return @name + ' (@ ' + @hbroot + ')'

  harbour: ->
    console.log( "harbour executable", @executable )
    return false unless @executable? and @executable isnt ''
    return false unless fs.existsSync(@executable)
    return fs.realpathSync(@executable)

  hbformat: ->
    result = atom.config.get('harbour-plus.harbourFormatExe')
    if result? and result isnt ''
      console.log "hbformat defined", result
      return result
    console.log "hbroot", @hbroot
    return false unless @hbroot? and @hbroot isnt ''
    result = path.join(@hbroot, 'bin', 'hbformat' + @exe)
    console.log "hbformat exec? :", result
    return false unless fs.existsSync(result)
    return fs.realpathSync(result)
