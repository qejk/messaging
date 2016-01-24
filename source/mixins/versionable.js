Space.messaging.Versionable = {

  schemaVersion: 1,

  onConstruction(data) {
    if (_.isObject(data)) this._transformLegacySchema(data);
  },

  _transformLegacySchema(data) {
    let schemaVersion = data.schemaVersion;
    if (!schemaVersion || schemaVersion === this.schemaVersion) return;
    for (let version = schemaVersion; version < this.schemaVersion; version++) {
      let transformMethod = this[`transformFromVersion${version}`];
      if (transformMethod !== undefined) transformMethod.call(this, data);
    }
    data.schemaVersion = this.schemaVersion;
  }

};
