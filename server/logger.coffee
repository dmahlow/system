# SERVER LOGGER
# --------------------------------------------------------------------------
# Handles server logging to the console and to files, using the Winston module.

class Logger

    # Define the referenced objects.
    settings = require "./settings.coffee"

    # Define the winston and logentries references. Logentries will be instantiated only if necessary.
    logentries = null
    winston = require "winston"

    # Helper function to get the current log filename based on the current date.
    # Please note that it DOES NOT mean having 1 log file for each day.
    # Log files will rotate only when the app restarts OR when the `maxsize`
    # is reached - value set on [Settings](settings.html), default 1MB.
    getLogFilename = () ->
        now = new Date()

        month = now.getMonth() + 1
        month = "0" + month.toString() if month < 10
        day = now.getDate()
        day = "0" + day.toString() if day < 10

        return now.getFullYear() + "-" + month + "-" + day + ".log"


    # INIT
    # --------------------------------------------------------------------------

    # Init the Logger. If `settings.Log.logentriesToken` is valid, logs will be dispatched
    # to the Logentries service (http://logentries.com). Otherwise a file transport will be
    # created and logs saved to /logs/current-date.log. The path and log filename are defined
    # on the [Settings](settings.html).
    # Please note that unhandled exceptions will ALWAYS be logged to the /logs/ directory,
    # even when using Logentries for general logging.
    init: =>
        winston.exitOnError = false

        if settings.Log.logentriesToken? and settings.Log.logentriesToken isnt ""
            logentries = require("node-logentries").logger {token: settings.Log.logentriesToken}
            logentries.winston winstonObj
        else
            filename = settings.Paths.logsDir + getLogFilename()
            winston.add winston.transports.File, {timestamp: true, filename: filename, maxsize: settings.Log.maxFileSize}

        winston.handleExceptions(new winston.transports.File {filename: settings.Paths.logsDir + "exceptions.log"})
        winston.info "WINSTON LOGGING STARTED!"


    # LOGGING
    # --------------------------------------------------------------------------

    # Log any object to the default transports as `info`.
    info: =>
        winston.info.apply this, arguments
        console.log.apply this, arguments if settings.General.debug

    # Log any object to the default transports as `warn`.
    warn: =>
        winston.warn.apply this, arguments
        console.warn.apply this, arguments if settings.General.debug

    # Log any object to the default transports as `error`.
    error: =>
        winston.error.apply this, arguments
        console.error.apply this, arguments if settings.General.debug


    # QUERYING
    # --------------------------------------------------------------------------

    # Return a list of all logs for the past 24 hours, value defined on
    # the [Server Settings](settings.html). A callback must be passed
    # to handle the results.
    getRecent: (callback) =>
        dateFrom = new Date()
        dateUntil = new Date()
        minutes = dateFrom.getMinutes() - settings.Log.recentMinutes
        dateFrom.setMinutes(minutes)
        options = {from: dateFrom, until: dateUntil}
        winston.query options, (err, results) -> callback err, results


    # CLEANING
    # --------------------------------------------------------------------------

    # Delete old log files. The param `maxDays` is optional, default is 30
    # and set on the [server settings](settings.html).
    cleanOld: (maxDays) =>
        maxDays = settings.Log.cleanOldDays if not days? or days < 0

        files = fs.readdirSync settings.Paths.logsDir

        for f in files
            basename = path.basename f

            # Make sure we don't delete the `_dirinfo` file.
            if basename isnt "_dirinfo"
                dateParts = basename.split "-"
                fdate = new Date dateParts[0], dateParts[1], dateParts[2]
                now = new Date()
                divider = 1000 * 60 * 60 * 24

                # Only delete older files!
                fs.unlinkSync f if (fdate - now) / divider > maxDays

        @info "Logs older than #{maxDays} were cleared!"


# Singleton implementation
# --------------------------------------------------------------------------
Logger.getInstance = ->
    @instance = new Logger() if not @instance?
    return @instance

module.exports = exports = Logger.getInstance()