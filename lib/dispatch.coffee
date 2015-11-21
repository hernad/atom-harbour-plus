{Subscriber, Emitter} = require 'emissary'
HbFormat = require './hbformat'
Executor = require './executor'
Environment = require './environment'
HarbourExecutable = require './harbourexecutable'
SplicerSplitter = require './util/splicersplitter'

_ = require 'underscore-plus'
{MessagePanelView, LineMessageView, PlainMessageView} = require 'atom-message-panel'
{$, SettingsView} = require 'atom'
path = require 'path'
os = require 'os'
async = require 'async'

module.exports =
class Dispatch
  Subscriber.includeInto(this)
  Emitter.includeInto(this)

  constructor: ->
    # Manage Save Pipeline
    @activated = false
    @dispatching = false
    @ready = false
    @messages = []

    @environment = new Environment(process.env)
    @executor = new Executor(@environment.Clone())
    @splicersplitter = new SplicerSplitter()
    @harbourexecutable = new HarbourExecutable(@env())

    @hbformat = new HbFormat(this)
    @messagepanel = new MessagePanelView title: '<span class="icon-diff-added"></span> harbour-plus', rawTitle: true unless @messagepanel?

    @on 'run-detect', => @detect()

    # Reset State If Requested
    hbformatsubscription = @hbformat.on 'reset', (editor) => @resetState(editor)

    @subscribe(hbformatsubscription)

    @on 'dispatch-complete', (editor) => @displayMessages(editor)
    @subscribeToAtomEvents()
    @emit 'run-detect'

  destroy: =>
    @unsubscribeFromAtomEvents()
    @unsubscribe()
    @resetPanel()
    @messagepanel?.remove()
    @messagepanel = null
    @hbformat.destroy()
    @hbformat = null
    @ready = false
    @activated = false
    @emit 'destroyed'

  subscribeToAtomEvents: =>
    @editorSubscription = atom.workspace.observeTextEditors (editor) => @handleEvents(editor)
    #@workspaceViewSubscription = atom.workspace.on 'pane-container:active-pane-item-changed', => @resetPanel()
    @activated = true


  handleEvents: (editor) =>
    buffer = editor?.getBuffer()
    return unless buffer?
    @updateGutter(editor, @messages)
    modifiedsubscription = buffer.on 'contents-modified', =>
      return unless @activated
      @handleBufferChanged(editor)

    savedsubscription = buffer.on 'saved', =>
      return unless @activated
      return unless not @dispatching
      @handleBufferSave(editor, true)

    destroyedsubscription = buffer.once 'destroyed', =>
      savedsubscription?.off()
      modifiedsubscription?.off()

    @subscribe(modifiedsubscription)
    @subscribe(savedsubscription)
    @subscribe(destroyedsubscription)

  unsubscribeFromAtomEvents: =>
    @editorSubscription?.off()

  detect: =>
    @ready = false
    @harbourexecutable.once 'detect-complete', =>
      @emitReady()
    @harbourexecutable.detect()

  resetAndDisplayMessages: (editor, msgs) =>
    return unless @isValidEditor?(editor?)
    @resetState?(editor?)
    @collectMessages?(msgs?)
    @displayMessages?(editor?)

  displayMessages: (editor) =>
    @updatePane(editor?, @messages)
    @updateGutter(editor?, @messages)
    @dispatching = false
    @emit 'display-complete'

  emitReady: =>
    @ready = true
    @emit 'ready'

  displayHarbourInfo: (force) =>
    editor = atom.workspace?.getActiveTextEditor()
    unless force
      return @isValidEditor(editor)

    @resetPanel()
    harbour = @harbourexecutable.current()
    if harbour? and harbour.executable? and harbour.executable.trim() isnt ''
      @messagepanel.add new PlainMessageView message: 'Using Harbour: ' + harbour.name + ' (@' + harbour.executable + ')', className: 'text-success'


      # hbformat
      if harbour.hbformat()? and go.hbformat() isnt false
        @messagepanel.add new PlainMessageView message: 'Format Tool: ' + harbour.hbformat(), className: 'text-success'
      else
        @messagepanel.add new PlainMessageView message: 'Format Tool (hbformat): Not Found', className: 'text-error' unless atom.config.get('harbour-plus.formatWithHarbourImports')

      # PATH
      thepath = if os.platform() is 'win32' then @env()?.Path else @env()?.PATH
      if thepath? and thepath.trim() isnt ''
        @messagepanel.add new PlainMessageView message: 'PATH: ' + thepath, className: 'text-success'
      else
        @messagepanel.add new PlainMessageView message: 'PATH: Not Set', className: 'text-error'
    else
      @messagepanel.add new PlainMessageView message: 'No Harbour Installations Were Found', className: 'text-error'

    @messagepanel.attach()
    @resetPanel()


  collectMessages: (messages) ->
    messages = _.flatten(messages) if messages? and _.size(messages) > 0
    messages = _.filter messages, (element, index, list) ->
      return element?
    return unless messages?
    messages = _.filter messages, (message) -> message?
    @messages = _.union(@messages, messages)
    @messages = _.uniq @messages, (element, index, list) ->
      return element?.line + ':' + element?.column + ':' + element?.msg
    @emit 'messages-collected', _.size(@messages)

  triggerPipeline: (editor, saving) ->
    @dispatching = true
    harbour = @harbourexecutable.current()
    unless harbour? and harbour.executable? and harbour.executable.trim() isnt ''
      @displayHarbourInfo(false)
      @dispatching = false
      return

    async.series([
      (callback) =>
        @hbformat.formatBuffer(editor, saving, callback)
     ], (err, modifymessages) =>
      @collectMessages(modifymessages)
      @emit 'dispatch-complete', editor
    )


  handleBufferSave: (editor, saving) ->
    return unless @ready and @activated
    return unless @isValidEditor(editor)
    @resetState(editor)
    @triggerPipeline(editor, saving)

  handleBufferChanged: (editor) ->
    return unless @ready and @activated
    return unless @isValidEditor(editor)

  resetState: (editor) ->
    @messages = []
    @resetGutter(editor)
    @resetPanel()

  resetGutter: (editor) ->
    return unless @isValidEditor(editor)
    if atom.config.get('core.useReactEditor')
      return unless editor?
      # Find current markers
      markers = editor?.getBuffer()?.findMarkers(class: 'harbour-plus')
      return unless markers? and _.size(markers) > 0
      # Remove markers
      marker.destroy() for marker in markers

  updateGutter: (editor, messages) ->
    @resetGutter(editor)
    return unless messages? and messages.length > 0
    if atom.config.get('core.useReactEditor')
      buffer = editor?.getBuffer()
      return unless buffer?
      for message in messages
        skip = false
        if message?.file? and message.file isnt ''
          skip = message.file isnt buffer.getPath()

        unless skip
          if message?.line? and message.line isnt false and message.line >= 0
            marker = buffer.markPosition([message.line - 1, 0], class: 'harbour-plus', invalidate: 'touch')
            editor.decorateMarker(marker, type: 'gutter', class: 'hbplus-' + message.type)

  resetPanel: ->
    @messagepanel?.close()
    @messagepanel?.clear()

  updatePane: (editor, messages) ->
    @resetPanel
    return unless messages?
    if messages.length <= 0 and atom.config.get('harbour-plus.showPanelWhenNoIssuesExist')
      @messagepanel.add new PlainMessageView message: 'No Issues', className: 'text-success'
      @messagepanel.attach()
      return
    return unless messages.length > 0
    return unless atom.config.get('harbour-plus.showPanel')
    sortedMessages = _.sortBy @messages, (element, index, list) ->
      return parseInt(element.line, 10)
    for message in sortedMessages
      className = switch message.type
        when 'error' then 'text-error'
        when 'warning' then 'text-warning'
        else 'text-info'

      file = if message.file? and message.file.trim() isnt '' then message.file else null
      file = atom.project.relativize(file) if file? and file isnt '' and atom?.project?
      column = if message.column? and message.column isnt '' and message.column isnt false then message.column else null
      line = if message.line? and message.line isnt '' and message.line isnt false then message.line else null

      if file is null and column is null and line is null
        # PlainMessageView
        @messagepanel.add new PlainMessageView message: message.msg, className: className
      else
        # LineMessageView
        @messagepanel.add new LineMessageView file: file, line: line, character: column, message: message.msg, className: className
    @messagepanel.attach() if atom?.workspaceView?

  isValidEditor: (editor) ->
    editor?.getGrammar()?.scopeName is 'source.harbour'

  env: ->
    @environment.Clone()
