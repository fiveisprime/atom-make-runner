shell = require 'shelljs'
path = require 'path'

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

    if target?.length
      cmd = "make #{target}"
    else
      cmd = 'make'

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
