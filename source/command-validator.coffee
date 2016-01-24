class Space.messaging.CommandValidator extends Space.Object

  @mixin [
    Space.messaging.CommandHandlerDecorator
    Space.messaging.EventPublishing
  ]

  @ERRORS: {
    missingCommands: 'Please specify commands that require validating'
    cannotValidateCommand: (command) ->
      new Error "No validation method found to validate #{command.typeName()}
        command"
  }

  commands: null

  constructor: ->
    @_initialize()
    super

  _initialize: ->
    if not @commands?
      throw new Error Space.messaging.CommandValidator.ERRORS.missingCommands

  onDependenciesReady: ->
    for command in @commands
      @_setupCommandHandlerDecorator(command)

  _setupCommandHandlerDecorator: (command) ->
    commandType = command.toString()
    unless @_hasValidator(commandType)
      throw Space.messaging.CommandValidator.ERRORS.cannotValidateCommand(command)

    validator = @_getValidator(commandType)
    @decorateCommandHandler(@_commandHandlerDecorator(validator), command)

  _hasValidator: (commandType) ->
    @validateCommands()[commandType]?

  _getValidator: (commandType) ->
    @validateCommands()[commandType]

  _commandHandlerDecorator: (validator) ->
    self = @
    wrapper = (handler) ->
      decoratedHandler = (command) ->
        self._handleDomainErrors(-> validator.call(self, command))
        handler(command)

      return decoratedHandler
    return wrapper

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
