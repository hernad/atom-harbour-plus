{spawn} = require ('child_process')
{Subscriber, Emitter} = require ('emissary')
_ = require ('underscore-plus')
path = require ('path')
{MessagePanelView, LineMessageView, PlainMessageView} =
  require 'atom-message-panel'

module.exports =
class HbFormat
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  constructor: (dispatch) ->
    atom.commands.add 'atom-workspace',
      'harbourlang:hbformat': => @formatCurrentBuffer()
    @dispatch = dispatch
    @name = 'hbformat'

  destroy: ->
    @unsubscribe()
    @dispatch = null

  reset: (editor) ->
    @emit 'reset', editor

  formatCurrentBuffer: ->
    editor = atom?.workspace?.getActiveTextEditor()
    editor.save()
    #console.log 'editor current buffer', editor
    return unless @dispatch.isValidEditor(editor)
    @reset editor
    done = (err, messages) =>
      @dispatch.resetAndDisplayMessages(editor, messages)
    @formatBuffer(editor, false, done)

  formatBuffer: (editor, saving, callback = ->) ->
    # console.log 'format buffer'
    unless @dispatch.isValidEditor(editor)
      @emit @name + '-complete', editor, saving
      callback(null)
      return
    if saving and not atom.config.get('harbour-plus.formatOnSave')
      @emit @name + '-complete', editor, saving
      callback(null)
      return
    buffer = editor?.getBuffer()
    unless buffer?
      @emit @name + '-complete', editor, saving
      callback(null)
      return
    cwd = path.dirname(buffer.getPath())
    # console.log( "cwd:", cwd)
    args = []
    configArgs = @dispatch.splicersplitter.splitAndSquashToArray(' ', \
      atom.config.get('harbour-plus.hbformatArgs'))
    args = _.union(args, configArgs) if configArgs? and _.size(configArgs) > 0

    # hbformat bug fix
    # hbformat <full path> eg /Users/hernad/github/harbour-plus/test.prg
    # DON'T WORK, we need:
    # hbformat test.prg
    currentFile = buffer.getPath().split('\\').pop().split('/').pop()
    args = _.union(args, [currentFile])
    harbour = @dispatch.harbourexecutable.current()
    # console.log( "formatBuffer args:", args)
    cmd = harbour.hbformat()
    # console.log( "hbformat cmd:", cmd )
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
      console.log "done callback:", @name, 'stdout: ', stdout, 'stderr:', stderr
      messages = @mapMessages(editor, stderr, cwd) \
       if stderr? and stderr.trim() isnt ''
      # emituje se hbformat-complete event
      @emit @name + '-complete', editor, saving
      @dispatch.resetPanel()
      callback(null, messages)

    @dispatch.messagepanel.add new PlainMessageView
      message: 'formatting ' + currentFile, className: 'text-success'
    @dispatch.messagepanel.attach()
    @dispatch.executor.exec(cmd, cwd, @dispatch?.env(), done, args)

  mapMessages: (editor, data, cwd) =>
    pattern = /^(.*?):(\d*?):((\d*?):)?\s(.*)$/img
    messages = []
    return messages unless data? and data isnt ''
    extract = (matchLine) =>
      return unless matchLine?
      file = if matchLine[1]? and matchLine[1] isnt '' \
        then matchLine[1] else null
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
