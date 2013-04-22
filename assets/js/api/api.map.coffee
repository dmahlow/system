# System API: Map
# --------------------------------------------------------------------------
# System API - Map interface. Used to query and manage maps and their shapes.

SystemApp.Api.Map =

    # Get the current [Map](map.html) being displayed. Might return null if no
    # maps are open at the moment.
    current: ->
        return SystemApp.mapView.model


    # GET
    # ----------------------------------------------------------------------

    # Return [maps](map.html) based on the specified filter.
    get: (filter) ->
        SystemApp.Api.log "Map.get", filter

        return SystemApp.Api.getFromCollection SystemApp.Data.maps, filter

    # Get the list of shapes available on the current [Map](map.html).
    getShapes: (filter) ->
        SystemApp.Api.log "Map.getShapes", filter

        map = SystemApp.Api.Map.current()

        # If no map is currently being viewed, stop and return null.
        return null if not map?

        return SystemApp.Api.getFromCollection map.shapes(), filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create a [Map](map.html) with the specified properties.
    create: (props) ->
        SystemApp.Api.log "Map.create", props

        map = SystemApp.Data.maps.create props
        return map

    # Create and add a [Shape](shape.html) to the current map and return its model.
    createShape: (props) ->
        SystemApp.Api.log "Map.addShape", props

        map = SystemApp.Api.Map.current()

        # If no map is currently being viewed, stop and return null.
        return null if not map?

        return map.shapes().create props


    # VIEW METHODS
    # ----------------------------------------------------------------------

    # Force refresh all map labels.
    refreshLabels: () ->
        SystemApp.mapView.refreshLabels()