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

        @socket.on "server:connectionCounter", @onServerConnectionCounter
        @socket.on "server:error", @onServerError
        @socket.on "entitydata:refresh", @onEntityDataRefresh
        @socket.on "auditdata:refresh", @onAuditDataRefresh
        @socket.on "clients:refresh", @onClientsRefresh

    # Stop listening to all socket messages from the server. Please note that this
    # will NOT kill the socket connection.
    stop: ->
        @socket.off()


    # SOCKET LISTEN
    # ----------------------------------------------------------------------

    # Listen to connection counter updates. This happens everytime someone a new browser
    # window pointing to the System app is opened or closed.
    onServerConnectionCounter: (count) ->
        SystemApp.footerView?.setOnlineUsers count

    # listen to server errors. A [footer alert](alertView.html) will be shown
    # and errors can also be listed on the [Settings menu](menuView.html).
    onServerError: (err) ->
        err.timestamp = new Date()
        SystemApp.Sockets.serverErrors.push err
        SystemApp.serverEvents.trigger "error", err

    # Listen to [Entity Definition data](entityObject.html) refreshes.
    onEntityDataRefresh: (entityDef) ->
        updated = SystemApp.Data.entities.getByFriendlyId entityDef.friendlyId

        # Only proceed if entity was found on the [data store](data.html).
        if not updated?
            SystemApp.consoleLog "Sockets entitydata:refresh", "Could not find entity #{entityDef.friendlyId}.", entityDef
            return

        updated.data entityDef.data
        updated.lastDataRefresh = new Date()

    # Listen to [AuditData](auditData.html) refreshes.
    onAuditDataRefresh: (auditData) ->
        updated = SystemApp.Data.auditData.getByFriendlyId auditData.friendlyId

        # Only proceed if entity was found on the [data store](data.html).
        if not updated?
            SystemApp.consoleLog "Sockets auditdata:refresh", "Could not find audit data #{auditData.friendlyId}.", auditData
            return

        updated.data auditData.data
        updated.lastDataRefresh = new Date()

        # Trigger the audit data refresh to the app.
        SystemApp.dataEvents.trigger "auditdata:refresh", updated

    # Force reload the app by refreshing the browser window.
    onClientsRefresh: (data) ->
        ms = data.seconds * 1000
        SystemApp.routes?.refresh ms


     # SOCKET SEND
    # ----------------------------------------------------------------------

    # Trigger the "clients:refresh" command on all connected browsers. This will force
    # clients to refresh the window in X seconds.
    sendClientsRefresh: (seconds) ->
        if not SystemApp.Data.loggedUser.hasRole("admin")
            SystemApp.consoleLog "Sockets.sendClientRefresh", "You don't have the necessary permissions!"
            return

        # Default seconds is 10.
        seconds = SystemApp.Settings.Sockets.clientRefreshSeconds if not seconds?

        # Emit event.
        SystemApp.Sockets.socket.emit "clients:refresh", {seconds: seconds}