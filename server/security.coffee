# SERVER SECURITY
# --------------------------------------------------------------------------
# This security module will handle all security and authentication related
# procedures of the app. The `init` method is called when the app starts.

class Security

    # Required modules.
    crypto = require "crypto"
    database = require "./database.coffee"
    expresser = require "expresser"
    moment = require "moment"
    settings = require "./settings.coffee"

    # Cache with logged users to avoid hitting the database all the time.
    # The default expirty time is 1 minute.
    cachedUsers: null

    # Init all security related stuff. Set the passport strategy to
    # authenticate users using basic HTTP authentication.
    init: =>
        @cachedUsers = {}

        # Helper to validate user login. If no user was specified and [settings](settings.html)
        # allow guest access, then log as guest.
        validateUser = (user, password, callback) =>
            if not user? or user is "" or user is "guest"
                if settings.security.guestEnabled
                    guest = {id: "guest", displayName: "Guest", username: "guest", roles: ["guest"]}
                    return callback null, guest
                else
                    return callback null, false, {message: "Username was not specified."}

            # Check if user should be fetched by ID or username.
            if not user.id?
                filter = {username: user}
            else
                fromCache = @cachedUsers[user.id]
                filter = user

            # Add password hash to filter.
            if password isnt false
                filter.passwordHash = @getPasswordHash user, password

            # Check if user was previously cached. If not valid, delete from cache.
            if fromCache?.cacheExpiryDate?
                if fromCache.cacheExpiryDate.isAfter(moment())
                    return callback null, fromCache
                delete @cachedUsers[user.id]

            # Get user from database.
            database.getUser filter, (err, result) =>
                if err?
                    return callback err
                else if not result? or result.length < 1
                    return callback null, false, {message: "User and password combination not found."}

                result = result[0] if result.length > 0

                # Set expiry date for the user cache.
                result.cacheExpiryDate = moment().add "s", settings.security.userCacheExpires
                @cachedUsers[result.id] = result

                # Return the login callback.
                return callback null, result

        # Use HTTP basic authentication.
        expresser.app.passportAuthenticate = validateUser

        # User serializer will user the user ID only.
        expresser.app.passport.serializeUser (user, callback) ->
            callback null, user.id

        # User deserializer will get user details from the database.
        expresser.app.passport.deserializeUser (user, callback) ->
            if user is "guest"
                validateUser "guest", null, callback
            else
                validateUser {id: user}, false, callback

    # Ensure that there's at least one admin user registered. The default
    # admin user will have username "admin", password "system".
    ensureAdminUser: =>
        database.getUser null, (err, result) =>
            if err?
                expresser.logger.error "Security.ensureAdminUser", err
                return

            # If no users were found, create the default admin user.
            if not result? or result.length < 1
                passwordHash = @getPasswordHash "admin", "system"
                user = {displayName: "Administrator", username: "admin", roles:["admin"], passwordHash: passwordHash}
                database.setUser user
                expresser.logger.info "Security.ensureAdminUser", "Default admin user was created."


    # AUTHENTICATION METHODS
    # ----------------------------------------------------------------------

    # Generates a password hash based on the provided `username` and `password`,
    # along with the `Settings.User.passwordSecretKey`. This is mainly used
    # by the HTTP authentication module. If password is empty, return an empty string.
    getPasswordHash: (username, password) =>
        return "" if not password? or password is ""
        text = username + "|" + password + "|" + settings.security.userPasswordKey
        return crypto.createHash("sha256").update(text).digest "hex"


# Singleton implementation
# --------------------------------------------------------------------------
Security.getInstance = ->
    @instance = new Security() if not @instance?
    return @instance

module.exports = exports = Security.getInstance()