# System API: Audit Data
# --------------------------------------------------------------------------
# System API - Audit Data interface. User to query and manage audit data.

System.Api.AuditData =

    # GET
    # ----------------------------------------------------------------------

    # Return [AuditData](auditData.html) based on the specified filter.
    get: (filter) ->
        System.Api.log "AuditData.get", filter

        return System.Api.getFromCollection System.App.Data.auditData, filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create an [AuditData](auditData.html) with the specified properties.
    create: (props) ->
        System.Api.log "AuditData.create", props

        auditdata = System.App.Data.auditData.create props
        return auditdata