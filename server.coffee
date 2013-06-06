# SERVER APP
# --------------------------------------------------------------------------

# Expresser.
expresser = require "expresser"
settings = expresser.settings

# Required modules.
lodash = require "lodash"
manager = require "./server/manager.coffee"
path = require "path"
security = require "./server/security.coffee"
sockets = require "./server/sockets.coffee"

# Load settings.
settingsPath = path.dirname(require.main.filename) + "/server/settings.json"
expresser.utils.loadSettingsFromJson settingsPath

# Init modules.
expresser.init()
manager.init()
security.init()
sockets.init()

# Configure the app and set the routes.
require("./server/routes.coffee")(expresser.app.server)