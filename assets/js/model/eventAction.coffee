# ALERT ACTION MODEL
# --------------------------------------------------------------------------
# Represents a single alert action. It is used to trigger special events on
# the UI, such as blinking a shape, changing its background color or displaying
# an alert on the footer.

class SystemApp.EventAction extends SystemApp.BaseModel
    typeName: "EventAction"
    defaults:
        actionType: null    # the action type can be: blink, colorBg, colorBorder, footerMessage
        actionValue: null   # the value for the action specified above (optional)

    # This holds a reference to all affected shapes when the action
    # was last triggered.
    affectedShapes: null


    # SYNC
    # ----------------------------------------------------------------------

    # Override the "save" method as we don't need to sync individual alert actions with the server.
    save: (key, value, options) => @noSyncSave key, value, options

    # Override the "destroy" method as we don't need to sync individual alert actions with the server.
    destroy: (options) => @noSyncDestroy options


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the action type.
    actionType: (value) =>
        if value?
            @set "actionType", value
        @get "actionType"

    # Helper to get / set the action value.
    actionValue: (value) =>
        if value?
            @set "actionValue", value
        @get "actionValue"

    # Returns a readable string with the action.
    toString: =>
        @actionType + ": " + @actionValue


# EVENT ACTION COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of event actions.

class SystemApp.EventActionCollection extends SystemApp.BaseCollection
    typeName: "EventActionCollection"
    model: SystemApp.EventAction

    # Set the comparator function to order the alert actions collection by action type.
    comparator: (action) -> return action.actionType()