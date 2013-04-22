# System API: Entity
# --------------------------------------------------------------------------
# System API - Entitiy interface. Used to query and manage entity definitions
# and their objects.

SystemApp.Api.Entity =

    # GET
    # ----------------------------------------------------------------------

    # Return [Entity Definitions](entityDefinition.html) based on the specified filter.
    get: (filter) ->
        SystemApp.Api.log "Entity.get", filter

        return SystemApp.Api.getFromCollection(SystemApp.Data.entities, filter)

    # Return [Entity Objects](entityObject.html) based on the
    # specified [Entity Definition](entityDefinition.html) and filter.
    # Please note: the filter applies to the data (objects), not the entity definition!
    # The `entityDef` can be either an instance or the ID of an [Entity Definition](entityDefinition.html)
    getObjects: (entityDef, filter) ->
        SystemApp.Api.log "Entity.getObjects", filter

        if not entityDef?
            return null

        if entityDef.data?
            data = entityDef.data().models
        else
            data = SystemApp.Data.entities.get entityDef
            data = entityDef?.data().models

        return SystemApp.Api.getFromCollection data, filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create an [Entity Definition](entityDefinition.html) map with the specified properties.
    create: (props) ->
        SystemApp.Api.log "Entity.create", props

        entity = SystemApp.Data.entities.create props
        return entity