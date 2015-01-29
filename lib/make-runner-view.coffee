{View} = require 'atom'
$ = require('atom').$

module.exports =
class MakeRunnerView extends View

  @content: ->
      @div tabIndex: -1, =>
        @div outlet: 'canvas', class: 'block', 'Press <i>Ctrl-R</i> to run make and <i>Ctrl-Shift-R</i> to toggle this pane.'

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  show: ->
    if not @hasParent()
      atom.workspaceView.prependToBottom(this)

  print: (line, type) ->
    # if we are scrolled all the way down we follow the output
    panel = @canvas.parent().parent()
    at_bottom = (panel.scrollTop() + panel.innerHeight() + 10 > panel[0].scrollHeight)

    @canvas.append $("<div class='make-runner-#{type}'></div>").append line

    if at_bottom and not @had_error
      panel.scrollTop(panel[0].scrollHeight)

  printOutput: (line) ->
    @print line, 'output'

  printError: (line) ->
    @had_error = true
    @print line, 'error'

  printWarning: (line) ->
    @print line, 'warning'

  clear: ->
    @had_error = false
    @canvas.empty()
