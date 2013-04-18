# SERVER APP
# --------------------------------------------------------------------------

# Required filesystem module.
fs = require "fs"

# Make sure that the `settings.coffee` file is present. There are 2 settings file: one for client settings
# and one for server and backend settings. In a normal and expected scenario this will be called only once
# when the app is started for the very first time.
if not fs.existsSync "./server/settings.coffee"
    baseSettings = fs.readFileSync "./server/settings.base.coffee"
    fs.writeFileSync "./server/settings.coffee", baseSettings
if not fs.existsSync "./assets/js/settings.coffee"
    baseSettings = fs.readFileSync "./assets/js/settings.base.coffee"
    fs.writeFileSync "./assets/js/settings.coffee", baseSettings

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