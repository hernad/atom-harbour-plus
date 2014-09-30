module.exports =
  configDefaults:
    environmentOverridesConfiguration: true # Environment variables override configuration
    formatOnSave: false
    harbourFormatExe: '' # c:\harbour\bin\hbformat.exe or /opt/harbour/bin/hbformat
    harbourExe: '' # e.g. c:\harbour\bin\harbour.exe or /opt/harbour/bin/harbour
    showPanel: true
    showPanelWhenNoIssuesExist: false


  activate: (state) ->
    @dispatch = @createDispatch()

  deactivate: ->
    @dispatch?.destroy()
    @dispatch = null

  createDispatch: ->
    unless @dispatch?
      Dispatch = require './dispatch'
      @dispatch = new Dispatch()
