# SELF TEST VIEW
# --------------------------------------------------------------------------
# Represents the Self Test overlay used to troubleshoot the app.

class System.SelfTestView extends System.OverlayView


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Self Test overlay view.
    initialize: =>
        @overlayInit "#selftest"
        @setDom()
        @setEvents()

    # Dispose the Self Test overlay view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        console.warn "todo!"

    # Bind events to the DOM.
    setEvents: =>
        console.warn "todo!"