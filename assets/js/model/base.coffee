# BASE MODEL
# --------------------------------------------------------------------------
# This is the base abstract model for all models of the System App.

class System.BaseModel extends Backbone.Model

    typeName: null

    # When was it last saved?
    lastSave: new Date(2000, 1, 1)

    # If model is syncing with server, property fetching will be true.
    fetching: false

    # Used for delayed saving to the server, so user can change multiple
    # properties of the model and it will send the changes to the server
    # all at once after a few milliseconds.
    timerSave: null


    # COMMON PROPERTIES
    # ----------------------------------------------------------------------

    # Get or set the model's active property.
    active: (value) =>
        if value?
            @set "active", value
        @get "active"

    # Get or set the model's friendly ID (updateable by the user, and different from the fixed "id").
    friendlyId: (value) =>
        if value?
            @set "friendlyId", value

        result = @get "friendlyId"

        if not result? or result is ""
            result = System.App.DataUtil.normalize(@get("name"), true)
            result = System.App.DataUtil.normalize(@get("title"), true) if not result? or result is ""
            result = System.App.DataUtil.normalize(@get("id"), true) if not result? or result is ""
            @set "friendlyId", result

        return result


    # ID AND URL HELPERS
    # ----------------------------------------------------------------------

    # Set a new entity ID, based on current date and an extra 2 random characters.
    generateId: =>
        chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
        today = new Date()
        result = today.valueOf().toString 16
        result += chars.substr Math.floor(Math.random() * chars.length), 1
        result += chars.substr Math.floor(Math.random() * chars.length), 1

        @set "id", result

        return result

    # Return the model's ID to be used on the local storage.
    localId: =>
        result = @typeName
        result += @id if @id?
        return result

    # The URL to call when syncing with server. If the model's ID is set, then
    # append it to the end of the URL.
    url: =>
        t = System.App.Settings.General.baseJsonUrl + @typeName.toLowerCase()

        if @id? and @id isnt ""
            return t + "/" + @id

        return t


    # PARSE AND TOJSON
    # ----------------------------------------------------------------------

    # Initialize the model, make sure its nested models and collections are created.
    initialize: =>
        return if not @relations?

        for key of @relations
            if not @attributes[key]?.typeName?
                @attributes[key] = new @relations[key](@attributes[key])
                @attributes[key].parentModel = this

    # If model has `relations` set, transform the data to proper models or collections.
    parse: (response) =>
        if not @relations?
            return response

        for key of @relations
            current = @get key
            responseValue = response[key]

            # Make sure value is valid JSON and not a string. Remove last `;` if there's one.
            # Alert if the response can't be parsed.
            if typeof responseValue is "string"
                try
                    if responseValue.substring(responseValue.length - 1) is ";"
                        responseValue = responseValue.substring(0, responseValue.length - 1)
                    responseValue = JSON.parse responseValue
                catch ex
                    console.warn @typeName + ".parse", responseValue, ex

            # If the current attribute is already "set" to the defined model / collection,
            # then update its value. Otherwise create a new model / collection.
            if current?.typeName?
                if current.update?
                    current.update responseValue
                else
                    current.set responseValue
                response[key] = current
            else
                response[key] = new @relations[key](responseValue)
                response[key].parentModel = this

        return response

    # If model has `relations` set, transform sub models and collections to JSON.
    toJSON: =>
        result = _.clone @attributes

        if @relations?
            for key of @relations
                result[key] = result[key].toJSON() if result[key]?

        return result


    # FETCH DATA
    # ----------------------------------------------------------------------

    # Override backbone's `fetch`. Set `fetching` to true before
    # fetching new data from server, and cancel fetching if collection
    # is being fetched already.
    fetch: (options) =>
        return if @fetching
        @fetching = true

        options = {} if not options?

        # Override `success` and `error`. If these callbacks are passed, they'll be handled
        # later inside `fetchSuccess` and `fetchError`.
        options.successCallback = options.success
        options.success = @fetchSuccess
        options.errorCallback = options.error
        options.error = @fetchError

        Backbone.Model.prototype.fetch.call this, options

    # Fetch data from local storage, using jquery.localData plugin.
    fetchLocal: =>
        return if @fetching
        @fetching = true

        localObj = $.localData.get @localId()

        if localObj?
            @set @parse localObj

        @fetching = false

    # When `fetch` is successful, set `fetching` to false.
    fetchSuccess: (model, resp, options) =>
        @fetching = false

        options.successCallback? model, resp, options
        System.App.consoleLog @typeName + ".fetch", "Success " + @id, resp

    # When `fetch` has problems or throws an error, set `fetching` to false
    # and log to the console if debugging is enabled.
    fetchError: (model, xhr, options) =>
        @fetching = false

        options.errorCallback? model, xhr, options
        System.App.consoleLog @typeName + ".fetch", "Error " + @id, xhr


    # SAVING DATA
    # ----------------------------------------------------------------------

    # Save model data. Try saving remotely, and if it fails, save a copy
    # on the local storage. Avoid saving to the server multiple times
    # in a row by using a timer to delay the remote save call.
    # Cancel the save is the model is currently being refreshed.
    save: (key, val, options) =>
        return if @fetching

        # We're not using `key` and `val` but Backbone uses it internally.
        # Just make sure `options` is properly set.
        options = val if not options?
        options = key if not options?

        if @timerSave?
            clearTimeout @timerSave
            @timerSave = null

        callback = () => @saveRemote options
        @timerSave = setTimeout callback, System.App.Settings.General.saveInterval

    # Save model data to the local storage using jquery.localData plugin.
    saveLocal: =>
        $.localData.set @localId(), @toJSON()

    # Save model data to the remote server (Node / MongoDB).
    # If no options are passed, created one, and set the
    # `success` and `error` callbacks.
    saveRemote: (options) =>
        @timerSave = null

        options = {} if not options?
        options.patch = System.App.Settings.General.savePatch

        # Override `success` and `error`. If these callbacks are passed, they'll be handled
        # later inside `saveSuccess` and `saveError`.
        options.successCallback = options.success
        options.success = @saveSuccess
        options.errorCallback = options.error
        options.error = @saveError

        # If `options.patch` is set, then send only updated data to the server.
        if options.patch and not @isNew()

            attrs = @changed

            # Make sure changed attributes inside nested collections are passed along.
            # Important: this will only work for first level nesting!!!
            if @relations?
                for key of @relations
                    # Get value of related model or collection.
                    propValue = @get key
                    # Has it a `changedModels` property?
                    if propValue.changedModels
                        changedModels = propValue.changedModels()
                        # Has changed models? If so, append to the `attrs`.
                        if changedModels.length > 0
                            attrs[key] = propValue.changedModels()

        # No patch, so send everything.
        else
            attrs = {}

        Backbone.Model.prototype.save.call this, attrs, options

    # Callback when the `save` is completed successfully. This will clear the local
    # storage data for this model, if there's one.
    saveSuccess: (model, resp, options) =>
        @lastSave = new Date()
        @deleteLocal()

        options.successCallback? model, resp, options
        System.App.consoleLog @typeName + ".save", "Success " + @id, resp

    # Callback when the `save` is not completed successfully or had an error.
    saveError: (model, xhr, options) =>
        @saveLocal()

        options.errorCallback? model, xhr, options
        System.App.consoleLog @typeName + ".save", "Error " + @id, xhr

    # Delete model data from local storage.
    deleteLocal: =>
        $.localData.del @localId()


    # NO SYNCING METHODS
    # ----------------------------------------------------------------------

    # To override the "save" method whenever we don't need to sync
    # the model with the server.
    noSyncSave: =>
        @generateId() if not @id? or @id is ""

    # To override the "destroy" method whenever we need to trigger the destroy
    # without syncing anything with the server.
    noSyncDestroy: (options) =>
        @trigger "destroy", this, @collection, options


