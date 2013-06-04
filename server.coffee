# SERVER APP
# --------------------------------------------------------------------------

# Required modules.
path = require "path"
expresser = require "expresser"
manager = require "./server/manager.coffee"
security = require "./server/security.coffee"
settings = require "./server/settings.coffee"
sockets = require "./server/sockets.coffee"

# Load settings.
settingsPath = path.dirname(require.main.filename) + "/server/settings.json"
expresser.settings.loadFromJson settingsPath

# Init modules.
expresser.init()
manager.init()
security.init()
sockets.init()

# Configure the app and set the routes.
require("./server/routes.coffee")(expresser.app.server)