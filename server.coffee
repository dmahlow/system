# SERVER APP
# --------------------------------------------------------------------------

# Expresser.
expresser = require "expresser"
settings = expresser.settings
settings.general.debug = true

# Required modules.
lodash = require "lodash"
manager = require "./server/manager.coffee"
path = require "path"
security = require "./server/security.coffee"
sockets = require "./server/sockets.coffee"

# Init modules.
expresser.init()
manager.init()
security.init()
sockets.init()

# Configure the app and set the routes.
require("./server/routes.coffee")(expresser.app.server)