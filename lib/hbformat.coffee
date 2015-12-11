{spawn} = require ('child_process')
{Subscriber, Emitter} = require ('emissary')
_ = require ('underscore-plus')
path = require ('path')
{exec, tempFile} = helpers = require('atom-linter')
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
    return unless @dispatch?.isValidEditor(editor)
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
    # console.log( "formatBuffer args:", args)
    cmd = @dispatch.harbour.hbformat()
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
      #console.log "done callback:", @name, 'stdout: ', stdout, 'stderr:', stderr
      messages = @mapMessages(editor, stderr, cwd)
      # emituje se hbformat-complete event
      @emit @name + '-complete', editor, saving
      @dispatch.resetPanel()
      callback(null, messages)

    @dispatch.messagepanel.add new PlainMessageView
      message: 'formatting ' + currentFile, className: 'text-success'
    @dispatch.messagepanel.attach()
    @dispatch.executor.exec(cmd, cwd, @dispatch?.env(), done, args)

  mapMessages: (editor, data, cwd) ->
    #console.log 'map error messages:', data
    # <...Error 3 on line 1924: END PRITN
    regex = /Error (\d+) on line (\d+)\: (.*)/g
    messages = []
    while((match = regex.exec(data)) isnt null)
      messages.push
        type: 'error'
        file: editor.getPath()
        line: match[2]
        column: "1"
        msg: match[1] + ': ' + match[3]
    messages
