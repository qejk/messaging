class Space.messaging.BulkCommandProcessor extends Space.messaging.CommandProcessor

  commands: null

  constructor: ->
    super
    @commands ?= []

  _initialize: ->
    if not @commands?
      throw new Error Space.messaging.CommandProcessor.ERRORS.missingCommands

  _setup: ->
    for command in @commands
      @_wrapCommand(command)

  _hasProcessor: (commandType) ->
    @processors()[commandType]?

  _getProcessor: (commandType) ->
    @processors()[commandType]

Space.messaging.BulkCommandProcessor.ERRORS.missingCommands =
  'Please specify commands that require processing'