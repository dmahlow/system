# System API: Variable
# --------------------------------------------------------------------------
# System API - Variable interface. Used to query and manage custom variables.

SystemApp.Api.Variable =

    # GET
    # ----------------------------------------------------------------------

    # Return [Variables](variable.html) based on the specified filter.
    get: (filter) ->
        SystemApp.Api.log "Variable.get", filter

        return SystemApp.Api.getFromCollection SystemApp.Data.variables, filter

    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create a [Variable](variable.html) map with the specified properties.
    create: (props) ->
        SystemApp.Api.log "Variable.create", props

        variable = SystemApp.Data.variables.create props
        return variable