# SERVER MANAGER
# --------------------------------------------------------------------------
# Handles all automated server procedures like log cleaning, Audit Data
# refresh, CMDB updates etc. The manager is started automatically with the app.

class Manager

    # Define the referenced objects.
    database = require "./database.coffee"
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"
    sockets = require "./sockets.coffee"
    sync = require "./sync.coffee"

    # Require file system.
    fs = require "fs"


    # TIMERS AND PROPERTIES
    # ----------------------------------------------------------------------

    connectionErrorCount: 0         # How many consecutive connection errors the app manager's got.
    timerDatabaseClean: null        # Holds the [Database](database.html) cleaner timer.
    timersEntityRefresh: null       # Holds all [Entity](entities.html) refresh timers.
    timersAuditDataRefresh: null    # Holds all [AuditData](auditData.html) refresh timers.

    # Holds the "restart all" timer. This is used in case the app identifies
    # multiple connection errors in a short period of time, meaning that
    # internet connection is broken or unreliable. In this case, all other
    # timers will be stopped and the restart timer will schedule a new restart
    # after a few seconds - value is defined at the [Settings](settings.html).
    timerRestartAll: null

    # INIT
    # ----------------------------------------------------------------------

    # Init the app manager by starting all the necessary timers.
    init: =>
        @initDatabaseTimer()
        @initEntityTimers()
        @initAuditDataTimers()


    # ERROR MANAGEMENT
    # ----------------------------------------------------------------------

    # Increase the connection error counter. and pass an optional error message do the manager.
    connectionError: =>
        @connectionErrorCount++


    # DATABASE MAINTENANCE
    # ----------------------------------------------------------------------

    # Init the [Database](database.html) cleaner timer.
    # Run the `cleanLogs` procedure every X seconds. The log "expiry hours" is defined on the
    # [Server Settings](settings.html). By default, logs will be stored for a minimum
    # of 2 hours and maximum of 3 hours.
    initDatabaseTimer: =>
        @stopDatabaseTimer()
        @timerDatabaseClean = setInterval database.cleanLogs, settings.Database.logExpires * 1800000

    # Stop the running database cleaner timer.
    stopDatabaseTimer: =>
        if @timerDatabaseClean?
            clearInterval @timerDatabaseClean
        @timerDatabaseClean = null


    # ENTITY MANAGER
    # ----------------------------------------------------------------------

    # Init the [Entity](entityDefinition.html) refresh timers, by creating one interval
    # timer for each entity definition and transmitting the refreshed data to users via sockets.
    initEntityTimers: =>
        @stopEntityTimers()
        database.getEntityDefinition null, @startEntityTimers

    # Stop all running [Entity](entityDefinition.html) refresh timers and
    # clear the `timersEntityRefresh` array.
    stopEntityTimers: =>
        if @timersEntityRefresh?
            clearInterval timer for timer in @timersEntityRefresh
        @timersEntityRefresh = []

    # Start the [Entity](entityDefinition.html) timers based on the returned items
    # and error (if any) in result of the `getAuditData` database call.
    startEntityTimers: (err, result) =>
        if err?
            sockets.sendServerError "Manager: could not load Entity Definition items.", err
        else
            @setEntityTimer entityDef for entityDef in result

    # Add an [Entity](entityDefinition.html) refresh timer to the `timersEntityRefresh` array.
    setEntityTimer: (entityDef) =>
        callback = => @refreshEntity entityDef
        interval = entityDef.refreshInterval

        # Make sure interval is at least 2 seconds.
        if not interval? or interval < settings.Web.minimumRefreshInterval
            interval = settings.Web.minimumRefreshInterval
            logger.warn "Entity Definition data refresh interval is too low: ID #{entityDef.friendlyId}, interval #{entityDef.refreshInterval} seconds."

        # Set the timer. Interval is in seconds, so we must multiply by 1000.
        timer = setInterval callback, interval * 1000

        @timersEntityRefresh.push timer

    # Refresh the specified [Entity](entityDefinition.html) data. This will run ONLY
    # if there are connected clients, to avoid bandwidth and processing waste.
    refreshEntity: (entityDef) =>
        if sockets.getConnectionCount() < 1
            return

        sync.download entityDef.sourceUrl, settings.Paths.downloadsDir + "entityobjects." + entityDef.friendlyId + ".json", (err, localFile) =>
            @transmitDataToClients err, localFile, entityDef, sockets.sendEntityRefresh, database.setEntityDefinition


    # AUDIT DATA MANAGER
    # ----------------------------------------------------------------------

    # Init the [AuditData](auditadta.html) refresh timers, by creating one interval
    # timer for each audit data and transmitting the refreshed data to users via sockets.
    initAuditDataTimers: =>
        @stopAuditDataTimers()
        database.getAuditData null, @startAuditDataTimers

    # Stop all running [AuditData](auditData.html) refresh timers and
    # clear the `timersAuditDataRefresh` array.
    stopAuditDataTimers: =>
        if @timersAuditDataRefresh?
            clearInterval timer for timer in @timersAuditDataRefresh
        @timersAuditDataRefresh = []

    # Start the [AuditData](auditData.html) timers based on the returned items
    # and error (if any) in result of the `getAuditData` database call.
    startAuditDataTimers: (err, result) =>
        if err?
            sockets.sendServerError "Manager: could not load Audit Data items.", err
        else
            @setAuditDataTimer auditData for auditData in result

    # Add an [AuditData](auditadata.html) refresh timer to the `timersAuditDataRefresh` array.
    setAuditDataTimer: (auditData) =>
        callback = => @refreshAuditData auditData
        interval = auditData.refreshInterval

        # Make sure interval is at least 2 seconds.
        if not interval? or interval < settings.Web.minimumRefreshInterval
            interval = settings.Web.minimumRefreshInterval
            logger.warn "Audit Data refresh interval is too low: ID #{auditData.friendlyId}, interval #{auditData.refreshInterval} seconds."

        # Set the timer. Interval is in seconds, so we must multiply by 1000.
        interval = interval * 1000
        timer = setInterval callback, interval
        @timersAuditDataRefresh.push timer

        if settings.General.debug
            logger.info "Manager.setAuditDataTimer", auditData.friendlyId, interval + "ms"

    # Refresh the specified [AuditData](auditData.html) records. This will run ONLY
    # if there are connected clients, to avoid bandwidth and processing waste.
    refreshAuditData: (auditData) =>
        if sockets.getConnectionCount() < 1
            return

        sync.download auditData.sourceUrl, settings.Paths.downloadsDir + "auditdata." + auditData.friendlyId + ".json", (err, localFile) =>
            @transmitDataToClients err, localFile, auditData, sockets.sendAuditDataRefresh, database.setAuditData


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Transmit refreshed `data` to the connected clients/browsers via Socket.IO.
    # This can be for example the `data` attribute of an [AuditData](auditData..html) or
    # the collection of [Entity Objects](entityObject.html) from an [Entity Definition](entityDefinition.html).
    # The `socketsCallback` and `dbCallback` are called against the passed object if no errors are found.
    transmitDataToClients: (err, localFile, obj, socketsCallback, dbCallback) =>
        if not err?
            fs.readFile localFile, (err1, result) =>
                if err1?
                    sockets.sendServerError "Manager: could not read #{localFile}.", err1
                else

                    try
                        obj.data = JSON.parse result
                    catch err2
                        logger.error err2
                        return

                    socketsCallback obj

                    # Verify and increase the refresh count.
                    counter = obj.refreshCount
                    if not counter? or counter < 1
                        counter = 1
                    else
                        counter++
                    obj.refreshCount = counter

                    # Save the updated data to the database on every third refresh. The default
                    # value (3) is set on the [Server Settings](settings.html).
                    if counter % settings.Web.saveDataEveryRefresh is 0
                        obj.data = database.cleanObjectForInsertion obj.data
                        dbCallback obj, {patch: true}


# Singleton implementation
# --------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()