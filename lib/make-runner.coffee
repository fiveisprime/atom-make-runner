cp = require 'child_process'
path = require 'path'
fs = require 'fs-plus'
readline = require 'readline'
$ = require('atom').$

MakeRunnerView = require './make-runner-view'

module.exports =
  #
  # Lock flag for running make processes (to avoid running make multiple times concurrently)
  #
  makeRunning: false

  #
  # Make output pane
  #
  makeRunnerView: null

  #
  # Write the status of the make target to the status bar.
  #
  updateStatus: (message) ->
    atom.workspaceView.statusBar.find('#make-runner').remove()
    atom.workspaceView.statusBar.appendLeft "<span id=\"make-runner\">Make: #{message}</span>"

  #
  # Clear the make result from the status bar.
  #
  clearStatus: ->
    atom.workspaceView.statusBar.find('#make-runner').remove()

  #
  # Attach the run command.
  #
  activate: (state) ->
    atom.workspaceView.command 'make-runner:run', '.editor', => @run()
    atom.workspaceView.command 'make-runner:toggle', '.editor', => @toggle()
    @makeRunnerView = new MakeRunnerView(state.makeRunnerViewState)

  #
  # Show/hide the make pane without re-running make
  #
  toggle: ->
    @makeRunnerView.toggle()

  #
  # Run the configured make target.
  #
  run: ->
    # guard against launching make while it is still running
    if @makeRunning
      return

    target = atom.config.get('make-runner.buildTarget')

    # figure out number of concurrent make jobs
    if 'JOBS' in process.env
      jobs = process.env.JOBS
    else
      jobs = require('os').cpus().length

    # Get the path of the current file
    editor = atom.workspace.activePaneItem
    make_path = editor.getUri()

    while not fs.existsSync "#{make_path}/Makefile"
      previous_path = make_path
      make_path = path.join(make_path, '..')

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
    @makeRunnerView.show()
    @makeRunnerView.clear()
    @makeRunning = true
    make = cp.spawn 'make', args, { cwd: make_path }

    # Use readline to generate line input from raw data
    stdout = readline.createInterface { input: make.stdout, terminal: false }
    stderr = readline.createInterface { input: make.stderr, terminal: false }

    stdout.on 'line',  (line) =>
      @makeRunnerView.printOutput line

    stderr.on 'line',  (line) =>
      # search for file:line:col: references
      html_line = null
      line.replace /^([^:]+):(\d+):(\d+):(.*)$/, (match, file, row, col, errormessage) =>
        html_line = [
          $('<a>')
            .text "#{file}:#{row}:#{col}"
            .attr 'href', '#'
            .on 'click', (e) =>
              e.preventDefault()

              # load file, but check if it is already open in any of the panes
              loading = atom.workspaceView.open file, { searchAllPanes: true }
              loading.done (editor) =>
                editor.setCursorBufferPosition [row-1, col-1],
          $('<span>').text errormessage
        ]

      @makeRunnerView.printError html_line || line

    # fire this off when the make process comes to an end
    make.on 'close',  (code) =>
      if code is 0
        @updateStatus 'succeeded'
        if atom.config.get('make-runner.hidePane')
          setTimeout (=>
            @makeRunnerView.destroy()
          ), atom.config.get('make-runner.hidePaneDelay')
      else
        @updateStatus "failed with code #{code}"

      @makeRunning = false

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

  #
  # Set the default build target.
  #
  configDefaults:
    buildTarget: ''
  config:
    hidePane:
      type: 'boolean'
      default: false
      description: 'Hide make panel if execution is successful.'
    hidePaneDelay:
      type: 'integer'
      default: 3000
      min:0
