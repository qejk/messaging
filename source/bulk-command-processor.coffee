class Space.messaging.BulkCommandProcessor extends Space.messaging.CommandProcessor

  @mixin [
    Space.messaging.CommandHandlerDecorator
  ]

  commands: null

  constructor: ->
    super
    @commands ?= []

  _initialize: ->
    if not @commands?
      throw new Error Space.messaging.CommandProcessor.ERRORS.missingCommands

  onDependenciesReady: ->
    for command in @commands
      @_setupCommandHandlerDecorator(command)

  _hasProcessor: (commandType) ->
    @processors()[commandType]?

  _getProcessor: (commandType) ->
    @processors()[commandType]

Space.messaging.BulkCommandProcessor.ERRORS.missingCommands =
  'Please specify commands that require processing'