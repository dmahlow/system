# SERVER APP
# --------------------------------------------------------------------------

# Expresser.
expresser = require "expresser"

# Required modules.
lodash = require "lodash"
manager = require "./server/manager.coffee"
path = require "path"
security = require "./server/security.coffee"
sockets = require "./server/sockets.coffee"

# Init passport.
expresser.app.extraMiddlewares.push security.passport.initialize()
expresser.app.extraMiddlewares.push security.passport.session()

# Init modules.
expresser.init()
security.init()
manager.init()
sockets.init()

# Configure the app and set the routes.
require("./server/routes.coffee")(expresser.app.server)