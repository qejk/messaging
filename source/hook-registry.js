Space.Object.extend('Space.messaging.HookRegistry', {

  dependencies: {
    underscore: 'underscore'
  },

  Constructor() {
    this._hooks = {};
    this._globalHooks = {};
  },

  addMessageHook(messageType, hookType, callback) {
    if (this._hooks[messageType] === undefined) {
      this._hooks[messageType] = {};
    }
    if (this._hooks[messageType][hookType] === undefined) {
      this._hooks[messageType][hookType] = [];
    }
    return callback(this._hooks[messageType][hookType]);
  },

  addBeforeHook(messageType, hookClass, hook, registeredViaClass,) {
    var hookType = 'before';
    var hookObj = this._createHookObject(
      hookClass, hookType, hook, registeredViaClass
    );
    return this.addMessageHook(messageType, hookType, function(hooks) {
      return hooks.push(hookObj);
    });
  },

  addBeforeHookAsFirst(messageType, hookClass, hook, registeredViaClass,) {
    var hookType = 'before';
    var hookObj = this._createHookObject(
      hookClass, hookType, hook, registeredViaClass
    );
    return this.addMessageHook(messageType, hookType, function(hooks) {
      return hooks.unshift(hookObj);
    });
  },

  addAfterHook(messageType, hookClass, hook, registeredViaClass,) {
    var hookType = 'after';
    var hookObj = this._createHookObject(
      hookClass, hookType, hook, registeredViaClass
    );
    return this.addMessageHook(messageType, hookType, function(hooks) {
      return hooks.push(hookObj);
    });
  },

  addAfterHookAsFirst(messageType, hookClass, hook, registeredViaClass,) {
    var hookType = 'after';
    var hookObj = this._createHookObject(
      hookClass, hookType, hook, registeredViaClass
    );
    return this.addMessageHook(messageType, hookType, function(hooks) {
      return hooks.unshift(hookObj);
    });
  },

  addRuleHook(messageType, hookClass, hook) {
    var hookType = 'rule';
    var hookObj = this._createHookObject(hookClass, hookType, hook);

    return this.addMessageHook(messageType, hookType, function(hooks) {
      return hooks.push(hookObj);
    });
  },

  addGlobalHook(hookType, callback) {
    if (this._globalHooks[hookType] === undefined) {
      this._globalHooks[hookType] = [];
    }
    return callback(this._globalHooks[hookType]);
  },

  addGlobalBeforeHook(hookClass, hook) {
    var hookType = 'before';
    var hookObj = this._createHookObject(hookClass, hookType, hook);
    return this.addGlobalHook(hookType, function(hooks) {
      return hooks.push(hookObj);
    });
  },

  addGlobalAfterHook(hookClass, hook) {
    var hookType = 'after';
    var hookObj = this._createHookObject(hookClass, hookType, hook);
    return this.addGlobalHook(hookType, function(hooks) {
      return hooks.push(hookObj);
    });
  },

  getHooks(messageType, hookType) {
    var registeredViaClass, hookMappings, hooks, messageMappings, ref;
    hooks = {};
    self = this;

    this.underscore.each(this._hooks, function(hookMappings, messageType){
      self.underscore.each(hookMappings, function(hooksForType, hookType){
        if (hooks[messageType] === undefined) {
          hooks[messageType] = {};
        }
        if (hooks[messageType][hookType] === undefined) {
          hooks[messageType][hookType] = [];
        }
        hooks[messageType][hookType] = hooks[messageType][hookType].concat(
          hooksForType
        )
      })
    });

    if (hooks[messageType] === undefined ||
    hooks[messageType][hookType] === undefined) {
      return [];
    }
    return this._applyGlobalHooksToHooksWithType(
      hooks[messageType][hookType], hookType
    );
  },

  getBeforeHooks(messageType) {
    return this.getHooks(messageType, 'before');
  },

  getAfterHooks(messageType) {
    return this.getHooks(messageType, 'after');
  },

  getRuleHooks(messageType) {
    return this.getHooks(messageType, 'rule');
  },

  _applyGlobalHooksToHooksWithType(hooks, hookType) {
    if (this._globalHooks[hookType] === undefined) {
      this._globalHooks[hookType] = [];
    }
    return this._globalHooks[hookType].concat(hooks);
  },

  _createHookObject(hookClass, hookType, hook, registeredViaClass) {
    obj = {
      hookClass: hookClass,
      hook: hook,
      hookType: hookType,
    };

    if (registeredViaClass !== undefined) {
      obj.registeredVia = registeredViaClass;
      obj.isGlobal = false;
    } else {
      obj.isGlobal = true;
    }
    return obj;
  }

});
