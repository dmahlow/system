// RAPHAEL LINK PLUGIN
// -------------------------------------------------------------------------
// Raphael "link plugin", creates a link between two shapes.

// Usage: paperObject.link(sourceObj, targetObj, options).

// Options:
// arrowSize: size of arrow, in case arrowSource or arrowTarget is not 0.
// arrowSource: arrow on the source. 0 = no arrow, 1 = filled arrow, 2 = open arrow
// arrowTarget: arrow on the target. 0 = no arrow, 1 = filled arrow, 2 = open arrow
// opacity: opacity of the link, from 0 to 1.
// smooth: true makes the link smooth, false makes it a straight line.
// stroke: stroke / foreground colour.
// width: link width / strength.
// onClick: callback when user clicks the link.


// LINK IMPLEMENTATION
// -------------------------------------------------------------------------

// Main link function.
// obj1 - the source element.
// obj2 - the target element.
// options - general linking options.
Raphael.fn.link = function (obj1, obj2, options)
{
    // If the first parameter is null or undefined, stops execution straight away.
    if (!obj1)
    {
        return;
    }

    var that = this;
    var link, arrowSize, arrowSource, arrowTarget, opacity, smooth, stroke, width, onClick;

    // Set the line options, if the "options" parameter is passed.
    if (options)
    {
        arrowSize = options.arrowSize;
        arrowSource = options.arrowSource;
        arrowTarget = options.arrowTarget;
        opacity = options.opacity;
        smooth = options.smooth;
        stroke = options.stroke;
        width = options.width;
        onClick = options.onClick;
    }

    // If the first parameter has the properties "line", "from" and "to",
    // then assume it is a link and set its options accordingly.
    if (obj1.svgLine && obj1.from && obj1.to)
    {
        link = obj1;

        // If options is undefined but there's the obj2, assume it is the options object.
        if (!options && obj2)
        {
            options = obj2;
        }

        if (options && options.arrowSize != undefined)
        {
            arrowSize = options.arrowSize;
        }
        else
        {
            arrowSize = link.arrowSize;
        }

        if (options && options.arrowSource != undefined)
        {
            arrowSource = options.arrowSource;
        }
        else
        {
            arrowSource = link.arrowSource;
        }

        if (options && options.arrowTarget != undefined)
        {
            arrowTarget = options.arrowTarget;
        }
        else
        {
            arrowTarget = link.arrowTarget;
        }

        if (options && options.opacity != undefined)
        {
            opacity = options.opacity;
        }
        else
        {
            opacity = link.opacity;
        }

        if (options && options.smooth != undefined)
        {
            smooth = options.smooth;
        }
        else
        {
            smooth = link.smooth;
        }

        if (options && options.stroke != undefined)
        {
            stroke = options.stroke;
        }
        else
        {
            stroke = link.stroke;
        }

        if (options && options.width != undefined)
        {
            width = options.width;
        }
        else
        {
            width = link.width;
        }

        if (options && options.onClick != undefined)
        {
            onClick = options.onClick;
        }
        else
        {
            onClick = link.onClick;
        }

        obj1 = link.from;
        obj2 = link.to;
    }

    // Make sure arrow size is valid. Default is 15.
    if (arrowSize === undefined || arrowSize === null)
    {
        arrowSize = 15;
    }

    // Make sure arrowSource are set to 0 in case they're undefined. Default is 0.
    if (arrowSource === undefined || arrowSource === null || arrowSource < 0)
    {
        arrowSource = 0;
    }

    // Make sure arrowTarget are set to 0 in case they're undefined. Default is 0.
    if (arrowTarget === undefined || arrowTarget === null || arrowTarget < 0)
    {
        arrowTarget = 0;
    }

    // Make sure opacity is valid. Default is 1.
    if (opacity === undefined || opacity === null)
    {
        opacity = 1;
    }

    // Make sure width is valid. Derfault is 1.
    if (width === undefined || width === null || width < 1)
    {
        width = 1;
    }

    var path;
    var res, dx, dy;
    var bb1 = obj1.getBBox();
    var bb2 = obj2.getBBox();

    // Set the "points" array, to calculate where the link will attach to the shapes.
    var p = [
        {
            x:bb1.x + bb1.width / 2,
            y:bb1.y - 1
        },
        {
            x:bb1.x + bb1.width / 2,
            y:bb1.y + bb1.height + 1
        },
        {
            x:bb1.x - 1,
            y:bb1.y + bb1.height / 2
        },
        {
            x:bb1.x + bb1.width + 1,
            y:bb1.y + bb1.height / 2
        },
        {
            x:bb2.x + bb2.width / 2,
            y:bb2.y - 1
        },
        {
            x:bb2.x + bb2.width / 2,
            y:bb2.y + bb2.height + 1
        },
        {
            x:bb2.x - 1,
            y:bb2.y + bb2.height / 2
        },
        {
            x:bb2.x + bb2.width + 1,
            y:bb2.y + bb2.height / 2
        }
    ];

    var d = {}, dis = [];

    for (var i = 0; i < 4; i++)
    {
        for (var j = 4; j < 8; j++)
        {
            dx = Math.abs(p[i].x - p[j].x);
            dy = Math.abs(p[i].y - p[j].y);

            if ((i == j - 4) || (((i != 3 && j != 6) || p[i].x < p[j].x) && ((i != 2 && j != 7) || p[i].x > p[j].x) && ((i != 0 && j != 5) || p[i].y > p[j].y) && ((i != 1 && j != 4) || p[i].y < p[j].y)))
            {
                dis.push(dx + dy);
                d[dis[dis.length - 1]] = [i, j];
            }
        }
    }

    if (dis.length == 0)
    {
        res = [0, 4];
    }
    else
    {
        res = d[Math.min.apply(Math, dis)];
    }

    var x1 = p[res[0]].x,
        y1 = p[res[0]].y,
        x4 = p[res[1]].x,
        y4 = p[res[1]].y;

    dx = Math.max(Math.abs(x1 - x4) / 2, 10);
    dy = Math.max(Math.abs(y1 - y4) / 2, 10);

    var x2 = [x1, x1, x1 - dx, x1 + dx][res[0]].toFixed(3),
        y2 = [y1 - dy, y1 + dy, y1, y1][res[0]].toFixed(3),
        x3 = [0, 0, 0, 0, x4, x4, x4 - dx, x4 + dx][res[1]].toFixed(3),
        y3 = [0, 0, 0, 0, y1 + dy, y1 - dy, y4, y4][res[1]].toFixed(3);

    // Values with 3 decimals.
    x1 = x1.toFixed(3);
    x4 = x4.toFixed(3);
    y1 = y1.toFixed(3);
    y4 = y4.toFixed(3);

    // If smooth is true then draw the link with curves, otherwise draw it straight.
    if (smooth)
    {
        path = ["M", x1, y1, "C", x2, y2, x3, y3, x4, y4].join(",");
    }
    else
    {
        path = ["M", x1, y1, "L", x4, y4].join(",");
    }

    var renderArrowSource = function(arrowSvg)
    {
        var arrowPath = "M" + x1 + " " + y1 + " L" + (x1) + " " + (y1 - arrowSize) + " L" + (x1 - arrowSize) + " " + (y1 + arrowSize) + " L" + x1 + " " + y1;
        var angle;

        // Set rotation angle. 3=right, 2=left, 1=bottom, 0=top.
        if (res[0] == 3) angle = 135;
        else if (res[0] == 2) angle = 315;
        else if (res[0] == 1) angle = 225;
        else if (res[0] == 0) angle = 45;

        if (!arrowSvg)
        {
            arrowSvg = that.path(arrowPath);
        }
        else
        {
            arrowSvg.attr({path: arrowPath});
        }

        arrowSvg.attr(
        {
            "fill":stroke,
            "opacity":opacity
        }).transform("R" + angle + "," + x1 + "," + y1);

        return arrowSvg;
    }

    var renderArrowTarget = function(arrowSvg)
    {
        var arrowPath = "M" + x4 + " " + y4 + " L" + (x4) + " " + (y4 - arrowSize) + " L" + (x4 - arrowSize) + " " + (y4 + arrowSize) + " L" + x4 + " " + y4;
        var angle;

        // Set rotation angle. 7=right, 6=left, 5=bottom, 4=top.
        if (res[1] == 7) angle = 135;
        else if (res[1] == 6) angle = 315;
        else if (res[1] == 5) angle = 225;
        else if (res[1] == 4) angle = 45;

        if (!arrowSvg)
        {
            arrowSvg = that.path(arrowPath);
        }
        else
        {
            arrowSvg.attr({path: arrowPath});
        }

        arrowSvg.attr(
        {
            "fill":stroke,
            "opacity":opacity
        }).transform("R" + angle + "," + x4 + "," + y4);

        return arrowSvg;
    }

    // If the "svgLine" properties is present, then assume it's an existing link
    // and update its properties.
    if (link && link.svgLine)
    {
        // Set link style.
        link.arrowSize = arrowSize;
        link.arrowSource = arrowSource;
        link.arrowTarget = arrowTarget;
        link.opacity = opacity;
        link.smooth = smooth;
        link.stroke = stroke;
        link.width = width;

        // Set click event.
        link.onClick = onClick;

        // Update line style.
        link.svgLine.attr(
        {
            "path":path,
            "stroke":stroke,
            "stroke-width":width,
            "opacity":opacity
        });

        // Make sure the arrow source SVG is removed in case arrowSource is less than 1.
        if (arrowSource < 1 && link.svgArrowSource)
        {
            link.svgArrowSource.remove();
            link.svgArrowSource = null;
        }
        else if (arrowSource > 0)
        {
            link.svgArrowSource = renderArrowSource(link.svgArrowSource);
        }

        // Make sure the arrow target SVG is removed in case arrowTarget is less than 1.
        if (arrowTarget < 1 && link.svgArrowTarget)
        {
            link.svgArrowTarget.remove();
            link.svgArrowTarget = null;
        }
        else if (arrowTarget > 0)
        {
            link.svgArrowTarget = renderArrowTarget(link.svgArrowTarget);
        }
    }
    // If the "line" property is undefined, it means it's a new link so create the SVG path.
    else
    {
        var lineObj, arrowSourceObj, arrowTargetObj;

        // Create the line (a Raphael path).
        lineObj = this.path(path).attr(
        {
            "fill":"none",
            "stroke":stroke,
            "stroke-width":width,
            "opacity":opacity
        });

        // Create the source arrow only if arrowSource is 1 or 2.
        if (arrowSource > 0)
        {
            arrowSourceObj = renderArrowSource();
        }

        // Create the target arrow only if arrowTarget is 1 or 2.
        if (arrowTarget > 0)
        {
            arrowTargetObj = renderArrowTarget();
        }

        // Return a new anonymous line Object.
        var result = {
            svgLine:lineObj,
            svgArrowSource:arrowSourceObj,
            svgArrowTarget:arrowTargetObj,
            from:obj1,
            to:obj2,
            arrowSize:arrowSize,
            arrowSource:arrowSource,
            arrowTarget:arrowTarget,
            opacity:opacity,
            smooth:smooth,
            stroke:stroke,
            width:width,
            onClick:onClick
        };

        // Function to hide the link. If `fadeInterval` is specified, it will
        // fade out the objects instead of just hiding.
        result.hide = function (fadeInterval)
        {
            if (fadeInterval > 0)
            {
                this.svgLine.animate({opacity:0}, fadeInterval);
                if (this.svgArrowSource) this.svgArrowSource.animate({opacity:0}, fadeInterval);
                if (this.svgArrowTarget) this.svgArrowTarget.animate({opacity:0}, fadeInterval);
            }
            else
            {
                this.svgLine.attr({opacity:0});
                if (this.svgArrowSource) this.svgArrowSource.attr({opacity:0});
                if (this.svgArrowTarget) this.svgArrowTarget.attr({opacity:0});
            }
        };

        // Function to set the link opacity to 0.04 (almost hidden). If fadeInterval is specified, it will
        // fade out the objects instead of just hiding.
        result.semiHide = function (fadeInterval)
        {
            var semiOpacity = 0.04;

            if (fadeInterval > 0)
            {
                this.svgLine.animate({opacity:semiOpacity}, fadeInterval);
                if (this.svgArrowSource) this.svgArrowSource.animate({opacity:semiOpacity}, fadeInterval);
                if (this.svgArrowTarget) this.svgArrowTarget.animate({opacity:semiOpacity}, fadeInterval);
            }
            else
            {
                this.svgLine.attr({opacity:semiOpacity});
                if (this.svgArrowSource) this.svgArrowSource.attr({opacity:semiOpacity});
                if (this.svgArrowTarget) this.svgArrowTarget.attr({opacity:semiOpacity});
            }
        };

        // Function to show the link. If `fadeInterval` is specified, it will
        // fade in the objects instead of just showing.
        result.show = function (fadeInterval)
        {
            var that = this;

            if (fadeInterval > 0)
            {
                this.svgLine.animate({opacity:that.opacity}, fadeInterval);
                if (this.svgArrowSource) this.svgArrowSource.animate({opacity:that.opacity}, fadeInterval);
                if (this.svgArrowTarget) this.svgArrowTarget.animate({opacity:that.opacity}, fadeInterval);
            }
            else
            {
                this.svgLine.attr({opacity:that.opacity});
                if (this.svgArrowSource) this.svgArrowSource.attr({opacity:that.opacity});
                if (this.svgArrowTarget) this.svgArrowTarget.attr({opacity:that.opacity});
            }
        };

        // Function to send the link and its label to the BACK of the map.
        result.toBack = function ()
        {
            if (this.svgArrowTarget) this.svgArrowTarget.toBack();
            if (this.svgArrowSource) this.svgArrowSource.toBack();
            this.svgLine.toBack();
        };

        // Function to send the link and its label to the FRONT of the map.
        result.toFront = function ()
        {
            this.svgLine.toFront();
            if (this.svgArrowSource) this.svgArrowSource.toFront();
            if (this.svgArrowTarget) this.svgArrowTarget.toFront();
        };

        // Function to remove and destroy the link.
        result.remove = function ()
        {
            if (this.svgLine) this.svgLine.remove();
            if (this.svgArrowSource) this.svgArrowSource.remove();
            if (this.svgArrowTarget) this.svgArrowTarget.remove();

            delete this["svgLine"];
            delete this["from"];
            delete this["to"];
            delete this["arrowSize"];
            delete this["arrowSource"];
            delete this["arrowTarget"];
            delete this["opacity"];
            delete this["smooth"];
            delete this["stroke"];
            delete this["width"];
            delete this["onClick"];
        };

        // Set the line click event handler.
        result.lineClick = function (e)
        {
            var obj = this.data("linkResult");

            if (obj.onClick)
            {
                obj.onClick(e, obj);
            }
        };

        // Set the line path click if "onClick" is specified. Please note that the bound
        // event is actually "mousedown", not click.
        if (onClick)
        {
            lineObj.mousedown(result.lineClick);
        }

        // Set the "linkResult" data on the line and label, so they can be accessed later.
        lineObj.data("linkResult", result);

        // Return itself.
        return result;
    }
};