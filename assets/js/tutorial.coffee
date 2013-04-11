# System DATA
# --------------------------------------------------------------------------
# This handles the interactive app tutorial (using the Joyride plugin).
# The tutorial steps are defined on the [tutorial.jade](tutorial.jade)
# file, and its main ID is `#tutorial`.

System.App.Tutorial =

    # Holds the joyride object and the "cancelbg" full size div.
    $tour: null
    $cancelbg: null

    # Define the callbacks for each step. Please make sure to keep these callbacks
    # in sync with the corresponding index for each step. If you add a new step, the
    # subsequent callbacks should have their index updated as well!
    callbacks:
        # Step: Entities. Show entities manager.
        0: () ->
            System.App.routes.openEntities()

        # Step: Sample Entity Definitions. Create fake "MyEntity".
        2: () ->
            afterMachine = () ->
                $("#entitymanager-but-create").click()
            addMachine = () ->
                System.App.Tutorial.simulateTyping $("#entitymanager-txt-create"), "MyEntity", afterMachine

            addMachine()

        # Step: Entity - Shape Templates. Show the shape template form.
        4: () ->
            $("#entitymanager-tabheader-shape").click()

        # Step: Audit Data. Show audit data manager.
        5: () ->
            System.App.routes.openAuditData()

        # Step: Audit Events. Show audit events manager.
        7: () ->
            System.App.routes.openAuditEvents()

        # Step: Maps. Hide overlays and create a "My Test System" map but only if it doesn't exist.
        9: () ->
            map = System.App.Data.maps.where {name: "My Test System"}

            if not map? or map.length < 1
                map = System.App.Data.maps.create {dateCreated: new Date(), name: "My Test System"}

            System.App.routes.showOverlay false
            System.App.routes.navigate "map/" + map.urlKey(), {trigger: true}

        # Step: Adding Shapes to the Map.
        10: () ->
            $("map-ctl-tab-header-entities").click()

    # Starts the tutorial by showing the "Create entities..." tip.
    start: ->
        System.App.consoleLog "Tutorial", "Start at " + new Date()
        @$cancelbg = $("#tutorial-cancelbg")
        @$cancelbg.show()
        @$tour = $("#tutorial").joyride {postStepCallback: @postStepCallback, postRideCallback: @postRideCallback}

    # Called each time the user clicks the "next step" button.
    postStepCallback: (index) ->
        callback = System.App.Tutorial.callbacks[index]

        if callback?
            callback()
            System.App.consoleLog "Tutorial", "Step #{index} with callback."
        else
            System.App.consoleLog "Tutorial", "Step #{index}."

    # Called when tour has finished. This will effectively hide the `cancelbg`.
    postRideCallback: ->
        System.App.consoleLog "Tutorial", "End at " + new Date()
        System.App.Tutorial.$cancelbg.hide()

        # Destroy "MyEntity".
        System.App.Data.entities.getByFriendlyId("MyEntity")?.destroy()


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