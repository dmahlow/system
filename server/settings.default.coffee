# DEFAULT SERVER SETTINGS
# --------------------------------------------------------------------------
# Has all default server side settings for the app. Please DOT NOT edit
# this file unless you know excatly what you're doing. To change settings,
# please use the settings.coffee file which will always override the ones
# specified here.

# TODO! Transform the settings to plain JSON files instead of coffee classes.

class SettingsDefault

    # GENERAL
    # ----------------------------------------------------------------------
    General:
        # The app title.
        appTitle: "Zalando System"
        # When debug is true, more messages will be logged to file and console.
        debug: false


    # DATABASE
    # ----------------------------------------------------------------------
    Database:
        # Connection string to MongoDB.
        connString: "mongodb://localhost/systemapp"
        # Wait for flush to file system before acknowlegement? Default is false.
        fsync: false
        # For how many hours should the DB keep insert/update/delete logs? Default is 3 hours.
        logExpires: 3


    # PATHS
    # ----------------------------------------------------------------------
    Paths:
        # Path to the logs directory.
        logsDir: "./logs/"
        # Path to the Jade views directory.
        viewsDir: "./views/"
        # Path to the public static folder.
        publicDir: "./public/"
        # Path where downloads will be stored.
        downloadsDir: "./public/downloads/"
        # Path where images are stored.
        imagesDir: "./public/images/"


    # LOGGING
    # ----------------------------------------------------------------------
    Log:
        # Delete log files older than 30 days by default.
        cleanOldDays: 30
        # Max filesize for each log is around 1MB.
        maxFileSize: 1024000
        # Recent log list is for the last 24 hours.
        recentMinutes: 1440
        # Token for the Logentries service. If left null or blank, logs will be saved to the /logs
        # directory. If a valid token is specified, logs will be saved ONLY to Logentries.
        logentriesToken: null


    # IMAGES
    # ----------------------------------------------------------------------
    Images:
        # Size of map thumbnails (width).
        mapThumbSize: 600


    # WEB (node.js server)
    # ----------------------------------------------------------------------
    Web:
        # The amount of time to wait for new connection requests, in case the internet / network is broken.
        connRestartInterval: 60000
        # Timeout to wait for downloads to complete
        downloadTimeout: 30000
        # Auth user and password when downloading external contents (Audit Data and Entity Objects, for example).
        # Please note that whis will be used for ALL requests. If you need to pass credentials for only a specific
        # URL, use the `http://username:password@domain.com/path` format on that particular URL.
        downloaderUser: null
        downloaderPassword: null
        # Headers to add to requests when downloading external contents, accepting key:value properties.
        # For example the Pingdom API requires an `App-Key` to be passed, so you could add here:
        # {"App-Key":"my-pingdom-api-key"}.
        downloaderHeaders: null
        # The cache interval to refresh entities JSON external files (DataCenter, Machine, Host and Service).
        entitiesCacheInterval: 30000
        # The minimum time between external data refresh, in seconds.
        minimumRefreshInterval: 3
        # If true, all JSON response will be minified before passed to the clients.
        minifyJsonResponse: true
        # If true, some settings might be overriden by cloud environment variables (AppFog and OpenShift, for example).
        # Web IP, port, and logentriesToken are among the settings that might be altered if `paas` is true.
        paas: true
        # The Node.js port to bind the app to.
        port: 3003
        # Saves the `data` from the Audit Data and Entity Definitions on every third refresh by default.
        saveDataEveryRefresh: 3


# Singleton implementation.
# --------------------------------------------------------------------------
SettingsDefault.getInstance = ->
    @instance = new SettingsDefault() if not @instance?
    return @instance

module.exports = exports = SettingsDefault.getInstance()