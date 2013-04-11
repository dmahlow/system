// SETTINGS: START! Edit the properties below...
// ---------------------------------------------------------------

// Default size and start position of each shape (both horizontal and vertical).
var sizeX = 4;
var sizeY = 4;
var startX = 1;
var startY = 2;

// Default spacing between shapes.
var spacingX = 1;
var spacingY = 2;

// How many http segments, and columns per segment.
var httpSegmentCount = 3;

// How many columns for each type of segment.
var httpCols = 3;
var solrCols = 6;
var fesnCols = 3;
var stsnCols = 3;

// Livecycle status values.
var enabledStatusName = "lifecycle_status_id";
var enabledStatusValue = 6000;

// SETTINGS: END! Do not change anything below!
// ---------------------------------------------------------------

// GENERAL VARIABLES AND DATA GATHERING
// ---------------------------------------------------------------

// Iterators and general variables.
var s, h, x, y, c,
    props, hostname, sColor, arrColor,
    textLeft, textRight, textTop, textBottom, textTitle, textAll, auditEventIds,
    hosts, segment, segmentSizeX, segmentSizeY;

// Get current map and reset its state.
var map = api.Map.current();
map.silent(true);
map.links(new System.LinkCollection());
map.shapes(new System.ShapeCollection());

// Get the "Host" entity definition.
var hostsEntity = api.Entity.get("Host")[0];

// Helper function to create a group of hosts with the specified settings.
var createSegment = function(title, hosts, cols, color, segX, segY, labels, events) {
    segmentSizeX = cols * (sizeX + spacingX) + spacingX;
    segmentSizeY = Math.ceil(hosts.length / cols);
    segmentSizeY = segmentSizeY * (sizeY + spacingY) + 1;

    // Set background color based on shape colors.
    arrColor = new Array();
    arrColor.push(Math.round(parseInt(color.substring(1, 3), 16) / 5));
    arrColor.push(Math.round(parseInt(color.substring(3, 5), 16) / 5));
    arrColor.push(Math.round(parseInt(color.substring(5, 7), 16) / 5));

    // Create segment shape.
    segment = api.Map.createShape({textTitle: title, titleForeground: color,
        background: "#" + arrColor.join(""),
        zIndex: 2,
        opacity: 0.5,
        fontSize: 14,
        sizeX: segmentSizeX,
        sizeY: segmentSizeY,
        x: segX,
        y: segY});

    // Set starting position for hosts.
    x = segX + spacingX;
    y = segY + spacingY;

    // Reset column to 1.
    c = 1;

    for (h = 0; h < hosts.length; h++) {

        hostname = hosts[h].attributes.hostname;

        // Set labels to request/sec.
        if (labels.left) textLeft = labels.left.replace("%hostname", hostname);
        else textLeft = "";
        if (labels.right) textRight = labels.right.replace("%hostname", hostname);
        else textRight = "";
        if (labels.top) textTop = labels.top.replace("%hostname", hostname);
        else textTop = "";
        if (labels.bottom) textBottom = labels.bottom.replace("%hostname", hostname);
        else textBottom = "";

        // Set shape properties.
        props = {entityDefinitionId: "Host", entityObjectId: hosts[h].id,
            sizeX: sizeX,
            sizeY: sizeY,
            x: x,
            y: y,
            fontSize: 11,
            textTitle: hostname,
            textLeft: textLeft,
            textRight: textRight,
            textTop: textTop,
            textBottom: textBottom,
            stroke: color};

        // Bind audit events, if any.
        if (events) props.auditEventIds = events;

        // Add a new shape representing the host to the map.
        api.Map.createShape(props);

        // Update column and x.
        c += 1;
        x += sizeX + spacingX;

        // Limit columns per segment. If reached the max columns
        // per segment, increase the y and reset x to startX.
        if (c > cols) {
            c = 1;
            x = segX + spacingX;
            y += sizeY + spacingY;
        }
    }

    return segment;
};

segmentSizeX = httpCols * (sizeX + spacingX) + spacingX;

// CREATE HTTP HOSTS
// ---------------------------------------------------------------

// Create http segments cache.
var httpSegments = new Array();

// Get O2 http hosts.
var httpO2Filter = function(obj)
{ return obj.get("hostname").indexOf("http") == 0 && obj.get(enabledStatusName) == enabledStatusValue; };
var httpO2Hosts = api.Entity.getObjects(hostsEntity, httpO2Filter);

// Get ITR http hosts.
var httpItrFilter = function(obj)
{ return obj.get("hostname").indexOf("itr-http") == 0 && obj.get(enabledStatusName) == enabledStatusValue; };
var httpItrHosts = api.Entity.getObjects(hostsEntity, httpItrFilter);

