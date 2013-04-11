# System DATA
# --------------------------------------------------------------------------
# This is a data manager for all collections and models used by System.

System.App.Data =

    autoUpdateEnabled: false
    timerRefreshLabels: null
    timerSaveUserSettings: null


    # COLLECTIONS
    # ----------------------------------------------------------------------

    # The current user's settings.
    userSettings: new System.UserSettings()

    # Holds the global collections for entities, maps, variables, events etc.
    auditData: new System.AuditDataCollection()
    auditEvents: new System.AuditEventCollection()
    entities: new System.EntityDefinitionCollection()
    maps: new System.MapCollection()
    variables: new System.VariableCollection()

    # Helper array to iterate through all collections.
    allCollections: []

    # LOADING FROM SERVER
    # ----------------------------------------------------------------------

    # Load all JSON files from server and sets a success and error callback.
    # While loading, the `fetching` property of the collection will be set
    # to true.
    init: ->
        @allCollections = [@auditData, @auditEvents, @entities, @maps, @variables]
        @userSettings.fetch()

        @timerRefreshLabels = null
        @autoUpdateEnabled = @userSettings.mapAuditAutoUpdate()
        @setEvents()

    # Set event listerners related to the app's data.
    setEvents: ->
        @auditData.off "sync", @startTimers
        @auditData.on "sync", @startTimers
        @userSettings.off "change", @saveUserSettings
        @userSettings.on "change", @saveUserSettings
        System.App.mapEvents.off "zoom", @userSettings.mapZoom
        System.App.mapEvents.on "zoom", @userSettings.mapZoom

    # Fetch all collections in parallel.
    fetch: ->
        taskEntities = (callback) =>
            @entities.onFetchCallback = callback
            @entities.fetch()

        taskAuditData = (callback) =>
            @auditData.onFetchCallback = callback
            @auditData.fetch()

        taskAuditEvents = (callback) =>
            @auditEvents.onFetchCallback = callback
            @auditEvents.fetch()

        taskVariables = (callback) =>
            @variables.onFetchCallback = callback
            @variables.fetch()

        taskMaps = (callback) =>
            @maps.onFetchCallback = callback
            @maps.fetch()

        # Fetch all collections from the server using `async`.
        parallels = [taskEntities, taskAuditData, taskAuditEvents, taskVariables, taskMaps]
        async.parallel parallels, @fetchFinished

    # Triggered after all data has loaded successfully.
    fetchFinished: (err, results) ->
        System.App.consoleLog "Data.load", "Error loading data.", err if err?
        System.App.dataEvents.trigger "load"

        # Make sure that the entities collections have up-to-date data.
        for entityDef in System.App.Data.entities.models
            url = entityDef.sourceUrl()
            data = entityDef.data()
            if data.length < 1 and url? and url isnt ""
                entityDef.refreshData()
                System.App.consoleLog("Data.fetchFinished",
                                      "Entity Definition #{entityDef.friendlyId()} has no data. Force refreshing!", url)


    # DATA PERSISTENCE
    # ----------------------------------------------------------------------

    # Saves all collections to the database (or local storage if network is down).
    save: ->
        @entities.save()
        @auditData.save()
        @auditEvents.save()
        @variables.save()
        @maps.save()
        @userSettings.save()

        System.App.alertEvents.trigger "footer", {title: System.App.Messages.dataSaved, message: System.App.Messages.okDataSavedLocally}

    # Auto save user settings to local storage whenever any of its properties gets updated.
    saveUserSettings: ->
        if System.App.Data.timerSaveUserSettings?
            clearTimeout System.App.Data.timerSaveUserSettings
            System.App.Data.timerSaveUserSettings = null

        interval = System.App.Settings.General.saveInterval
        callback = System.App.Data.userSettings.save

        System.App.Data.timerSaveUserSettings = setTimeout callback, interval


    # AUTOREFRESH TIMERS
    # ----------------------------------------------------------------------

    # Start the auto refreshing timers for [AuditData](auditData.html) and normal entities.
    startTimers: ->
        return if not System.App.Data.autoUpdateEnabled

        System.App.consoleLog "Data.startTimers", "Auto Refresh Timers: STARTED"
        System.App.Data.stopTimers true

        # Start the map refresh timer.
        if not System.App.Data.timerRefreshLabels?
            interval = setInterval System.App.mapView.refreshLabels, System.App.Data.userSettings.mapLabelRefreshInterval()
            System.App.Data.timerRefreshLabels = interval

    # Stop and cancel the auto refreshing timers to update [Shape Labels]
    stopTimers: (doNotLog) ->
        if not doNotLog
            System.App.consoleLog "Data.stopTimers", "Auto Refresh Timers: STOPPED"

        if System.App.Data.timerRefreshLabels?
            clearInterval System.App.Data.timerRefreshLabels
            System.App.Data.timerRefreshLabels = null