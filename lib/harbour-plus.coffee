module.exports =
  configDefaults:
    environmentOverridesConfiguration: true # Environment variables override configuration
    formatOnSave: false
    harbourInstallation: '' # You should not need to specify this by default!
    harbourPath: '' # This should usually be set in the environment, not here
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
