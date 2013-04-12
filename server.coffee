# SERVER APP
# --------------------------------------------------------------------------

# Require filesystem.
fs = require "fs"

# Make sure that the `settings.coffee` file is present. There are 2 settings file: one for client settings
# and one for server and backend settings. In a normal and expected scenario this will be called only once
# when the app is started for the very first time.
checkSettingsFiles = () ->
    if not fs.existsSync "./server/settings.coffee"
        baseSettings = fs.readFileSync "./server/settings.base.coffee"
        fs.writeFileSync "./server/settings.coffee", baseSettings
    if not fs.existsSync "./assets/js/settings.coffee"
        baseSettings = fs.readFileSync "./assets/js/settings.base.coffee"
        fs.writeFileSync "./assets/js/settings.coffee", baseSettings
checkSettingsFiles()

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