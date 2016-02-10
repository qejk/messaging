Space.messaging.Hooks = {

  dependencies: {
    _hooks: 'Space.messaging.HookRegistry'
  },

  addBeforeHook(messageType, hookClass, hook) {
    return this._hooks.addBeforeHook(
      messageType, hookClass, hook, this
    );
  },

  addBeforeHookAsFirst(messageType, hookClass, hook) {
    return this._hooks.addBeforeHookAsFirst(
      messageType, hookClass, hook, this
    );
  },

  addAfterHook(messageType, hookClass, hook) {
    return this._hooks.addAfterHook(
      messageType, hookClass, hook, this
    );
  },

  addAfterHookAsFirst(messageType, hookClass, hook) {
    return this._hooks.addAfterHookAsFirst(
      messageType, hookClass, hook, this
    );
  },
  // TODO: Keep getter syntax or more natural expressive hooks(), beforeHooks(),
  // afterHooks(), ruleHooks()
  getHooks(messageType, hookType) {
    return this._hooks.getHooks(messageType, hookType);
  },

  getBeforeHooks(messageType) {
    return this.getHooks(messageType, 'before');
  },

  getAfterHooks(messageType) {
    return this.getHooks(messageType, 'after');
  },

  getRuleHooks(messageType) {
    return this.getHooks(messageType, 'rule');
  }
}
