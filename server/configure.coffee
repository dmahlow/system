# SERVER CONFIG
# --------------------------------------------------------------------------
# Define the basic configuration options for the node server.

module.exports = (app, express) ->

    # Define the database and settings objects.
    database = require "./database.coffee"
    logger = require "./logger.coffee"
    manager = require "./manager.coffee"
    security = require "./security.coffee"
    settings = require "./settings.coffee"

    # Helper function to configure the app in OpenShift and AppFog.
    # Please note that this will only apply if the `Settings.Web.pass` is true.
    configPaaS = ->
        # Check for web (IP and port) variables.
        ip = process.env.OPENSHIFT_INTERNAL_IP
        port = process.env.OPENSHIFT_INTERNAL_PORT
        port = process.env.VCAP_APP_PORT if not port? or port is ""
        settings.Web.ip = ip if ip? and ip isnt ""
        settings.Web.port = port if port? and port isnt ""

        # Check for Mongo variables.
        vcap = process.env.VCAP_SERVICES
        vcap = JSON.parse vcap if vcap?
        if vcap? and vcap isnt ""
            mongo = vcap["mongodb-1.8"]
            mongo = mongo[0]["credentials"] if mongo?
            if mongo?
                settings.Database.connString = "mongodb://#{mongo.hostname}:#{mongo.port}/#{mongo.db}"

        # Check for logging variables.
        logentries = process.env.LOGENTRIES_TOKEN
        settings.Log.logentriesToken = logentries if logentries? and logentries isnt ""

    # Common configuration for all envrionments. This will tweak process settings, bind error
    # handlers and init all the necessary modules.
    app.configure ->
        process.setMaxListeners 30
        process.on "uncaughtException", (err) -> sockets.sendServerError "Proc unhandled exception!", err
        app.on "uncaughtException", (err) -> sockets.sendServerError "App unhandled exception!", err

        # If the `Settings.Web.paas` is true, then override settings with environmental variables.
        configPaaS() if settings.Web.paas

        # Sets the app path variables.
        app.viewsDir = settings.Paths.viewsDir
        app.publicDir = settings.Paths.publicDir
        app.downloadsDir = settings.Paths.downloadsDir

        # Set view options, use Jade.
        app.set "views", app.viewsDir
        app.set "view engine", "jade"
        app.set "view options", { layout: false }

        # Set express methods.
        app.use express.bodyParser()
        app.use express.methodOverride()
        app.use express.cookieParser()

        # Express routing.
        app.use app.router
        app.use express["static"] app.publicDir

        # Init other modules.
        logger.init()
        manager.init()
        security.init()

    # Config for development. Do not minify builds, and set debug to `true` in case it's unset.
    app.configure "development", ->
        settings.General.debug = true if not settings.General.debug?

        ConnectAssets = (require "connect-assets") {build: true, buildDir: false, minifyBuilds: false}
        app.use ConnectAssets
        app.use express.errorHandler {dumpExceptions: true, showStack: true}

    # Config for production. JS and CSS will be minified. Set debug to `false` in case it's unset.
    app.configure "production", ->
        settings.General.debug = false if not settings.General.debug?

        ConnectAssets = (require "connect-assets") {build: true, buildDir: false, minifyBuilds: true}
        app.use ConnectAssets
        app.use express.errorHandler()