# System App - Readme

System monitoring and infrastructure mapping app by Zalando. Please note that the app is still in BETA
so some features are not yet implemented, although it's quite usable in its current state.
We recommend using Google Chrome but FireFox should work fine as well.

There's a functional demo running on AppFog: <http://systemapp.rs.af.cm>
Documentation can be found under the `/docs` directory of the app.

As the app is being developed on a daily basis, we recommend you to keep an eye on commits and
especially the CHANGELOG file. The final 1.0.0 version will be available by summer 2013.

#### What's still not ready for prime time?

- The `settings.coffee` file will be created automatically but only after the app has
  started for the first time. We'll change this once we have the UI to manage these settings,
  so when app is started for the first time a page with the settings manager will open
  allowing the user to create its own customized settings.
- User authentication. We're implementing basic HTTP authentication first, and LDAP will follow
  as soon as we get the basic stuff done.
- Performance improvements on complex maps. SVG is slow, so we'll tweak our implementation to
  minimze DOM queries and whenever possible use hardware accelerated features on rendering.
- Editing and moving multiple shapes simultaneously on a map by selecting them holding Ctrl.
- Better and smarter auto completion when editing shape labels.
- Auto completion when editing Audit Event rules (just like on shape labels).
- Undo and redo of actions especially when editing maps.
- Better and more stable sync of data using Socket.IO instead of AJAX calls.
- Support for multiple users editing a map at the same time, or at least map locking when there's
  someone editing it already.
- External API with HTTP webhooks.
- Self-healing features - app will self diagnose in case too many errors are triggered.

## Installation

Felling lazy? Simply run the `./install.sh` script and it will try to do all the hard work for you.
It should work on Linux and OS X environments.

1.  Download the `./install.sh` and save it on the directory where you want to install the *System App*.
    <http://github.com/zalando/system/raw/master/install.sh>

2.  Make it executable.
    `$ chmod +x install.sh`

3.  Run it and hope for the best :-)
    `$ ./install.sh`

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

If you want to keep the documentation up-to-date, you'll need Docco:
<http://jashkenas.github.io/docco/>

### Required Node.js modules

Check the `package.json` file for details on dependencies.

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

All basic server configuration settings are located on the file `server/settings.coffee`.
If you want to override settings, please edit the `settings.json` file, or create one if
it doesn't exist. Detailed instructions are available on on the top of
the `server/settings.coffee` file.

The following settings might need your attention:

##### Settings.General
`appTitle` - The app title, default is Zalando System. You can use something like "MyCompany System".
`debug` - This should be set to false before you deploy the app to production!

##### Settings.Database
`connString` - The MongoDB connection string, including user and password (if any).

##### Settings.Paths
The default paths should not be touched UNLESS you have very specific restrictions on your environment.
Edit these values in case you need to save or fetch data from different folders,
for example saving the app logs on a global `/etc/logs` location.

##### Settings.Web
`defaultPort` - The port used by the Node.js server. The default 3003 should work fine if you have no firewall rules.

##### Deploying to PaaS
The *System App* can be easily deployed to AppFog, OpenShift and other providers. The only requirement is
that you set `Settings.Web.paas` to true (it is true by default). In this case we'll override a few
settings to cope with the PaaS environment. For example:
- the web `port` will be automatically set so it doesn't matter what value you have entered.
- if your app on AppFog has a MongoDB bound to it, the `connString` will be automatically set.
- it will use Logentries for logging if you have it enabled on your AppFog app account.

At the moment the `paas` setting supports AppFog and OpenShift only!

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

## Need help?

Check the readme again! And then if you REALLY still need help please get in touch with Igor: igor.ramadas@zalando.de

*Have fun!*

To update the app docs, run the `updatedocs.sh` file.