# System API: Audit Event
# --------------------------------------------------------------------------
# System API - Audit Event interface. User to query and manage audit events.

SystemApp.Api.AuditEvent =

    # GET
    # ----------------------------------------------------------------------

    # Return [Audit Events](auditEvents.html) based on the specified filter.
    get: (filter) ->
        SystemApp.Api.log "AuditEvent.get", filter

        return SystemApp.Api.getFromCollection SystemApp.Data.auditEvents, filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create an [Audit Events](auditEvents.html) with the specified properties.
    create: (props) ->
        SystemApp.Api.log "AuditEvent.create", props

        auditevent = SystemApp.Data.auditEvents.create props
        return auditevent