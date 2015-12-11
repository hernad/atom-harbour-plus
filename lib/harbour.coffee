fs = require 'fs-plus'
path = require 'path'
os = require 'os'
_ = require 'underscore-plus'
ExePath = require('./util/exepath')

module.exports =
class Harbour
  name: '' # Name of this harbour
  exe: ''
  version: ''
  hbroot: '' # env's HB_ROOT
  env: false # Copy of the environment

  constructor: (@executable, options) ->
    @name = options.name if options?.name?
    if os.platform() is 'win32'
      @exe = ".exe"
    @hbroot = process.ENV
    @version = options.version if options?.version?
    @hbroot = process.env.HB_ROOT
    @exepath = new ExePath()

  description: ->
    return @name? + ' (@ ' + @hbroot? + ')'

  harbour: ->
    exe = atom.config.get('harbour-plus.harbourExe')
    # console.log "harbour exe from config: ", exe
    exe = @exepath.full(exe)
    # console.log "harbour exe with exepath: ", exe
    return exe

    # confg not defined, path based ond HB_ROOT
    if @hbroot? and @hbroot isnt ''
      result = path.join(@hbroot, 'bin', 'harbour' + @exe)
      #console.log "hbformat exec? :", result
      return false unless fs.existsSync(exe)
      return exe

  hbformat: ->
    exe = atom.config.get('harbour-plus.harbourFormatExe')
    exe = @exepath.full(exe)
    return exe

    # confg not defined, path based ond HB_ROOT
    if @hbroot? and @hbroot isnt ''
      result = path.join(@hbroot, 'bin', 'hbformat' + @exe)
      #console.log "hbformat exec? :", result
      return false unless fs.existsSync(exe)
      return exe
