# SOCKETS
# --------------------------------------------------------------------------
# Handle Socket.IO communication with the Node.js server. Using sockets to
# push messages from/to the server is much more efficient than pooling it
# for new data.

SystemApp.Sockets =

    socket: null      # the Socket.IO object
    serverErrors: []  # holds a cached list of errors which happened on the server


    # STARTING AND STOPPING
    # ----------------------------------------------------------------------

    # Start listening to Socket.IO messages from the server.
    start: ->
        if not @socket?
            url = window.location
            @socket = io.connect "http://#{url.hostname}:#{url.port}"

        @socket.on "server:connectionCounter", @serverConnectionCounter
        @socket.on "server:error", @serverError
        @socket.on "entitydata:refresh", @entityDataRefresh
        @socket.on "auditdata:refresh", @auditDataRefresh
        @socket.on "app:reload", @appReload

    # Stop listening to all socket messages from the server. Please note that this
    # will NOT kill the socket connection.
    stop: ->
        @socket.off()


    # SOCKET METHODS
    # ----------------------------------------------------------------------

    # Listen to connection counter updates. This happens everytime someone a new browser
    # window pointing to the System app is opened or closed.
    serverConnectionCounter: (count) =>
        SystemApp.footerView.setOnlineUsers count

    # listen to server errors. A [footer alert](alertView.html) will be shown
    # and errors can also be listed on the [Settings menu](menuView.html).
    serverError: (err) ->
        err.timestamp = new Date()
        SystemApp.Sockets.serverErrors.push err
        SystemApp.serverEvents.trigger "error", err

    # Listen to [Entity Definition data](entityObject.html) refreshes.
    entityDataRefresh: (entityDef) ->
        updated = SystemApp.Data.entities.getByFriendlyId entityDef.friendlyId

        # Only proceed if entity was found on the [data store](data.html).
        if not updated?
            SystemApp.consoleLog "SOCKETS entitydata:refresh", "Could not find entity #{entityDef.friendlyId}.", entityDef
            return

        updated.data entityDef.data
        updated.lastDataRefresh = new Date()

    # Listen to [AuditData](auditData.html) refreshes.
    auditDataRefresh: (auditData) ->
        updated = SystemApp.Data.auditData.getByFriendlyId auditData.friendlyId

        # Only proceed if entity was found on the [data store](data.html).
        if not updated?
            SystemApp.consoleLog "SOCKETS auditdata:refresh", "Could not find audit data #{auditData.friendlyId}.", auditData
            return

        updated.data auditData.data
        updated.lastDataRefresh = new Date()

        # Trigger the audit data refresh to the app.
        SystemApp.dataEvents.trigger "auditdata:refresh", updated

    # Force reload the app by refreshing the browser window.
    appReload: =>
        SystemApp.routes.refresh()