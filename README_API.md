# System App - API Reame

The System API can be used by scripts and external resources to script maps and
interact with the System App.

PLEASE NOTE! The API is still experimental and will probably change till we reach
version 1.0.0. Any significant updates will be especifically written here
and on specific code commits.


## The API basics

All API methods are abstract wrappers for internal System collections:
Maps, Shapes, Entities, Audit Data, Audit Events and Variables.
The exception is the "view" api, which represents the app UI.

In the vast majority of cases, whilst using the API you'll be dealing with
the System's models implemented using Backbone.js.

At the moment the API is operated in synchronous mode.


## Getting data

All API wrappers have a `get` method accepting one `filter` argument, which can be:
- The ID of a single element as a string or integer.
- An object containing keys and values representing properties.
- A callback filter.

The `get` will ALWAYS return a collection of models, even when only one result is found.
If nothing was found, the result will be an empty collection. If something goes wrong,
`null` will be returned.

#### Samples: how to query data

- Return the [EntityDefinition](entityDefinition.html) with ID "Host".
`api.Entity.get("Host");`

- Return all [Shapes](shape.html) from the current map with a zIndex 3.
`api.Map.getShapes({zIndex: 3});`

- Return all [AuditData](auditData.html) models with data coming from "www.zalando.de".
```
var filter = function(obj) { return obj.get("sourceUrl").indexOf("www.zalando.de") > 0 };
api.AuditData.get(filter);
```


## Inserting and updating

All API wrappers have a `create` method accepting one `props` argument, which defines
the properties of the model to be created.

#### Samples: how to create and update models

- Create a new [Variable](variable.html) with name "CurrentDate" that returns the current date.
`api.Variable.create({name: "CurrentDate", code: "var now = new Date(); return now.getDate();"});`

- Create a new [Map](map.html) with name "Dashboard".
`api.Map.create({name: "Dashboard"});`

- Add a new [Shape](shape.html) to the current [Map](map.html) representing
  an [EntityObject](entityObject.html) and with size 6x4, around top left corner.
```
var props = {entityDefinitionId: "Host", entityObjectId: "http01", sizeX: 6, sizeY: 4, x: 2, y: 2}
api.Map.createShape(props);
```


## Sample map script

This will create a map of http hosts divided in 3 segments, having 3 columns of servers per segment.

```
// Iterators and general variables.
var s, h, x, y, c, props;

// Default size of each http shape (both horizontal and vertical).
var sizeX = 5;
var sizeY = 4;
var startX = 2;
var startY = 3;

// Spacing between shapes.
var spacingX = 1;
var spacingY = 2;

// How many columns of http hosts per segment.
var cols = 3;

// Get current map.
var map = api.Map.current();
map.links().reset();
map.shapes().reset();

// Get the "Host" entity definition.
var hostsEntity = api.Entity.get("Host")[0];

// Get all http hosts.
var httpFilter = function(obj) { return obj.get("hostname").indexOf("http") >= 0; };
var httpHosts = api.Entity.getObjects(hostsEntity, httpFilter);

// Get all solr hosts.
var solrFilter = function(obj) { return obj.get("hostname").indexOf("solr") >= 0; };
var solrHosts = api.Entity.getObjects(hostsEntity, solrFilter);

// Set the default segment size.
var segmentSizeX = sizeX * cols + spacingX;
var segmentSizeY = 20;

// Create custom shapes which represents "server segments".
var segment1 = api.Map.createShape({labelTitle: "Segment 1", zIndex: 2, sizeX: segmentSizeX, sizeY: segmentSizeY, x: 1, y: 1});
var segment2 = api.Map.createShape({labelTitle: "Segment 2", zIndex: 2, sizeX: segmentSizeX, sizeY: segmentSizeY, x: segmentSizeX + spacingX * 2, y: 1});
var segment3 = api.Map.createShape({labelTitle: "Segment 3", zIndex: 2, sizeX: segmentSizeX, sizeY: segmentSizeY, x: segmentSizeX * 2 + spacingX * 3, y: 1});
var arrSegments = [segment1, segment2, segment3];

// Add the http hosts to the map inside the segments. We're assuming here
// that the servers are already sorted on the JSON.
for (s = 0; s < arrSegments.length; s++) {

    x = startX + s * (segmentSizeX + spacingX);
    y = startY;

    // Reset column to 1.
    c = 1;

    for (h = s; h < httpHosts.length; h += 3) {

        // Set shape properties.
        props = {entityDefinitionId: "Host", entityObjectId: httpHosts[h].id, sizeX: sizeX, sizeY: sizeY, x: x, y: y, textTitle: h, textCenter: s, textLeft: x, textRight: y}

        // Add a new shape representing the host to the map.
        api.Map.createShape(props);

        // Update column and x.
        c += 1;
        x += sizeX + spacingX;

        // Limit columns per segment. If reached the max columns
        // per segment, increase the y and reset x to startX.
        if (c > cols) {
            c = 1;
            x = startX + s * (segmentSizeX + spacingX);
            y += sizeY + spacingY;
        }
    }
}
```