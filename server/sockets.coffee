# SERVER SOCKETS
# --------------------------------------------------------------------------
# Handles sockets communication using the module Socket.IO.

class Sockets

    expresser = require "expresser"
    settings = require "./settings.coffee"


    # Init socket connections.
    init: =>
        expresser.sockets.listenTo "disconnect", @onDisconnect
        expresser.sockets.listenTo "clients:refresh", @onClientsRefresh


    # TRIGGER: ENTITIES AND AUDIT DATA
    # ----------------------------------------------------------------------

    # Send updated [Entity Definition data](entityObject.html) to the clients.
    sendEntityRefresh: (entityDef) =>
        expresser.sockets.emit "entitydata:refresh", entityDef

    # Send updated [AuditData](auditData.html) values to the clients.
    sendAuditDataRefresh: (auditData) =>
        expresser.sockets.emit "auditdata:refresh", auditData


    # TRIGGER: SERVER LOGS AND ERRORS
    # ----------------------------------------------------------------------

    # Send a server error JSON to the clients, containing a title and message.
    sendServerError: (title, errorMessage) =>
        errorMessage = "Unknown error" if not errorMessage?
        expresser.sockets.emit "server:error", {title: title, message: errorMessage.toString().replace(":", " ")}


    # LISTEN: CLIENT COMMANDS
    # ----------------------------------------------------------------------

    # When user disconnects, emit an event with the new connection count to all clients.
    onDisconnect: =>
        expresser.sockets.emit "server:connectionCounter", expresser.sockets.getConnectionCount()

    # When an admin user triggers the "clients:refresh" command, resend it
    # to all connected clients so they'll get the page refreshed.
    onClientsRefresh: (data) =>
        expresser.sockets.emit "clients:refresh", data


# Singleton implementation
# --------------------------------------------------------------------------
Sockets.getInstance = ->
    @instance = new Sockets() if not @instance?
    return @instance

module.exports = exports = Sockets.getInstance()