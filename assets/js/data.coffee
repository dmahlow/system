# System DATA
# --------------------------------------------------------------------------
# This is a data manager for all collections and models used by SystemApp.

SystemApp.Data =

    autoUpdateEnabled: false
    timerRefreshLabels: null
    timerSaveUserSettings: null


    # COLLECTIONS
    # ----------------------------------------------------------------------

    # The current user's settings.
    userSettings: new SystemApp.UserSettings()

    # Holds the global collections for entities, maps, variables, events etc.
    auditData: new SystemApp.AuditDataCollection()
    auditEvents: new SystemApp.AuditEventCollection()
    entities: new SystemApp.EntityDefinitionCollection()
    maps: new SystemApp.MapCollection()
    variables: new SystemApp.VariableCollection()

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
        @autoUpdateEnabled = @userSettings.mapAutoRefresh()
        @setEvents()

    # Set event listerners related to the app's data.
    setEvents: ->
        @auditData.off "sync", @startTimers
        @auditData.on "sync", @startTimers
        @userSettings.off "change", @saveUserSettings
        @userSettings.on "change", @saveUserSettings
        SystemApp.mapEvents.off "zoom", @userSettings.mapZoom
        SystemApp.mapEvents.on "zoom", @userSettings.mapZoom

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
        SystemApp.consoleLog "Data.load", "Error loading data.", err if err?
        SystemApp.dataEvents.trigger "load"

        # Make sure that the entities collections have up-to-date data.
        for entityDef in SystemApp.Data.entities.models
            url = entityDef.sourceUrl()
            data = entityDef.data()
            if data.length < 1 and url? and url isnt ""
                entityDef.refreshData()
                SystemApp.consoleLog("Data.fetchFinished",
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

        SystemApp.alertEvents.trigger "footer", {title: SystemApp.Messages.dataSaved, message: SystemApp.Messages.okDataSavedLocally}

    # Auto save user settings to local storage whenever any of its properties gets updated.
    saveUserSettings: ->
        if SystemApp.Data.timerSaveUserSettings?
            clearTimeout SystemApp.Data.timerSaveUserSettings
            SystemApp.Data.timerSaveUserSettings = null

        interval = SystemApp.Settings.General.saveInterval
        callback = SystemApp.Data.userSettings.save

        SystemApp.Data.timerSaveUserSettings = setTimeout callback, interval


    # AUTOREFRESH TIMERS
    # ----------------------------------------------------------------------

    # Start the auto refreshing timers for [AuditData](auditData.html) and normal entities.
    startTimers: ->
        return if not SystemApp.Data.autoUpdateEnabled

        SystemApp.consoleLog "Data.startTimers", "Auto Refresh Timers: STARTED"
        SystemApp.Data.stopTimers true

        # Start the map refresh timer.
        if not SystemApp.Data.timerRefreshLabels?
            interval = setInterval SystemApp.mapView.refreshLabels, SystemApp.Data.userSettings.mapLabelRefreshInterval()
            SystemApp.Data.timerRefreshLabels = interval

    # Stop and cancel the auto refreshing timers to update [Shape Labels]
    stopTimers: (doNotLog) ->
        if not doNotLog
            SystemApp.consoleLog "Data.stopTimers", "Auto Refresh Timers: STOPPED"

        if SystemApp.Data.timerRefreshLabels?
            clearInterval SystemApp.Data.timerRefreshLabels
            SystemApp.Data.timerRefreshLabels = null