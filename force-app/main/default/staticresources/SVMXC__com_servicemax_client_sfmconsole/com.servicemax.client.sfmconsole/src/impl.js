/**
 * This file needs a description
 * @class com.servicemax.client.sfmconsole.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

    var consoleImpl = SVMX.Package("com.servicemax.client.sfmconsole.impl");
    var TS, TS_FSA;

    consoleImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {


        __constructor : function(){
            this.__base();
            this._logger = SVMX.getLoggingService().getLogger("CONSOLE-IMPL");

            // set up a static variable for global access
            consoleImpl.Module.instance = this;

            // set up the org namespace
            var ons = SVMX.getClient().getApplicationParameter("org-name-space");
            if(!ons || ons === "") ons = "SVMXC";

            SVMX.OrgNamespace = ons;
            // end set up namespace

            // Modify navigation to open in current primary tab if in service console.
            SVMX.navigateToCheckExternal = function(url, isNewRecord) {
                if (navigateTo) {
                    navigateTo(url, isNewRecord);
                }
                else {
                    SVMX.navigateTo(url);
                }
            };
			SVMX.getCustomFieldName = function (name) {
                return SVMX.OrgNamespace + "__" + name + "__c";
            };
            SVMX.getCustomObjectName = function (name) {
                return SVMX.OrgNamespace + "__" + name + "__c";
            };
            SVMX.getCustomRelationName = function (name) {
                return SVMX.OrgNamespace + "__" + name + "__r";
            };
            SVMX.getTempTableName = function (name) {
                return "TEMP__" + name;
            };
        },

        beforeInitialize : function(){
            com.servicemax.client.sfmconsole.utils.init();
            com.servicemax.client.sfmconsole.commands.init();
            com.servicemax.client.sfmconsole.expressionbridge.init();
            com.servicemax.client.sfmconsole.constants.init();
            com.servicemax.client.sfmconsole.engine.init();
        },

        initialize : function(){
            // Gets an empty dictionary so that TS is never null/undefined.
            TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("FSA");
        },

        afterInitialize : function(){
            var serv = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.preferences").getInstance();
            serv.addPreferenceKey(com.servicemax.client.sfmconsole.constants.Constants.PREF_LOGGING);
        }

    }, {

        instance : null
    });


    /**
     * The Console Application; while the class name is "Application", this is just one possible
     * instance of AbstractApplication which exists in the sfmconsole namespace.
     *
     * This application manages a set of "console applications" which are really just applets designed
     * to run within this container.
     * @class com.servicemax.client.sfmconsole.impl.Application
     * @super com.servicemax.client.lib.api.AbstractApplication
     */
    consoleImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication,{

        // Module instance
        __parent : null,
        __logger : null,
        __namedInstanceService  : null,


        // DEPRECATED; do not use these (there is still code that depends upon them though)
        // These are bad because we have no means of updating the handlers in a multi-window
        // app based on which window is currently showing.  We simply grab control and
        // don't let go until someone else grabs control.
        __stateHandlers: {
            // State Handler; Currently manages turning on/off the busy indicator/spinning icon
            applicationStateHandler : null,

            // Error Handler; Shows error messages
            applicationErrorHandler : null,

            // Message Handler; Shows messages such as alerts
            applicationMessageUIHandler : null,

            // Quick Message Handler; Shows a popup/toast message
            applicationQuickMessageHandler : null,
        },

        // Contains the configurations for each type of console app as specified in manifest.json
        // Hash indexed by Application Id.  Access this using getAppConfig method; do not access directly.
        __consoleAppConfigs : null,

        // Hash of running console apps indexed by Application Id (specified in manifest.json)
        // As there can be multiple apps of the same id, this hash may not contain ALL open console apps.
        // This is used primarily to determine if a Singleton console app of the specified Id has already been created
        // so we know whether to show it or create it.
        __runningConsoleAppsByAppId : null,

        // Hash of running console apps indexed by the Window Id (which is the Id of their Root Container).
        // Unlike __runningConsoleAppsByAppId this should always contain ALL running console apps.
        __runningConsoleAppsByWindowId : null,

        // Hash of launching console apps to prevent multiple of the same type from launching at once.
        __launchingConsoleAppsById : null,

        // The UserInfo structure used to identify the current user.  Only access this using getUserInfo().
        // TODO: Create a UserInfo class to represent this that makes all user info properties private
        __userInfo: null,


        // Whatever notifications the UI Library has provided
        __notificationService : null,

        // Stores the VIEW component which identifies which classes are used to generate
        // Key parts of our UI based on which version of the app we are running (laptop, online, phone, etc...)
        __view : null,

        __constructor : function(){
            this.__parent = consoleImpl.Module.instance;
            this.__logger = this.__parent.getLogger();
            this.__notificationService = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.notifications");


            this.__consoleAppConfigs = {};
            this.__runningConsoleAppsByAppId = {};
            this.__runningConsoleAppsByWindowId = {};
            this.__launchingConsoleAppsById = {};
        },

        triggerEvent : function(e) {
            SVMX.getLoggingService().getLogger("SFMConsoleApplication").warn("SFMConsole event triggered: " + e.type);
            return this.__base(e);
        },

        beforeRun : function(options){
            // create the named default controller
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();

            // create the named default controller
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){
                // now create the named default model
                ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
                    controller.setModel(model);
                     ni.createNamedInstanceAsync("SFMCONSOLE.VIEW",{ handler : function(view){
                         this.__view = view;
                         options.handler.call(options.context);
                     }, context: this, additionalParams: {}});
                }, context : this});
            }, context : this, additionalParams : { eventBus : this }});
        },

        run : function(){
            this.__logger.info("Caching is => " + SVMX.isCachingEnabled());

            this.__loadTags(SVMX.proxy(this, function() {
                this.__runConsole();
            }));
        },

        __runConsole : function () {
            var me=this;
            me.getAppInfo().then(function(appInfo){
                me.__addDeviceInfo()
                    .then(SVMX.proxy(me, function(data) {
                        me.__runSync();
                    }));
            });

        },
        getAppInfo:function(){
            var deferred = SVMX.Deferred();
            var ec = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection", this, [
                SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFMCONSOLE.GET_APP_INFO", this, {
                        request: {}
                    }
                )
            ]);
            ec.triggerAll(function(evtCol) {
                var info = evtCol.items()[0].response;
                //Set it as the Application Parameter . so that it is passed in all the Syncs Properly.
                var appVersion=(info.version ||"");
                SVMX.getClient().addApplicationParameter("app-version",  appVersion);
                SVMX.getClient()['ClientVersion']=appVersion;
                deferred.resolve(info);
            });
            return deferred.promise();
        },
        //Get the device info from native layer, instaed of config file.
        //Because going farword, one config file would be used for all client app.
        __addDeviceInfo : function() {
            var d = SVMX.Deferred();
            var nativeService = com.servicemax.client.offline.sal.model.nativeservice.Facade;
            var nativeReq = nativeService.createDeviceInfoRequest();

            nativeReq.bind("REQUEST_COMPLETED", function(evt){
                SVMX.getClient().addApplicationParameter("device-info", evt.data.data || {});
                if(SVMX.getClient().getApplicationParameter("device-info")
                        && SVMX.getClient().getApplicationParameter("device-info")["client-type"]) {
                    var clientType = SVMX.getClient().getApplicationParameter("device-info")["client-type"];
                    SVMX.getClient().addApplicationParameter("client-type", clientType);

                    // Short cut method for check whether client type is laptop.
                    SVMX.getClient().isLaptop = function() {
                        return SVMX.getClient().getApplicationParameter("client-type").toLowerCase() == "laptop";
                    };

                    var clientDetails = SVMX.getClient().getApplicationParameter("device-info")["details"];
                    var clientUuid;
                    if(!SVMX.getClient().isLaptop()) {
                        if (typeof clientDetails !== 'string') {
                            clientUuid = clientDetails.uuid;
                        }
                    } else {
                        var clientDetailInfo = JSON.parse(clientDetails);
                        for(var i = 0; i < clientDetailInfo.length; i++){
                            if(clientDetailInfo[i].Key === "BiosSerialNumber") {
                                clientUuid = clientDetailInfo[i].Value;
                                break;
                            }
                        }
                    }
                    SVMX.getClient().addApplicationParameter("client-uuid", clientUuid);

                    // Now lets use that new function and change our webview behaviour a bit.
                    // We need this be cause we use Google API for our maps which has a link to google
                    // in the lower left corner, if a user clicks it we do not want to to load over our app
                    // but in a new browser window.
                    if (!SVMX.getClient().isLaptop()) {
                        $(document).on('click', 'a[href^="http"]', function (e) {
                            var url = $(this).attr('href');
                            window.open(url, '_system');
                            e.preventDefault();
                        });
                    }

                    SVMX.getClient().isBarCodeEnabled = function(){
                        var isBarcodeEnabled = false;
                        var deviceInfo = SVMX.getClient().getApplicationParameter("device-info");
                        if(deviceInfo && deviceInfo["barcode-enabled"]){
                            isBarcodeEnabled = true;
                        }
                        return isBarcodeEnabled;
                    };
                }
                d.resolve({});
            }, this);

            nativeReq.bind("REQUEST_ERROR", function(evt){
                d.resolve({});
            }, this);

            nativeReq.execute({
                method : "DEVICEINFO",
                type: "MISC"
            });
            return d;
        },

        __runSync : function(){
            var syncImpl = this.__getSyncImpl();
            //Below 2 steps used to be run after initial sync completed,
            //Now run before since initial sync has been changed to a console application.

            this.__buildRootContainer();
            //Show spinner until we start an app.
            this.showSpinner(this.getRoot());
            this.__discoverConsoleApps();

            // This should be triggered only once.
            syncImpl.bind("SYNC_FINISHED_INITIALIZING", function(evt){
                // Set our console user info cache object
                if (evt.data.lastSync.user) {
                    this.setUserInfo(evt.data.lastSync.user);
                }

                this.hideSpinner(this.getRoot());

                setTimeout(SVMX.proxy(this, function(){
                    this.__syncCompleted(evt.data.lastSync);
                }), 200);

            }, this);

            // This should be triggered after every sync.
            syncImpl.bind("SYNC_COMPLETED", function(evt){
                syncImpl.getSyncUserInfo({
                    context: this,
                    callback: function(info){
                        // Set our console user info cache object
                        this.setUserInfo(info);
                    }
                });
            }, this);

            //Start initial sync
            syncImpl.run();
        },

        __syncCompleted : function(lastSync){
            if (TS.isEmpty()) {
                this.__loadTags(SVMX.proxy(this, function() {
                    this.__buildConsole(lastSync);
                }));
            } else {
                this.__buildConsole(lastSync);
            }
       },

        __buildConsole: function(lastSync) {
            this.__userInfo = lastSync.user;
            //this.__buildRootContainer(); //Moved to run before initial sync
            if(!SVMX.TEST) {
              this.__root.setUserInfo(this.getUserInfo());
            }
            //this.__discoverConsoleApps(); //Moved to run before initial sync
            //TODO: Rediscover console applications so we can now take advantage of Tags after initial sync.
            this.__openFirstConsoleApp();
            this.__startIncrementalReSync();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "CONSOLE_APP_LAUNCHED", this);
            SVMX.getClient().triggerEvent(evt);

            // Tell the other application to open
            var externalInstalled = SVMX.getClient().getApplicationParameter("InstallBase");
            if (externalInstalled) {
                var message = {
                    action      : 'OPEN',
                    operation   : 'OPEN'
                };

                // Call External application
                var nativeService = com.servicemax.client.offline.sal.model.nativeservice.Facade;
                var request = nativeService.createSendExternalRequest();

                request.bind("REQUEST_COMPLETED", function(evt) {});

                request.bind("REQUEST_ERROR", function(evt) {});

                // Fire and forget, for now
                request.execute({
                    appName         : "Installigence",
                    externalRequest : SVMX.toJSON(message)
                });
            }


        },

        // WARNING: This call to loadTags, as currently implemented, needs to be able to access dictionary's for all modules.
        // TODO: Each module should localize its tooltip before sfmconsole ever sees it.
        __loadTags : function(callback){
            var client = SVMX.getClient();
            var declaration = client.getDeclaration("com.servicemax.client.sfmconsole.translation-tags");
            var definitions = client.getDefinitionsFor(declaration) || [];
            var configs = SVMX.array.map(definitions, function(d) {return d.config;});
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "SFMCONSOLE.RETRIEVE_DISPLAY_TAGS", this, {
                            request : {moduleIds : configs},
                            responder: SVMX.create("com.servicemax.client.sfmconsole.commands.RetrieveDisplayTagsResponder", this, callback)
                        }
            );
            this.triggerEvent(evt);
        },

        onRetrieveDisplayTags: function(translationService, errorMsg, callback) {
            TS = translationService.getDictionary("IPAD");
            TS_FSA = translationService.getDictionary("FSA");
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "DISPLAY_TAGS_LOADED", this);
            SVMX.getClient().triggerEvent(evt);

            callback.call();
        },

        /*
         * Load all configurations for all console apps from the manifest.json files.
         */
        __discoverConsoleApps : function(){
            var declaration = SVMX.getClient().getDeclaration("com.servicemax.client.sfmconsole.consoleapp");
            var definitions = SVMX.getClient().getDefinitionsFor(declaration);
            if(definitions.length === 0){
                this.__logger.error("No console apps defined.");
                return;
            }

            var discovered = [];
            for(var i=0;i<definitions.length;i++){
                var key = definitions[i].config.app.id;
                this.__consoleAppConfigs[key] = definitions[i].config;

                // If config tooltip is an array, then 0 is tag id and 1 is default text
                var tag = this.__consoleAppConfigs[key].tooltip;
                var tagId = (typeof tag === 'object') ? tag[0] : tag;
                var tagDefault = (typeof tag === 'object') ? tag[1] : tag;

                // repeat for button text
                var text_tag = this.__consoleAppConfigs[key]["button-text"];
                var text_tagId = (typeof text_tag === 'object') ? text_tag[0] : text_tag;
                var text_tagDefault = (typeof text_tag === 'object') ? text_tag[1] : text_tag;

                //Gather information if this console application's button should show a conflict badge when Sync conflicts are encountered
                var showConflictBadge = false;
                var conflictBadgeCls = "";
                if (this.__consoleAppConfigs[key]["show-conflicts"]) {
                    showConflictBadge = true;
                    conflictBadgeCls = this.__consoleAppConfigs[key]["conflict-badge-class"] || "";
                }

                if(this.__consoleAppConfigs[key].discover) {
                    discovered.push({
                            weight : definitions[i].config.positionWeight,
                            context : this,
                            "key":key,
                            iconClass : this.__consoleAppConfigs[key].icon['large-css-class'],
                            tooltip : tagId ? TS.T(tagId, tagDefault) : "",
                            buttonText: text_tagId ? TS_FSA.T(text_tagId, text_tagDefault) : "",
                            showConflictBadge: showConflictBadge,
                            conflictBadgeCls: conflictBadgeCls
                        });
                }
            }
            discovered.sort(function(a, b){return a.weight-b.weight;});
            for(var t=0;t<discovered.length;t++){
                if (discovered[t]) {
                    this.__registerLaunchableApp(discovered[t]);
                }
            }
            //Let all know that all discoverable console applications have been discovered and registered
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "CONSOLE_APPS_REGISTERED", this);
            SVMX.getClient().triggerEvent(evt);
        },

        __buildRootContainer : function(){
            this.__root = this.__view.createComponent("ROOTCONTAINER", {
                renderTo : SVMX.getDisplayRootId(),
                console  : this
            });
        },

        /**
         * Get the config data for the specified application id; config data is set via module.json file
         * @param {string} appId
         * @returns {Object} Application config data
         */
        getAppConfig : function(appId) {
            return this.__consoleAppConfigs[appId];
        },

       /**
        * Get the root container component for sfmconsole; this should contain everything within the application.
        */
        getRoot : function(){
            return this.__root;
        },

        /**
         * Iterate over the console apps
         * @param callback Your iterator function
         * @param {AbstractConsoleApp} callback.consoleApp An AbstractConsoleApp instance
         * @TODO: Might be handy to have an optional parameter of appId, and only call the callback on apps
         * with that appId.
         */
        forEachConsoleApp : function(callback) {
            SVMX.forEachProperty(this.__runningConsoleAppsByWindowId, function(inKey, inValue) {
                callback(inValue);
            });
        },

        /**
         * Returns the ConsoleApp that is currently showing
         * If we fail to find a current app, just return the configured start/home app.
         */
        getCurrentConsoleApp : function() {
            throw "Application subclass must implement getCurrentConsoleApp";
        },

        /**
         * Returns any console apps that have been instantiated with the specified appId (appId specified in module.json)
         * @returns {Object} result
         * @returns {Console} result.consoleAppInstance Instance of a console app
         * @returns {Panel} result.consoleAppContainer Instance of the console app's Root Container
         */
        findConsoleAppByAppId : function(appId) {
            return this.__runningConsoleAppsByAppId[appId];
        },

        /**
         * Returns any console apps that have been instantiated with the specified ComponentId/upi
         * @returns {Object} result
         * @returns {Console} result.consoleAppInstance Instance of a console app
         * @returns {Panel} result.consoleAppContainer Instance of the console app's Root Container
         */
        findConsoleAppByWindowId : function(appId) {
            return this.__runningConsoleAppsByWindowId[appId];
        },

        /**
         * Use this to show a console app that has previously been created.
         * While launchConsoleApp can detect if a given console app has already been created and show it,
         * this only works well for cases where a given console app can have only a single instance.
         * @param {Console} windowId ID of the window/console app instance to be shown
         */
        showConsoleApp : function(windowId) {
            throw "Subclass must implement showConsoleApp";
        },



        /**
         * Use this to instantiate a console app if needed and then show it.
         * If needed means that it can detect if a Singleton console app has previously been created
         * or not and instantiate it when needed.  If the app is NOT a singleton console app (sfmdelivery)
         * this will not detect if its already been created, and will always create a new one.
         * @param {String} consoleAppId Id specified for the app in its manifest.json file
         * @param {Object} [Options] Not sure if this should ever be used.
         */
        launchConsoleApp : function (consoleAppId, options) {
            // Prevent the same app from launching twice within a short time frame
            if (this.consoleAppLaunching(consoleAppId)) {
                return false;
            }

            options = options || {};

            var consoleAppInstance;
            // Get the configuration for the requested application (module.json)
            var appConfig = this.getAppConfig(consoleAppId);
            var isSingleton = appConfig ? !appConfig.multiple : false;

            if (isSingleton) {
                consoleAppInstance = this.findConsoleAppByAppId(consoleAppId);
            }

            if (isSingleton && consoleAppInstance) {
                options.context = this;
                consoleAppInstance.show();
            } else {
                // Find out if that app has already been created (not too useful if its not a singleton)
                consoleAppInstance = this.createConsoleApp(consoleAppId, options);
                if (consoleAppInstance) {
                    options.context = this;
                    consoleAppInstance.show();
                    consoleAppInstance.__start(options);
                }
            }

            this.consoleAppLaunched(consoleAppId);
        },

        /**
         * Creates a console app instance according to the configured ConsoleAppClass
         * or returns one if it already exists.
         */
        createConsoleApp : function(consoleAppId, options) {
            var consoleAppInstance;
            var appConfig = this.getAppConfig(consoleAppId);
            var isSingleton = appConfig ? !appConfig.multiple : false;

            // If the appConfig doesn't exist, then the consoleAppId is invalid.
            if (!appConfig) {
                this.__logger.error("Console App Not Defined: " + consoleAppId);
            } else {
                // Else create a new console app
                options.isClosable = !isSingleton;
                try {
                    consoleAppInstance = this.__createConsoleAppInternal(consoleAppId, options);

                    // Index console app instance
                    this.__runningConsoleAppsByAppId[consoleAppInstance.getAppTypeId()] = consoleAppInstance;
                    this.__runningConsoleAppsByWindowId[consoleAppInstance.getId()] = consoleAppInstance;
                } catch (err) {
                    this.__logger.error(err);
                    return false;
                }
            }

            return consoleAppInstance;
        },

        consoleAppLaunching : function(consoleAppId) {
            if (!this.__launchingConsoleAppsById[consoleAppId]) {
                var me = this;
                setTimeout(function(){
                    me.__launchingConsoleAppsById[consoleAppId] = null;
                }, 1000);
                return false;
            }
            return true;
        },

        consoleAppLaunched : function(consoleAppId) {
            this.__launchingConsoleAppsById[consoleAppId] = true;
        },

        __createConsoleAppInternal : function(consoleAppId, options) {
            return SVMX.create(
                this.getAppConfig(consoleAppId).app["class-name"],
                {
                    parent: this,
                    rootContainer: this.__root,
                    appConfig: this.getAppConfig(consoleAppId),
                    options: options
                }
            );
        },

        closeClosableApps : function() {
            this.forEachConsoleApp(SVMX.proxy(this, function(consoleApp){
                if(consoleApp.__appConfig.multiple) this.destroyConsoleApp(consoleApp);
            }));
        },

        applyAppInfo : function(consoleAppInstance, options) {

        },

        __getSyncImpl : function() {
            if(!this.__syncImpl){
                var declaration = SVMX.getClient().getDeclaration("com.servicemax.client.sfmconsole.synchronizer");
                var definitions = SVMX.getClient().getDefinitionsFor(declaration);
                if(definitions.length === 0){
                    this.__logger.error('Unable to load console synchronizer');
                    return;
                }

                var className = definitions[0].config.impl['class-name'];
                this.__syncImpl = SVMX.create(className, this);
            }

            return this.__syncImpl;
        },

        getSyncImpl : function(){
            return this.__syncImpl;
        },


        changeApplicationState : function(request) {
            switch(request.state) {
                case "BLOCK":
                    this.showSpinner();
                    break;
                case "UNBLOCK":
                    this.hideSpinner();
                    break;
            }
        },

        /**
         * Shows a spinner over the page.
         * May show some other "waiting" indicator than a spinner; name is poorly chosen.
         */
        showSpinner : function(optionalTarget) {
            if (this.__notificationService) {
                this.__notificationService.waitingMessage(optionalTarget);
            } else {
                this.__logger.error("showSpinner failed because there is no notification service");
            }
        },

        /**
         * Hides the spinner shown with showSpinner
         */
        hideSpinner : function(optionalTarget) {
            if (this.__notificationService) {
                this.__notificationService.endWaitingMessage(optionalTarget);
            }
        },

        runManualSyncBackground : function () {
            this.__getSyncImpl().performSync("ONECALLSYNC");
        },

        /**
         * @method getUserInfo
         * Returns the userInfo object as a readonly object
         * Insures readonly by returning a clone of the object rather than the original object
         */
        getUserInfo : function() {
           return SVMX.cloneObject(this.__userInfo) || {};
        },

        setUserInfo : function(userInfo) {
            if(!userInfo){
                return;
            }
            var isChanged = userInfo && !this.__userInfo || userInfo && this.__userInfo && this.__userInfo.UserSessionId != userInfo.UserSessionId;

            this.__userInfo = userInfo;

            // If all else fails get the TimeZoneOffset from the device directly.
            // We prefer to get it from the native layer since the user may have the ability to change it
            // on their device.
            if (this.__userInfo.TimezoneOffset === undefined) {
                //set to local timezone
                this.__userInfo.TimezoneOffset =  com.servicemax.client.lib.datetimeutils.DatetimeUtil.getLocalUTCOffsetString();
            }

            // Setup the datetimeutils constants so it will have date regardless if the application has the sync module or not.
            var DatetimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
            DatetimeUtils.setDateFormat(userInfo.DateFormat);
            DatetimeUtils.setTimeFormat(userInfo.TimeFormat);
            DatetimeUtils.setTimezoneOffset(userInfo.TimezoneOffset);
            if (userInfo.Timezone) {
                DatetimeUtils.setTimezone(userInfo.Timezone);
            } else {
                DatetimeUtils.setTimezoneOffset(userInfo.TimezoneOffset);
            }

            // Warning: both DatetimeUtils and this.__userInfo must always have the correct offset since
            // com.servicemax.client.offline.sal.model.utils.Data also does date manipulation.
            // SalesForce user info service call returns SalesForce timezone but the native layer returns device time.
            // Sync will have handled this before we reach here.

            if (isChanged) {
                var evtUserInfo = SVMX.create("com.servicemax.client.lib.api.Event",
                                               "GLOBAL.HANDLE_USER_INFO", this, userInfo);
                SVMX.getClient().triggerEvent(evtUserInfo);
            }
        },

        /**
         * Close a console app.  This represents a request from someone other than the app itself to close the console
         * app, which must first be passed by the console app itself to verify that it can safely be closed.
         * @param {Object} options
         * TODO: Document what the options are
         */
        closeConsoleApp : function(consoleAppInstance){
            if(consoleAppInstance){
                consoleAppInstance.onCanClose(SVMX.proxy(this, function(canClose){
                    if(canClose === true) this.destroyConsoleApp(consoleAppInstance);
                }));
            }
        },

        destroyConsoleApp : function(consoleAppInstance) {
            if (consoleAppInstance) {
               consoleAppInstance.onClose();
               delete this.__runningConsoleAppsByWindowId[consoleAppInstance.getId()];

               if (this.__runningConsoleAppsByAppId[consoleAppInstance.getAppTypeId()] == consoleAppInstance) {
                   delete this.__runningConsoleAppsByWindowId[consoleAppInstance.getAppTypeId()];
               }
               this.__root.manageConsoleAppContainerClose(consoleAppInstance);
               consoleAppInstance.destroy();
            }
        },

        goToHome: function() {
            this.__openFirstConsoleApp(true);
        },

        __getFirstConsoleApp : function() {
            var consoleAppId = (SVMX.getClient().getApplicationParameter("sfmconsole-runtime-start") || null);
            if(!consoleAppId || consoleAppId === ""){
                this.__logger.error("sfmconsole-runtime-start is not set in application config.");
                return false;
            }
            return consoleAppId;
        },

        __openFirstConsoleApp : function () {
            var consoleAppId = this.__getFirstConsoleApp();
            if (consoleAppId) {
                this.launchConsoleApp(consoleAppId,{});
            }
        },

        __startIncrementalReSync : function(){
            if(this.__userInfo && this.__userInfo.reSync){
                this.runManualSyncBackground();
            }
        },

        // deprecated
        setApplicationStateHandler : function(stateHandler){

            // set up the application state handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application UI state will
            // be managed by SFMConsole itself.
            this.__stateHandlers.applicationStateHandler = stateHandler;
        },

        // deprecated
        getApplicationStateHandler : function(){
            return this.__stateHandlers.applicationStateHandler || this;
        },

        // deprecated
        setApplicationErrorHandler : function(errorHandler){

            // set up the application error handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application errors will
            // be managed by SFMConsole itself.
            this.__stateHandlers.applicationErrorHandler = errorHandler;
        },

        // deprecated
        getApplicationErrorHandler : function(){
            return this.__stateHandlers.applicationErrorHandler || this;
        },

        // deprecated
        setApplicationMessageUIHandler : function(messageUIHandler){

            // set up the application message UI handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application message UI will
            // be managed by SFMConsole itself.
            this.__stateHandlers.applicationMessageUIHandler = messageUIHandler;
        },

        // deprecated
        getApplicationMessageUIHandler : function(){
            return this.__stateHandlers.applicationMessageUIHandler || this;
        },

        // deprecated
        setApplicationQuickMessageHandler : function(quickMessageUIHandler){

            // set up the application quick message handler since SFMConsole cannot handle it.
            // once SFMConsole takes over the complete control of the UI, application quick messages will
            // be managed by SFMConsole itself.
            this.__stateHandlers.applicationQuickMessageHandler = quickMessageUIHandler;
        },

        // deprecated
        getApplicationQuickMessageHandler : function(){
            return this.__stateHandlers.applicationQuickMessageHandler || this;
        },


        showQuickMessage : function(message, duration, type){
            if (this.__notificationService) {
                this.__notificationService.quickMessage(message, duration, type);
            } else {
                this.__logger.error("showQuickMessage failed because there is no notification service");
            }
        },

        notifyApplicationError : function(error){
            if (this.__notificationService) {
                var title = TS.T("FSA007_TAG005","Error Message");
                this.__notificationService.errorMessage(error, title);
            } else {
                this.__logger.error("notifyApplicationError failed because there is no notification service");
            }
        },

        /**
         * Supports default and custom messages
         *
         * @param {Object} options
         * options.type: QUESTION, WARN, ERROR, INFO, CUSTOM
         * options.text
         * options.buttons Array of ["OK", "CANCEL", "YES", "NO"]
         * options.itemId Unique identifier of this message
         */
        showMessage : function(options){
            var msgBox;
            if (this.__notificationService) {
                if (!options.title) {
                    options.title = TS.T("FSA007_TAG006", "Information");
                }
                msgBox = this.__notificationService.showMessage(options);
            } else {
                this.__logger.error("showMessage failed because there is no notification service");
            }
            return msgBox;
        },

        /**
         * When calling showMessage itemId can be passed as an option.
         * This will check for the existence of any component with that itemId and
         * return true.
         */
        checkForMessageId: function(itemId) {
            return (this.__notificationService && this.__notificationService.checkForMessageId(itemId)) ? true : false;
        }
    },{});

    consoleImpl.Class("CompositionEngine", com.servicemax.client.lib.api.Object,{
        __metamodel : null, __parent : null,

        __constructor : function(metamodel, parent){
            this.__metamodel = metamodel;
            this.__parent = parent;
        },

        compose : function(){
            var composition = this.__parent.__self.composition;
            return this.__composeInternal(this.__metamodel, composition, this.__parent);
        },

        __composeInternal : function(metamodel, composition, parent){
            var length = composition.length, i;
            for(i = 0; i < length; i++){
                var compositionItem = composition[i];
                var compositionMetamodel = metamodel.getChildNode(compositionItem.name);

                if(compositionMetamodel){
                    var compositionItemObj = null,
                        compositionItemClass = compositionItem.className;

                    if(compositionMetamodel instanceof Array === false){
                        compositionMetamodel = [compositionMetamodel];
                    }
                    var compositionMetamodelLength = compositionMetamodel.length, j, compositionMetamodelItem;
                    for(j = 0; j < compositionMetamodelLength; j++){
                        compositionMetamodelItem = compositionMetamodel[j];

                        if(compositionMetamodelItem.title) {
                            // XSS protection
                            compositionMetamodelItem.title = Ext.String.htmlEncode(compositionMetamodelItem.title);
                        }

                        compositionItemObj = SVMX.create(compositionItemClass, {compositionMetamodel : compositionMetamodelItem});
                        if(compositionItemObj.__self.composition !== undefined){
                            this.__composeInternal(compositionMetamodelItem, compositionItemObj.__self.composition, compositionItemObj);
                        }
                        parent.onCompositionChildCreate(compositionItemObj, compositionItem.name);
                    }
                }
            }
        }
    }, {});

})();
