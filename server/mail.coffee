# SERVER MAIL
# --------------------------------------------------------------------------
# Handles and send emails. NOT IMPLEMENTED YET!

class Mail

    # Required modules.
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"


# Singleton implementation
# --------------------------------------------------------------------------
Mail.getInstance = ->
    @instance = new Mail() if not @instance?
    return @instance

module.exports = exports = Mail.getInstance()