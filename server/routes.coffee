# SERVER ROUTES
# --------------------------------------------------------------------------
# Define server routes.

module.exports = (app) ->

    # Require Expresser.
    expresser = require "expresser"
    settings = expresser.settings

    # Required modules.
    database = require "./database.coffee"
    fs = require "fs"
    manager = require "./manager.coffee"
    security = require "./security.coffee"
    sync = require "./sync.coffee"

    # Define the package.json.
    packageJson = require "./../package.json"

    # When was the package.json last modified?
    lastModified = null


    # MAIN AND ADMIN ROUTES
    # ----------------------------------------------------------------------

    # The login page and form.
    getLogin = (req, res) ->
        options =  getResponseOptions req

        # Render the index page.
        res.render "login", options

    # The login validation via post.
    postLogin = (req, res) ->
        username = req.body.username
        password = req.body.password

        if not username? or username is "" or not password? or password is ""
            res.redirect "/login"
        else
            security.validateUser username, password, (err, result) ->
                if err?
                    res.send "Error: #{JSON.stringify(err)}"
                else
                    res.send "Login validated! #{JSON.stringify(result)}"


    # The main index page.
    getIndex = (req, res) ->
        if not req.user?
            res.redirect "/login"
            return

        options =  getResponseOptions req

        # Render the index page.
        res.render "index", options

    # The main index page. Only users with the "admin" role will be able to
    # access this page.
    getAdmin = (req, res) ->
        if not req.user?
            res.redirect "/login"
            return

        options =  getResponseOptions req

        # Make sure user has admin role.
        if options.roles.admin isnt true
            res.redirect "/401"
            return

        # Render the admin page.
        res.render "admin", options

    # Run the system upgrader.
    runUpgrade = (req, res) ->
        files = fs.readdirSync "./upgrade/"

        for f in files
            if f.indexOf(".coffee") > 0
                require "../upgrade/" + f

        res.send "UPGRADED!!!"


    # ENTITY ROUTES
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
        roles = getUserRoles req
        if not roles.admin and not roles.entities
            sendForbiddenResponse res, "Entity POST"
            return

        database.setEntityDefinition getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                manager.initEntityTimers()
                res.send minifyJson result
            else
                sendErrorResponse res, "Entity POST", err

    # Patch only the specified properties of an [Entity Definition](entityDefinition.html).
    patchEntityDefinition = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.entities
            sendForbiddenResponse res, "Entity PATCH"
            return

        database.setEntityDefinition getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                manager.initEntityTimers()
                res.send minifyJson result
            else
                sendErrorResponse res, "Entity PATCH", err

    # Delete an [Entity Definition](entityDefinition.html).
    # This will also restart the entity timers on the server [manager](manager.html).
    deleteEntityDefinition = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.entities
            sendForbiddenResponse res, "Entity DELETE"
            return

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


    # AUDIT DATA ROUTES
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
        roles = getUserRoles req
        if not roles.admin and not roles.auditdata
            sendForbiddenResponse res, "Audit Data POST"
            return

        database.setAuditData getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                manager.initAuditDataTimers()
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Data POST", err

    # Patch only the specified properties of an [AuditData](auditData.html).
    patchAuditData = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.auditdata
            sendForbiddenResponse res, "Audit Data PATCH"
            return

        database.setAuditData getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                manager.initAuditDataTimers()
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Data PATCH", err

    # Delete an [AuditData](auditData.html).
    deleteAuditData = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.auditdata
            sendForbiddenResponse res, "Audit Data DELETE"
            return

        database.deleteAuditData getIdFromRequest(req), (err, result) ->
            if not err?
                manager.initAuditDataTimers()
                res.send ""
            else
                sendErrorResponse res, "Audit Data DELETE", err


    # AUDIT EVENT ROUTES
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
        roles = getUserRoles req
        if not roles.admin and not roles.auditevents
            sendForbiddenResponse res, "Audit Event POST"
            return

        database.setAuditEvent getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Event POST", err

    # Patch only the specified properties of an [AuditEvent](auditEvent.html).
    patchAuditEvent = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.auditevents
            sendForbiddenResponse res, "Audit Event PATCH"
            return

        database.setAuditEvent getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Audit Event PATCH", err

    # Delete an [AuditEvent](auditEvent.html).
    deleteAuditEvent = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.auditevents
            sendForbiddenResponse res, "Audit Event DELETE"
            return

        database.deleteAuditEvent getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "Audit Event DELETE", err


    # VARIABLE ROUTES
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
        roles = getUserRoles req
        if not roles.admin and not roles.variables
            sendForbiddenResponse res, "Variable POST"
            return

        database.setVariable getDocumentFromBody(req), null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Variable POST", err

    # Patch only the specified properties of a [Variable](variable.html).
    patchVariable = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.variables
            sendForbiddenResponse res, "Variable PATCH"
            return

        database.setVariable getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Variable PATCH", err

    # Delete a [Variable](variable.html).
    deleteVariable = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.variables
            sendForbiddenResponse res, "Variable DELETE"
            return

        database.deleteVariable getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "Variable DELETE", err


    # MAP ROUTES
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
        roles = getUserRoles req
        if not roles.admin and not roles.mapcreate and not roles.mapedit
            sendForbiddenResponse res, "Map POST"
            return

        # Get map from request body.
        map = getDocumentFromBody req

        # Check if map is read only.
        if map.isReadOnly
            sendForbiddenResponse res, "Map POST (read-only)"
            return

        # If map is new, set the `createdByUserId` to the current logged user's ID.
        if not map.id? or map.id is ""
            map.createdByUserId = req.user.id

        # Make sure creation date is set.
        if not map.dateCreated? or map.dateCreated is ""
            map.dateCreated = new Date()

        database.setMap map, null, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map POST", err

    # Patch only the specified properties of a [Map](map.html).
    patchMap = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.mapedit
            sendForbiddenResponse res, "Map PATCH"
            return

        database.setMap getDocumentFromBody(req), {patch: true}, (err, result) ->
            if result? and not err?
                res.send minifyJson result
            else
                sendErrorResponse res, "Map PATCH", err

    # Delete a [Map](map.html).
    deleteMap = (req, res) ->
        roles = getUserRoles req
        if not roles.admin and not roles.mapedit
            sendForbiddenResponse res, "Map DELETE"
            return

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
        svgPath = settings.path.imagesDir + "mapthumbs/" + req.params["id"] + ".svg"

        fs.writeFile svgPath, svg, (err) ->
            if err?
                sendErrorResponse res, "Map Thumbnail POST", err
            else
                expresser.imaging.toPng svgPath, {size: settings.images.mapThumbSize}, (err2, result) ->
                    if err2?
                        sendErrorResponse res, "Map Thumbnail POST", err2
                    else
                        res.send result


    # USER ROUTES
    # ----------------------------------------------------------------------

    # Get a single or a collection of [Users](user.html).
    getUser = (req, res) ->
        if not req.user?
            sendForbiddenResponse res, "User GET"
            return

        roles = getUserRoles req

        # Check if should get the logged user's details.
        id = getIdFromRequest(req)
        id = req.user.id if id is "logged"

        # Return guest user if logged as "guest" and guest access is enabled on settings.
        if settings.security.guestEnabled and req.user.id is "guest"
            res.send minifyJson security.guestUser
        else
            database.getUser id, (err, result) ->
                if result? and not err?

                    # Check user permissions.
                    if not roles.admin and result.id isnt req.user.id
                        sendForbiddenResponse res, "User GET"
                        return

                    # Make sure password fields are removed.
                    delete result["passwordHash"]
                    delete result["password"]

                    res.send minifyJson result
                else
                    sendErrorResponse res, "User GET", err

    # Add or update a [Users](user.html).
    postUser = (req, res) ->
        roles = getUserRoles req
        user = getDocumentFromBody req

        # Check user permissions.
        if not roles.admin and user.id isnt req.user.id
            sendForbiddenResponse res, "User POST"
            return

        # Make sure password hash is set and remove clear text password.
        if user.password?
            user["passwordHash"] = security.getPasswordHash user.username, user.password
            delete user["password"]

        database.setUser user, null, (err, result) ->
            if result? and not err?
                # Make sure password fields are removed.
                delete result["passwordHash"]
                delete result["password"]

                res.send minifyJson result
            else
                sendErrorResponse res, "User POST", err

    # Patch only the specified properties of a [Users](user.html).
    patchUser = (req, res) ->
        roles = getUserRoles req
        user = getDocumentFromBody req

        # Check user permissions.
        if not roles.admin and user.id isnt req.user.id
            sendForbiddenResponse res, "User PATCH"
            return

        # Make sure user password hash is set.
        user = getDocumentFromBody req
        if user.password?
            user["passwordHash"] = security.getPasswordHash user.username, user.password
            delete user["password"]

        database.setUser user, {patch: true}, (err, result) ->
            if result? and not err?
                # Make sure password fields are removed.
                delete result["passwordHash"]
                delete result["password"]

                res.send minifyJson result
            else
                sendErrorResponse res, "User PATCH", err

    # Delete a [Users](user.html).
    deleteUser = (req, res) ->
        roles = getUserRoles req

        # Check user permissions.
        if not roles.admin
            sendForbiddenResponse res, "User DELETE"
            return

        database.deleteUser getIdFromRequest(req), (err, result) ->
            if not err?
                res.send ""
            else
                sendErrorResponse res, "User DELETE", err


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


    # STATUS ROUTES
    # ----------------------------------------------------------------------

    # Get the system status page.
    getDocs = (req, res) ->
        res.redirect "/docs/README.html"

    # Get the system status page.
    getStatus = (req, res) ->
        res.json { status: "ok" }

    # Error 401 (not authorized) page.
    get401 = (req, res) ->
        res.status 401
        res.render "status401", title: settings.general.appTitle,

    # Error 404 (not found) page.
    get404 = (req, res) ->
        res.status 404
        res.render "status404", title: settings.general.appTitle,


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Minify the passed JSON value. Please note that the result will be minified
    # ONLY if the `Web.minifyJsonResponse` setting is set to true.
    minifyJson = (source) ->
        if settings.web.minifyJsonResponse
            return expresser.utils.minifyJson source
        else
            return source

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

    # Get default app and server variables to be sent with responses.
    getResponseOptions = (req) ->
        os = require "os"
        moment = require "moment"
        host = req.headers["host"]

        # Check the last modified date.
        lastModified = fs.statSync("./package.json").mtime if not lastModified?

        # Set render options.
        options =
            title: settings.general.appTitle,
            version: packageJson.version,
            lastModified: moment(lastModified).format("YYYY-MM-DD hh:mm"),
            serverUptime: moment.duration(os.uptime(), "s").humanize(),
            serverHostname: os.hostname(),
            serverPort: settings.web.port,
            serverOS: os.type() + " " + os.release(),
            serverCpuLoad: os.loadavg()[0].toFixed(2),
            serverRamLoad: (os.freemem() / os.totalmem() * 100).toFixed(2),
            roles: getUserRoles req

        return options

    # Return an object with the user roles, based on the authenticated user's roles array.
    # Please note that the "admin" role will be returned always for the online demo.
    getUserRoles = (req) =>
        roles = {}
        return roles if not req.user?

        # Set roles object using role_name: true.
        for r in req.user.roles
            roles[r] = true

        return roles

    # When the server can't return a valid result,
    # send an error response with status code 500.
    sendErrorResponse = (res, method, message) ->
        expresser.logger.error "HTTP 500", method, message

        res.statusCode = 500
        res.send "Error: #{method} - #{message}"

    # When user is not authorized to request a resource, send an 403 error
    # with an "access denied" message.
    sendForbiddenResponse = (res, method) ->
        expresser.logger.error "HTTP 403", method

        res.statusCode = 403
        res.send "Access denied for #{method}."


    # SET MAIN AND ADMIN ROUTES
    # ----------------------------------------------------------------------

    # Set authentication options.
    passportOptions = {session: true}
    passportStrategy = if expresser.settings.passport.ldap.enabled then "ldapauth" else "basic"

    # The login page.
    app.get "/login", getLogin

    # The login page post validation.
    app.post "/login", postLogin

    # Main index.
    if expresser.app.passport?
        app.get "/", expresser.app.passport.authenticate(passportStrategy, passportOptions), getIndex
    else
        app.get "/", getIndex

    # Admin area.
    if expresser.app.passport?
        app.get "/admin", expresser.app.passport.authenticate(passportStrategy, passportOptions), getAdmin
    else
        app.get "/admin", getAdmin

    # Upgrader page.
    app.get "/upgrade", runUpgrade


    # SET DATA AND SPECIAL ROUTES
    # ----------------------------------------------------------------------

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


    # SET DOCS AND STATUS ROUTES
    # ----------------------------------------------------------------------

    # Error and status routes.
    app.get "/docs", getDocs
    app.get "/status", getStatus
    app.get "/401", get401
    app.get "/404", get404