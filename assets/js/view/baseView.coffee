# BASE VIEW
# --------------------------------------------------------------------------
# Base abstract view class. All views MUST inherit from this one, as it has
# some basic features like event triggering and elements disposing.

class SystemApp.BaseView extends Backbone.View

    # Holds the parent view. Please note that the parent view does not necessarily the parent DOM container.
    parentView: null

    # DOM elements and variables cache. This is set by calling and passing the selectors to `domInit`.
    dom: {}


    # BASE HELPER METHODS
    # ----------------------------------------------------------------------

    # Init the view and set the parent view (if the `p` parameter is passed).
    baseInit: (parent) =>
        @parentView = parent if parent?

    # Dispose the view element and set it to null.
    baseDispose: =>
        @stopListening()

        try
            @remove()
        catch ex
            console.warn "Could not remove element. Maybe it was already removed?", this

        @$el = null
        @el = null
        @parentView = null


    # DOM HELPERS
    # ----------------------------------------------------------------------

    # Set the DOM elements. The arr should be an array containing all the selectors which
    # will populate the `dom` property. The key will be made of the selector minus its special characters.
    # Example:
    # `view.domInit ["#butCreate", "#txtCreate", ".tabs", ".tab-headers"]`
    domInit: (arr) =>
        @addToDom selector for selector in arr

    # Add the specified DOM element(s) to the `dom` cache.
    addToDom: (selector) =>
        return if not selector? or selector is ""

        domId = SystemApp.DataUtil.normalize selector, true
        @dom[domId] = $ selector


    # UI HELPERS
    # ----------------------------------------------------------------------

    # Set the window title and append the default app name on it.
    setTitle: (value) =>
        if value?
            value = "#{value} - #{SystemApp.Settings.General.appTitle}"
        else
            value = SystemApp.Settings.General.appTitle
        document.title = value

    # Warn the user by blinking the specified field with a red background.
    warnField: (field) =>
        extraMs = SystemApp.Settings.General.elementBlinkInterval / 2
        redClass = "error"

        @addClass field, redClass
        _.delay @removeClass, SystemApp.Settings.General.elementBlinkInterval, field, redClass
        _.delay @addClass, SystemApp.Settings.General.elementBlinkInterval + extraMs, field, redClass
        _.delay @removeClass, SystemApp.Settings.General.elementBlinkInterval * 2, field, redClass
        _.delay @addClass, SystemApp.Settings.General.elementBlinkInterval * 2 + extraMs, field, redClass
        _.delay @removeClass, SystemApp.Settings.General.elementBlinkInterval * 3, field, redClass

    # Show a "saved" message next to the specified field, and fade it out after a few seconds.
    fieldSaved: (field) =>
        alert = $(document.createElement "span")
        alert.addClass "saved"
        alert.html SystemApp.Messages.saved

        # Get container and its last span to check if "saved" is already being shown.
        parent = field.parent()
        lastChild = parent.children("span:last-child")

        # Append the "saved" at the very end of the field container,
        # but only if a "saved" is not present yet.
        if not lastChild.hasClass "saved"
            field.parent().append alert

            # Fade out and then remove from the DOM.
            alert.fadeOut SystemApp.Settings.General.fadeRemoveDelay * 2, () -> alert.remove()

    # Remove a DOM element representing a model from the view. This will add the class "removed"
    # and then fade the element out.
    modelElementRemove: (el) =>
        el.removeClass("active").addClass "removed"
        el.fadeOut SystemApp.Settings.General.fadeRemoveDelay, () -> el.remove()

    # Add the specified class to an element.
    addClass: (el, className) =>
        el?.addClass className

    # Remove the specified class from the element.
    removeClass: (el, className) =>
        el?.removeClass className

    # Sort the specified list. The default item selector is the tag `li`, but you can override this.
    # To sort descending, set `desc` to true.
    sortList: (list, selector, desc) =>
        selector = "li" if not selector?
        desc = false if not desc?
        items = list.children(selector).get()

        # If `desc` is true, sort descending.
        if desc
            sorter = (a, b) ->
                keyA = $(a).text()
                keyB = $(b).text()
                return -1 if keyA > keyB
                return 1 if keyA < keyB
                return 0
            items.sort(sorter)
        else
            items.sort()

        # Reappend each item on its correct position after sorting.
        $.each items, (i, el) -> list.append el


    # MODIFIER KEY HELPERS
    # ----------------------------------------------------------------------

    # Check if user is pressing the key combination for delete actions (when deleting a link for example).
    # The default combination is "Ctrl + Left Click", set on the [Settings](settings.html).
    isEventDelete: (e) =>
        if not e?
            return false
        return @testModifierEvent(e, SystemApp.Data.userSettings.modifierDelete())

    # Check if user is pressing key combination for multiple selections (when selecting multiple shapes for example).
    # The default combination is "Shift + Left Click", set on the [Settings](settings.html).
    isEventMultiple: (e) =>
        if not e?
            return false
        return @testModifierEvent(e, SystemApp.Data.userSettings.modifierMultiple())

    # Check if user is pressing the key combination for "send to back" (when reordering map shapes for example).
    # The default combination is "Right Click", set on the [Settings](settings.html).
    isEventToBack: (e) =>
        if not e?
            return false
        return @testModifierEvent(e, SystemApp.Data.userSettings.modifierToBack())

    # Test a modifier key combination against a keyboard / mouse event.
    testModifierEvent: (e, modifier) =>
        hasLeftClick = modifier.indexOf("leftclick") >= 0
        hasRightClick = modifier.indexOf("rightclick") >= 0
        hasCtrl = modifier.indexOf("ctrl") >= 0
        hasShift = modifier.indexOf("shift") >= 0
        hasAlt = modifier.indexOf("alt") >= 0
        hasNone = (!hasCtrl and !hasShift and !hasAlt)

        keyOk = (hasCtrl and e.ctrlKey) or (hasShift and e.shiftKey) or (hasAlt and e.altKey) or hasNone
        mouseOk = (hasLeftClick and e.which is 1) or (hasRightClick and e.which is 3)

        return mouseOk and keyOk