# SERVER SOCKETS
# --------------------------------------------------------------------------
# Handles sockets communication using the module Socket.IO.

class Sockets

    # Define the [Logger](logger.html).
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # Bind the Socket.IO object to the Express app. This will also set
    # the counter to increase / decrease when users connects or
    # disconnects from the app.
    bind: (server) =>
        @io = require("socket.io").listen server

        # Set transports.
        @io.set "transports", ["websocket", "xhr-polling", "htmlfile"]

        # On production, log only critical errors. On development, log almost everything.
        if process.env.NODE_ENV is "production"
            @io.set "log level", 1
            @io.set "browser client minification"
            @io.set "browser client etag"
            @io.set "browser client gzip"
        else
            @io.set "log level", 2

        # Listen to user connection count updates.
        @io.sockets.on "connection", (socket) =>
            @io.sockets.emit "server:connectionCounter", @getConnectionCount()

            socket.on "disconnect", @onDisconnect
            socket.on "clients:refresh", @onClientsRefresh

    # Helper to get how many users are currenly connected to the app.
    getConnectionCount: =>
        count = Object.keys(@io.sockets.manager.open).length
        if settings.General.debug
            logger.info "Sockets.getConnectionCount", count
        return count


    # TRIGGER: ENTITIES AND AUDIT DATA
    # ----------------------------------------------------------------------

    # Send updated [Entity Definition data](entityObject.html) to the clients.
    sendEntityRefresh: (entityDef) =>
        @io.sockets.emit "entitydata:refresh", entityDef

    # Send updated [AuditData](auditData.html) values to the clients.
    sendAuditDataRefresh: (auditData) =>
        @io.sockets.emit "auditdata:refresh", auditData


    # TRIGGER: SERVER LOGS AND ERRORS
    # ----------------------------------------------------------------------

    # Send a server error JSON to the clients, containing a title and message.
    sendServerError: (title, errorMessage) =>
        if not @io?
            if settings.General.debug
                console.error "Sockets.sendServerError", "Sockets object was not initiated yet!"
            return

        errorMessage = "Unknown error" if not errorMessage?
        @io.sockets.emit "server:error", {title: title, message: errorMessage.toString().replace(":", " ")}


    # LISTEN: CLIENT COMMANDS
    # ----------------------------------------------------------------------

    # When user disconnects, emit an event with the new connection count to all clients.
    onDisconnect: =>
        @io.sockets.emit "server:connectionCounter", @getConnectionCount()

    # When an admin user triggers the "clients:refresh" command, resend it
    # to all connected clients so they'll get the page refreshed.
    onClientsRefresh: (data) =>
        if settings.General.debug
            logger.info "Sockets.onClientsRefresh", data
        @io.sockets.emit "clients:refresh", data


# Singleton implementation
# --------------------------------------------------------------------------
Sockets.getInstance = ->
    @instance = new Sockets() if not @instance?
    return @instance

module.exports = exports = Sockets.getInstance()