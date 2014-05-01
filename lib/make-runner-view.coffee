{View} = require 'atom'
$ = require('atom').$

module.exports =
class MakeRunnerView extends View

  @content: ->
      @div tabIndex: -1, class: 'atom-make-runner tool-panel panel-bottom', =>
        @div outlet: 'canvas', class: 'block', 'Press <i>Ctrl-R</i> to run make and <i>Ctrl-Shift-R</i> to toggle this pane.'

  initialize: (serializeState) ->
    atom.workspaceView.command "atom-make-runner", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this)

  show: ->
    if not @hasParent()
      atom.workspaceView.prependToBottom(this)

  print: (line, type) ->
    # if we are scrolled all the way down we follow the output
    panel = @canvas.parent()
    at_bottom = (panel.scrollTop() + panel.height() + 30 > panel[0].scrollHeight)

    @canvas.append $("<div class='make-runner-#{type}'></div>").append line

    if at_bottom
      panel.scrollTop(panel[0].scrollHeight)

  printOutput: (line) ->
    @print line, 'output'

  printError: (line) ->
    @print line, 'error'

  clear: ->
    @canvas.empty()
