$(document).ready(function()
{
    var $window = $(window),
        $body = $("body");
        $wrapper = $("#wrapper");

    // Make sure if fits on smaller screens.
    if ($window.innerWidth() < $body.innerWidth() - 1)
    {
        $body.css("zoom", 0.75);
    }

    $("#demoframe-overlay").click(function(){ window.open("http://systemapp.io/demo/index.html", "SystemApp"); });
});

// Helper to "pulsate" an element.
function elementPulsate(el) {
    el.fadeIn(250, function() {
        el.fadeOut(50, function() {
            el.fadeIn(50, function() {
                el.fadeOut(50, function() {
                    el.fadeIn(100, function() {
                        el.fadeOut(4500);
                    });
                });
            });
        });
    });
}
// 1036 x 664
// Load top menu.
function loadTopMenu() {
    var callback = function() {
        var filename = location.pathname;

        if (!filename || filename === "") {
            filename = "index";
        }

        while (filename.indexOf("/") >= 0) {
            filename = filename.substring(filename.indexOf("/") + 1);
        }

        $("#topmenu").find("." + filename.replace(".html", "")).addClass("active");
    };

    $("#topmenu-wrapper").load("topmenu.html", callback);

}

// Load footer.
function loadFooter() {
    $("#footer-wrapper").load("footer.html");
}