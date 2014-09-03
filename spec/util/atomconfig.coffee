module.exports =
class AtomConfig

  defaults: ->
    atom.config.set('core.useReactEditor', false)
    atom.config.set('harbour-plus.environmentOverridesConfiguration', true)
    atom.config.set('harbour-plus.gofmtArgs', '-w')
    atom.config.set('harbour-plus.vetArgs', '')
    atom.config.set('harbour-plus.goPath', '')
    atom.config.set('harbour-plus.golintArgs', '')
    atom.config.set('harbour-plus.showPanel', true)
    atom.config.set('harbour-plus.showPanelWhenNoIssuesExist', false)

  allfunctionalitydisabled: =>
    @defaults()
    atom.config.set("harbour-plus.syntaxCheckOnSave", false)
    atom.config.set("harbour-plus.formatOnSave", false)
    atom.config.set("harbour-plus.formatWithGoImports", false)
    atom.config.set("harbour-plus.getMissingTools", false)
    atom.config.set("harbour-plus.vetOnSave", false)
    atom.config.set("harbour-plus.lintOnSave", false)
    atom.config.set("harbour-plus.runCoverageOnSave", false)
