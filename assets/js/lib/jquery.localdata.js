// jQuery plugin to handle local data using local storage or DOM data,
// depending on the browser
// --------------------------------------------------------------------------

(function ($)
{
    // check for jQuery
    if (!$ || !($.toJSON || Object.toJSON || window.JSON))
    {
        throw new Error("jQuery MUST be loaded BEFORE this plugin!!!");
    }

    // VARIABLES
    // ----------------------------------------------------------------------

    var
        _backend = false,
        _ttl_timeout = 0,
        _storage = {},
        _storage_elm = null,
        _storage_size = 0,
        _storage_service = {
            localData:"{}"
        };

    // XML HELPER
    // ----------------------------------------------------------------------

    var xmlService = {

        // check if element is XML
        isXML:function (elm)
        {
            var documentElement = (elm ? elm.ownerDocument || elm : 0).documentElement;
            return documentElement ? documentElement.nodeName !== "HTML" : false;
        },

        // encode a xml node
        encode:function (xmlNode)
        {
            if (!this.isXML(xmlNode))
            {
                return false;
            }
            try
            {
                return new XMLSerializer().serializeToString(xmlNode);
            }
            catch (e1)
            {
                try
                {
                    return xmlNode.xml;
                }
                catch (e2)
                {
                }
            }

            return false;
        },

        // decodes a xml node
        decode:function (xmlString)
        {
            var resultXML;
            var dom_parser = ("DOMParser" in window && (new DOMParser()).parseFromString) ||

                (window.ActiveXObject && function (_xmlString)
                {
                    var xml_doc = new ActiveXObject("Microsoft.XMLDOM");
                    xml_doc.async = "false";
                    xml_doc.loadXML(_xmlString);

                    return xml_doc;
                });

            if (!dom_parser)
            {
                return false;
            }

            resultXML = dom_parser.call("DOMParser" in window && (new DOMParser()) || window, xmlString, "text/xml");

            return this.isXML(resultXML) ? resultXML : false;
        }
    };

    // encode and decode json
    var encodeJson = $.toJSON || Object.toJSON || (window.JSON && (JSON.encode || JSON.stringify));
    var decodeJson = $.evalJSON || (window.JSON && (JSON.decode || JSON.parse)) || function (str)
    {
        return String(str).evalJSON();
    };


    // PRIVATE METHODS!!!
    // ----------------------------------------------------------------------

    function _init()
    {

        var haveLocalStorage = false;

        if ("localStorage" in window)
        {
            try
            {
                window.localStorage.setItem("__test__", "__value__");
                haveLocalStorage = true;
                window.localStorage.removeItem("__test__");
            }
            catch (e1)
            {
                // oops?
            }
        }

        if (haveLocalStorage)
        {
            try
            {
                if (window.localStorage)
                {
                    _storage_service = window.localStorage;
                    _backend = "localStorage";
                }
            }
            catch (e2)
            {
                // oops
            }
        }
        else if ("globalStorage" in window)
        {
            try
            {
                if (window.globalStorage)
                {
                    _storage_service = window.globalStorage[window.location.hostname];
                    _backend = "globalStorage";
                }
            }
            catch (e3)
            {
                // oops
            }
        }
        else
        {
            _storage_elm = document.createElement("link");

            if (_storage_elm.addBehavior)
            {
                _storage_elm.style.behavior = "url(#default#userData)";
                document.getElementsByTagName("head")[0].appendChild(_storage_elm);
                _storage_elm.load("localData");

                var data = "{}";

                try
                {
                    data = _storage_elm.getAttribute("localData");
                }
                catch (e4)
                {
                    // nothing works!!! won't use local storage
                }

                _storage_service.localData = data;
                _backend = "userDataBehavior";

            }
            else
            {
                _storage_elm = null;

                return;
            }
        }

        _load_storage();
        _handleTTL();
    }

    // loads data from local storage
    function _load_storage()
    {
        if (_storage_service.localData)
        {
            try
            {
                _storage = decodeJson(String(_storage_service.localData));
            }
            catch (e5)
            {
                _storage_service.localData = "{}";
            }
        }
        else
        {
            _storage_service.localData = "{}";
        }

        _storage_size = _storage_service.localData ? String(_storage_service.localData).length : 0;
    }

    // saves data to local storage
    function _save()
    {
        try
        {
            _storage_service.localData = encodeJson(_storage);

            if (_storage_elm)
            {
                _storage_elm.setAttribute("localData", _storage_service.localData);
                _storage_elm.save("localData");
            }

            _storage_size = _storage_service.localData ? String(_storage_service.localData).length : 0;
        }
        catch (e6)
        {
            // cache is full maybe?
        }
    }

    // checks if a specific key is set
    function _checkKey(key)
    {
        if (!key || (typeof key != "string" && typeof key != "number"))
        {
            throw new TypeError("Key name must be string or numeric");
        }
        if (key == "__localData_meta")
        {
            throw new TypeError("Reserved key name");
        }

        return true;
    }

    // remove expired keys from local storage
    function _handleTTL()
    {
        var curtime, i, TTL, nextExpire = Infinity, changed = false;

        clearTimeout(_ttl_timeout);

        if (!_storage.__localData_meta || typeof _storage.__localData_meta.TTL != "object")
        {
            return;
        }

        curtime = +new Date();
        TTL = _storage.__localData_meta.TTL;

        for (i in TTL)
        {
            if (TTL.hasOwnProperty(i))
            {
                if (TTL[i] <= curtime)
                {
                    delete TTL[i];
                    delete _storage[i];

                    changed = true;
                }
                else if (TTL[i] < nextExpire)
                {
                    nextExpire = TTL[i];
                }
            }
        }

        // set next check
        if (nextExpire != Infinity)
        {
            _ttl_timeout = setTimeout(_handleTTL, nextExpire - curtime);
        }

        // save changes
        if (changed)
        {
            _save();
        }
    }

    // PUBLIC INTERFACE WITH JQUERY
    // ----------------------------------------------------------------------

    $.localData = {

        version:"1.0.0.1",

        // sets a key and value to local storage
        set:function (key, value)
        {
            _checkKey(key);

            if (xmlService.isXML(value))
            {
                value = {
                    _is_xml:true,
                    xml:xmlService.encode(value)
                };
            }
            else if (typeof value == "function")
            {
                value = null; // functions can't be saved!
            }
            else if (value && typeof value == "object")
            {
                value = decodeJson(encodeJson(value));
            }

            _storage[key] = value;
            _save();

            return value;
        },

        // get a value from local storage by its key, with optional default
        get:function (key, def)
        {
            _checkKey(key);

            if (key in _storage)
            {
                if (_storage[key] && typeof _storage[key] == "object" && _storage[key]._is_xml && _storage[key]._is_xml)
                {
                    return xmlService.decode(_storage[key].xml);
                }
                else
                {
                    return _storage[key];
                }
            }

            return typeof(def) == "undefined" ? null : def;
        },

        // deletes a key from local storage, if it exists
        del:function (key)
        {
            _checkKey(key);

            if (key in _storage)
            {
                delete _storage[key];

                if (_storage.__localData_meta && typeof _storage.__localData_meta.TTL == "object" && key in _storage.__localData_meta.TTL)
                {
                    delete _storage.__localData_meta.TTL[key];
                }
                _save();

                return true;
            }

            return false;
        },

        // sets time to live for a key, or remove it completely if value is 0 or less
        setTTL:function (key, ttl)
        {
            _checkKey(key);

            var curtime = new Date();
            ttl = Number(ttl) || 0;

            if (key in _storage)
            {
                if (!_storage.__localData_meta)
                {
                    _storage.__localData_meta = {};
                }

                if (!_storage.__localData_meta.TTL)
                {
                    _storage.__localData_meta.TTL = {};
                }

                if (ttl > 0)
                {
                    _storage.__localData_meta.TTL[key] = curtime + ttl;
                }
                else
                {
                    delete _storage.__localData_meta.TTL[key];
                }

                _save();
                _handleTTL();

                return true;
            }

            return false;
        },

        // deletes everything from the cache
        flush:function ()
        {
            _storage = {};
            _save();
            return true;
        },

        // read only copy of local storage
        storageObj:function ()
        {
            function F()
            {
            }

            F.prototype = _storage;

            return new F();
        },

        // return array of key indexes
        index:function ()
        {
            var index = [], i;

            for (i in _storage)
            {
                if (_storage.hasOwnProperty(i) && i != "__localData_meta")
                {
                    index.push(i);
                }
            }

            return index;
        },

        // current storage size
        storageSize:function ()
        {
            return _storage_size;
        },

        // current backend in use (local storage, DOM data, etc...)
        currentBackend:function ()
        {
            return _backend;
        },

        // test if local storage is available
        storageAvailable:function ()
        {
            return !!_backend;
        },

        // refresh data
        reInit:function ()
        {
            var new_storage_elm, data;

            if (_storage_elm && _storage_elm.addBehavior)
            {
                new_storage_elm = document.createElement("link");

                _storage_elm.parentNode.replaceChild(new_storage_elm, _storage_elm);
                _storage_elm = new_storage_elm;

                /* Use a DOM element to act as userData storage */
                _storage_elm.style.behavior = "url(#default#userData)";

                /* userData element needs to be inserted into the DOM! */
                document.getElementsByTagName("head")[0].appendChild(_storage_elm);

                _storage_elm.load("localData");
                data = "{}";

                try
                {
                    data = _storage_elm.getAttribute("localData");
                }
                catch (e)
                {
                    // does not work!
                }

                _storage_service.localData = data;
                _backend = "userDataBehavior";
            }

            _load_storage();
        }
    };

    // init the plugin!
    _init();

})(window.jQuery || window.$);
