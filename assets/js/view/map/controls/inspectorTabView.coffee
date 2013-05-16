# MAP CONTROLS: EDIT / MAP FILTER PROPERTIES VIEW
# --------------------------------------------------------------------------
# Represents the "Shape properties" tab inside a [Map Controls View](controlsView.html).

class SystemApp.MapControlsInspectorTabView extends SystemApp.BaseView

    # DOM ELEMENTS
    # ----------------------------------------------------------------------

    $topDescription: null           # the "H6" element on top of the tab
    $attributesDiv: null            # the list-div with shape properties (Shape details tab)
    $linksDiv: null                 # the list-div with the shape connections (Shape related tab)
    $parentAndChildDiv: null        # the list-div with the shape parent and child elements (Shape related tab)
    $eventsDiv: null                # the div containing the list of registered / active alerts for the selected shape


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Inits the view. Parent will be the [Map Controls View](controlsView.html).
    initialize: (parent) =>
        @baseInit parent
        @setDom()
        @setEvents()

    # Dispose the map view edit control.
    dispose: =>
        $(window).unbind "resize", @resize

        @$attributesDiv.empty()
        @$linksDiv.empty()
        @$parentAndChildDiv.empty()
        @$eventsDiv.empty()

        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @setElement $ "#map-ctl-tab-inspector"

        @$topDescription = @$el.find "h6"

        @$attributesDiv = $ "#map-ctl-inspector-attributes"
        @$parentAndChildDiv = $ "#map-ctl-shape-parent-child"
        @$linksDiv = $ "#map-ctl-shape-links"
        @$eventsDiv = $ "#map-ctl-shape-events"

        # Hide editable forms initially.
        @toggleForms false

    # Bind events to DOM and other controls.
    setEvents: =>
        $(window).resize @resize

        @listenTo SystemApp.Data.auditEvents, "add", @loadAuditEvent
        @listenTo SystemApp.Data.auditEvents, "remove", @removeAuditEvent
        @listenTo SystemApp.Data.auditEvents, "change:title", @updateAuditEventTitle

    # Unbind event listeners from the current [Shape View](shapeView.html).
    clearEvents: =>
        if @currentBoundViews?.linkViews?
            _.each @currentBoundViews.linkViews, (linkView) => linkView.model.off "change", @bindAllLinks

        if @currentBoundViews?.shapeViews?
            _.each @currentBoundViews.shapeViews, (shapeView) => shapeView.model.off "change", @bindAllChildItems

    # Enable or disable editing the current shape / link attached events.
    setEnabled: (value) =>
        fields = [@$eventsDiv, @$eventsDiv.find "input"]

        if not value
            elm.attr("disabled", "disabled").addClass("disabled") for elm in fields
        else
            elm.removeAttr("disabled").removeClass("disabled") for elm in fields

    # When window has loaded or resized, call this to resize the `$attributesDiv` in a way
    # that the `$eventsDiv` is always visible.
    # TODO! Prorperly calculate height considering tabs, headers, paddings etc.
    resize: =>
        height = @parentView.$el.innerHeight() - @$eventsDiv.outerHeight() - 140
        @$attributesDiv.css "max-height", height


    # BIND SHAPE / LINK
    # ----------------------------------------------------------------------

    # Bind a [Shape View](shapeView.html) or [Link View](linkView.html) to the control
    # and display its properties / related elements / links / etc.
    bind: (view) =>
        @currentBoundViews = view

        if @currentBoundViews?

            if @currentBoundViews.model?.id?
                @$topDescription.hide()

                if @currentBoundViews.linkViews?
                    _.each @currentBoundViews.linkViews, (linkView) => linkView.model.on "change", @bindAllLinks
                if @currentBoundViews.shapeViews?
                    _.each @currentBoundViews.shapeViews, (childView) => childView.model.on "change", @bindAllChildItems
            else


            # Show all editable panels.
            @toggleForms true

        else

            @$topDescription.text SystemApp.Messages.multipleShapesSelected
            @$topDescription.show()

            # No shape(s) selected, so hide panels and show the h6 element with the "no shapes selected text".
            @toggleForms false

        # Bind attributes, related entities and links.
        @bindAllAttributes()
        @bindAllLinks()
        @bindAllChildItems()
        @bindAllAuditEvents()
        @bindActiveAuditEvents()
        @resize()

    # Show or hide forms depending on what's selected on the map.
    toggleForms: (visible) =>
        if visible
            @$el.find("h5,.panel").show()
        else
            @$el.find("h5,.panel").hide()
            @$topDescription.text SystemApp.Messages.noShapeSelected
            @$topDescription.show()


    # INSPECT PROPERTIES
    # ----------------------------------------------------------------------

    # Bind all shape / link attributes to the `$attributesDiv`.
    bindAllAttributes: =>
        @$attributesDiv.empty()

        if @currentBoundViews?.model?.id?

            @bindAttribute @currentBoundViews.model.id, "ID"
            entityObj = @currentBoundViews.model.entityObject

            if entityObj?
                @bindAttribute @currentBoundViews.model.entityDefinitionId(), "Type"
                _.each entityObj.attributes, @bindAttribute
            else
                span = $(document.createElement "span")
                span.html SystemApp.Settings.Shape.customText
                @$attributesDiv.append span

    # Add a single attribute to the `$attributesDiv`. First check the `ignoreDisplayProps` setting
    # to see if that particular attribute should be ignored.
    bindAttribute: (propValue, propName) =>
        if SystemApp.Settings.Map.ignoreDisplayProps.indexOf(propName) > 0
            return

        if not propValue? or propValue is ""
            return

        # Transform the value to a readable string.
        propValue = JSON.stringify propValue
        propValue = propValue.replace /\"/g, ""

        div = $ document.createElement "div"
        name = $ document.createElement "label"
        value = $ document.createElement "span"

        name.html propName + ":"
        value.html propValue

        # If property value is too long, add a class to make text smaller.
        value.addClass "small" if propValue.length > 50

        div.append name
        div.append value

        @$attributesDiv.append div

    # SHAPE RELATED TAB
    # ----------------------------------------------------------------------

    # Bind all child items to the "Related" tab.
    bindAllChildItems: =>
        @$parentAndChildDiv.empty()
        @bindParentDetails()

    # Add a single child entity to the child div, passing the shape view and its unique ID.
    bindChildItem: (item) =>
        div = $ document.createElement "div"
        name = $ document.createElement "label"
        value = $ document.createElement "span"

        name.html item.typeName + ": "
        value.html item.text()
        value.click item, @relatedEntityClick

        div.addClass "child"
        div.append name
        div.append value

        @$parentAndChildDiv.append div

    # Bind the parent entity details to the "Related" tab. For example if the selected shape
    # is a [Host](host.html), it will bind details about the [Machine](machine.html) in where
    # it is running.
    bindParentDetails: =>
        if not @currentBoundViews?.model?.id?
            return

        isShape = @currentBoundViews.constructor is SystemApp.MapShapeView

        if not isShape
            target = @parentView.parentView.shapeViews[@currentBoundViews.model.targetId()]
            parent = @parentView.parentView.shapeViews[@currentBoundViews.model.sourceId()]
            parentText = parent.model.id + " - " + target.model.id

        if not parent?
            return

        div = $ document.createElement "div"
        name = $ document.createElement "label"
        value = $ document.createElement "span"

        name.html "Parent: "
        value.html parentText

        if isShape
            value.click parent, @relatedEntityClick
        else
            value.addClass "nocursor"

        div.addClass "parent"
        div.append name
        div.append value

        @$parentAndChildDiv.append div

    # When user clicks on a related entity, copy its name or value and trigger the event
    # to search for it at the [Entity List View](entityListView.html).
    relatedEntityClick: (e) =>
        entity = e.data
        SystemApp.mapEvents.trigger "entitylist:search", entity.text()


    # LINKS
    # ----------------------------------------------------------------------

    # Bind the links tab.
    bindAllLinks: =>
        @$linksDiv.empty()

        if @currentBoundViews? and @currentBoundViews?.linkViews? and _.size(@currentBoundViews.linkViews) > 0
            _.each @currentBoundViews.linkViews, @bindLink

    # Add a single link to the links div, passing the [Link View](linkView.html) and its name.
    bindLink: (linkView) =>
        if not linkView?.model?.id?
            return

        div = $ document.createElement "div"
        name = $ document.createElement "label"
        value = $ document.createElement "span"

        if linkView.model.sourceId() is @currentBoundViews.model.id
            target = linkView.model.targetId()
        else
            target = linkView.model.sourceId()

        target = @parentView.parentView.shapeViews[target]

        if target.model.entityObject?
            target = target.model.entityObject.title()
        else
            target = target.model.id

        textStart = linkView.model.textStart()
        textMiddle = linkView.model.textMiddle()
        textEnd = linkView.model.textEnd()

        # All labels will be shown and merged on the "text".
        text = ""
        text += " " + textStart if textStart? and textStart isnt ""
        text += " " + textMiddle if textMiddle? and textMiddle isnt ""
        text += " " + textEnd if textEnd? and textEnd isnt ""

        label = text
        label = SystemApp.Messages.noLabelsSet if not label? or label is ""

        name.html "Link » #{target}: "
        value.html $.trim(label)

        div.append name
        div.append value

        @$linksDiv.append div


    # EVENTS BOTTOM TAB
    # ----------------------------------------------------------------------

    # Load all [Audit Events](auditEvent.html) and create the elements on the alerts div.
    loadAllAuditEvents: =>
        @$eventsDiv.empty()
        _.each SystemApp.Data.auditEvents.models, @loadAuditEvent

    # Add a single [AuditEvent](auditEvent.html) to the alerts div.
    loadAuditEvent: (auditEvent) =>
        div = $ document.createElement "div"
        checked = $ document.createElement "input"
        title = $ document.createElement "label"

        checked.attr "id", SystemApp.Settings.AuditEvent.shapeCheckboxName + auditEvent.id
        checked.attr "name", SystemApp.Settings.AuditEvent.shapeCheckboxName
        checked.attr "title", auditEvent.description() + " " + SystemApp.Messages.tooltipShapeAuditEventCheckbox
        checked.attr "type", "checkbox"
        checked.change auditEvent.id, @eventCheckChange

        title.html auditEvent.friendlyId()
        title.attr "for", SystemApp.Settings.AuditEvent.shapeCheckboxName + auditEvent.id
        title.attr "title", SystemApp.Messages.tooltipShapeAuditEventCheckbox

        div.append checked
        div.append title

        @$eventsDiv.append div

    # When user deletes an [AuditEvent](auditEvent.html), remove its associated div from the `$eventsDiv`.
    removeAuditEvent: (auditEvent) =>
        $("#" + SystemApp.Settings.AuditEvent.shapeCheckboxName + auditEvent.id).parent().remove()

    # If user changes the title of an [AuditEvent](auditEvent.html), update the corresponding div on `$eventsDiv`.
    updateAuditEventTitle: (auditEvent) =>
        title = auditEvent.id
        $("#" + SystemApp.Settings.AuditEvent.shapeCheckboxName + auditEvent.id).parent().children("label").html title

    # Check all [Audit Events](auditEvent.html) that are attached to the selected [Shape](shape.html).
    bindAllAuditEvents: =>
        checkboxes = @$eventsDiv.find "input"
        checkboxes.prop "checked", false

        if not @currentBoundViews?.model?.auditEventIds?
            @$eventsDiv.hide()
            return

        @$eventsDiv.show()
        ids = @currentBoundViews.model.auditEventIds()

        # If there are [AuditEvent](auditEvent.html) IDs attached to the selected shape/link, then
        # mark the correspondent checkboxes.
        if ids? and ids.length > 0
            for alertId in ids
                $("#" + SystemApp.Settings.AuditEvent.shapeCheckboxName + alertId).prop("checked", true)

    # Bind all currently active [Audit Events](auditEvent.html) for the selected shape.
    # Active alerts will have a small icon next to them, set via a CSS class.
    bindActiveAuditEvents: =>
        if not @currentBoundViews?
            return

        # Remove the `active` class from all alert divs.
        @$eventsDiv.children("div").removeClass "active"

        # Add the `active` class to all corresponding active alert divs.
        if @currentBoundViews?.labelsView?.activeAuditEvents?
            _.each @currentBoundViews.labelsView.activeAuditEvents, (auditEvent) =>
                $("#" + SystemApp.Settings.AuditEvent.shapeCheckboxName + auditEvent.id).parent().addClass "active"

    # When user (un)check an alert checkbox, update the [Shape](shape.html) `auditEventIds` property.
    eventCheckChange: (e) =>
        if not @currentBoundViews?
            return

        src = $ e.currentTarget
        checked = src.prop "checked"

        if checked
            arr = _.union @currentBoundViews.model.auditEventIds(), e.data
        else
            arr = _.without @currentBoundViews.model.auditEventIds(), e.data
            delete @currentBoundViews.labelsView.activeAuditEvents[e.data]

        # Force remove any null values from the array, and set the shape/link model `auditEventIds` attribute.
        arr = _.without arr, null
        @currentBoundViews.model.auditEventIds arr

        # If no alerts are selected, remove all `active` classes from the `$eventsDiv`
        # and force reset the selected shape/link view to its original appearance.
        if arr.length < 1
            @$eventsDiv.children("div").removeClass "active"
            @currentBoundViews.render()

        # Save the current shape/link model.
        @currentBoundViews.model.save()
        @parentView.model.save()