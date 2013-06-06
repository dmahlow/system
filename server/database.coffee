# SERVER DATABASE
# --------------------------------------------------------------------------
# Handles the database interactions on the app.

class Database

    # Require Expresser.
    expresser = require "expresser"
    settings = expresser.settings


    # ENTITY DEFINITIONS AND OBJECTS
    # ----------------------------------------------------------------------

    # Get [Entity Definitions](entityDefinition.html).
    getEntityDefinition: (filter, callback) =>
        expresser.database.get "entity", filter, callback

    # Insert or update an [Entity Definition](entityDefinition.html).
    setEntityDefinition: (obj, options, callback) =>
        expresser.database.set "entity", obj, options, callback

    # Delete the specified [Entity Definition](entityDefinition.html).
    deleteEntityDefinition: (id, callback) =>
        expresser.database.del "entity", id, callback

    # MAPS
    # ----------------------------------------------------------------------

    # Get [Maps](map.html).
    getMap: (filter, callback) =>
        expresser.database.get "map", filter, callback

    # Insert or update a [Map](map.html)
    setMap: (obj, options, callback) =>
        expresser.database.set "map", obj, options, callback

    # Delete the specified [Map](map.html).
    deleteMap: (id, callback) =>
        expresser.database.del "map", id, callback


    # AUDIT DATA
    # ----------------------------------------------------------------------

    # Get [Audit Data records](auditData.html).
    getAuditData: (filter, callback) =>
        expresser.database.get "auditdata", filter, callback

    # Insert or update an [AuditData](auditData.html).
    setAuditData: (obj, options, callback) =>
        expresser.database.set "auditdata", obj, options, callback

    # Delete the specified [AuditData](auditData.html).
    deleteAuditData: (id, callback) =>
        expresser.database.del "auditdata", id, callback


    # AUDIT EVENTS
    # ----------------------------------------------------------------------

    # Get [Audit Events](auditEvent.html).
    getAuditEvent: (filter, callback) =>
        expresser.database.get "auditevent", filter, callback

    # Insert or update an [AuditEvent](auditEvent.html).
    setAuditEvent: (obj, options, callback) =>
        expresser.database.set "auditevent", obj, options, callback

    # Delete the specified [AuditEvent](auditEvent.html).
    deleteAuditEvent: (id, callback) =>
        expresser.database.del "auditevent", id, callback


    # VARIABLES
    # ----------------------------------------------------------------------

    # Get [Variables](variable.html).
    getVariable: (filter, callback) =>
        expresser.database.get "variable", filter, callback

    # Insert or update a [Variable](variable.html).
    setVariable: (obj, options, callback) =>
        expresser.database.set "variable", obj, options, callback

    # Delete the specified [Variable](variable.html).
    deleteVariable: (id, callback) =>
        expresser.database.del "variable", id, callback


    # USERS
    # ----------------------------------------------------------------------

    # Get [User](user.html).
    getUser: (filter, callback) =>
        expresser.database.get "user", filter, callback

    # Insert or update a [User](user.html).
    setUser: (obj, options, callback) =>
        expresser.database.set "user", obj, options, callback

    # Delete the specified [User](user.html).
    deleteUser: (id, callback) =>
        expresser.database.del "user", id, callback


    # HISTORY LOGS
    # ----------------------------------------------------------------------

    # Every insert and update on the database will be logged to a "logs" collection
    # and kept saved for a few hours. This is NOT related to general logging, for
    # this please check the [Logger](logger.html) class.
    log: (obj, options) =>
        return if not obj?

        # Append timestamp and options, if any.
        obj.timestamp = new Date()
        obj.setOptions = options if options?

        expresser.database.db.collection("log").insert obj

    # Delete old log data. The maximum log age is defined at the [Server Settings](settings.html).
    # Default interval is every 2 hours.
    cleanLogs: =>
        minDate = new Date()
        minDate.setHours(minDate.getHours() - settings.database.logExpires)

        expresser.database.db.collection("log").remove {"timestamp": {"$lt":minDate}}
        expresser.logger.info "Deleted DB logs older than #{minDate}."


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