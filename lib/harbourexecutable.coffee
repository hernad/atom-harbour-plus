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
    harbourInstallation = atom.config.get('harbour-plus.harbourInstallation')
    switch os.platform()
      when 'darwin', 'freebsd', 'linux', 'sunos'
        # Configuration
        if harbourInstallation? and harbourInstallation.trim() isnt ''
          if harbourInstallation.lastIndexOf(path.sep + 'harbour') is harbourInstallation.length - 3
            executables.push path.normalize(harbourInstallation)

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
        if harbourInstallation? and harbourInstallation.trim() isnt ''
          if harbourInstallation.lastIndexOf(path.sep + 'harbour.exe') is harbourInstallation.length - 7
            executables.push path.normalize(harbourInstallation)

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
        done = (exitcode, stdout, stderr) =>
          unless stderr? and stderr isnt ''
            if stdout? and stdout isnt ''
              components = stdout.replace(/\r?\n|\r/g, '').split(' ')
              harbour.name = components[2] + ' ' + components[3]
              harbour.version = components[2]
              harbour.env = @env
          console.log 'Error running harbour version: ' + err if err?
          console.log 'Error detail: ' + stderr if stderr? and stderr isnt ''
          callback(null)
        try
          console.log 'starting [' + absoluteExecutable + ']'
          @executor.exec(absoluteExecutable, false, @env, done, ['--version'])
        catch error
          console.log 'harbour [' + absoluteExecutable + '] is not a valid harbour'
          harbour = null
      (callback) =>
        done = (exitcode, stdout, stderr) =>
          unless stderr? and stderr isnt ''
            if stdout? and stdout isnt ''
              items = stdout.split("\n")
              for item in items
                if item? and item isnt '' and item.trim() isnt ''
                  tuple = item.split('=')
                  key = tuple[0]
                  value = ''
                  if os.platform() is 'win32'
                    value = tuple[1]
                  else
                    value = tuple[1].substring(1, tuple[1].length - 1) if tuple[1].length > 2
                  if os.platform() is 'win32'
                    switch key
                      when 'set HB_ROOT' then harbour.hbroot = value
                  else
                    switch key
                      when 'HB_ROOT' then harbour.hbroot = value
          console.log 'Error running harbour env: ' + err if err?
          console.log 'Error detail: ' + stderr if stderr? and stderr isnt ''
          callback(null)
        try
          @executor.exec(absoluteExecutable, false, @env, done, ['env']) unless harbour is null
        catch error
          console.log 'harbour [' + absoluteExecutable + '] is not a valid harbour'
    ], (err, results) =>
      outercallback(err, harbour)
    )


  current: =>
    return @harbours[0] if _.size(@harbours) is 1
    for harbour in @harbours
      return harbour if harbour.executable is @currentharbour
    return @harbours[0]
