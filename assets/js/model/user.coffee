# USER MODEL
# --------------------------------------------------------------------------
# Represents a user on the system. The password will be stored as a hash
# based on the username.

class SystemApp.User extends SystemApp.BaseModel
    typeName: "User"
    defaults:
        displayName: null   # the user display name
        passwordHash: null  # the user password hash
        username: null      # the username
        roles: []           # the user roles array


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the user's display name.
    displayName: (value) =>
        if value?
            @set "displayName", value
        @get "displayName"

    # Helper to get / set the user's password hash.
    passwordHash: (value) =>
        if value?
            @set "passwordHash", value
        @get "passwordHash"

    # Helper to get / set the user's username.
    username: (value) =>
        if value?
            @set "username", value
        @get "username"

    # Helper to get / set the user roles.
    roles: (value) =>
        if value?
            @set "roles", value
        @get "roles"


    # METHODS
    # ----------------------------------------------------------------------

    # Check if user has a specific role. Returns true or false.
    hasRole: (role) =>
        index = @roles().indexOf role
        return (index > -1)


# USER COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of users.

class SystemApp.UserCollection extends SystemApp.BaseCollection
    typeName: "UserCollection"
    model: SystemApp.User
    url: SystemApp.Settings.User.url

    # Set the comparator function to order the user collection by username.
    comparator: (user) -> return user.us