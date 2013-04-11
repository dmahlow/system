// SERVER APP
// -------------------------------------------------------------------------
// This is a shim file to run the `server.coffee` in case CoffeeScript is not
// globally installed. If you have CoffeeScript installed globally (coffee command)
// please run the `server.coffee` directly.

require("coffee-script");
require("./server.coffee");