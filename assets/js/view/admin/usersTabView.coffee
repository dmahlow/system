# ADMIN USERS TAB VIEW
# --------------------------------------------------------------------------
# Represents the "Users and Roles" tab on the admin area.

class SystemApp.AdminUsersTabView extends SystemApp.BaseView

    $txtDisplayName: null       # the "display name" text field
    $txtUsername: null          # the "username" text field
    $txtPassword: null          # the "password" tet field
    $txtPasswordConfirm: null   # the "confirm password" text field
    $chkRoles: null             # the "roles" checkboxes
    $butSave: null              # the "Save user" button
    $userGrid: null             # the users grid

    selectedUser: null          # the user beind edited at the moment



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
        @listenTo SystemApp.Data.users, "add", @addUserToGrid
        @listenTo SystemApp.Data.users, "remove", @removeUserFromGrid

        @$butSave.click @saveUser

        $(document).keyup @keyUp


    # EDITING USERS
    # ----------------------------------------------------------------------

    # Bind the current selected [user](user.html) to the editing form.
    bindUserForm: =>
        if not @selectedUser?
            @$txtDisplayName.val ""
            @$txtUsername.val ""
            @$txtPassword.val ""
            @$txtPasswordConfirm.val ""
            return

        @$txtDisplayName.val @selectedUser.displayName()
        @$txtUsername.val @selectedUser.username()

        for c in @$chkRoles
            chk = $ c
            if @selectedUser.hasRole chk.val()
                chk.prop "checked", true
            else
                chk.prop "checked", false


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
        props = {displayName: displayName, username: username, password: password, roles: roles}
        user = SystemApp.Data.users.create props, {wait: true}


    # USERS GRID
    # ----------------------------------------------------------------------

    # When a new user is added to the users collection.
    addUserToGrid: (user) =>
        props = {displayName: user.displayName(), username: user.username(), roles: user.roles().join(", ")}
        row = _.template $("#template-user-grid-row").html(), props
        row = $ row

        # Set row ID.
        row.attr "id", SystemApp.Settings.User.rowListPrefix + user.id

        # Bind edit and delete events.
        row.find(".actions .edit").click user, @editClick
        row.find(".actions .delete").click user, @deleteClick

        # Append row to the `$userGrid`.
        @$userGrid.append row

    # When a user is removed from the users collection.
    removeUserFromGrid: (user) =>
        row = $("#" + SystemApp.Settings.User.rowListPrefix + user.id)
        @modelElementRemove row

    # Bind registered users to the users grid.
    bindUsers: =>
        @$userGrid.empty()
        @addUserToGrid(user) for user in SystemApp.Data.users.models

    # When user clicks the "edit" icon, highlight the row and bind user details
    # to the top form so it can be edited.
    editClick: (e) =>
        if @selectedUser?
            $("#" + SystemApp.Settings.User.rowListPrefix + @selectedUser.id).removeClass "active"

        # Highlight the clicked row.
        row = $(e.target).parent().parent()
        row.addClass "active"

        # Set `selectedUser` and bind to the edit form.
        @selectedUser = e.data
        @bindUserForm()

    # When user clicks the "delete" icon, make it red and if clicking again,
    # remove the user from the database and the row from the `$userGrid`.
    deleteClick: (e) =>
        e.preventDefault()
        e.stopPropagation()

        src = $ e.currentTarget

        # If the icon is red, then confirm the deletion by removing the row's associated model
        # from the [data store](data.html).
        if src.hasClass "delete-red"
            e.data.destroy()
        else
            src.addClass "delete-red"


    # HELPER METHODS
    # ----------------------------------------------------------------------

    # When user presses a key, check if it's Esc to cancel pending actions like
    # editing user details or deleting a user.
    keyUp: (e) =>
        keyCode = e.keyCode

        if keyCode is 27
            @$el.find("div.delete").removeClass "delete-red"
            @$el.find("div.row").removeClass "active"
            @selectedUser = null
            @bindUserForm()

        @lastPressedKey = keyCode