{View} = require 'atom'

module.exports =
class MakeRunnerView extends View

  @content: ->
      @div tabIndex: -1, class: 'atom-make-runner tool-panel panel-bottom', =>
        @div outlet: 'canvas', class: 'block', 'Press <i>Ctrl-R</i> to run make'

  initialize: (serializeState) ->
    atom.workspaceView.command "atom-make-runner", => @toggle()

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @detach()

  toggle: ->
    console.log "atom-make-runner-view was toggled!"
    if @hasParent()
      @detach()
    else
      atom.workspaceView.prependToBottom(this)

  show: ->
    console.log "trying to switch on atom-make-runner-view!"
    if not @hasParent()
      atom.workspaceView.prependToBottom(this)
      console.log "atom-make-runner-view was switched on!", this

  print: (line, type) ->
    # if we are scrolled all the way down we follow the output
    panel = @canvas.parent()
    at_bottom = (panel.scrollTop() + panel.height() + 10 > panel[0].scrollHeight)

    @canvas.append "<div class='make-runner-#{type}'>#{line}</div>"

    if at_bottom
      panel.scrollTop(panel[0].scrollHeight)

  printOutput: (line) ->
    @print line, 'output'

  printError: (line) ->
    @print line, 'error'

  clear: ->
    @canvas.empty()
