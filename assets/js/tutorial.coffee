# System DATA
# --------------------------------------------------------------------------
# This handles the interactive app tutorial (using the Joyride plugin).
# The tutorial steps are defined on the [tutorial.jade](tutorial.jade)
# file, and its main ID is `#tutorial`.

SystemApp.Tutorial =

    # Holds the joyride object and the "cancelbg" full size div.
    $tour: null
    $cancelbg: null

    # Define the callbacks for each step. Please make sure to keep these callbacks
    # in sync with the corresponding index for each step. If you add a new step, the
    # subsequent callbacks should have their index updated as well!
    callbacks:
        # Step: Entities. Show entities manager.
        0: () ->
            SystemApp.routes.openEntities()

        # Step: Sample Entity Definitions. Create fake "MyEntity".
        2: () ->
            afterMachine = () ->
                $("#entitymanager-but-create").click()
            addMachine = () ->
                SystemApp.Tutorial.simulateTyping $("#entitymanager-txt-create"), "MyEntity", afterMachine

            addMachine()

        # Step: Entity - Shape Templates. Show the shape template form.
        4: () ->
            $("#entitymanager-tabheader-shape").click()

        # Step: Audit Data. Show audit data manager.
        5: () ->
            SystemApp.routes.openAuditData()

        # Step: Audit Events. Show audit events manager.
        7: () ->
            SystemApp.routes.openAuditEvents()

        # Step: Maps. Hide overlays and create a "My Test System" map but only if it doesn't exist.
        9: () ->
            map = SystemApp.Data.maps.where {name: "My Test System"}

            if not map? or map.length < 1
                map = SystemApp.Data.maps.create {dateCreated: new Date(), name: "My Test System"}

            SystemApp.routes.showOverlay false
            SystemApp.routes.navigate "map/" + map.urlKey(), {trigger: true}

        # Step: Adding Shapes to the Map.
        10: () ->
            $("map-ctl-tab-header-entities").click()

    # Starts the tutorial by showing the "Create entities..." tip.
    start: ->
        SystemApp.consoleLog "Tutorial", "Start at " + new Date()
        @$cancelbg = $("#tutorial-cancelbg")
        @$cancelbg.show()
        @$tour = $("#tutorial").joyride {postStepCallback: @postStepCallback, postRideCallback: @postRideCallback}

    # Called each time the user clicks the "next step" button.
    postStepCallback: (index) ->
        callback = SystemApp.Tutorial.callbacks[index]

        if callback?
            callback()
            SystemApp.consoleLog "Tutorial", "Step #{index} with callback."
        else
            SystemApp.consoleLog "Tutorial", "Step #{index}."

    # Called when tour has finished. This will effectively hide the `cancelbg`.
    postRideCallback: ->
        SystemApp.consoleLog "Tutorial", "End at " + new Date()
        SystemApp.Tutorial.$cancelbg.hide()

        # Destroy "MyEntity".
        SystemApp.Data.entities.getByFriendlyId("MyEntity")?.destroy()


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # Simulate typing on a field, and when finished call the passed callback.
    simulateTyping: (field, value, callback) ->
        field.val ""
        arr = value.split ""
        i = 0
        delay = 180

        while i < arr.length
            setTimeout (() -> field.val(field.val() + "" + arr.shift())), delay * (i + 1)
            i++

        setTimeout callback, delay * (arr.length + 1)