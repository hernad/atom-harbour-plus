path = require('path')
fs = require('fs-plus')

module.exports =
class ExePath
  full: (exe) ->
    console.log 'exe:', exe
    if exe? and exe isnt ''
      if not path.isAbsolute exe
        for dir in process.env.PATH.split(path.delimiter)
          file = path.join(dir, exe)
          console.log "file exe:", file
          if fs.existsSync(file)
            return file
        return ''
    else
      #console.log "hbformat defined", result
      return '' unless fs.existsSync(exe)
      return exe
