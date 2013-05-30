$(document).ready(function()
{
    var $window = $(window),
        $body = $("body");
        $wrapper = $("#wrapper"),
        $toFullDemo = $("#tofulldemo"),
        $demoFrame = $("#demoframe"),
        $header = $("#header"),
        $miniHeader = $("#miniheader"),
        $miniHeaderLinks = $miniHeader.find("a"),
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
    var headerHeight = $header.outerHeight(),
        miniHeaderVisible = false,
        linkTopPos = $("a[name='top']").offset().top,
        linkInstallingPos = $("a[name='installing']").offset().top,
        linkConfiguringPos = $("a[name='configuring']").offset().top,
        linkRunningPos = $("a[name='running']").offset().top,
        linkHelpPos = $("a[name='help']").offset().top,
        currentHeaderHref = $($miniHeaderLinks[0]);

    // Scroll handler to show the mini header.
    $window.scroll(function(e) {
        var sTop = window.pageYOffset || document.documentElement.scrollTop;

        if (sTop > headerHeight && !miniHeaderVisible) {
            $miniHeader.fadeIn();
            miniHeaderVisible = true;
        } else if (sTop <= headerHeight && miniHeaderVisible) {
            $miniHeader.fadeOut();
            miniHeaderVisible = false;
        }

        sTop = sTop + 380;

        if (miniHeaderVisible) {
            var newTopLink;

            if (sTop >= linkHelpPos) {
                newTopLink = $($miniHeaderLinks[4]);
            } else if (sTop >= linkRunningPos) {
                newTopLink = $($miniHeaderLinks[3]);
            } else if (sTop >= linkConfiguringPos) {
                newTopLink = $($miniHeaderLinks[2]);
            } else if (sTop >= linkInstallingPos) {
                newTopLink = $($miniHeaderLinks[1]);
            } else if (sTop >= linkTopPos) {
                newTopLink = $($miniHeaderLinks[0]);
            }

            if (!newTopLink.hasClass("active")) {
                currentHeaderHref.removeClass("active");
                newTopLink.addClass("active");

                currentHeaderHref = newTopLink;
            }
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