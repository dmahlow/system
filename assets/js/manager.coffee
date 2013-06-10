# MANAGER
# --------------------------------------------------------------------------
# The Manager makes sure that the app is running smoothly by checking data
# and specific variables at specific intervals.

SystemApp.Manager =

    timerCheckEntities: null


    # STARTING AND STOPPING
    # ----------------------------------------------------------------------

    # Start listening to Socket.IO messages from the server.
    start: ->
        @timerCheckEntities = setInterval @checkEntities, SystemApp.Settings.manager.checkEntitiesInterval

    # Stop listening to all socket messages from the server. Please note that this
    # will NOT npm testkill the socket connection.
    stop: ->
        if @timerCheckEntities?
            clearInterval @timerCheckEntities


    # DATA CHECK
    # ----------------------------------------------------------------------

    # Check if [entities](entityDefinition.html) are up to date. It's considered
    # outdated if it failed refreshing 3 times in a row.
    checkEntities: ->
        if SystemApp.Settings.general.debug
            SystemApp.consoleLog "Manager.checkEntities", "Checking entities data..."

        now = moment()

        for item in SystemApp.Data.entities.models
            lastRefresh = moment item.lastDataRefresh
            seconds = item.refreshInterval() * 3

            # Check if entity data wasn't refreshed for too long.
            if now.subtract("s", seconds).isAfter lastRefresh
                lastRefresh = lastRefresh.format("YYYY-MM-DD hh:mm:ss")
                errTitle = SystemApp.Messages.dataOutdated
                errMessage = SystemApp.Messages.errEntityOutdated
                errMessage = errMessage.replace "#E", item.friendlyId()
                errMessage = errMessage.replace "#D", lastRefresh
                SystemApp.alertEvents.trigger "footer", {title: errTitle, message: errMessage, isError: true}

                if SystemApp.Settings.general.debug
                    SystemApp.consoleLog "Manager.checkEntities", "#{item.friendlyId()} not updated since #{lastRefresh}."