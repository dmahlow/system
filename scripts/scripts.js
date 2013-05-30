$(document).ready(function()
{
    var $window = $(window),
        $body = $("body");
        $wrapper = $("#wrapper"),
        $toFullDemo = $("#tofulldemo"),
        $demoFrame = $("#demoframe"),
        $header = $("#header"),
        $miniHeader = $("#miniheader"),
        originalX = $demoFrame.css("left"),
        originalY = $demoFrame.css("top"),
        originalW = $demoFrame.css("width"),
        originalH = $demoFrame.css("height"),
        originalP = $demoFrame.css("padding-left");

    // Make sure if fits on smaller screens.
    if ($window.innerWidth() < $body.innerWidth() - 1)
    {
        $body.css("zoom", 0.75);
    }

    // Mini header variables.
    var headerHeight = $header.outerHeight();
    var miniHeaderVisible = false;

    // Scroll handler to show the mini header.
    $window.scroll(function(e) {
        var stop = window.pageYOffset || document.documentElement.scrollTop;

        if (stop > headerHeight && !miniHeaderVisible) {
            $miniHeader.fadeIn();
            miniHeaderVisible = true;
        } else if (stop <= headerHeight && miniHeaderVisible) {
            $miniHeader.fadeOut();
            miniHeaderVisible = false;
        }

    });

    // Attach full demo click handler.
    $toFullDemo.attr("href", "#demo");
    $toFullDemo.click(function(e)
    {
        var options;

        if ($body.hasClass("fulldemo"))
        {
            $body.removeClass("fulldemo");
            $toFullDemo.html("expand Sample System Map");
            options = {left: originalX, top: originalY, width: originalW, height: originalH, padding: originalP};
        }
        else
        {
            $body.addClass("fulldemo");
            $toFullDemo.html("collapse Sample System Map");
            options = {left: 0, top: 0, width: $window.innerWidth(), height: $window.innerHeight(), padding: 0};
        }

        $demoFrame.animate(options, 300);
    });
});