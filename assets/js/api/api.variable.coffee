# System API: Variable
# --------------------------------------------------------------------------
# System API - Variable interface. Used to query and manage custom variables.

System.Api.Variable =

    # GET
    # ----------------------------------------------------------------------

    # Return [Variables](variable.html) based on the specified filter.
    get: (filter) ->
        System.Api.log "Variable.get", filter

        return System.Api.getFromCollection System.App.Data.variables, filter

    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create a [Variable](variable.html) map with the specified properties.
    create: (props) ->
        System.Api.log "Variable.create", props

        variable = System.App.Data.variables.create props
        return variable