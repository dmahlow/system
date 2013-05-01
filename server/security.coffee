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
        @ensureAdminUser()

        # Helper to validate user login.
        getUserFromDb = (username, password, callback) =>
            if not username?
                return callback "User not specified.", null

            # Check if user should be fetched by ID or username.
            if not username.id?
                filter = {username: username}
            else
                filter = username

            # Add password hash to filter.
            if password? and password isnt "zalando"
                filter.passwordHash = @getPasswordHash username, password

            database.getUser filter, (err, result) ->
                if err?
                    return callback err
                if not result? or result.length < 0
                    return callback "User and pasword combination not found.", null

                result = result[0] if result.length > 0
                return callback null, result

        # Use HTTP basic authentication.
        passport.use new passportHttp.BasicStrategy (username, password, callback) =>
            getUserFromDb username, password, callback

        # User serializer will user the user ID only.
        passport.serializeUser (user, callback) ->
            callback null, user.id

        # User deserializer will get user details from the database.
        passport.deserializeUser (user, callback) ->
            getUserFromDb {id: user}, null, callback

    # Ensure that there's at least one admin user registered. The default
    # admin user will have username "admin", password "system".
    ensureAdminUser: =>
        database.getUser null, (err, result) ->
            if err?
                logger.error "Security.ensureAdminUser", err
                return

            # If no users were found, create the default admin user.
            if result.length < 1
                passwordHash = @getPasswordHash "admin", "system"
                user = {displayName: "Administrator", roles:{"admin": true}, username: "admin", passwordHash: passwordHash}
                database.setUser user
                logger.info "Security.ensureAdminUser", "Default admin user was created."


    # AUTHENTICATION METHODS
    # ----------------------------------------------------------------------

    # Generates a password hash based on the provided `username` and `password`,
    # along with the `Settings.User.passwordSecretKey`. This is mainly used
    # by the HTTP authentication module. If password is empty, return an empty string.
    getPasswordHash: (username, password) =>
        return "" if not password? or password is ""
        text = username + "|" + password + "|" + settings.Security.userPasswordKey
        return crypto.createHash("sha256").update(text).digest "hex"


# Singleton implementation
# --------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()