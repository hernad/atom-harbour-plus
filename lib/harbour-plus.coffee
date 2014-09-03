module.exports =
  configDefaults:
    environmentOverridesConfiguration: true # Environment variables override configuration
    formatOnSave: true # Run gofmt or goimports on save
    formatWithGoImports: true # Use goimports instead of gofmt
    getMissingTools: true # go get -u missing tools
    # gofmtArgs: '-w' - Specify this in your user config if you need different args
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
