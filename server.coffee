# SERVER APP
# --------------------------------------------------------------------------

# Required modules.
settings = require "./server/settings.coffee"
sockets = require "./server/sockets.coffee"
express = require "express"

# Create the express app.
app = express()

# Configure the app and set the routes.
require("./server/configure.coffee")(app, express)
require("./server/routes.coffee")(app, express)

# Create server and bind Socket.IO to the app and listen to connections.
# Port is defined on the [Server Settings](settings.html).
server = require("http").createServer app
server.listen settings.Web.port
sockets.bind server