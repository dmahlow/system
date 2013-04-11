# System API: Map
# --------------------------------------------------------------------------
# System API - Map interface. Used to query and manage maps and their shapes.

System.Api.Map =

    # Get the current [Map](map.html) being displayed. Might return null if no
    # maps are open at the moment.
    current: ->
        return System.App.mapView.model


    # GET
    # ----------------------------------------------------------------------

    # Return [maps](map.html) based on the specified filter.
    get: (filter) ->
        System.Api.log "Map.get", filter

        return System.Api.getFromCollection System.App.Data.maps, filter

    # Get the list of shapes available on the current [Map](map.html).
    getShapes: (filter) ->
        System.Api.log "Map.getShapes", filter

        map = System.Api.Map.current()

        # If no map is currently being viewed, stop and return null.
        return null if not map?

        return System.Api.getFromCollection map.shapes(), filter


    # CREATE, UPDATE, DELETE
    # ----------------------------------------------------------------------

    # Create a [Map](map.html) with the specified properties.
    create: (props) ->
        System.Api.log "Map.create", props

        map = System.App.Data.maps.create props
        return map

    # Create and add a [Shape](shape.html) to the current map and return its model.
    createShape: (props) ->
        System.Api.log "Map.addShape", props

        map = System.Api.Map.current()

        # If no map is currently being viewed, stop and return null.
        return null if not map?

        return map.shapes().create props


    # VIEW METHODS
    # ----------------------------------------------------------------------

    # Force refresh all map labels.
    refreshLabels: () ->
        System.App.mapView.refreshLabels()