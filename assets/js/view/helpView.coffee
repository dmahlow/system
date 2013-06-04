# HELP VIEW
# --------------------------------------------------------------------------
# Represents the Help overlay.

class SystemApp.HelpView extends SystemApp.OverlayView


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
        @$menuItem = $ "#menu-help"

        @$el.find(".prefix-variables").html SystemApp.Settings.general.dataBindingKey + SystemApp.Settings.variable.bindingNamespace
        @$el.find(".prefix-auditeventcontext").html SystemApp.Settings.general.dataBindingKey + SystemApp.Settings.shape.bindingNamespace