# System App - Readme

System monitoring and infrastructure mapping app by Zalando.

### The master tips

- This app depends on Node.js and MongoDB. The default port is set to 3003, make sure firewall is properly set.
- ALL client side settings (database conn string, ports, etc) are located on `/assets/js/settings.coffee`.
- ALL server side settings (timers, colors, prefixes, etc) are located on `/server/settings.coffee`.
- You MUST be familiar with CoffeeScript, Backbone.js, jQuery and Raphaël to fully understand the app.
- If something goes really weird with the UI, refreshing the page (refresh button or F5) will solve most problems.

## Installation

Felling lazy? Simply run the `./install.sh` script and it will try to do all the hard work for you.
It should work on Linux and OS X environments.

1.  Download the `./install.sh` and save it on the directory where you want to install the *System App*.
    <http://github.com/zalando/system/raw/master/install.sh>

2.  Make it executable.
    `$ chmod +x install.sh`

3.  Run it as root and hope for the best :-)
    `$ sudo ./install.sh`

The script should tell you what's missing and ask if you want to install the missing dependencies.
As easy as just choosing "Yes" for everything.

### Installing manually

If the install script doesn't work or if you prefer to do stuff manually, please make sure
you have installed on your system.

- Node.js (http://nodejs.org)
- MongoDB (http://mongodb.org)
- ImageMagick (http://www.imagemagick.org)

To install Node.js on Linux, please check:
<http://github.com/joyent/node/wiki/Installing-Node.js-via-package-manager>

MongoDB can be downloaded from:
<http://www.mongodb.org/downloads>

ImageMagick is necessary to generate map thumbnails. The app will actually run without it,
but then you won't have a "preview" of each map on the start screen.
To download ImageMagick go to:
<http://www.imagemagick.org/script/binary-releases.php>

If you want to keep the documentation up-to-date, you'll need Zocco:
<http://github.com/zalando/zocco>

### Required Node.js modules

The following Node.js modules are required by the *System App*.

- async
- coffee-script
- connect-assets
- express
- imagemagick
- jade
- mongoskin
- socket.io
- stylus
- winston

The easiest way to get these is by running NPM install:

`$ npm install`

But in case you want to install any of these modules globally, use:

`$ npm install -g module_name`

It's up to you to decide what should be installed globally and what should be local.
Any combination should work fine. We prefer going local.

### Avoiding MongoDB installation

If you don't want to install and configure MongoDB locally, we suggest creating a free online
database at MongoLab (http://mongolab.com). The connection string will be something like:

`mongodb://your_user:your_password@ds033187.mongolab.com:33187/your_database?auto_reconnect`

## Configuring the server

All server configuration settings are located on the file `server/settings.coffee`.
The following `System.Settings` keys will certainly need your attention:

##### Settings.General
Change the `appTitle` and set your desired title. Something like "MyCompany System".
Make sure the `debug` is set to false before you deploy the app to production!

##### Settings.Database.connString
The MongoDB connection string. If you have MongoDB installed locally with no user and password,
the default should work fine.

##### Settings.Paths (all)
The default paths should work unless you have very specific restrictions on your environment.
Edit these values in case you need to save or fetch data from different folders,
for example saving the app logs on a global "/logs" location.

##### Settings.Web.defaultPort
Port used by Node.js. The default 3003 should work fine if you have no firewall rules.

## Starting the server

To start the *System App*:

`$ coffee server.coffee`

This will start Node.js under the port 3003 (or whatever port you have set on `Settings.Web.defaultPort`).
In case you don't have installed the module *coffee-script* globally, you'll have to run it from within the
node_modules directory, like this:

`$ ./node_modules/coffee-script/bin/coffee server.coffee`

If it throws an error or if you can't access the app on the browser then you might have something wrong
on your `server/settings.coffee` file, or a firewall issue.

### Production vs. Debugging

By default Node.js will run in "Debug mode". If you're deploying and running on production,
you must set the `NODE_ENV` to "production" to avoid having all the debugging statements
logged to the console. Putting it simple:

`$ NODE_ENV=production coffee server.coffee`

Please note that the *System App* will enter debug mode automatically when it runs under
the `localhost` hostname. In debug mode, most actions and procedures will be logged to the
console, both on the server and the client side.

### Running the server "forever"

If you want the server to run like a service (so it restarts itself in case of crash / error / termination)
we recommend using the node module *forever*. You can install it using NPM globally like this:

`$ sudo npm install -g forever`

To start *System* using *forever*, run it under the app root folder:

`$ forever start -c coffee server.coffee`

## Code implementation

To make things easier to understand:

* All customizable settings are available on the *System.Settings* object, at the `/assets/js/settings.coffee` file.
* Non-HTML messages are set under the *System.Messages* object, file `/assets/js/messagess.coffee`.
* URL routes are set under a *System.Routes* object, file `/assets/js/routes.coffee`.

*System* uses the latest version of [Backbone](http://http://backbonejs.org/) to implement models, collections and views.
The maps are implemented using SVG and handled mainly by [Raphaël](http://raphaeljs.com/). Other required libraries are
[jQuery](http://jquery.com/), [Underscore](http://underscorejs.org/), [JSONPath](http://goessner.net/articles/JsonPath/).

Having experience with the aforementioned libraries is not strictly necessary, but highly desirable in
case you want to customize the *System App*.

### Models and collections

Models won't inherit directly from Backbone.Model. Instead we're using our own [System.BaseModel](base.html),
which extends Backbone's model with special methods like `save`, `generateId`, etc. Same thing
for collections, which should inherit from [System.BaseCollection](base.html).

All models are located under the folder `/assets/js/models`, and each model has its own specific collection
implemented at the end of the same file.

### Views

The views are composed of:

* HTML template using [Jade](http://jade-lang.com/), folder `/views`.
* CSS styles using [Stylus](http://learnboost.github.com/stylus/), folder `/assets/css`.
* View controllers implemented with CoffeeScript, folder `/assets/js/view`.

Just like models and collections, the app has its own [System.BaseView](baseView.html)
which extends Backbone's view with extra helpers and utilities.

### Database

*System* uses MongoDB to store its data, having the following collections:

* *map* - stores all maps (Map model) including their referenced shapes and links.
* *entity* - store entity schemas (EntityDefinition model) and data (EntityObject model).
* *auditdata* - store all audit data definitions and data (AuditData model).
* *auditevent* - store all audit events and alerts (AuditEvent model).
* *variable* - stores custom JS variables (Variable model) created by users.
* *log* - logs all updates, inserts and deletes on the collections above.

The "log" collection is implemented for increased security and damage control. All updates, inserts
and deletions are logged there, and these records stay saved for 2 hours by default - you can
change this setting on the [Server Settings](server/settings.html) file. As the logs
are stored in a separate collection and saved in async mode, performance stays roughly the same.

### Diagrams

And now some imagery to better understand everything we have said above :-)

#### Framework
![Entities](diagrams/System_Framework.png)

#### Entities and objects
![Entities](diagrams/System_Entities.png)

#### Views
![Entities](diagrams/System_Views.png)

## Common questions and answers

#### Which browsers are supported?
Due to its pure-and-sleek-javascript-web-app nature, we recommend *Google Chrome* and in fact this is
the only browser that we use while developing and testing *System*. But as the app follows all major
web standards (HTML5, CSS3, SVG etc...), FireFox and Opera *should* work fine as well. If you want
to use IE, well... good luck with that.

#### Missing shapes to the map, shadows on incorrect placements, links not being saved... something's wrong!
The quick-and-dirty answer is: reload the page. The long answer: *System* depends on third-party
libraries and getting these libraries to work in sync together proved to be more challenging than
expected. We are working *hard* to pinpoint all these failures and get rid of them with our own
patches. But till we get there, if something weird happens refreshing the page will likely solve the problem.

#### Sometimes there's an asterisk * next to the shapes title. Why?
When you change the "Shape's title" dropdown (on the right bar > Map View), it will bind the selected
value to the all shape titles. But sometimes the shape might not have that specific property,
so in this case the default property will get bound and that asterisk will be shown.

## Need help?

Check the readme again! And then if you REALLY still need help please get in touch with Igor: igor.ramadas@zalando.de

*Have fun!*

*Documentation generated generated with [Zocco](http://zalando.github.com/zocco/)!*
```
zocco -o public/docs `find . \( -name "*.coffee" ! -path "*node_modules*" \)`
```