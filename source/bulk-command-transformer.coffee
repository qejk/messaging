class Space.messaging.BulkCommandTransformer extends Space.messaging.CommandTransformer

  @mixin [
    Space.messaging.CommandHandlerDecorator
  ]

  commands: null

  constructor: ->
    super
    @commands ?= []

  _initialize: ->
    if not @commands?
      throw new Error Space.messaging.CommandTransformer.ERRORS.missingCommands

  onDependenciesReady: ->
    for command in @commands
      @_setupCommandHandlerDecorator(command)

  _hasTransformer: (commandType) ->
    @transformers()[commandType]?

  _getTransformer: (commandType) ->
    @transformers()[commandType]

Space.messaging.BulkCommandProcessor.ERRORS.missingCommands =
  'Please specify commands that require transformer'