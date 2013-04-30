# SERVER ROUTES
# --------------------------------------------------------------------------
# Define server routes.

module.exports = (app) ->

    # Define required modules.
    logger = require "./logger.coffee"
    database = require "./database.coffee"
    fs = require "fs"
    imaging = require "./imaging.coffee"
    manager = require "./manager.coffee"
    passport = require "passport"
    settings = require "./settings.coffee"
    sockets = require "./sockets.coffee"
    sync = require "./sync.coffee"

    # Define the package.json.
    packageJson = require "./../package.json"

    # When was the package.json last modified?
    lastModified = null


    # ADMIN PAGE
    # ----------------------------------------------------------------------

    # The main index page.
    getAdmin = (req, res) ->
        os = require "os"
        host = req.headers["host"]

        # Check the last modified date.
        lastModified = fs.statSync("./package.json").mtime if not lastModified?

        options =
            title: settings.General.appTitle,
            version: packageJson.version,
            lastModified: lastModified,
            serverPort: settings.Web.port,
            serverOS: os.type() + " " + os.platform(),
            serverCpuLoad: os.loadavg()[0],
            serverRamLoad: Math.round(os.freemem() / ostotalmen() * 100),
            roles: {admin: 1, mapcreate: 1, mapedit: 1, entities: 1, auditdata: 1, auditevents: 1, settings: 1}

        res.render "admin", options


    # MAIN PAGE
    # ----------------------------------------------------------------------

    # The main index page.
    getIndex = (req, res) ->
        os = require "os"
        moment = require "moment"
        host = req.headers["host"]

        # Check the last modified date.
        lastModified = fs.statSync("./package.json").mtime if not lastModified?

        # Set render options.
        options =
            title: settings.General.appTitle,
            version: packageJson.version,
            lastModified: moment(lastModified).format("YYYY-MM-DD hh:mm"),
            serverUptime: moment.duration(os.uptime(), "s").humanize(),
            serverHostname: os.hostname(),
            serverPort: settings.Web.port,
            serverOS: os.type() + " " + os.release(),
            serverCpuLoad: os.loadavg()[0].toFixed(2),
            serverRamLoad: (os.freemem() / os.totalmem() * 100).toFixed(2),
            roles: {admin: true}

        res.render "index", options


    # ENTITIES
    # ----------------------------------------------------------------------

    # Get a single or a collection of [Entity Definitions](entityDefinition.html).
    getEntityDefinition = (req, res) ->
        database.getEntityDefinition getIdFromRequest(req), (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Entity GET", err

    # Add or update an [Entity Definition](entityDefinition.html).
    # This will also restart the entity timers on the server [manager](manager.html).
    postEntityDefinition = (req, res) ->
        database.setEntityDefinition getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                manager.initEntityTimers()
                res.send minifyJson result
            else
                sendErrorResponse res, "Entity POST", err

    # Patch only the specified properties of an [Entity Definition](entityDefinition.html).
    patchEntityDefinition = (req, reslo) ->
        database.setEntityDefinition getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Entity PATCH", err

    # Delete an [Entity Definition](entityDefinition.html).
    # This will also restart the entity timers on the server [manager](manager.html).
    deleteEntityDefinition = (req, res) ->
        database.deleteEntityDefinition getIdFromRequest(req), (err, result) ->
            if not err?
                manager.initEntityTimers()
                res.send ""
            else
                sendErrorResponse res, "Entity DELETE", err

    # Get the data for the specified [Entity Definition](entityDefinition.html).
    # This effectively returns the [Entity Objects Collection](entityObject.html)
    # related to the definition.
    getEntityObject = (req, res) ->
        friendlyId = getIdFromRequest(req)
        database.getEntityDefinition {friendlyId: friendlyId}, (err, result) ->
            if result? and not err?
                filename = "entity.#{friendlyId}.json"

                # Results is an array! If it has no models, then the
                # specified `friendlyId` wasn't found in the database.
                if result.length < 1
                    sendErrorResponse res, "EntityObject GET - could not find entity definition ID " + friendlyId
                    return

                result = result[0]

                # Got the entity definition, now download from its SourceUrl.
                sync.download result.sourceUrl, app.downloadsDir + filename, (errorMessage, localFile) ->
                    if errorMessage?
                        sendErrorResponse res, "EntityObject GET - download failed: " + localFile, errorMessage
                    else
                        fs.readFile localFile, (fileError, fileData) ->
                            if fileError?
                                sendErrorResponse res, "EntityObject GET - downloaded, but read failed: " + localFile, fileError
                            else
                                data = fileData.toString()
                                result.data = database.cleanObjectForInsertion data
                                database.setEntityDefinition result, {patch: true}
                                res.send data

            # If we can't find the matching entity definition, return an error.
            else
                sendErrorResponse res, "Entity Data GET", err


    # AUDIT DATA
    # ----------------------------------------------------------------------

    # Get all [AuditData](auditData.html).
    getAuditData = (req, res) ->
        database.getAuditData getIdFromRequest(req), (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Data GET", err

    # Add or update an [AuditData](auditData.html).
    postAuditData = (req, res) ->
        database.setAuditData getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Data POST", err

    # Patch only the specified properties of an [AuditData](auditData.html).
    patchAuditData = (req, res) ->
        database.setAuditData getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Data PATCH", err

    # Delete an [AuditData](auditData.html).
    deleteAuditData = (req, res) ->
        database.deleteAuditData getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
                manager.initAuditDataTimers()
            else
                sendErrorResponse res, "Audit Data DELETE", err


    # AUDIT EVENTS
    # ----------------------------------------------------------------------

    # Get a single or a collection of [Audit Events](auditEvent.html).
    getAuditEvent = (req, res) ->
        database.getAuditEvent getIdFromRequest(req), (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Event GET", err

    # Add or update an [AuditEvent](auditEvent.html).
    postAuditEvent = (req, res) ->
        database.setAuditEvent getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Event POST", err

    # Patch only the specified properties of an [AuditEvent](auditEvent.html).
    patchAuditEvent = (req, res) ->
        database.setAuditEvent getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Event PATCH", err

    # Delete an [AuditEvent](auditEvent.html).
    deleteAuditEvent = (req, res) ->
        database.deleteAuditEvent getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "Audit Event DELETE", err


    # VARIABLES
    # ----------------------------------------------------------------------

    # Get a single or a collection of [Variables](variable.html).
    getVariable = (req, res) ->
        database.getVariable getIdFromRequest(req), (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Variable GET", err

    # Add or update an [Variable](variable.html).
    postVariable = (req, res) ->
        database.setVariable getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Variable POST", err

    # Patch only the specified properties of a [Variable](variable.html).
    patchVariable = (req, res) ->
        database.setVariable getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Variable PATCH", err

    # Delete a [Variable](variable.html).
    deleteVariable = (req, res) ->
        database.deleteVariable getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "Variable DELETE", err


    # MAPS
    # ----------------------------------------------------------------------

    # Get a single or a collection of [Maps](map.html).
    getMap = (req, res) ->
        database.getMap getIdFromRequest(req), (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map GET", err

    # Add or update a [Map](map.html).
    postMap = (req, res) ->
        database.setMap getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map POST", err

    # Patch only the specified properties of a [Map](map.html).
    patchMap = (req, res) ->
        database.setMap getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map PATCH", err

    # Delete a [Map](map.html).
    deleteMap = (req, res) ->
        database.deleteMap getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "Map DELETE", err


    # MAP THUMBS
    # ----------------------------------------------------------------------

    # Generates a thumbnail of the specified [Map](map.html), by passing
    # its ID and SVG representation.
    postMapThumb = (req, res) ->
        svg = req.body.svg
        svgPath = settings.Paths.imagesDir + "mapthumbs/" + req.params["id"] + ".svg"

        fs.writeFile svgPath, svg, (err) ->
            if err?
                logger.error "Thumbnail SVG save error.", err
            else
                imaging.svgToPng svgPath, settings.Images.mapThumbSize


    # USERS
    # ----------------------------------------------------------------------

    # Get a single or a collection of [Users](user.html).
    getUser = (req, res) ->
        database.getMap getIdFromRequest(req), (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map GET", err

    # Add or update a [Users](user.html).
    postUser = (req, res) ->
        database.setMap getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map POST", err

    # Patch only the specified properties of a [Users](user.html).
    patchUser = (req, res) ->
        database.setMap getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map PATCH", err

    # Delete a [Users](user.html).
    deleteUser = (req, res) ->
        database.deleteMap getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "Map DELETE", err


    # PROXY DOWNLOAD
    # ----------------------------------------------------------------------

    # Download an external file and serve it to the client, thus acting like a "proxy".
    # The local filename is provided after the /downloader/ on the url, and the
    # download URL is provided with the post parameter "url".
    downloader = (req, res) ->
        remoteUrl = req.body.url
        filename = req.params["filename"]

        sync.download remoteUrl, app.downloadsDir + filename, (errorMessage, localFile) ->
            if errorMessage?
                sendErrorResponse res, "Download failed: " + localFile, errorMessage
            else
                fs.readFile localFile, (err, data) ->
                    if err?
                        sendErrorResponse res, "Downloaded, read failed: " + localFile, err
                    else
                        res.send data.toString()


    # SERVER INFO AND UPDATE
    # ----------------------------------------------------------------------

    # Get the list of server logs for the past 24 hours. Value can be changed on
    # the [Server Settings](settings.html).
    getLogsRecent = (req, res) ->
        logger.getRecent (err, result) ->
            if not err?
                res.send minifyJson result
            else
                res.json err

    # Get the system status page.
    getStatus = (req, res) ->
        res.json { status: "ok" }

    # Run the system upgrader.
    runUpgrade = (req, res) ->
        files = fs.readdirSync "./upgrade/"

        for f in files
            if f.indexOf(".coffee") > 0
                require "../upgrade/" + f

        res.send "UPGRADED!!!"

    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Minify the passed JSON value. Please note that the result will be minified
    # ONLY if the `Web.minifyJsonResponse` setting is set to true.
    minifyJson = (source) ->
        return source if settings.Web.minifyJsonResponse

        source = JSON.stringify source if typeof source is "object"
        index = 0
        length = source.length
        result = ""
        symbol = undefined
        position = undefined
        
        while index < length

            symbol = source.charAt(index)
            switch symbol

                # Ignore whitespace tokens. According to ES 5.1 section 15.12.1.1,
                # whitespace tokens include tabs, carriage returns, line feeds, and
                # space characters.
                when "\t", "\r"
                , "\n"
                , " "
                    index += 1

                # Ignore line and block comments.
                when "/"
                    symbol = source.charAt(index += 1)
                    switch symbol

                        # Line comments.
                        when "/"
                            position = source.indexOf("\n", index)

                            # Check for CR-style line endings.
                            position = source.indexOf("\r", index)  if position < 0
                            index = (if position > -1 then position else length)

                        # Block comments.
                        when "*"
                            position = source.indexOf("*/", index)
                            if position > -1

                                # Advance the scanner's position past the end of the comment.
                                index = position += 2
                                break
                            throw SyntaxError("Unterminated block comment.")
                        else
                            throw SyntaxError("Invalid comment.")

                # Parse strings separately to ensure that any whitespace characters and
                # JavaScript-style comments within them are preserved.
                when "\""
                    position = index
                    while index < length
                        symbol = source.charAt(index += 1)
                        if symbol is "\\"

                            # Skip past escaped characters.
                            index += 1
                        else break  if symbol is "\""
                    if source.charAt(index) is "\""
                        result += source.slice(position, index += 1)
                        break
                    throw SyntaxError("Unterminated string.")

                # Preserve all other characters.
                else
                    result += symbol
                    index += 1
        result

    # Return the ID from the request. Give preference to the ID parameter
    # on the body first, and then to the parameter passed on the URL path.
    getIdFromRequest = (req) ->
        if req.body?.id?
            return req.body.id
        else
            return req.params.id

    # Return the document from the request body.
    # Make sure the document ID is set by checking its body and
    # if necessary appending from the request parameters.
    getDocumentFromBody = (req) ->
        obj = req.body
        obj.id = req.params.id if not obj.id?
        return obj

    # When the server can't return a valid result,
    # send an error response with status code 500.
    sendErrorResponse = (res, method, message) ->
        logger.error "Web response error!", method, message

        res.statusCode = 500
        res.send "Error: #{method} - #{message}"


    # SET ROUTES
    # ----------------------------------------------------------------------

    # Login using basic HTTP authentication.
    app.get "/login", passport.authenticate("basic", {session: true}), (req, res) -> res.json req.user

    # Admin page.
    app.get "/admin", getAdmin

    # Main index.
    app.get "/", getIndex

    # Entity definition routes.
    app.get     "/json/entitydefinition",     getEntityDefinition
    app.get     "/json/entitydefinition/:id", getEntityDefinition
    app.post    "/json/entitydefinition",     postEntityDefinition
    app.put     "/json/entitydefinition/:id", postEntityDefinition
    app.patch   "/json/entitydefinition/:id", patchEntityDefinition
    app.delete  "/json/entitydefinition/:id", deleteEntityDefinition

    # Entity data (objects) routes.
    app.get     "/json/entityobject/:id", getEntityObject

    # Audit Data routes.
    app.get     "/json/auditdata",        getAuditData
    app.get     "/json/auditdata/:id",    getAuditData
    app.post    "/json/auditdata",        postAuditData
    app.put     "/json/auditdata/:id",    postAuditData
    app.patch   "/json/auditdata/:id",    patchAuditData
    app.delete  "/json/auditdata/:id",    deleteAuditData

    # Audit Event routes.
    app.get     "/json/auditevent",       getAuditEvent
    app.get     "/json/auditevent/:id",   getAuditEvent
    app.post    "/json/auditevent",       postAuditEvent
    app.put     "/json/auditevent/:id",   postAuditEvent
    app.patch   "/json/auditevent/:id",   patchAuditEvent
    app.delete  "/json/auditevent/:id",   deleteAuditEvent

    # Variable routes.
    app.get     "/json/variable",         getVariable
    app.get     "/json/variable/:id",     getVariable
    app.post    "/json/variable",         postVariable
    app.put     "/json/variable/:id",     postVariable
    app.patch   "/json/variable/:id",     patchVariable
    app.delete  "/json/variable/:id",     deleteVariable

    # Map routes.
    app.get     "/json/map",        getMap
    app.get     "/json/map/:id",    getMap
    app.post    "/json/map",        postMap
    app.put     "/json/map/:id",    postMap
    app.patch   "/json/map/:id",    patchMap
    app.delete  "/json/map/:id",    deleteMap

    # Map thumbnails.
    app.post    "/images/mapthumbs/:id", postMapThumb

    # User routes.
    app.get     "/json/user",       getUser
    app.get     "/json/user/:id",   getUser
    app.post    "/json/user",       postUser
    app.put     "/json/user/:id",   postUser
    app.patch   "/json/user/:id",   patchUser
    app.delete  "/json/user/:id",   deleteUser

    # External downloader.
    app.post    "/downloader/:filename", downloader

    # Server status and log routes.
    app.get     "/status",        getStatus
    app.get     "/logs/recent",   getLogsRecent
    app.get     "/upgrade",       runUpgrade