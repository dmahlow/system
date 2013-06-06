# SERVER MANAGER
# --------------------------------------------------------------------------
# Handles all automated server procedures like log cleaning, Audit Data
# refresh, CMDB updates etc. The manager is started automatically with the app.

class Manager

    # Require Expresser.
    expresser = require "expresser"
    settings = expresser.settings

    # Required modules.
    database = require "./database.coffee"
    fs = require "fs"
    sockets = require "./sockets.coffee"
    sync = require "./sync.coffee"


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
        if not expresser.database.db?
            setTimeout @init, 100
            return

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
        @timerDatabaseClean = setInterval database.cleanLogs, settings.database.logExpires * 1800000

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
        if settings.general.debug
            expresser.logger.info "Manager.initEntityTimers"

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
            if settings.general.debug
                expresser.logger.info "Manager.startEntityTimers", "Started timers for #{result.length} entities."

    # Add an [Entity](entityDefinition.html) refresh timer to the `timersEntityRefresh` array.
    setEntityTimer: (entityDef) =>
        callback = => @refreshEntity entityDef
        interval = entityDef.refreshInterval

        # Make sure interval is at least 2 seconds.
        if not interval? or interval < settings.web.minimumRefreshInterval
            interval = settings.web.minimumRefreshInterval
            expresser.logger.warn "Entity Definition data refresh interval is too low: ID #{entityDef.friendlyId}, interval #{entityDef.refreshInterval} seconds."

        # Set the timer. Interval is in seconds, so we must multiply by 1000.
        timer = setInterval callback, interval * 1000

        # Call the refresh immediatelly so clients will get updated data straight away.
        callback()

        @timersEntityRefresh.push timer

        if settings.general.debug
            expresser.logger.info "Manager.setEntityTimer", entityDef.friendlyId, interval + "s"

    # Refresh the specified [Entity](entityDefinition.html) data. This will run ONLY
    # if there are connected clients, to avoid bandwidth and processing waste.
    refreshEntity: (entityDef) =>
        if expresser.sockets.getConnectionCount() < 1
            return

        # Only proceed if the entity sourceUrl is set.
        if entityDef.sourceUrl? and entityDef.sourceUrl isnt ""
            sync.download entityDef.sourceUrl, settings.path.downloadsDir + "entityobjects." + entityDef.friendlyId + ".json", (err, localFile) =>
                @transmitDataToClients err, localFile, entityDef, sockets.sendEntityRefresh, database.setEntityDefinition
        else if settings.general.debug
            expresser.logger.warn "Manager.refreshEntity", entityDef.friendlyId, "No sourceUrl set. Abort."


    # AUDIT DATA MANAGER
    # ----------------------------------------------------------------------

    # Init the [AuditData](auditadta.html) refresh timers, by creating one interval
    # timer for each audit data and transmitting the refreshed data to users via sockets.
    initAuditDataTimers: =>
        if settings.general.debug
            expresser.logger.info "Manager.initAuditDataTimers"

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
            if settings.general.debug
                expresser.logger.info "Manager.startAuditDataTimers", "Started timers for #{result.length} audit data."

    # Add an [AuditData](auditadata.html) refresh timer to the `timersAuditDataRefresh` array.
    setAuditDataTimer: (auditData) =>
        callback = => @refreshAuditData auditData
        interval = auditData.refreshInterval

        # Make sure interval is at least 2 seconds.
        if not interval? or interval < settings.web.minimumRefreshInterval
            interval = settings.web.minimumRefreshInterval
            expresser.logger.warn "Audit Data refresh interval is too low: ID #{auditData.friendlyId}, interval #{auditData.refreshInterval} seconds."

        # Set the timer. Interval is in seconds, so we must multiply by 1000.
        timer = setInterval callback, interval * 1000

        # Call the refresh immediatelly so clients will get updated data straight away.
        callback()

        @timersAuditDataRefresh.push timer

        if settings.general.debug
            expresser.logger.info "Manager.setAuditDataTimer", auditData.friendlyId, interval + "ms"

    # Refresh the specified [AuditData](auditData.html) records. This will run ONLY
    # if there are connected clients, to avoid bandwidth and processing waste.
    refreshAuditData: (auditData) =>
        if expresser.sockets.getConnectionCount() < 1
            return

        # Only proceed if the audit data sourceUrl is properly set.
        if auditData.sourceUrl? and auditData.sourceUrl isnt ""
            sync.download auditData.sourceUrl, settings.path.downloadsDir + "auditdata." + auditData.friendlyId + ".json", (err, localFile) =>
                @transmitDataToClients err, localFile, auditData, sockets.sendAuditDataRefresh, database.setAuditData
        else if settings.general.debug
            expresser.logger.warn "Manager.refreshAuditData", auditData.friendlyId, "No sourceUrl set. Abort."


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
                    if settings.general.debug
                        expresser.logger.info "Manager.transmitDataToClients", localFile

                    # Try parsing the data as JSON.
                    try
                        obj.data = JSON.parse result
                    catch err2
                        expresser.logger.error err2
                        return

                    socketsCallback obj

                    # Verify and increase the refresh count.
                    counter = obj.refreshCount
                    if not counter? or counter < 1
                        counter = 1
                    else
                        counter++
                    obj.refreshCount = counter

                    # Save the updated data to the database.
                    obj.data = database.cleanObjectForInsertion obj.data
                    dbCallback obj, {patch: true}
        else
            expresser.logger.error "Manager.transmitDataToClients", localFile, err


# Singleton implementation
# --------------------------------------------------------------------------
Manager.getInstance = ->
    @instance = new Manager() if not @instance?
    return @instance

module.exports = exports = Manager.getInstance()