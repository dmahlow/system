# SERVER CONFIG
# --------------------------------------------------------------------------
# Define the basic configuration options for the node server.

module.exports = (app, express) ->

    # Define the database and settings objects.
    database = require "./database.coffee"
    logger = require "./logger.coffee"
    manager = require "./manager.coffee"
    passport = require "passport"
    security = require "./security.coffee"
    settings = require "./settings.coffee"
    sockets = require "./sockets.coffee"

    # Helper function to configure the app in OpenShift and AppFog.
    # Please note that this will only apply if the `Settings.Web.pass` is true.
    configPaaS = ->
        # Check for web (IP and port) variables.
        ip = process.env.OPENSHIFT_INTERNAL_IP
        port = process.env.OPENSHIFT_INTERNAL_PORT
        port = process.env.VCAP_APP_PORT if not port? or port is ""
        settings.web.ip = ip if ip? and ip isnt ""
        settings.web.port = port if port? and port isnt ""

        # Check for Mongo variables.
        vcap = process.env.VCAP_SERVICES
        vcap = JSON.parse vcap if vcap?
        if vcap? and vcap isnt ""
            mongo = vcap["mongodb-1.8"]
            mongo = mongo[0]["credentials"] if mongo?
            if mongo?
                settings.database.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

        # Check for logging variables.
        logentries = process.env.LOGENTRIES_TOKEN
        settings.Log.logentriesToken = logentries if logentries? and logentries isnt ""

    # Common configuration for all envrionments. This will tweak process settings, bind error
    # handlers and init all the necessary modules.
    app.configure ->
        process.setMaxListeners 30
        process.on "uncaughtException", (err) ->
            sockets.sendServerError "Proc unhandled exception!", err
            console.error "Proc unhandled exception!", err
        app.on "uncaughtException", (err) ->
            sockets.sendServerError "App unhandled exception!", err
            console.error "App unhandled exception!", err

        # If the `Settings.Web.paas` is true, then override settings with environmental variables.
        configPaaS() if settings.web.paas

        # Init other modules.
        logger.init()



        # Sets the app path variables.
        app.viewsDir = settings.path.viewsDir
        app.publicDir = settings.path.publicDir
        app.downloadsDir = settings.path.downloadsDir

        # Set view options, use Jade.
        app.set "views", app.viewsDir
        app.set "view engine", "jade"
        app.set "view options", { layout: false }

        # Set express methods.
        app.use express.bodyParser()
        app.use express.methodOverride()
        app.use express.cookieParser()
        app.use express.session {secret: settings.security.sessionKey}



        # Express routing.
        app.use app.router
        app.use express["static"] app.publicDir

    # Config for development. Do not minify builds, and set debug to `true` in case it's unset.
    app.configure "development", ->
        settings.general.debug = true if not settings.general.debug?

        ConnectAssets = (require "connect-assets") {build: true, buildDir: false, minifyBuilds: false}
        app.use ConnectAssets
        app.use express.errorHandler {dumpExceptions: true, showStack: true}

    # Config for production. JS and CSS will be minified. Set debug to `false` in case it's unset.
    app.configure "production", ->
        settings.general.debug = false if not settings.general.debug?

        ConnectAssets = (require "connect-assets") {build: true, buildDir: false, minifyBuilds: true}
        app.use ConnectAssets
        app.use express.errorHandler()