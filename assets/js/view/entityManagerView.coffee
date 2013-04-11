# ENTITY MANAGER VIEW
# --------------------------------------------------------------------------
# Represents the entities manager overlay.

class System.EntityManagerView extends System.OverlayView

    $txtCreate: null                # the text input used to create a new entity definition
    $butCreate: null                # the button used to create a new entity definition
    $txtDescription: null           # the "Description" textbox when editing an entity definition
    $txtSourceUrl: null             # the "Source URL" textbox when editing an entity definition
    $txtRefresh: null               # the "Refresh interval" textbox when editing an entity definition
    $txtIdAttribute: null           # the "Object's ID attribute" textbox when editing an entity definition
    $txtTitleAttribute: null        # the "Object's Title attribute" textbox when editing an entity definition
    $txtShapeSizeX: null            # the shape template "Size X" textbox
    $txtShapeSizeY: null            # the shape template "Size Y" textbox
    $txtShapeBackground: null       # the shape template "Background" textbox
    $txtShapeForeground: null       # the shape template "Label colour" textbox
    $txtShapeTitleForeground: null  # the shape template "Title foreground" textbox
    $txtShapeStroke: null           # the shape template "Border colour" textbox
    $cboShapeStrokeWidth: null      # the shape template "Border width" combobox
    $cboShapeFontSize: null         # the shape template "Font size" combobox
    $cboShapeOpacity: null          # the shape template "Opacity" combobox
    $chkShapeRoundedCorners: null   # the shape template "Rounded corners" checkbox
    $shapePreview: null             # the shape template preview


    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the Entity Manager overlay view.
    initialize: =>
        @currentSettings = System.App.Settings.EntityDefinition
        @overlayInit "#entitymanager"
        @setDom()
        @setEvents()

    # Dispose the Entity Manager view.
    dispose: =>
        @baseDispose()

    # Set the DOM elements cache.
    setDom: =>
        @$menuItem = $ "#menu-entities"
        @$modelsList = $ "#entitymanager-list"
        @$txtCreate = $ "#entitymanager-txt-create"
        @$butCreate = $ "#entitymanager-but-create"

        # Input fields for the entity definition properties.
        @$txtDescription = $ "#entitymanager-txt-description"
        @$txtSourceUrl = $ "#entitymanager-txt-sourceurl"
        @$txtRefresh = $ "#entitymanager-txt-refresh"
        @$txtIdAttribute = $ "#entitymanager-txt-idattribute"
        @$txtTitleAttribute = $ "#entitymanager-txt-titleattribute"

        # Input fields for shape template.
        @$txtShapeSizeX = $ "#entitymanager-txt-shape-sizex"
        @$txtShapeSizeY = $ "#entitymanager-txt-shape-sizey"
        @$txtShapeBackground = $ "#entitymanager-txt-shape-background"
        @$txtShapeForeground = $ "#entitymanager-txt-shape-foreground"
        @$txtShapeTitleForeground = $ "#entitymanager-txt-shape-titleforeground"
        @$txtShapeStroke = $ "#entitymanager-txt-shape-stroke"
        @$cboShapeStrokeWidth = $ "#entitymanager-cbo-shape-strokewidth"
        @$cboShapeFontSize = $ "#entitymanager-cbo-shape-fontsize"
        @$cboShapeOpacity = $ "#entitymanager-cbo-shape-opacity"
        @$chkShapeRoundedCorners = $ "#entitymanager-chk-shape-roundedcorners"

        # The shape preview.
        @$shapePreview = $ "#entitymanager-shape-preview > div"

        # Add dynamic attributes to input fields.
        @$txtRefresh.attr "min", System.App.Settings.EntityDefinition.minRefreshInterval
        @$txtRefresh.attr "max", System.App.Settings.EntityDefinition.maxRefreshInterval

    # Bind events to the DOM. This will effectively update the `model` automatically
    # whenever any input field value gets changed.
    setEvents: =>
        @$butCreate.click @createEntityClick
        @$txtCreate.keyup @createEntityKeyUp

        @$txtDescription.change @inputOnChange
        @$txtSourceUrl.change @inputOnChange
        @$txtRefresh.change @inputOnChange
        @$txtIdAttribute.change @inputOnChange
        @$txtTitleAttribute.change @inputOnChange

        @$txtShapeSizeX.change @inputOnChangeShape
        @$txtShapeSizeY.change @inputOnChangeShape
        @$txtShapeBackground.change @inputOnChangeShape
        @$txtShapeForeground.change @inputOnChangeShape
        @$txtShapeTitleForeground.change @inputOnChangeShape
        @$txtShapeStroke.change @inputOnChangeShape
        @$cboShapeStrokeWidth.change @inputOnChangeShape
        @$cboShapeFontSize.change @inputOnChangeShape
        @$cboShapeOpacity.change @inputOnChangeShape
        @$chkShapeRoundedCorners.change @inputOnChangeShape


    # ENTITY LIST
    # ----------------------------------------------------------------------

    # Clear the current view by setting the `model` to null
    # and emptying the `$modelsList`.
    clear: =>
        @model = null
        @$modelsList.empty()
        @clearTextInputs()

    # Clear the text input fields.
    clearTextInputs: =>
        @$txtCreate.val ""

    # Bind all [EntityDefinitions](entityDefinition.html) from the [data store](data.html).
    bindEntities: =>
        @clear()
        @addToModelsList item for item in System.App.Data.entities.models


    # CREATING ENTITIES
    # ----------------------------------------------------------------------

    # When user clicks the "Add" entity button, add a new record to the
    # [Data.entities](data.html) and move focus to the properties form.
    createEntityClick: (e) =>
        newId = @$txtCreate.val()

        # The entity definition ID must have at least 2 chars.
        if newId.length < 2
            @warnField @$txtCreate
            return
        else
            newId = System.App.DataUtil.normalize newId, true

        System.App.Data.entities.create {friendlyId: newId}, {wait: true}
        @clearTextInputs()

    # If the `$txtCreate` field has focus, pressing Enter will call the `click`
    # event on the `$butCreate`.
    createEntityKeyUp: (e) =>
        if e.keyCode is 13
            @$butCreate.click()


    # PROPERTIES AND SHAPE TEMPLATE
    # ----------------------------------------------------------------------

    # Bind entity properties and refresh the shape template.
    onBindModel: =>
        @bindEntityProperties()
        @bindShapeProperties()

        # Delay the `updateShapeTemplate` so it can property calculate width and height.
        setTimeout @updateShapeTemplate, 100

    # Bind the properties (ID, url, description etc...) from the specified
    # [Entity Definition](entityDefinition.html) to the form.
    bindEntityProperties: =>
        return if not @model?

        @$txtDescription.val @model.description()
        @$txtSourceUrl.val @model.sourceUrl()
        @$txtRefresh.val @model.refreshInterval()
        @$txtIdAttribute.val @model.objectIdAttribute()
        @$txtTitleAttribute.val @model.objectTitleAttribute()

    # Bind the shape template properties for the selected [Entity Definition](entityDefinition.html).
    bindShapeProperties: =>
        return if not @model?

        @$txtShapeSizeX.val @model.shapeSizeX()
        @$txtShapeSizeY.val @model.shapeSizeY()
        @$txtShapeBackground.val @model.shapeBackground()
        @$txtShapeForeground.val @model.shapeForeground()
        @$txtShapeTitleForeground.val @model.shapeTitleForeground()
        @$txtShapeStroke.val @model.shapeStroke()
        @$cboShapeStrokeWidth.val @model.shapeStrokeWidth()
        @$cboShapeFontSize.val @model.shapeFontSize()
        @$cboShapeOpacity.val @model.shapeOpacity()
        @$chkShapeRoundedCorners.prop "checked", @model.shapeRoundedCorners()

    # Update the div representing the shape template with the new values.
    # If not entity is being edited, hide the shape template preview.
    updateShapeTemplate: =>
        if not @model?
            @$shapePreview.hide()
            return

        if @model.shapeRoundedCorners()
            borderRadius = "10px"
        else
            borderRadius = "0"

        shapeCss =
            "background": @model.shapeBackground()
            "border": "#{@model.shapeStrokeWidth()}px solid #{@model.shapeStroke()}"
            "border-radius": borderRadius
            "font-size": "#{@model.shapeFontSize()}px"
            "height": @model.shapeSizeY() * System.App.Settings.Map.gridSizeY - @model.shapeStrokeWidth()
            "opacity": @model.shapeOpacity()
            "width": @model.shapeSizeX() * System.App.Settings.Map.gridSizeX - @model.shapeStrokeWidth()

        titleCss =
            "color": @model.shapeTitleForeground()

        labelCss =
            "color": @model.shapeForeground()

        @$shapePreview.show()
        @$shapePreview.css shapeCss
        @$shapePreview.children("label").css titleCss
        @$shapePreview.children("span").css labelCss

        moveToCenter = (i, label) ->
            label = $(label)
            label.css "margin-left", label.outerWidth() / 2 * -1 + "px"

        moveToMiddle = (i, label) ->
            label = $(label)
            label.css "margin-top", label.outerHeight() / 2 * -1 + "px"

        $.each @$shapePreview.find(".label-title,.label-top,.label-center,.label-bottom"), moveToCenter
        $.each @$shapePreview.find(".label-left,.label-center,.label-right"), moveToMiddle


    # UPDATING SHAPE PROPERTIES
    # ----------------------------------------------------------------------

    # When user changes the value of shape related fields, do a `updateShapeTemplate`
    # and save the new value by calling the generic `inputOnChange`.
    inputOnChangeShape: (e) =>
        @inputOnChange e
        @updateShapeTemplate()


    # SHOW AND HIDE
    # ----------------------------------------------------------------------

    # Bind the `keyUp` event when overlay is shown.
    onShow: =>
        @bindEntities()

        $(document).keyup @hasModelListKeyUp
        @listenTo System.App.Data.entities, "add", @addToModelsList
        @listenTo System.App.Data.entities, "remove", @removeFromModelsList

    # Save the `model` (if there's one) when the overlay is closed,
    # and remove the `keyUp` from the document.
    onHide: =>
        $(document).unbind "keyup", @hasModelListKeyUp
        @stopListening()

        @model?.save()
        @model = null