{CompositeDisposable} = require 'atom'
helpers = require('atom-linter')

module.exports =
  config:
    environmentOverridesConfiguration:
      title: 'ENV overrides'
      description: 'Environment variables override configuration'
      default: true
      type: 'boolean'
      order: 1
    formatOnSave:
      title: 'Format on save'
      description: 'format on save'
      default: false
      type: 'boolean'
      order: 2
    harbourFormatExe:
      title: 'EXE hbformat'
      description: 'c:\\harbour\\bin\\hbformat.exe or /opt/harbour/bin/hbformat'
      default: 'hbformat'
      type: 'string'
      order: 3
    harbourExe:
      title: 'EXE harbour'
      description: 'e.g. c:\\harbour\\bin\\harbour.exe or /opt/harbour/bin/harbour'
      default: ''
      type: 'string'
      order: 4
    showPanel:
      title: 'SHOW panel'
      description: 'show panel'
      type: 'boolean'
      default: true
      order: 5
    showPanelWhenNoIssuesExist:
      title: 'SHOW panel no issues'
      description: 'show panel when no issues exists'
      default: false
      type: 'boolean'
      order: 6

  _testHbFormatBin: ->
    title = 'Unable to run hbformat'
    message = 'Unable run "' + @harbourFormatExe +
      '", please verify this file path.'
    try
      helpers.exec(@harbourFormatExe, []).then (output) =>
        # Harbour 3.2.0dev (r1408271619)
        regex = /Harbour Source Formatter/g
        if not regex.exec(output)
          atom.notifications.addError(title, {detail: message})
          @harbourFormatExe = ''
      .catch (e) ->
        #console.log e
        atom.notifications.addError(title, {detail: message})

  activate: (state) ->
    require('atom-package-deps').install()
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.config.observe 'harbour-plus.harbourFormatExe',
      (exePath) =>
        @harbourFormatExe = exePath
        @_testHbFormatBin()
    @dispatch = @createDispatch()

  deactivate: ->
    @dispatch?.destroy()
    @dispatch = null

  createDispatch: ->
    unless @dispatch?
      Dispatch = require('./dispatch')
      @dispatch = new Dispatch()
