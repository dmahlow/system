# HELP VIEW
# --------------------------------------------------------------------------
# Represents the Help overlay.

class System.HelpView extends System.OverlayView


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Help overlay view.
    initialize: =>
        @overlayInit "#help"
        @setHtml()

    # Dispose the Help overlay view and set the frame source to blank.
    dispose: =>
        @baseDispose()

    # Add dynamic values to the Help html.
    setHtml: =>
        @$el.find(".prefix-variables").html System.App.Settings.General.dataBindingKey + System.App.Settings.Variable.bindingNamespace
        @$el.find(".prefix-auditeventcontext").html System.App.Settings.General.dataBindingKey + System.App.Settings.Shape.bindingNamespace