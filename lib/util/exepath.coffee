path = require('path')
fs = require('fs-plus')

module.exports =
class ExePath
  full: (exe) ->
    console.log 'exe:', exe
    if exe? and exe isnt ''
      if not path.isAbsolute exe
        for dir in process.env.PATH.split(path.delimiter)
          f = path.join(dir, exe)
          console.log "f exe:", f
          if fs.existsSync(f)
            return f
        return false
    else
      #console.log "hbformat defined", result
      return false unless fs.existsSync(exe)
      return exe