# BASE COLLECTION
# --------------------------------------------------------------------------
# This is the base abstract collection for all collections of the System App.

class System.BaseCollection extends Backbone.Collection

    typeName: null

    # When was it last saved?
    lastSave: new Date(2000, 1, 1)

    # If collection is syncing with server, property fetching will be true.
    # Used to delay binding data to views while still loading.
    fetching: false

    # Temporary function to be executed whenever `fetch` is finished.
    # The callback must be in the format (err, results), whereas `err` contains
    # errors and problems (if any!) and `results` the final result.
    # IMPORTANT: this property will always cleared after called!!!
    onFetchCallback: null


    # ID HELPERS
    # ----------------------------------------------------------------------

    # Return the collection's ID to be used on the local storage.
    localId: =>
        result = @typeName
        result += @id if @id?
        result


    # FETCH DATA
    # ----------------------------------------------------------------------

    # Override backbone's `fetch`. Set `fetching` to true before
    # fetching new data from server, and cancel fetching if collection
    # is being fetched already.
    fetch: (options) =>
        return if @fetching
        @fetching = true

        # If no options are passed then create one, and set the
        # `success` and `error` callbacks.
        options = {} if not options?
        options.success = @fetchSuccess
        options.error = @fetchError

        Backbone.Collection.prototype.fetch.call this, options

    # Fetch data from local storage, using jquery.localData plugin.
    fetchLocal: =>
        return if @fetching
        @fetching = true

        localObj = $.localData.get @localId()

        if localObj?
            @reset localObj

        @fetching = false

    # When `fetch` is successful, set `fetching` to false.
    fetchSuccess: =>
        @fetching = false

        # If `onFetchCallback` is defined, call and set it back to null.
        if @onFetchCallback?
            @onFetchCallback null, true
            @onFetchCallback = null

    # When `fetch` has problems or throws an error, set `fetching` to false
    # and log to the console if debugging is enabled.
    fetchError: =>
        @fetching = false

        # If `onFetchCallback` is defined, call and set it back to null.
        if @onFetchCallback?
            @onFetchCallback "Could not load from remote server.", null
            @onFetchCallback = null

        System.App.consoleLog @typeName + ".fetch", "Fetch ERROR: " + @id, arguments

    # Delete collection data from local storage.
    deleteLocal: =>
        $.localData.del @localId()


    # CLEAR DATA
    # ----------------------------------------------------------------------

    # Clear all models by calling each model's destroy method,
    # and save the parent model if there's one.
    clear: =>
        _.each @models, (item) -> item.destroy() if item?
        @parentModel.save() if @parentModel?


    # NO SYNCING METHODS
    # ----------------------------------------------------------------------

    # To override the default "create" method whenever we don't need to sync
    # the collection models directly with the server.
    noSyncCreate: (model, options) =>
        options = (if options then _.clone(options) else {})

        model = @_prepareModel(model, options)
        return false if not model? or model is false
        model.generateId() if not model.id? or model.id is ""

        # Add the model without calling save afterwards.
        @add model, options

        return model


    # EXTRA HELPERS
    # ----------------------------------------------------------------------

    # Return an array containing all models which were changed since last sync.
    changedModels: =>
        result = []
        for m in @models
            if m.hasChanged()
                result.push m
        return result

    # Get a specific model by its friendlyId. If no item is found, return null.
    getByFriendlyId: (value) =>
        result = @where {friendlyId: value}

        if result.length > 0
            return result[0]
        else
            return null