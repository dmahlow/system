# APP CLIENT SETTINGS
# --------------------------------------------------------------------------
# All server settings should be set here (filename should be settings.coffee).
# Check the `settings.default.coffee` for a list of all available settings.

System.App.Settings =

    General:
        debug: null


# COPY DEFAULT SETTINGS
# --------------------------------------------------------------------------
# Default settings will be copied from `settings.default.coffee`.
xtend = (source, target) ->
    for prop, value of source
        if value?.constructor is Object
            target[prop] = {} if not target[prop]?
            xtend source[prop], target[prop]
        else
            target[prop] = source[prop] if not target[prop]?

xtend System.App.SettingsDefault, System.App.Settings