# ENTITY OBJECT MODEL
# --------------------------------------------------------------------------
# Represents a single entity object. Please note that the entity definitions
# are represented by a [EntityDefinition](entityDefinition.html) model.

class SystemApp.EntityObject extends SystemApp.BaseModel
    typeName: "EntityObject"
    defaults:
        entityDefinitonId: null


    # PROPERTIES
    # ----------------------------------------------------------------------

    # Helper to get / set the entity definition ID.
    entityDefinitionId: =>
        return null if not @collection?
        return @collection.parentModel.friendlyId()

    # Helper to get / set the entity definition ID.
    title: =>
        return "" if not @collection?.parentModel?

        entityDef = @collection.parentModel
        att = entityDef.objectTitleAttribute()

        # If the `objectTitleAttribute` has no commas, get the value directly.
        if att.indexOf(",") < 1
            result = @get att
        else
            # Split the`objectTitleAttribute` and try to get a value based on each
            # specified attribute name.
            arr = att.split ","

            for i in arr
                att = @get i
                if att? and att.length > 0
                    result = att

        # If no valid title is found, return the entity object ID followed by an asterisk.
        # Otherwise return the result itself.
        if not result? or result.length < 1
            return @id + "*"

        return result


# ENTITY COLLECTION
# --------------------------------------------------------------------------
# Represents a collection of entity objects.

class SystemApp.EntityObjectCollection extends SystemApp.BaseCollection
    typeName: "EntityObjectCollection"
    model: SystemApp.EntityObject

    # URL should be set to the parent [entity definition](entityDefinition.html)
    # property `sourceUrl`. If not parent model was set, return a generic "for-all" URL.
    url: =>
        if @parentModel?
            return SystemApp.Settings.EntityObject.url + "/" + @parentModel.friendlyId()
        else
            return SystemApp.Settings.EntityObject.url

    # Set the comparator function to order the entity objects by title.
    comparator: (shape) -> return shape.title()