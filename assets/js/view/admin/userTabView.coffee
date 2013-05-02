# ADMIN USER TAB VIEW
# --------------------------------------------------------------------------
# Represents the "Users and Roles" tab on the admin area.

class SystemApp.AdminUserTabView extends SystemApp.BaseView

    $txtDisplayName: null       # the "display name" text field
    $txtUsername: null          # the "username" text field
    $txtPassword: null          # the "password" tet field
    $txtPasswordConfirm: null   # the "confirm password" text field
    $chkRoles: null             # the "roles" checkboxes
    $butSave: null              # the "Save user" button
    $userGrid: null             # the users grid



    # INIT AND DISPOSE
    # ----------------------------------------------------------------------

    # Init the user tab view by settings the DOM and events.
    initialize: =>
        @setDom()
        @setEvents()

        SystemApp.Data.users.onFetchCallback = @bindUsers
        SystemApp.Data.users.fetch()

    # Dispose the menu view.
    dispose: =>
        @baseDispose()

    # Set all DOM elements.
    setDom: =>
        @setElement $ "#tab-users"

        @$txtDisplayName = $ "#user-txt-display-name"
        @$txtUsername = $ "#user-txt-username"
        @$txtPassword = $ "#user-txt-password"
        @$txtPasswordConfirm = $ "#user-txt-password-confirm"
        @$chkRoles = @$el.find ".edit .roles input"
        @$butSave = $ "#user-but-save"

        @$userGrid = $ "#user-grid"

    # Bind events to DOM.
    setEvents: =>
        @$butSave.click @saveUser


    # EDITING USERS
    # ----------------------------------------------------------------------

    # When user clicks the "Save user" button, validate the form and save.
    saveUser: (e) =>
        displayName = $.trim @$txtDisplayName.val()
        username = $.trim @$txtUsername.val()
        password = $.trim @$txtPassword.val()
        roles = []

        # Validate the form fields.
        if username is ""
            @warnField @$txtUsername
            return
        else if password is ""
            @warnField @$txtPassword
            return
        else if password isnt @$txtPasswordConfirm.val()
            @warnField @$txtPasswordConfirm
            return

        # Make sure display name is set.
        if displayName is ""
            displayName = username

        # Get selected roles.
        for chk in @$chkRoles
            if $(chk).prop "checked"
                roles.push $(chk).val()

        # Create model with specified attributes.
        user = new SystemApp.User {displayName: displayName, username: username, password: password, roles: roles}


    # USERS GRID
    # ----------------------------------------------------------------------

    # Bind registered users to the users grid.
    bindUsers: =>
        for u in SystemApp.Data.users.models
            props = {displayName: u.displayName(), username: u.username(), roles: u.roles().join()}
            row = _.template $("#template-user-grid-row").html(), props
            row = $ row

            row.find("img.edit").click @editClick

            @$userGrid.append row

    # When user clicks the "edit" icon, highlight the row and bind user details
    # to the top form so it can be edited.
    editClick: (e) =>
        row = $(e.target).parent().parent()
        row.addClass "active"