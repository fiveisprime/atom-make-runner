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

  print: (line) ->
    @canvas.append "<div class='make-runner-output'>#{line}</div>"

  printError: (line) ->
    @canvas.append "<div class='make-runner-error'>#{line}</div>"

  clear: ->
    @canvas.empty()
