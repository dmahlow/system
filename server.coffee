# SERVER APP
# --------------------------------------------------------------------------

# Require filesystem.
fs = require "fs"

# Make sure that the `settings.coffee` file is present. In a normal and expected scenario
# this will be called only once when the app is started for the very first time.
if not fs.existsSync "./server/settings.coffee"
    fs.renameSync "./server/settings.base.coffee", "./server/settings.coffee"

# Define the settings and sockets.
logger = require "./server/logger.coffee"
manager = require "./server/manager.coffee"
settings = require "./server/settings.coffee"
sockets = require "./server/sockets.coffee"

# Require express and create the app server.
express = require "express"
app = express()

# Set max event listeners to 30 (instead of the default 10).
process.setMaxListeners 30

# Sets the default app and process exception handler.
# This will log to the server console.
process.on "uncaughtException", (err) -> sockets.sendServerError "Proc unhandled exception!", err
app.on "uncaughtException", (err) -> sockets.sendServerError "App unhandled exception!", err

# Require configuration, database and routes.
require("./server/configure.coffee")(app, express)
require("./server/routes.coffee")(app, express)

# Create server and bind Socket.IO to the app and listen to connections.
# Port is defined on the [Server Settings](settings.html).
server = require("http").createServer app
server.listen settings.Web.port
sockets.bind server

# Start the [Logger](server/logger.html) and the server [Manager](manager.html).
logger.init()
manager.init()