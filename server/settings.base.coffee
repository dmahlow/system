# SERVER SETTINGS
# --------------------------------------------------------------------------
# All server settings should be set here (filename is settings.coffee).

class Settings

# Singleton implementation
# --------------------------------------------------------------------------
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