class Space.messaging.CommandProcessor extends Space.Object

  @mixin [
    Space.messaging.CommandHandlerDecorator
    Space.messaging.EventPublishing
  ]

  @ERRORS: {
    missingCommand: 'Please specify command that require processing'
    commandTypeMismatch: 'Returned command from processing must be same type as
      the processed one'
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
    command = @command
    @_setupCommandHandlerDecorator(command)

  _setupCommandHandlerDecorator: (command) ->
    commandType = command.toString()
    unless @_hasProcessor(commandType)
      throw Space.messaging.CommandProcessor.ERRORS.cannotProcessCommand(command)

    processor = @_getProcessor(commandType)
    @decorateCommandHandler(@_commandHandlerDecorator(processor), command)

  _hasProcessor: (commandType) ->
    @process?
  _getProcessor: (commandType) ->
    @process

  _commandHandlerDecorator: (processor) ->
    self = @
    wrapper = (handler) -> # THIS
      decoratedHandler = (command) ->
        processedCommand = self._handleDomainErrors(-> processor.call(self, command))

        # Coffeescript workaround for returning last element from invoked
        # function
        unless self._isCommand(processedCommand)
          processedCommand = command

        unless self._areCommandsSameType([processedCommand, command])
          throw new Error self.ERRORS.commandTypeMismatch
        else
          handler(command)

      return decoratedHandler
    return wrapper

  _isCommand: (command) ->
    command instanceof Space.messaging.Command
  _areCommandsSameType: (commands=[]) ->
    commands[0].toString() == commands[1].toString()

  _handleDomainErrors: (fn) ->
    try
      return fn.call(@)
    catch error
      if error instanceof Space.Error
        @publish(new Space.domain.Exception({
          thrower: @constructor.name,
          error: error
        }))
        return null
      else
        throw error
