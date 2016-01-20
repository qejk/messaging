Space.messaging.CommandHandlerDecorator = {

  dependencies: {
    commandBus: 'Space.messaging.CommandBus'
  }

  decorateCommandHandler: (decorator, command) ->
    commandType = command.toString()
    unless @_hasCommandRegisteredHandlerOnCommandBus(commandType)
      throw new Error "Cannot find command handler for #{commandType}"

    currentHandlerOnCommandBus = @_getCurrentCommandHandlerFromCommandBus(
      commandType
    )
    decoratedCommandHandler = decorator(currentHandlerOnCommandBus)
    @_overrideCurrentHandler(
      commandType, decoratedCommandHandler
    )

  _hasCommandRegisteredHandlerOnCommandBus: (commandType) ->
    @commandBus.hasHandlerFor(commandType)

  _getCurrentCommandHandlerFromCommandBus: (commandType) ->
    @commandBus.getHandlerFor(commandType)

  _overrideCurrentHandler: (commandType, decoratedCommandHandler) ->
    @commandBus.overrideHandler(commandType, decoratedCommandHandler)
}

