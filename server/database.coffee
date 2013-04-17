# SERVER DATABASE
# --------------------------------------------------------------------------
# Handles the database interactions on the app.

class Database

    # Define the logger and settings.
    logger = require "./logger.coffee"
    settings = require "./settings.coffee"

    # Define mongoskin and set the default connection string.
    mongo = require "mongoskin"
    db = mongo.db settings.Database.connString, {fsync: settings.Database.fsync}


    # UNDERLYING METHODS
    # ----------------------------------------------------------------------

    # Make sure that we transform MongoDB "_id" to "id".
    normalizeId: (result) =>
        if not result?
            return

        if result.length?
            for obj in result
                obj["id"] = obj["_id"].toString()
                delete obj["_id"]
        else
            result["id"] = result["_id"].toString()
            delete result["_id"]

        return result

    # Get the full collection if no `filter` is specified. If `filter` is set,
    # check if it represents an ID to return a single document by ID, otherwise
    # assume it's a property filter and pass it to the `find` method on MongoDB.
    # The `callback` is mandatory here.
    getData: (table, filter, callback) =>
        if settings.General.debug
            console.log "Database.getData", table.collectionName, filter

        if filter?
            if filter.id?
                id = filter.id
            else
                t = typeof filter
                id = filter if t is "string" or t is "integer"

        if id?
            table.findById id, (err, result) => callback err, @normalizeId(result)
        else if filter?
            table.find(filter).toArray (err, result) => callback err, @normalizeId(result)
        else
            table.find().toArray (err, result) => callback err, @normalizeId(result)

    # Insert a new document if its ID is null or undefined, or updates the specified
    # document if its ID is set. If `options.patch` is true, patch the document
    # with its updated info instead of replacing it entirely.
    setData: (table, obj, options, callback) =>
        if not obj?
            callback? "#{table} record not found.", null
            return

        if settings.General.debug
            console.log "Database.setData", table.collectionName, obj.id, obj.friendlyId

        # Make sure the ID is converted to ObjectID, and delete the `obj.id` as
        # internally Mongo only uses the `_id` property.
        if obj.id?
            id = mongo.ObjectID.createFromHexString obj.id.toString()
        else
            id = obj._id

        delete obj.id

        if options?.patch
            table.findAndModify {"_id": id}, {"sort": "_id"}, {$set: obj}, {"new": true}, (err, result) =>
                callback(err, @normalizeId(result)) if callback?
        else
            table.findAndModify {"_id": id}, {"sort": "_id"}, obj, {"new": true, "upsert": true}, (err, result) =>
                callback(err, @normalizeId(result)) if callback?

        # Log transaction to the logs collection.
        @log obj, options

    # Delete the specified document from the database, based on its ID.
    delData: (table, id, callback) =>
        if not id?
            callback? "#{table} record not found.", null
            return

        # Make sure the ID is converted to ObjectID.
        id = mongo.ObjectID.createFromHexString id

        table.remove {"_id": id}, (err, result) =>
            callback(err, @normalizeId(result)) if callback?


    # ENTITY DEFINITIONS AND OBJECTS
    # ----------------------------------------------------------------------

    # Get [Entity Definitions](entityDefinition.html).
    getEntityDefinition: (filter, callback) =>
        table = db.collection "entity"
        @getData table, filter, callback

    # Insert or update an [Entity Definition](entityDefinition.html).
    setEntityDefinition: (obj, options, callback) =>
        table = db.collection "entity"
        @setData table, obj, options, callback

    # Delete the specified [Entity Definition](entityDefinition.html).
    deleteEntityDefinition: (id, callback) =>
        table = db.collection "entity"
        @delData table, id, callback

    # MAPS
    # ----------------------------------------------------------------------

    # Get [Maps](map.html).
    getMap: (filter, callback) =>
        table = db.collection "map"
        @getData table, filter, callback

    # Insert or update a [Map](map.html)
    setMap: (obj, options, callback) =>
        table = db.collection "map"
        @setData table, obj, options, callback

    # Delete the specified [Map](map.html).
    deleteMap: (id, callback) =>
        table = db.collection "map"
        @delData table, id, callback


    # AUDIT DATA
    # ----------------------------------------------------------------------

    # Get [Audit Data records](auditData.html).
    getAuditData: (filter, callback) =>
        table = db.collection "auditdata"
        @getData table, filter, callback

    # Insert or update an [AuditData](auditData.html).
    setAuditData: (obj, options, callback) =>
        table = db.collection "auditdata"
        @setData table, obj, options, callback

    # Delete the specified [AuditData](auditData.html).
    deleteAuditData: (id, callback) =>
        table = db.collection "auditdata"
        @delData table, id, callback


    # AUDIT EVENTS
    # ----------------------------------------------------------------------

    # Get [Audit Events](auditEvent.html).
    getAuditEvent: (filter, callback) =>
        table = db.collection "auditevent"
        @getData table, filter, callback

    # Insert or update an [AuditEvent](auditEvent.html).
    setAuditEvent: (obj, options, callback) =>
        table = db.collection "auditevent"
        @setData table, obj, options, callback

    # Delete the specified [AuditEvent](auditEvent.html).
    deleteAuditEvent: (id, callback) =>
        table = db.collection "auditevent"
        @delData table, id, callback


    # VARIABLES
    # ----------------------------------------------------------------------

    # Get [Variables](variable.html).
    getVariable: (filter, callback) =>
        table = db.collection "variable"
        @getData table, filter, callback

    # Insert or update a [Variable](variable.html).
    setVariable: (obj, options, callback) =>
        table = db.collection "variable"
        @setData table, obj, options, callback

    # Delete the specified [Variable](variable.html).
    deleteVariable: (id, callback) =>
        table = db.collection "variable"
        @delData table, id, callback


    # USERS
    # ----------------------------------------------------------------------

    # Get [User](user.html).
    getUser: (filter, callback) =>
        table = db.collection "user"
        @getData table, filter, callback

    # Insert or update a [User](user.html).
    setUser: (obj, options, callback) =>
        table = db.collection "user"
        @setData table, obj, options, callback

    # Delete the specified [User](user.html).
    deleteUser: (id, callback) =>
        table = db.collection "user"
        @delData table, id, callback


    # HISTORY LOGS
    # ----------------------------------------------------------------------

    # Every insert and update on the database will be logged to a "logs" collection
    # and kept saved for a few hours. This is NOT related to general logging, for
    # this please check the [Logger](logger.html) class.
    log: (obj, options) =>
        table = db.collection "log"

        if not obj?
            return
        else
            obj.timestamp = new Date()

        # Append options, if any.
        obj.setOptions = options if options?

        table.insert obj

    # Delete old log data. The maximum log age is defined at the [Server Settings](settings.html).
    # Default interval is every 2 hours.
    cleanLogs: =>
        minDate = new Date()
        minDate.setHours(minDate.getHours() - settings.Database.logExpires)

        table = db.collection "log"
        table.remove {"timestamp": {"$lt":minDate}}

        logger.info "Deleted DB logs older than #{minDate}."


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Clean a specific object and make it valid for MongoDB insertion.
    cleanObjectForInsertion: (obj) =>
        for k of obj
            if obj.hasOwnProperty k
                if k.indexOf(".") >= 0 or k.indexOf("$") >= 0
                    delete obj[k]
                else if typeof obj[k] is "object"
                    obj[k] = @cleanObjectForInsertion obj[k]
        return obj


# Singleton implementation.
# --------------------------------------------------------------------------
Database.getInstance = ->
    @instance = new Database() if not @instance?
    return @instance

module.exports = exports = Database.getInstance()