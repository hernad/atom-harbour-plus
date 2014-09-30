module.exports =
  configDefaults:
    environmentOverridesConfiguration: true # Environment variables override configuration
    formatOnSave: false
    harbourFormatExe: ''
    harbourInstallation: '' # You should not need to specify this by default!
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
