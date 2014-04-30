shell = require 'shelljs'
path = require 'path'
fs = require 'fs-plus'

module.exports =

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
    target = atom.config.get('make-runner.buildTarget')

    # Get the path of the current file
    editor = atom.workspace.activePaneItem
    make_path = editor.getUri()

    while not fs.existsSync "#{make_path}/Makefile"
      console.log("#{make_path}/Makefile")
      previous_path = make_path
      make_path = path.join(make_path, '..')

      if make_path == previous_path
        @updateStatus "no makefile found"

        setTimeout (=>
          @clearStatus()
        ), 3000

        return

    if target?.length
      cmd = "cd #{make_path} && make #{target}"
    else
      cmd = "cd #{make_path} && make"

    shell.cd atom.project.path
    shell.exec cmd, (code, output) =>
      if code is 0
        @updateStatus 'succeeded'
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

  serialize: ->

  #
  # Set the default build target.
  #
  configDefaults:
    buildTarget: ''
