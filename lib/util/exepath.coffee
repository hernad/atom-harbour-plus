path = require('path')
fs = require('fs-plus')

module.exports =
class ExePath
  full: (exe) ->
    # console.log 'exe:', exe
    if exe? and exe isnt '' and path.isAbsolute(exe)
      #console.log "exepath absolute defined", result
      return '' unless fs.existsSync(exe)
      return exe
    else
      for dir in process.env.PATH.split(path.delimiter)
        file = path.join(dir, exe)
        #console.log "file check exe:", file
        if fs.existsSync(file)
          return file
      return ''
