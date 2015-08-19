cp = require 'child_process'
path = require 'path'
fs = require 'fs-plus'
readline = require 'readline'
{$} = require 'atom-space-pen-views'

MakeRunnerView = require './make-runner-view'

module.exports =
  #
  # Lock flag for running make processes (to avoid running make multiple times concurrently)
  #
  makeRunning: null

  #
  # Make output panel
  #
  makeRunnerPanel: null
  makeRunnerView: null

  #
  # Write the status of the make target to the status bar.
  #
  updateStatus: (message) ->
    @statusBarTile?.destroy()
    statusBar = document.querySelector("status-bar")
    @statusBarTile = statusBar?.addLeftTile(priority: 10, item: $ "<span>Make: #{message}</span>")

  #
  # Escape html characters in a string
  #
  escape: (line) ->
    line = line.replace '<', '&lt;'
    line.replace '>', '&gt;'

  #
  # Clear the make result from the status bar.
  #
  clearStatus: ->
    @statusBarTile?.destroy()

  activate: (state) ->
    setTimeout (=>
      @activateLater(state)
    ), 1000

  #
  # Attach the run command.
  #
  activateLater: (state) ->
    atom.commands.add 'atom-workspace', 'make-runner:run', => @run()
    atom.commands.add 'atom-workspace', 'make-runner:toggle', => @toggle()
    atom.commands.add 'atom-workspace', 'core:cancel', => @makeRunnerPanel?.hide()
    @addTargetsToPalette()
    @makeRunnerView = new MakeRunnerView state.makeRunnerViewState
    @makeRunnerPanel = atom.workspace.addBottomPanel(item: @makeRunnerView, visible: false, className: 'atom-make-runner tool-panel panel-bottom')

  #
  # Show/hide the make pane without re-running make
  #
  toggle: ->
    if @makeRunnerPanel.isVisible()
      @makeRunnerPanel.hide()
    else
      @makeRunnerPanel.show()

  #
  # Run the configured make target.
  #
  run: (target = null) ->
    # guard against launching make while it is still running
    if @makeRunning
      if atom.config.get 'make-runner.killAndRestart'
        @makeRunning.kill 'SIGKILL'
        @updateStatus "killing make..."
      return

    @isError = false

    if target == null
      target = atom.config.get 'make-runner.buildTarget'

    # figure out number of concurrent make jobs
    if 'JOBS' in process.env
      jobs = process.env.JOBS
    else
      jobs = require('os').cpus().length

    # Check if the active item is a text editor
    editor = atom.workspace.getActiveTextEditor()
    return unless editor?

    make_path = editor.getPath()

    unless make_path?
      @updateStatus "file not saved, nowhere to search for Makefile"

      setTimeout (=>
        @clearStatus()
      ), 3000

      return

    while not fs.existsSync "#{make_path}/Makefile"
      previous_path = make_path
      make_path = path.join make_path, '..'

      if make_path is previous_path
        @updateStatus "no makefile found"

        setTimeout (=>
          @clearStatus()
        ), 3000

        return

    # add number of jobs and possible the make target argument
    args = ['-j', jobs]
    if target?.length
      args.push target

    # spawn make child process
    @updateStatus "running make..."
    @makeRunnerView.clear()
    @makeRunnerPanel.show()
    @makeRunning = make = cp.spawn 'make', args, { cwd: make_path }

    # Use readline to generate line input from raw data
    stdout = readline.createInterface { input: make.stdout, terminal: false }
    stderr = readline.createInterface { input: make.stderr, terminal: false }

    stdout.on 'line',  (line) =>
      @makeRunnerView.printOutput @escape(line)

    stderr.on 'line',  (line) =>
      # search for file:line:col: references
      html_line = null
      line = @escape(line)
      line.replace /^([^:]+):(\d+):(\d+):(.*)$/, (match, file, row, col, errormessage) =>
        html_line = [
          $('<a>')
            .text "#{file}:#{row}:#{col}"
            .attr 'href', '#'
            .on 'click', (e) =>
              e.preventDefault()

              # load file, but check if it is already open in any of the panes
              loading = atom.workspace.open file, { searchAllPanes: true }
              loading.done (editor) =>
                editor.setCursorBufferPosition [row-1, col-1],
          $('<span>').text errormessage
        ]

        @isError = errormessage.indexOf(" error:") is 0

      if @isError
        @makeRunnerView.printError html_line || line
      else
        @makeRunnerView.printWarning html_line || line

    # fire this off when the make process comes to an end
    make.on 'close',  (code, signal) =>
      @makeRunning = null

      # the previous make process was killed successfully
      if signal is 'SIGKILL'
        @run()
        return

      # make exited on its own
      if code is 0
        @updateStatus 'succeeded'
        if atom.config.get 'make-runner.hidePane'
          setTimeout (=>
            @makeRunnerPanel.hide()
          ), atom.config.get 'make-runner.hidePaneDelay'
      else
        @updateStatus "failed with code #{code}"

      setTimeout (=>
        @clearStatus()
      ), 3000

  #
  # Deactivate the package.
  #
  deactivate: ->
    @clearStatus()
    @makeRunnerView.destroy()

  serialize: ->
    makeRunnerViewState: @makeRunnerView.serialize()

  addTargetsToPalette: ->
    project = atom.project
    if project.rootDirectories.length < 1
      return
    directory = project.rootDirectories[0]

    directory.getEntries do (self = @) ->
      (err, entries) ->
        if err
          console.log 'Error :', err

        for entry in entries
          if entry.isFile() and entry.getBaseName() == 'Makefile'
            self.readTargets(entry.path)


  readTargets: (path) ->
    # use an object for the cache to imitate a set datastructure
    @_targets = {}
    fs.readFile path, do (self = @) ->
      (err, data) ->
        if err
          console.log 'error reading makefile:', makefile.path
          return

        makefileContents = data.toString().split '\n'
        for line in makefileContents # search each line for a target
          matches = line.match /(^[a-zA-Z-]{1,}?):/

          # if it matches and it's not already in the cache
          if matches and matches[1] not in self._targets
            makefileTarget = matches[1]
            do (self, makefileTarget) ->
              atom.commands.add 'atom-workspace', 'make:' + makefileTarget + '', => self.run(makefileTarget)
            # add it to the cache
            self._targets[makefileTarget] = makefileTarget


  #
  # Set the default build target.
  #
  config:
    buildTarget:
      type: 'string'
      default: ''
    killAndRestart:
      type: 'boolean'
      default: false
      description: 'Kill and restart the current make process rather than block if make is running.'
    hidePane:
      type: 'boolean'
      default: false
      description: 'Hide make panel if execution is successful.'
    hidePaneDelay:
      type: 'integer'
      default: 3000
      min:0