// Set the default http segment settings.
textAll = {
    top: "#var.SumLabels12(%hostname)",
    left: "#audit.ReqMonitor.%hostname_requests[0]",
    right: "#audit.ReqMonitor.%hostname_requests[1]"};

auditEventIds = new Array();
auditEventIds.push("506edf87f035b61e7860fae6");

// Create O2 http segments.
for (s = 0; s < httpSegmentCount; s++) {
    hosts = new Array();
    for (h = s; h < httpO2Hosts.length; h += httpCols) { hosts.push(httpO2Hosts[h]); }
    sColor = "#3" + (s * 3) + "99FF";
    x = startX + (segmentSizeX + spacingX) * s;
    httpSegments.push(createSegment("O2 HTTP " + (s + 1) + " - #var.RequestsPerSegmentPerSec(" + s + ")", hosts, httpCols, sColor, x, startY, textAll, auditEventIds));
}

// Create ITR http segments.
for (s = 0; s < httpSegmentCount; s++) {
    hosts = new Array();
    for (h = s; h < httpItrHosts.length; h += httpCols) { hosts.push(httpItrHosts[h]); }
    sColor = "#5" + (s * 3) + "BBFF";
    x = startX + (segmentSizeX + spacingX) * s + spacingX;
    x += httpSegmentCount * (segmentSizeX + spacingX);
    httpSegments.push(createSegment("ITR HTTP " + (s + 1) + " - #var.RequestsPerSegmentPerSec(" + s + ")", hosts, httpCols, sColor, x, startY, textAll, auditEventIds));
}

// CREATE SOLR HOSTS
// ---------------------------------------------------------------

// Create http segments cache.
var solrSegments = new Array();

// Get O2 solr hosts.
var solrO2Filter = function(obj)
{ return obj.get("hostname").indexOf("solr") == 0 && obj.get("host_role_id") == "29" && obj.get(enabledStatusName) == enabledStatusValue; };
var solrO2Hosts = api.Entity.getObjects(hostsEntity, solrO2Filter);

// Get ITR solr hosts.
var solrItrFilter = function(obj)
{ return obj.get("hostname").indexOf("itr-solr") == 0 && obj.get("host_role_id") == "29" && obj.get(enabledStatusName) == enabledStatusValue; };
var solrItrHosts = api.Entity.getObjects(hostsEntity, solrItrFilter);

// Set the default solr segment settings.
textAll = {
    left: "#audit.ReqMonitor.%hostname_requests[0]",
    right: "#audit.ReqMonitor.%hostname_requests[1]",
    top: "#audit.ReqMonitor.%hostname_requests[2]",
    bottom: "#audit.ReqMonitor.%hostname_requests[3]"};

// Create O2 solr segment.
hosts = new Array();
for (h = 0; h < solrO2Hosts.length; h++) { hosts.push(solrO2Hosts[h]); }
x = startX;
y = startY + httpSegments[0].attributes.sizeY + spacingY;
solrSegments.push(createSegment("O2 SOLR", hosts, solrCols, "#FF9966", x, y, textAll));

// Create ITR solr segment.
hosts = new Array();
for (h = 0; h < solrItrHosts.length; h++) { hosts.push(solrItrHosts[h]); }
x = httpSegments[3].x();
y = httpSegments[3].y() + httpSegments[3].sizeY() + spacingY;
solrSegments.push(createSegment("ITR SOLR", hosts, solrCols / 2, "#FFBB88", x, y, textAll));

// CREATE FESN HOSTS
// ---------------------------------------------------------------

// Create fesn segments cache.
var fesnSegments = new Array();

// Get O2 fesn hosts.
var fesnO2Filter = function(obj)
{ return obj.get("hostname").indexOf("fesn") == 0 && obj.get(enabledStatusName) == enabledStatusValue; };
var fesnO2Hosts = api.Entity.getObjects(hostsEntity, fesnO2Filter);

// Get ITR fesn hosts.
var fesnItrFilter = function(obj)
{ return obj.get("hostname").indexOf("itr-fesn") == 0 && obj.get(enabledStatusName) == enabledStatusValue; };
var fesnItrHosts = api.Entity.getObjects(hostsEntity, fesnItrFilter);

// Set the default fesn segment settings.
textAll = {
    left: "#audit.ReqMonitor.%hostname_requests[0]",
    right: "#audit.ReqMonitor.%hostname_requests[1]",
    top: "#audit.ReqMonitor.%hostname_requests[2]",
    bottom: "#audit.ReqMonitor.%hostname_requests[3]"};

