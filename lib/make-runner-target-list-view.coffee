{$$, SelectListView} = require 'atom-space-pen-views'

module.exports =
class ListView extends SelectListView
  initialize: (@data, @onConfirm) ->
    super
    @addClass('make-runner-target')
    @show()
    targets = ({name} for name in @data)
    @setItems(targets)
    @focusFilterEditor()
    @currentPane = atom.workspace.getActivePane()

  getFilterKey: -> 'name'

  show: ->
    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @storeFocusedElement()

  cancelled: -> @hide()

  hide: -> @panel?.destroy()

  viewForItem: ({name}) ->
    $$ ->
      @li name, =>
        @div class: 'pull-right'

  confirmed: (item) ->
    @onConfirm(item)
    @cancel()
    @currentPane.activate() if @currentPane?.isAlive()
