{spawn} = require 'child_process'
{Subscriber, Emitter} = require 'emissary'
_ = require 'underscore-plus'
path = require 'path'

module.exports =
class HbFormat
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  constructor: (dispatch) ->
    atom.workspaceView.command 'harbourlang:hbformat', => @formatCurrentBuffer()
    @dispatch = dispatch
    @name = 'hbformat'

  destroy: ->
    @unsubscribe()
    @dispatch = null

  reset: (editorView) ->
    @emit 'reset', editorView

  formatCurrentBuffer: ->
    editorView = atom?.workspaceView?.getActiveView()
    return unless @dispatch.isValidEditorView(editorView)
    @reset editorView
    done = (err, messages) =>
      @dispatch.resetAndDisplayMessages(editorView, messages)
    @formatBuffer(editorView, false, done)

  formatBuffer: (editorView, saving, callback = ->) ->
    unless @dispatch.isValidEditorView(editorView)
      @emit @name + '-complete', editorView, saving
      callback(null)
      return
    if saving and not atom.config.get('harbour-plus.formatOnSave')
      @emit @name + '-complete', editorView, saving
      callback(null)
      return
    buffer = editorView?.getEditor()?.getBuffer()
    unless buffer?
      @emit @name + '-complete', editorView, saving
      callback(null)
      return
    cwd = path.dirname(buffer.getPath())
    console.log( "cwd:", cwd)
    args = []
    configArgs = @dispatch.splicersplitter.splitAndSquashToArray(' ', atom.config.get('harbour-plus.hbformatArgs'))
    args = _.union(args, configArgs) if configArgs? and _.size(configArgs) > 0
    # hbformat bug fix
    # hbformat /Users/hernad/github/harbour-plus/test.prg ne radi ?!
    # zato sam odsjekao path tako da dobijem
    # currentFile = test.prg
    # Na svu srecu imam cwd komandu koja me pozicionira u tekuci direktorij, u ovom slucaju /Users/hernad/github/harbour-plus
    currentFile = buffer.getPath().split('\\').pop().split('/').pop()
    args = _.union(args, [currentFile])
    harbour = @dispatch.harbourexecutable.current()
    console.log( "formatBuffer args:", args)
    cmd = harbour.hbformat()
    console.log( "hbformat cmd:", cmd )
    if cmd is false
      message =
        line: false
        column: false
        msg: 'Harbour Format Tool Missing'
        type: 'error'
        source: @name
      callback(null, [message])
      return
    done = (exitcode, stdout, stderr, messages) =>
      console.log @name + ' - stdout: ' + stdout if stdout? and stdout.trim() isnt ''
      messages = @mapMessages(editorView, stderr, cwd) if stderr? and stderr.trim() isnt ''
      # emituje se hbformat-complete event
      @emit @name + '-complete', editorView, saving
      callback(null, messages)
    @dispatch.executor.exec(cmd, cwd, @dispatch?.env(), done, args)

  mapMessages: (editorView, data, cwd) =>
    pattern = /^(.*?):(\d*?):((\d*?):)?\s(.*)$/img
    messages = []
    return messages unless data? and data isnt ''
    extract = (matchLine) =>
      return unless matchLine?
      file = if matchLine[1]? and matchLine[1] isnt '' then matchLine[1] else null
      message = switch
        when matchLine[4]?
          file: file
          line: matchLine[2]
          column: matchLine[4]
          msg: matchLine[5]
          type: 'error'
          source: @name
        else
          file: file
          line: matchLine[2]
          column: false
          msg: matchLine[5]
          type: 'error'
          source: @name
      messages.push message
    loop
      match = pattern.exec(data)
      extract(match)
      break unless match?
    return messages