// Create O2 fesn segment.
hosts = new Array();
for (h = 0; h < fesnO2Hosts.length; h++) { hosts.push(fesnO2Hosts[h]); }
x = solrSegments[0].x() + solrSegments[0].sizeX() + spacingX;
y = solrSegments[0].y();
fesnSegments.push(createSegment("O2 FESN", hosts, fesnCols, "#9966FF", x, y, textAll));

// Create ITR fesn segment.
hosts = new Array();
for (h = 0; h < fesnItrHosts.length; h++) { hosts.push(fesnItrHosts[h]); }
x = solrSegments[1].x() + solrSegments[1].sizeX() + spacingX;
y = solrSegments[1].y();
fesnSegments.push(createSegment("ITR FESN", hosts, fesnCols, "#BB88FF", x, y, textAll));

// CREATE STSN HOSTS
// ---------------------------------------------------------------

// Create stsn segments cache.
var stsnSegments = new Array();

// Get O2 stsn hosts.
var stsnO2Filter = function(obj)
{ return obj.get("hostname").indexOf("stsn") == 0 && obj.get(enabledStatusName) == enabledStatusValue; };
var stsnO2Hosts = api.Entity.getObjects(hostsEntity, stsnO2Filter);

// Get ITR fesn hosts.
var stsnItrFilter = function(obj)
{ return obj.get("hostname").indexOf("itr-stsn") == 0 && obj.get(enabledStatusName) == enabledStatusValue; };
var stsnItrHosts = api.Entity.getObjects(hostsEntity, stsnItrFilter);

// Set the default stsn segment settings.
textAll = {top: "#audit.ReqMonitor.%hostname_requests[0]"};

// Create O2 fesn segment.
hosts = new Array();
for (h = 0; h < stsnO2Hosts.length; h++) { hosts.push(stsnO2Hosts[h]); }
x = solrSegments[0].x() + solrSegments[0].sizeX() + spacingX;
y = fesnSegments[0].y() + fesnSegments[0].sizeY() + spacingY;
stsnSegments.push(createSegment("O2 STSN", hosts, stsnCols, "#339966", x, y, textAll));

// Create ITR fesn segment.
hosts = new Array();
for (h = 0; h < stsnItrHosts.length; h++) { hosts.push(stsnItrHosts[h]); }
x = solrSegments[1].x() + solrSegments[1].sizeX() + spacingX;
y = fesnSegments[1].y() + fesnSegments[1].sizeY() + spacingY;
stsnSegments.push(createSegment("ITR STSN", hosts, stsnCols, "#55BB88", x, y, textAll));

// CREATE CUSTOM SHAPES
// ---------------------------------------------------------------

// Create custom shapes cache.
var customShapes = new Array();

// Set custom shape size.
sizeX = 20;
sizeY = 10;
props = {sizeX: sizeX, sizeY: sizeY, fontSize: 35, strokeWidth: 5, stroke: "#333333", background: "#333333"};

// Create REQUESTS shape.
props.x = fesnSegments[0].x() + fesnSegments[0].sizeX() + spacingX * 6;
props.y = fesnSegments[0].y() + spacingY * 2;
props.textCenter = "REQUESTS";
props.textTop = "#var.HttpTotalRequestsPerSec http/s";
props.textBottom = "#var.SolrTotalRequestsPerSec solr/s";
customShapes.push(api.Map.createShape(props));

// Create ORDERS shape.
props.x = customShapes[0].x() + customShapes[0].sizeX() + spacingX * 2;
props.y = fesnSegments[0].y() + spacingY * 2;
props.textCenter = "ORDERS";
props.textTop = "#var.HttpOrderSuccessPerMin success/m";
props.textBottom = "#var.HttpOrderFailsPerMin fails/m";
customShapes.push(api.Map.createShape(props));

// Create USERS shape.
props.x = customShapes[0].x();
props.y = customShapes[0].y() + customShapes[0].sizeY() + spacingY;
props.textCenter = "USERS";
props.textTop = "#var.HttpUserRegsPerMin regs/m";
props.textBottom = "#var.HttpUserLoginsPerSec logins/s";
customShapes.push(api.Map.createShape(props));

// Create INVENTORY shape.
props.x = customShapes[1].x();
props.y = customShapes[1].y() + customShapes[1].sizeY() + spacingY;
props.textCenter = "INVENTORY";
props.textTop = "#var.ArticleUpdatesPerMin";
props.textBottom = "#var.StockUpdatesPerMin";
customShapes.push(api.Map.createShape(props));