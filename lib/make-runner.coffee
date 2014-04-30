cp = require 'child_process'
path = require 'path'
fs = require 'fs-plus'
readline = require 'readline'

module.exports =
  #
  # Lock flag for running make processes (to avoid running make multiple times concurrently)
  #
  make_running: false

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
  activate: ->
    atom.workspaceView.command 'make-runner:run', '.editor', => @run()

  #
  # Run the configured make target.
  #
  run: ->
    # guard against launching make while it is still running
    if @make_running
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
    @make_running = true
    make = cp.spawn 'make', args, { cwd: make_path }

    # Use readline to generate line input from raw data
    stdout = readline.createInterface { input: make.stdout, terminal: false }

    stderr = readline.createInterface { input: make.stderr, terminal: false }

    stdout.on 'line',  (line) =>
      console.log('stdout:', line)

    stderr.on 'line',  (line) =>
      console.log('stderr:', line)

    # fire this off when the make process comes to an end
    make.on 'close',  (code) =>
      if code is 0
        @updateStatus 'succeeded'
      else
        @updateStatus "failed with code #{code}"

      @make_running = false

      setTimeout (=>
        @clearStatus()
      ), 3000

  #
  # Deactivate the package.
  #
  deactivate: ->
    @clearStatus()

  serialize: ->

  #
  # Set the default build target.
  #
  configDefaults:
    buildTarget: ''
