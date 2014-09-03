fs = require 'fs-plus'
path = require 'path'
os = require 'os'
_ = require 'underscore-plus'

module.exports =
class Harbour
  name: '' # Name of this go
  os: '' # go env's GOOS
  exe: ''
  version: ''
  gopath: '' # go env's GOPATH
  goroot: '' # go env's GOROOT
  gotooldir: '' # go env's GOTOOLDIR
  env: false # Copy of the environment

  constructor: (@executable, @pathexpander, options) ->
    @name = options.name if options?.name?
    @os = options.os if options?.os?
    @exe = options.exe if options?.exe?

    @version = options.version if options?.version?
    @hbpath = options.hbpath if options?.hbpath?
    @hbroot = options.hbroot if options?.hbroot?


  description: ->
    return @name + ' (@ ' + @goroot + ')'

  harbour: ->
    return false unless @executable? and @executable isnt ''
    return false unless fs.existsSync(@executable)
    return fs.realpathSync(@executable)

  buildharbourpath: ->
    result = ''
    hbpathConfig = atom.config.get('harbour-plus.harbourPath')
    environmentOverridesConfig = atom.config.get('harbour-plus.environmentOverridesConfiguration')? and atom.config.get('harbour-plus.environmentOverridesConfiguration')
    result = @env.HB_PATH if @env.HB_PATH? and @env.HB_PATH isnt ''
    result = @hbpath if @hbpath? and @hbpath isnt ''
    result = hbpathConfig if not environmentOverridesConfig and hbpathConfig? and hbpathConfig.trim() isnt ''
    result = hbpathConfig if result is '' and hbpathConfig? and hbpathConfig.trim() isnt ''
    return @pathexpander.expand(result, '')

  splitharbourpath: ->
    result = @buildgopath()
    return [] unless result? and result isnt ''
    return result.split(path.delimiter)

  hbformat: ->
    return false unless @goroot? and @goroot isnt ''
    result = path.join(@goroot, 'bin', 'hbformat' + @exe)
    return false unless fs.existsSync(result)
    return fs.realpathSync(result)

  format: ->
    if atom.config.get('harbour-plus.formatWithHarbourImports')? and atom.config.get('harbour-plus.formatWithHarbourImports') then @goimports() else @gofmt()


  hbpathOrPathBinItem: (name) ->
    pathresult = false

    hbpaths = @splitgopath()
    for item in hbpaths
      result = path.resolve(path.normalize(path.join(item, 'bin', name + @exe)))
      return fs.realpathSync(result) if fs.existsSync(result)

    # PATH
    p = if os.platform() is 'win32' then @env.Path else @env.PATH
    if p?
      elements = p.split(path.delimiter)
      for element in elements
        target = path.resolve(path.normalize(path.join(element, name + @exe)))
        pathresult = fs.realpathSync(target) if fs.existsSync(target)

    return pathresult
