class Space.messaging.CommandProcessor extends Space.Object

  dependencies: {
    commandBus: 'Space.messaging.CommandBus'
  }

  @ERRORS: {
    missingCommand: 'Please specify command that require processing'
    missingCommandHandler: 'Please register a handler for specific command before
    processing it'
    cannotProcessCommand: (command) ->
      new Error "No processing method found to process #{command.typeName()}
        command"
  }

  command: null

  constructor: ->
    @_initialize()
    super

  _initialize: ->
    if not @command?
      throw new Error Space.messaging.CommandProcessor.ERRORS.missingCommand

  onDependenciesReady: ->
    @_setup()

  _setup: ->
    @_wrapCommand(@command)

  _wrapCommand: (command) ->
    commandType = command.toString()
    unless @_hasCommandRegisteredHandlerOnCommandBus(commandType)
      throw new Error Space.messaging.CommandProcessor.ERRORS.missingCommandHandler
    unless @_hasProcessor(commandType)
      throw Space.messaging.CommandProcessor.ERRORS.cannotProcessCommand(command)

    currentHandlerOnCommandBus = @_getCurrentCommandHandlerFromCommandBus(
      commandType
    )
    processor = @_getProcessor(commandType)
    wrappedCommandHandlerWithProcessor = @_wrapCommandHandlerWithProcessor(
      currentHandlerOnCommandBus, processor
    )
    @_overrideCurrentHandlerWithWrappedProcessor(
      commandType, wrappedCommandHandlerWithProcessor
    )

  _hasCommandRegisteredHandlerOnCommandBus: (commandType) ->
    @commandBus.hasHandlerFor(commandType)

  _hasProcessor: (commandType) ->
    @process?
  _getProcessor: (commandType) ->
    @process

  _getCurrentCommandHandlerFromCommandBus: (commandType) ->
    @commandBus.getHandlerFor(commandType)

  _wrapCommandHandlerWithProcessor: (handler, processor) ->
    self = @
    wrapper = (command) ->
      processedCommand = processor.call(self, command)
      processedCommand = command unless processedCommand
      handler(command)

    return wrapper

  _overrideCurrentHandlerWithWrappedProcessor: (commandType, wrappedHandler) ->
    @commandBus.overrideHandler(commandType, wrappedHandler)
