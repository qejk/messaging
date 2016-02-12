Space.Object.extend('Space.messaging.CommandMiddleware', {

  dependencies: {
    underscore: 'underscore',
    hooks: 'Space.messaging.CommandBusHooks'
  },

  mixin: [
    Space.messaging.DeclarativeMappings
  ],

  onDependenciesReady() {
    if (this.before !== undefined) this._setupBeforeHooks();
    if (this.after !== undefined) this._setupAfterHooks();
    if (this.beforeMap !== undefined) this._setupBeforeMapHooks();
    if (this.afterMap !== undefined) this._setupAfterMapHooks()
  },

  _setupBeforeHooks: function() {
    return this.hooks.addGlobalBeforeHook(this, this.before.bind(this));
  },

  _setupAfterHooks: function() {
    return this.hooks.addGlobalAfterHook(this, this.after.bind(this));
  },

  _setupBeforeMapHooks: function() {
    return this._setupDeclarativeMappings('beforeMap', (function(_this) {
      return function(hook, commandName) {
        return _this.hooks.addBeforeHook(
          commandName, _this, hook.bind(_this)
        );
      };
    })(this));
  },

  _setupAfterMapHooks: function() {
    return this._setupDeclarativeMappings('afterMap', (function(_this) {
      return function(hook, commandName) {
        return _this.hooks.addAfterHook(
          commandName, _this, hook.bind(_this)
        );
      };
    })(this));
  },
});
