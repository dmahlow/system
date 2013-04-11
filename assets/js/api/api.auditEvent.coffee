# System API: Audit Event
# --------------------------------------------------------------------------
# System API - Audit Event interface. User to query and manage audit events.

System.Api.AuditEvent =

    # GET
    # ----------------------------------------------------------------------

    # Return [Audit Events](auditEvents.html) based on the specified filter.
    get: (filter) ->
        System.Api.log "AuditEvent.get", filter

        return System.Api.getFromCollection System.App.Data.auditEvents, filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create an [Audit Events](auditEvents.html) with the specified properties.
    create: (props) ->
        System.Api.log "AuditEvent.create", props

        auditevent = System.App.Data.auditEvents.create props
        return auditevent