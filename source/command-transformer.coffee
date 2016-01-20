class Space.messaging.CommandTransformer extends Space.Object

  @mixin [
    Space.messaging.CommandHandlerDecorator
  ]

  @ERRORS: {
    missingCommand: 'Please specify command that require transforming'
    sameCommandType: 'Returned command from transforming cant be same type as
      the base one, use Space.messaging.CommandProcessor for this purpose'
    cannotTransformCommand: (command) ->
      new Error "No transforming method found to transform #{command.typeName()}
        command"

  }

  command: null

  constructor: ->
    @_initialize()
    super

  _initialize: ->
    if not @command?
      throw new Error Space.messaging.CommandTransformer.ERRORS.missingCommand

  onDependenciesReady: ->
    command = @command
    @_setupCommandHandlerDecorator(command)

  _setupCommandHandlerDecorator: (command) ->
    commandType = command.toString()
    unless @_hasTransformer(commandType)
      throw Space.messaging.CommandTransformer.ERRORS.cannotTransformCommand(command)

    transformer = @_getTransformer(commandType)
    @decorateCommandHandler(@_commandHandlerDecorator(transformer), command)

  _hasTransformer: (commandType) ->
    @process?
  _getTransformer: (commandType) ->
    @process

  _commandHandlerDecorator: (transformer) ->
    self = @
    wrapper = (handler) -> # THIS
      decoratedHandler = (command) ->
        transformedCommand = self._handleDomainErrors(-> transformer.call(self, command))

        # Coffeescript workaround for returning last element from invoked
        # function
        unless self._isCommand(transformedCommand)
          transformedCommand = command

        if self._areCommandsSameType([transformedCommand, command])
          throw new Error self.ERRORS.sameCommandType
        else
          handler(transformedCommand)

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
