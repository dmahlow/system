# SERVER SETTINGS
# --------------------------------------------------------------------------
# All server settings should be set here (filename should be settings.coffee).
# Check the `settings.default.coffee` for a list of all available settings.

class Settings

# Singleton implementation
# --------------------------------------------------------------------------
# Default settings will be copied from `settings.default.coffee`.
Settings.getInstance = ->
    if not @instance?
        xtend = (source, target) ->
            for prop, value of source
                if value?.constructor is Object
                    target[prop] = {} if not target[prop]?
                    xtend source[prop], target[prop]
                else
                    target[prop] = source[prop] if not target[prop]?

        @instance = new Settings()
        settingsDefault = require "./settings.default.coffee"
        xtend settingsDefault, @instance

    return @instance

module.exports = exports = Settings.getInstance()