async = require 'async'
path = require 'path'
fs = require 'fs-plus'
os = require 'os'
Harbour = require './harbour'
_ = require 'underscore-plus'
Executor = require './executor'
PathExpander = require './util/pathexpander'
{Subscriber, Emitter} = require 'emissary'

module.exports =
class HarbourExecutable
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  constructor: (@env) ->
    @harbours = []
    @currentharbour = ''
    @executor = new Executor(@env)
    @pathexpander = new PathExpander(@env)

  destroy: ->
    @unsubscribe()
    @executor = null
    @pathexpander = null
    @harbours = []
    @currentharbour = ''
    @reset()

  reset: ->
    @harbours = []
    @currentharbour = ''
    @emit 'reset'

  detect: =>
    executables = []
    harbourExe = atom.config.get('harbour-plus.harbourExe')
    console.log "os.platform:", os.platform(), "path.separator", path.sep
    switch os.platform()
      when 'darwin', 'freebsd', 'linux', 'sunos'
        # Configuration
        if harbourExe? and harbourExe.trim() isnt ''
          if harbourExe.lastIndexOf(path.sep + 'harbour') is harbourExe.length - 8
            executables.push path.normalize(harbourExe)

        # PATH
        if @env.PATH?
          elements = @env.PATH.split(path.delimiter)
          for element in elements
            executables.push path.normalize(path.join(element, 'harbour'))

        executables.push path.normalize(path.join('/opt', 'harbour', 'bin', 'harbour'))
        # Homebrew
        executables.push path.normalize(path.join('/usr', 'local', 'bin', 'harbour', ))
      when 'win32'
        # Configuration
        if harbourExe? and harbourExe.trim() isnt ''
          if harbourExe.lastIndexOf(path.sep + 'harbour.exe') is harbourExe.length - 12
            executables.push path.normalize(harbourExe)

        # PATH
        if @env.Path?
          elements = @env.Path.split(path.delimiter)
          for element in elements
            executables.push path.normalize(path.join(element, 'harbour.exe'))

        # Binary Distribution
        executables.push path.normalize(path.join('C:','harbour', 'bin', 'harbour.exe'))


    # De-duplicate entries
    executables = _.uniq(executables)
    async.filter executables, fs.exists, (results) =>
      executables = results
      async.map executables, @introspect, (err, results) =>
        console.log 'Error mapping harbour: ' + err if err?
        @harbours = results
        @emit('detect-complete', @current())

  introspect: (executable, outercallback) =>
    absoluteExecutable = path.resolve(executable)

    harbour = new Harbour(absoluteExecutable, @pathexpander)
    async.series([
      (callback) =>
        # done object
        done = (exitcode, stdout, stderr) =>
          unless stderr? and stderr isnt ''
            if stdout? and stdout isnt ''
              components = stdout.replace(/\r?\n|\r/g, '').split(' ')
              harbour.name = components[2] + ' ' + components[3]
              harbour.version = components[2]
              harbour.env = @env
          console.log 'Error running harbour version: ' + err if err?
          console.log 'Error detail (stderr): ' + stderr if stderr? and stderr isnt ''
          callback(null)
        try
          console.log( 'starting [' + absoluteExecutable + ' --version ]' )
          @executor.exec( absoluteExecutable, false, @env, done, ['--version'] )
        catch error
          console.log 'harbour [' + absoluteExecutable + '] is not a valid harbour'
          harbour = null
    ], (err, results) =>
      outercallback(err, harbour)
    )
    console.log( "introspect HB_ROOT", process.env.HB_ROOT )
    harbour.hbroot = process.env.HB_ROOT


  current: =>
    return @harbours[0] if _.size(@harbours) is 1
    for harbour in @harbours
      return harbour if harbour.executable is @currentharbour
    return @harbours[0]
