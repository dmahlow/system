# System API
# --------------------------------------------------------------------------
# This is the main namespace / object for the System API. This wraps all
# individual API methods into a single "api" object which should be accessible
# directly from the window / document instance.

SystemApp.Api =

    # Property that defines if console logs are enabled.
    logsEnabled: false

    # Init the System API interface.
    init: ->
        SystemApp.Api.log "INIT: " + new Date()
        window.api = SystemApp.Api


    # GET DATA
    # ----------------------------------------------------------------------

    # Return models from a collection based on the filter.
    # Passing no parameters or null will return the whole collection.
    # A string or integer will be used as the object friendly ID.
    # An object will be used as properties (key and values).
    # A function will be used as a callback which should return true or false.
    getFromCollection: (collection, filter) ->
        if not collection?
            return null
        if not filter?
            return collection.models
        if _.isFunction filter
            result = _.filter collection, filter
        else if _.isObject filter
            result = collection.where filter
        else
            result = collection.where {friendlyId: filter}

        return result


    # LOGGING
    # ----------------------------------------------------------------------

    # Enable API logs (will write to the console for every API call).
    enableLogs: ->
        SystemApp.Api.logsEnabled = true

    # Disable API logs (will NOT write to the console for every API call).
    disableLogs: ->
        SystemApp.Api.logsEnabled = false

    # Log to the console, but only if `logsEnabled` is true.
    log: (msg) ->
        console.log "API", msg if SystemApp.Api.logsEnabled