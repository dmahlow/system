# FOOTER VIEW
# --------------------------------------------------------------------------
# Represents the page footer.

class SystemApp.FooterView extends SystemApp.BaseView

    height: 0               # cached variable that holds the footer height

    $text: null             # the footer dynamic text span
    $onlineUsers: null      # the div with the online user count


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the footer view.
    initialize: =>
        @setElement $ "#footer"

        @$text = $ "#footer-text"
        @$onlineUsers = $ "#footer-online-users"

        @height = @$el.outerHeight()

    # Dispose the footer view.
    dispose: =>
        @baseDispose()


    # CURRENT FOOTER
    # ----------------------------------------------------------------------

    # Set the footer text value.
    setText: (value) =>
        @$text.html value

        if value? or value isnt ""
            @$text.show()
        else
            @$text.hide()

    # Set the online user count.
    setOnlineUsers: (count) =>
        @$onlineUsers.html count


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Show (fade in) the footer bar.
    show: =>
        @$el.fadeIn SystemApp.Settings.Footer.opacityInterval

    # Hide (fade out) the footer bar.
    hide: =>
        @$el.fadeOut SystemApp.Settings.Footer.opacityInterval