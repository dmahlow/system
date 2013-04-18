# SERVER SECURITY
# --------------------------------------------------------------------------
# This security module will handle all security and authentication related
# procedures of the app. The `init` method is called when the app starts.

class Security

    # Required modules.
    crypto = require "crypto"
    database = require "./database.coffee"
    logger = require "./logger.coffee"
    passport = require "passport"
    passportHttp = require "passport-http"
    settings = require "./settings.coffee"

    # Init all security related stuff. Set the passport strategy to
    # authenticate users using basic HTTP authentication.
    init: =>
        passport.use new passportHttp.BasicStrategy (username, password, callback) =>

            # Password must be hashed before comparing.
            passwordHash = @getPasswordHash username, password

            database.getUser {username: username, password: passwordHash}, (err, user) ->
                if err?
                    return callback err
                if not user?
                    return callback null, null
                if not user.validatePassword password
                    return callback null, null
                return callback null, user

    # Generates a password hash based on the provided `username` and `password`,
    # along with the `Settings.User.passwordSecretKey`. This is mainly used
    # by the HTTP authentication module.
    getPasswordHash: (username, password) =>
        text = username + "|" + password + "|" + settings.User.passwordSecretKey
        return crypto.createHash("sha256").update(text).digest "hex"


# Singleton implementation
# --------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()