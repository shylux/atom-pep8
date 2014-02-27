path = require 'path'
process = require 'child_process'
byline = require 'byline'

Pep8ErrorsView = require './pep8-view'

module.exports =
    supportedExtensions: [".py"]
    errorView: null
    pep8Path: null

    activate: (state) ->
        unless atom.config.get('pep8.PEP8Path')
            atom.config.set('pep8.PEP8Path', "/usr/local/bin/pep8")

        @pep8Path = atom.config.get('pep8.PEP8Path')

        atom.workspaceView.command 'pep8:lint', =>
            @lint()

    lint: ->
        editor = atom.workspace.getActiveEditor()
        return unless editor?

        filePath = editor.getPath()
        if path.extname(filePath) not in @supportedExtensions
            console.log "PEP8 Linter: Ignore file " + filePath
            return

        @lintFile filePath, (errors) ->
            if errors
                @errorView = new Pep8ErrorsView()
                @errorView.setItems(errors)
                @errorView.show()

    lintFile: (path, callback) ->

        console.log "PEP8 Linter: Linting file " + path

        line_expr = /:(\d+):(\d+): (E\d{3}) (.*)/
        errors = []

        return unless @pep8Path

        proc = process.spawn(@pep8Path, [path])

        # Watch for pep8 errors
        output = byline(proc.stdout)
        output.on 'data', (line) ->
            line = line.toString().replace path, ""
            matches = line_expr.exec(line)

            if matches
                errors.push {
                    "message": matches.pop(),
                    "type": matches.pop(),
                    "position": parseInt(matches.pop()) - 1,
                    "line": parseInt(matches.pop()) - 1
                }
            else
                console.log "PEP8 Linter: Failed to match " + line

        # Watch for the exit code
        proc.on 'exit', (exit_code, signal) ->
            if not exit_code or not errors
                return
            callback errors
