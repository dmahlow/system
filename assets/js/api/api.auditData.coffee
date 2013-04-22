# System API: Audit Data
# --------------------------------------------------------------------------
# System API - Audit Data interface. User to query and manage audit data.

SystemApp.Api.AuditData =

    # GET
    # ----------------------------------------------------------------------

    # Return [AuditData](auditData.html) based on the specified filter.
    get: (filter) ->
        SystemApp.Api.log "AuditData.get", filter

        return SystemApp.Api.getFromCollection SystemApp.Data.auditData, filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create an [AuditData](auditData.html) with the specified properties.
    create: (props) ->
        SystemApp.Api.log "AuditData.create", props

        auditdata = SystemApp.Data.auditData.create props
        return auditdata