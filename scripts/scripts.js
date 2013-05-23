$(document).ready(function()
{
    var $window = $(window),
        $body = $("body");
        $toFullDemo = $("#tofulldemo"),
        $demoFrame = $("#demoframe"),
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

    // Attach full demo click handler.
    $toFullDemo.attr("href", "#demo");
    $toFullDemo.click(function(e)
    {
        var options;

        if ($body.hasClass("fulldemo"))
        {
            $body.removeClass("fulldemo");
            $toFullDemo.html("expand to full demo");
            options = {left: originalX, top: originalY, width: originalW, height: originalH, padding: originalP};
        }
        else
        {
            $body.addClass("fulldemo");
            $toFullDemo.html("minimize demo");
            options = {left: 0, top: 0, width: $window.innerWidth(), height: $window.innerHeight(), padding: 0};
        }

        $demoFrame.animate(options, 300);
    });
});