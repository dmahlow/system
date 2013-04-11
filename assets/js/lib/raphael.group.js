// RAPHAEL GROUP PLUGIN
// --------------------------------------------------------------------------
// Raphael "group plugin", implements group functionality using
// SVG's <g> element.

// Usage: var groupVariable = paperObject.group([optional]arrayOfSvgElements, [optional]svgIndex).
// Ex:    var rectangles = r.group([rec1, rect3, rec6], 0)

Raphael.fn.group = function (items)
{
    var r = this;

    function Group()
    {
        var instance,
            set = r.set(items),
            group = r.raphael.vml ? document.createElement("group") : document.createElementNS("http://www.w3.org/2000/svg", "g");

        r.canvas.appendChild(group);

        // To update the group's elements scale.
        function updateScale(transform, scale)
        {
            var scaleString = "scale(" + scale + ")";

            if (!transform)
            {
                return scaleString;
            }

            if (transform.indexOf("scale(") < 0)
            {
                return transform + " " + scaleString;
            }

            return transform.replace(/scale\(-?[0-9]+(\.[0-9][0-9]*)?\)/, scaleString);
        }

        // To update the group's elements rotation.
        function updateRotation(transform, rotation)
        {
            var rotateString = "rotate(" + rotation + ")";

            if (!transform)
            {
                return rotateString;
            }

            if (transform.indexOf("rotate(") < 0)
            {
                return transform + " " + rotateString;
            }

            return transform.replace(/rotate\(-?[0-9]+(\.[0-9][0-9]*)?\)/, rotateString);
        }

        // The group instance.
        instance = {

            // Implements the "scale" function, passing the new scale as parameter.
            scale:function (newScale)
            {
                var transform = group.getAttribute("transform");
                group.setAttribute("transform", updateScale(transform, newScale));
                return this;
            },

            // Implements the "rotate" function, passing the degrees as parameter.
            rotate:function (deg)
            {
                var transform = group.getAttribute("transform");
                group.setAttribute("transform", updateRotation(transform, deg));
            },

            // Implements the "push" function, to add new elements to the group.
            push:function (el)
            {
                function pushElement(it)
                {
                    if (!it)
                    {
                        return;
                    }

                    if (it.type === "set" || it.constructor === Array)
                    {
                        var i;

                        for (i = 0; i < it.length; i++)
                        {
                            pushElement(it[i]);
                        }
                    }
                    else
                    {
                        group.appendChild(it.node);
                        set.push(it);
                    }
                }

                if (el)
                {
                    pushElement(el);
                }

                return this;
            },

            // Implements the "exclude" function, to remove a specific element from the group.
            exclude:function (el)
            {
                set.exclude(el);
                set.canvas.appendChild(el);
            },

            // Implements the "remove" function, to remove the group and its child elements from the paper.
            remove:function ()
            {
                r.canvas.removeChild(group);
            },

            // Implements the "getBBox" function, to get the group's virtual bounding box.
            getBBox:function ()
            {
                return set.getBBox();
            },

            // Set group type and node.
            type:"group",
            node:group
        };

        return instance;
    }

    return Group();
};