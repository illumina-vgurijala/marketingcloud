// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.runtime\src\api.js
/**
 * This file needs a description 
 * @class com.servicemax.client.runtime.api
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	var runtimeApi = SVMX.Package("com.servicemax.client.runtime.api");
	
	runtimeApi.Class("AbstractNamedInstance", com.servicemax.client.lib.api.Object, {
		
		__constructor : function(){
			
		},
		
		initialize : function(name, data, params){
			
		}
	}, {});
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.runtime\src\constants.js
/**
 * This file needs a description 
 * @class com.servicemax.client.runtime.constants
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */
(function(){
	
	var constantsImpl = SVMX.Package("com.servicemax.client.runtime.constants");

	constantsImpl.Class("Constants", com.servicemax.client.lib.api.Object, {
		__constructor : function(){}
	}, {
		PREF_KEY_THEME : "CURRENT-THEME"
	});
	
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.runtime\src\impl.js
/**
 * This file needs a description
 * @class com.servicemax.client.runtime.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var runtimeImpl = SVMX.Package("com.servicemax.client.runtime.impl");

	runtimeImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__runtime : null, __displayRoot : null,

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("CLIENT-RUNTIME");

			this.__runtime = new runtimeImpl.Runtime(this);

			// register with the READY client event
			SVMX.getClient().bind("READY", this.__onClientReady, this);

		},

		beforeInitialize : function(){

		},

		initialize : function(){

		},

		afterInitialize : function(){
			var serv = SVMX.getClient().getServiceRegistry()
								.getService("com.servicemax.client.preferences").getInstance();
			serv.addPreferenceKey(com.servicemax.client.runtime.constants.Constants.PREF_KEY_THEME);
		},

		__onClientReady : function(evt){
			this._logger.info("Client ready to run!");
			this.__runtime.start();
		}

	}, {});

	/**
	 * The platform runtime
	 */
	runtimeImpl.Class("Runtime", com.servicemax.client.lib.api.Object, {
		__parent : null, __logger : null, __app : null,

		__constructor : function(parent){
			this.__parent = parent;
			this.__logger = parent.getLogger();
		},

		start : function(){

			var client = SVMX.getClient(), declaration = null, definitions = null;

			// first load all the CSS definitions. This will optimize the runtime for DOM construction
			var currentTheme = "CLASSIC";

			// check if there is a url or configuration parameter specifying a theme. if yes, then load that theme
			var themeFromUrl = SVMX.getUrlParameter("theme");
			var themeFromConfig = client.getApplicationParameter("theme");
			if(themeFromUrl != undefined && themeFromUrl != ''){
				currentTheme = themeFromUrl;
			}else if(themeFromConfig){
				currentTheme = themeFromConfig;
			}else{
				// check if we can get the current theme from preference
				try{
					var serv = SVMX.getClient().getServiceRegistry()
									.getService("com.servicemax.client.preferences").getInstance(),
					key = com.servicemax.client.runtime.constants.Constants.PREF_KEY_THEME;

					var pref = serv.getPreference(key);
					if(pref){
						currentTheme = pref;
					}
				}catch(e){
					// could not find preferences. this could typically happen when a cache service is
					// present. just continue...
					this.__logger.warn("Could not load preferences. => " + e);
				}
			}

			function afterCssLoad(){
				this.__logger.info("Theme <" + currentTheme + ">loaded successfully");

				// get the interface definition for runtime application interface.
				// there can exist only one such definition. however, one can define
				// multiple runnable applications and specify which one to run in the application
				// configuration

				declaration = client.getDeclaration("com.servicemax.client.runtime.application");
				definitions = client.getDefinitionsFor(declaration);

				if(definitions.length == 0){
					this.__logger.error("Cannot find an application extension!");
					return;
				}

				//if there are more than one, pick up the first one.
				// !!! More than one is not a use case
				var definition = definitions[0], appConfig = definition.config.application;

				// now get which runtime application to run from the application configuration
				// it is possible that one can set application id from the url. if it is not available, then look into
				// what is available in the application parameters from config.json, ...

				var appId = '';

				appId = SVMX.getUrlParameter("application-id");
				if(appId == null || appId == ''){
					appId = client.getApplicationParameter("application-id");
				}

				if(!appId){
					this.__logger.error("Your application configuration does not specify an application id. Please rectify");
					return;
				}

				if(appConfig instanceof Array){
					for(var acIndex =0;  acIndex < appConfig.length; acIndex++){
						var ac = appConfig[acIndex];
						if(ac.id == appId){
							appConfig = ac;
							break;
						}
					}

					// invalid application id
					if(acIndex == appConfig.length){
						appConfig = {id : "__INVALID_APP_ID__"};
					}
				}

				if(appConfig.id != appId){
					this.__logger.error("Cannot find the application " + appId + " in any of the definitions. Please rectify");
					return;
				}

				// create the runnable instance
				var appClassName = appConfig["class-name"];
				this.__app = SVMX.create(appClassName);

				this.__logger.info("Running application <" + appId + "> with class <" + appClassName + ">");

				// set up the static instance
				com.servicemax.client.lib.api.AbstractApplication.currentApp = this.__app;

				if(SVMX.TEST) {
	          // Stop setup app, run tests
	          SVMX.startTests();
	          return;
        }

				// preinitialize the application
				this.__app.beforeRun({handler : this.__beforeRunCompleted, context : this});

				// trigger the application created event
				var ce = SVMX.create("com.servicemax.client.lib.core.ClientEvent", "APPLICATION_CREATED", this);
				SVMX.getClient().triggerEvent(ce);

			}

			// load the theme
			var themeService = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.themeservice").getInstance();
			themeService.loadTheme(currentTheme, afterCssLoad, this);
		},

		__beforeRunCompleted : function(){

			// end the load monitor
			SVMX.getClient().getProgressMonitor().finish();

			// now run the app
			this.__app.run();
		}
	},{});


	runtimeImpl.Class("ThemeService", com.servicemax.client.lib.api.Object,{
		__logger : null, __themeProperties : null, __currentTheme : null,
		__constructor : function(){
			if(runtimeImpl.ThemeService.__instance != null) return runtimeImpl.ThemeService.__instance;

			runtimeImpl.ThemeService.__instance = this;
			this.__themeProperties = {};
			this.__logger = SVMX.getLoggingService().getLogger("THEME-SERVICE");
		},

		getThemeProperties : function(){
			return this.__themeProperties;
		},

		getThemeProperty : function(propName){
			var allProps = this.getThemeProperties(), ret = null;
			for(var name in allProps){
				if(name == propName){
					ret = allProps[name]
					break;
				}
			}
			return ret;
		},

		__extractThemeProperties : function(props){
			var allProps = this.getThemeProperties();
			for(var name in props){
				allProps[name] = props[name];
			}
		},

		getAvailableThemes : function(){
			var client = SVMX.getClient(), declaration = null, definitions = null, ret = {};

			declaration = client.getDeclaration("com.servicemax.client.runtime.uitheme");
			definitions = client.getDefinitionsFor(declaration);
			if(definitions.length > 0){
				var i, count = definitions.length;
				for(i = 0; i < count; i++){
					var def = definitions[i], themeDefs = def.config["theme-defs"];

					// if a theme definition is present
					if(themeDefs){
						var j , themeDefCount = themeDefs.length;
						for(j = 0; j < themeDefCount; j++){
							var themeDef = themeDefs[j];
							ret[themeDef.type] = ret[themeDef.type] ? ret[themeDef.type] : { properties : {}};
							if(themeDef.properties) {
								for(var name in themeDef.properties)
								ret[themeDef.type].properties[name] = themeDef.properties[name];
							}
						}
					}
				}
			}
			return ret;
		},

		getCurrentTheme : function(){
			return this.__currentTheme;
		},

		loadTheme : function(type, handler, context, loadLater){
			this.__currentTheme = type;

			if(loadLater){
				this.__logger.info("Will load the theme later => " + type);
				handler.call(context);
				return;
			}

			this.__logger.info("Loading theme => " + type);
			var client = SVMX.getClient(), declaration = null, definitions = null, allUrls = [];

			declaration = client.getDeclaration("com.servicemax.client.runtime.uitheme");
			definitions = client.getDefinitionsFor(declaration);
			if(definitions.length > 0){
				var i, count = definitions.length;
				for(i = 0; i < count; i++){
					var def = definitions[i], themeDefs = def.config["theme-defs"];

					// if a theme definition is present
					if(themeDefs){
						var j , themeDefCount = themeDefs.length;
						for(j = 0; j < themeDefCount; j++){
							var themeDef = themeDefs[j];
							if(themeDef.type == type){

								// see if this definition applies only to certain platform
								if(themeDef["valid-platforms"]){
									var validPlatforms = themeDef["valid-platforms"];

									// right now support only one platform
									if(!SVMX.isPlatform(validPlatforms)) continue;

								}

								if(themeDef.properties){
									this.__extractThemeProperties(themeDef.properties);
								}

								if(themeDef.path){
									var url = def.getResourceUrl(themeDef.path);
									allUrls[allUrls.length] = url;
								}
							}
						}
					}
				}
			}
			if(SVMX.TEST) {
	        console.log('Skipping requireStyleSheet in test mode for now');
	        handler.call(context);
					return;
      }
			if(allUrls.length > 0){
				SVMX.requireStyleSheet(allUrls, handler, context, {});
			}else{
				handler.call(context);
			}
		}

	}, {
		__instance : null
	});

	runtimeImpl.Class("NamedInstanceService", com.servicemax.client.lib.api.Object, {
		__logger : null,
		__allInstanceDefinitions : null,

		__constructor : function(){
			if(runtimeImpl.NamedInstanceService.__instance != null) return runtimeImpl.NamedInstanceService.__instance;

			runtimeImpl.NamedInstanceService.__instance = this;

			this.__logger = SVMX.getLoggingService().getLogger("NAMEDINSTANCE-SERVICE");
			this.__allInstanceDefinitions = {};

			// initialize the service
			var client = SVMX.getClient(), declaration = null, definitions = null;

			declaration = client.getDeclaration("com.servicemax.client.runtime.namedinstance");
			definitions = client.getDefinitionsFor(declaration);

			if(definitions != null){
				var i, count = definitions.length;

				// get all the instance definitions first
				for(i = 0; i < count; i++){
					var def = definitions[i], config = def.config;

					if(config.define){
						this.__allInstanceDefinitions[config.define.name] = {definition : def, data : []};
					}
				}

				// now get all the configurations
				for(i = 0; i < count; i++){
					var def = definitions[i], config = def.config;

					if(config.configure){
						var def = this.__allInstanceDefinitions[config.configure.name];
						def.data[def.data.length] = {definition : def, data : config.configure.data};
					}
				}
			}
		},

		createNamedInstanceAsync : function(name, options){

			// TODO : Load the module if it is not already loaded
			this.__createdNamedInstanceAsyncInternal(name, options);
		},

		__createdNamedInstanceAsyncInternal : function(name, options){

			var namedInstanceDef = this.__allInstanceDefinitions[name];
			var className = namedInstanceDef.definition.config.define.type;
			var cls = SVMX.getClass(className);
			var namedInstance = new cls();
			namedInstance.initialize(name, namedInstanceDef.data, options.additionalParams);
			options.handler.call(options.context, namedInstance);
		}

	}, {
		__instance : null
	});

	runtimeImpl.Class("Preferences", com.servicemax.client.lib.api.Object, {
		__preferenceKeys : null,
		__constructor : function(){ this.__preferenceKeys = {}; },

		addPreferenceKey : function(key){
			key = this.__getKey(key);
			this.__preferenceKeys[key] = key;
		},

		getPreferenceKeys : function(){
			return SVMX.cloneObject(this.__preferenceKeys);
		},

		getPreference : function(key){
			var value;

			// This is under the assumption that the cache service is already loaded
			var servDef = SVMX.getClient().getServiceRegistry()
							.getService("com.servicemax.client.cache");
			if (servDef) {
			    var serv = servDef.getInstance();
    			key = this.__getKey(key);
    			value = serv.getItem(key);
    		} else {
			     SVMX.getLoggingService().getLogger("CLIENT-RUNTIME").warning("No com.servicemax.client.cache has been registered");
			}
			return value;
		},

		setPreference : function(key, value){
			// This is under the assumption that the cache service is already loaded
			var servDef = SVMX.getClient().getServiceRegistry()
							.getService("com.servicemax.client.cache");
            if (servDef) {
                var serv = servDef.getInstance();
    			key = this.__getKey(key);
    			serv.setItem(key, value);
			} else {
			    SVMX.getLoggingService().getLogger("CLIENT-RUNTIME").warning("No com.servicemax.client.cache has been registered");
			}
		},

		__getKey : function(key){
			return "SVMX-CLIENT-UPREF-" + key;
		}
	}, {});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.runtime\src\jsee\api.js
/**
 * This is the core implementation of the expression engine which is consumer neutral
 * 
 * @class com.servicemax.client.runtime.jsee.api
 * @singleton
 * @author Indresh MS
 *
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	if(window.$EXPR == undefined || window.$EXPR == null) window.$EXPR = {};
	
	/**
	 * The expression engine implementation class
	 */
	var JSEE = function(){
		
		/**
		 * The core internal API method to evaluate the JS expression
		 * !!! Note the right now, this method works on single context. In future, it may 
		 * !!! support multiple contexts via context roots mechanism ($D for data for example) 
		 * 
		 * @param expr String the expression that needs to be evaluated
		 * @param context Object the contextual data that this expression works on
		 * @param callback Function the function to be invoked to present the result
		 * @param callbackContext Object the object on which the callback function exists
		 * @param async Boolean true if the expression results in an asynchronous behavior, false otherwise
		 */
		this.evalExpression = function(expr, context, callback, callbackContext, async){
			var result = null, bReturned = false;;
			(function (expr, context, callback, callbackContext, async){
				
				function $ADD(a, b){ return a + b; };
				function $SUB(a ,b){ return a - b; };
				function $ISNULL(a){ if(a) return true; else return false; };
				function $BOOL(a){ return !!a; };
				
				function $SORT(items, fieldOrFunc){
					// right now, only field name is supported
					if(typeof(fieldOrFunc) != 'string') return;
					
					var i, l = items.length;
					
					if(l < 2) return items;
					
					for(i = 0; i < (l - 1);){
						var k = 0;
						for(; k < (l - 1); k++){
							if(items[k][fieldOrFunc] > items[k+1][fieldOrFunc]){
								var temp   = items[k];
								items[k]   = items[k+1];
								items[k+1] = temp; 
							}
						}
						l--;
					}
					return items;
				};
				
				// always assumes that this is invoked as part of asynchronous calls
				function $RETURN(value){
					
					// it is not allowed to return twice in the same expression
					if(bReturned) throw new Error("Attempted to RETURN twice in the same expression!");
					
					bReturned = true;
					callback.call(callbackContext, value);
				}
				
				function $FORMAT(){
					return SVMX.format(arguments);
				}
				
				context = $EXPR.toObject(context);
	
				result = eval(expr);
			})(expr, context, callback, callbackContext, async);
			
			// invoke the call back immediately if this is not an asynchronous call
			if(!async){
				callback.call(callbackContext, result);
			}		
			
			// return the result anyways
			return result;
		};
	};
	
	/**
	 * The external API method to be consumed by the respective bridges
	 */
	$EXPR.executeExpression = function(expr, context, callback, callbackContext, async){
		var jsel = new JSEE();;
		var ret = jsel.evalExpression(expr, context, callback, callbackContext, async);
		return ret;	
	};
	
	$EXPR.toJSON = function(data){
		return SVMX.toJSON(data);
	};
	
	$EXPR.toObject = function(data){
		return SVMX.toObject(data);
	};
	
	$EXPR.ajax = function(options){
		return SVMX.ajax(options);
	};
	
	$EXPR.Logger = SVMX.getLoggingService().getLogger("JSEE");
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.runtime\src\jsee\expressions.js
/**
 * Expression engine for evaling customer expressions and applying data values to the expression.
 * @author Michael Kantor, Indresh MS
 * @class com.servicemax.client.runtime.jsee.expression
 * @singleton
 *
 * @copyright 2013 ServiceMax, Inc
 */

(function(){

	/**
	 * The expression engine implementation class
	 */
	var JSEE = function(){
				function $LC (a) {
					return (typeof a === "string") ? a.toLowerCase() : a;
				}

				/* Math Functions */
				function $ADD(a, b){ return a + b; };
				function $SUB(a ,b){ return a - b; };

				/* Comparison Functions */

				// isnull/isnotnull: null, undefined and "" are all treated as null values.
				// Status: Should work for any type of field.
				function $ISNULL(a){ if(a || a === 0 || a === false) return false; else return true; };
				function $ISNOTNULL(a){ if(a || a === 0 || a === false) return true; else return false; };

				// EQ/NE: Returns whether values are equal or not equal
				// Status: Should work for strings, numbers, dates, booleans. String comparisons are case-insensitive
				//         Should fail for Objects (are there any?)
				function $EQ(a, b, allowNull) {
                    if (!allowNull && a !== b && ($ISNULL(a) || $ISNULL(b))) return CONSTANTS.INVALID;
					if (a instanceof Date) a = a.getTime();
					if (b instanceof Date) b = b.getTime();
					return $LC(a) === $LC(b);
				};
				function $NE(a, b)  {
				    // NE is never invalid; comparing null NE xxx should always return false unless xxx is "" or null
				    if ($ISNULL(a) || $ISNULL(b)) return false;
				    var result = $EQ(a,b, true);
				    return !result;
				};

				// GT/LT/GE/LE: Returns values greater than or less than.  Does case-insenstive comparison.
				// Status: Tested for Strings, Numbers and Dates though Date values must be entered as yyyy-mm-dd or "2013-04-13 00:00:00"
				// Note that because this is ultimately a string comparison, the following date comparisons give the following results:
				// "2013-04-13 00:00:00" > "2013-04-13" > true
				// "2013-04-13 00:00:00" > "2013-04-13 01" > false
				function $GT(a, b) {
                    if ($ISNULL(a) || $ISNULL(b)) return CONSTANTS.INVALID;
				    return $LC(a) > $LC(b);
				};
				function $LT(a, b) {
                    if ($ISNULL(a) || $ISNULL(b)) return CONSTANTS.INVALID;
				    return $LC(a) < $LC(b);
				};
				function $GE(a, b) {
                    if ($ISNULL(a) || $ISNULL(b)) return CONSTANTS.INVALID;
				    return $LC(a) >= $LC(b);
				};
				function $LE(a, b) {
                    if ($ISNULL(a) || $ISNULL(b)) return CONSTANTS.INVALID;
				    return $LC(a) <= $LC(b);
				};


				// Substring Tests
				// Status: Tested on Strings and Numbers.  Should work on anyting except Objects.
				function $STARTS(a,b) {
                    if ($ISNULL(a) || $ISNULL(b)) return CONSTANTS.INVALID;
				    return String(a).toLowerCase().indexOf($LC(b)) === 0;
				};
				function $CONTAINS(a, b) {
                    if ($ISNULL(a) || $ISNULL(b)) return CONSTANTS.INVALID;
				    return String(a).toLowerCase().indexOf($LC(b)) !== -1;
				};
				function $NOTCONTAINS(a, b) {
					// NOTCONTAINS is never invalid; NULL values can be safely used in a NOTCONTAINS
					// "hello" NOTCONTAINS null is true
					// null NOTCONTAINS "hello" is also true
					// An expression testing NOTCONTAINS is almost always going to be satisfied with that response
					return String(a).toLowerCase().indexOf($LC(b)) === -1;
				};



				// Array Tests (INCLUDE == $IN/EXCLUDE == $NOTIN).  Because the input is a string of the form "x;y;z", the second parameter b must be turned to string
				// Does case insensitive string comparison
				// If a is not a list of values, it will still be turned into an array of one element
				// If a is not a string it will be turned into a string
				function $IN(inList,inValue) {
					if ($ISNULL(inValue) || $ISNULL(inList)) return CONSTANTS.INVALID;
					var tmpArray = String(inList).toLowerCase().split(/[,;]/);
					return SVMX.array.indexOf(tmpArray, String(inValue).toLowerCase()) !== -1;
				};
				function $NOTIN(inList,inValue) {
					var result = $IN(inList,inValue);
					if (result === 0) return CONSTANTS.INVALID;
					return !result;
				};


				function $NUMBER(inValue) {
					if ($ISNULL(inValue)) return null; // so that expressions using this can return -1 instead of true/false
					return Number(inValue);
				}

				// Sometimes a boolean is true/false
				// Sometimes a boolean is "true"/"false"
				// And the rest of the time a boolean is just a truthiness 0/1, ""/"has text", null, undefined, etc.
				function $BOOLEAN(inValue) {
					if (!inValue) return false;
					var value = String(inValue).toLowerCase();

					// Only one value gets past the first "if" statement that means false.
					if (value === "false") return false;
					return true;
				}

				// Date methods.
				function $DATE(inValue) {
        			if ($ISNULL(inValue)) return null;
					return com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDate(inValue);
				}

				//Converts GMT to Display DateTime as Object
				function $LOCALDATETIME(inValue) {
					if ($ISNULL(inValue)) return null;
						var rst = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseGMTDate(inValue);
						return rst;
				}

				//Converts DisplayTime to GMT DateTime as Object
        function $TIMEZONEDATE(inValue) {
	        if ($ISNULL(inValue)) return null;
            var rst = com.servicemax.client.lib.datetimeutils.DatetimeUtil.convertToTimezone(
                com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(inValue, 'YYYY-MM-DD HH:mm:ss'),
                com.servicemax.client.lib.datetimeutils.DatetimeUtil.getLocalUTCOffset()*-1, false);

            return rst;
        }

				//Convert GMT to Display DateTime as String
				function $DISPLAYDATETIME(inValue) {
					if ($ISNULL(inValue)) return null;
					return com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(inValue, 'YYYY-MM-DD', 'HH:mm:ss');
				}

				/* DATE COMPARISON FUNCS:
				 * If these are called, we aren't doing a datetime equality test, only a date equality test
				 * that must ignore any time components for an accurate comparison.
				 * NOTE: Never modify the input date object which may be reused elsewhere; always copy the date.
				 */
				function $DATEEQ(a,b) {
					if (!a || !b) return CONSTANTS.INVALID;
					a = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(a);
					b = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(b);
					return a.getTime() === b.getTime();
				}
				function $DATENE(a,b) {
					if (!a || !b) return CONSTANTS.INVALID;
					return !$DATEEQ(a,b);
				}
				function $DATEGT(a,b) {
					if (!a || !b) return CONSTANTS.INVALID;
					a = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(a);
					b = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(b);
					return a.getTime() > b.getTime();
				}
				function $DATEGE(a,b) {
					if (!a || !b) return CONSTANTS.INVALID;
					a = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(a);
					b = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(b);
					return a.getTime() >= b.getTime();
				}
				function $DATELT(a,b) {
					if (!a || !b) return CONSTANTS.INVALID;
					a = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(a);
					b = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(b);
					return a.getTime() < b.getTime();
				}
				function $DATELE(a,b) {
					if (!a || !b) return CONSTANTS.INVALID;
					a = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(a);
					b = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(b);
					return a.getTime() <= b.getTime();
				}

				/* These date methods get values for comparison against Dates, not Datetimes
				 * Use the comparison functions above if comparing them to datetimes.
				 */
				function $DATETODAY() {
					var today = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime('today', 'YYYY-MM-DD', 'HH:mm:ss');
					today = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(today);
					return today;
				}
				function $DATETOMORROW() {
					var tomorrow = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime('tomorrow', 'YYYY-MM-DD', 'HH:mm:ss');
					tomorrow = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(tomorrow);
					return tomorrow;
				}
				function $DATEYESTERDAY() {
					var yesterday = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime('yesterday', 'YYYY-MM-DD', 'HH:mm:ss');
					yesterday = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseDateOnly(yesterday);
					return yesterday;
				}
				function $DATENOW() {
					var now = com.servicemax.client.lib.datetimeutils.DatetimeUtil.macroDrivenDatetime('now', 'YYYY-MM-DD', 'HH:mm:ss');
					now = com.servicemax.client.lib.datetimeutils.DatetimeUtil.parseGMTDate(now);
					return now;
				}

				/* Array Functions: UNTESTED */
				function $SORT(items, fieldOrFunc){
					// right now, only field name is supported
					if(typeof(fieldOrFunc) != 'string') return;

					var i, l = items.length;

					if(l < 2) return items;

					for(i = 0; i < (l - 1);){
						var k = 0;
						for(; k < (l - 1); k++){
							if(items[k][fieldOrFunc] > items[k+1][fieldOrFunc]){
								var temp   = items[k];
								items[k]   = items[k+1];
								items[k+1] = temp;
							}
						}
						l--;
					}
					return items;
				};

				/* MICHAEL: I have not reviewed this; was copied from prior version; recommend SVMX.string.replace instead */
				function $FORMAT(){
					return SVMX.format(arguments);
				}


		/**
		 * The core internal API method to evaluate the JS expression
		 * !!! Note the right now, this method works on single context. In future, it may
		 * !!! support multiple contexts via context roots mechanism ($D for data for example)
		 *
		 * @param expr String the expression that needs to be evaluated
		 * @param context Object the contextual data that this expression works on
		 * @param callback Function the function to be invoked to present the result
		 * @param callbackContext Object the object on which the callback function exists
		 * @param async Boolean true if the expression results in an asynchronous behavior, false otherwise
		 */
		this.evalExpressions = function(exprs, context, callback, callbackContext, async){
				var bReturned = false, results = [];

				// always assumes that this is invoked as part of asynchronous calls
				function $RETURN(value){

					// it is not allowed to return twice in the same expression
					if(bReturned) throw new Error("Attempted to RETURN twice in the same expression!");

					bReturned = true;
					callback.call(callbackContext, value);
				}


			(function (exprs, context, callback, callbackContext, async){

				context = SVMX.toObject(context);

				var scopeExpr = [];
				for (var key in context) {
					if (context.hasOwnProperty(key)) {
						scopeExpr.push("var " + key + " = context." + key + ";");
					}
				}

				eval(scopeExpr.join("\n"));  // Set all fields to be in this function scope; the next eval will have access to this scope and these variables
				// If expression defines vars, don't let them affect other expressions; localize their context with an inner function
				SVMX.array.forEach(exprs, function(expr, i) {
					//SVMX.getLoggingService().getLogger("SVMX-expressions").info("EXPR:" + expr);
					results[i] = eval(expr);
					logger.info(expr + " = " + results[i]);
				});
			})(exprs, context, callback, callbackContext, async);

			// invoke the call back immediately if this is an asynchronous call
			// If its a synchronous call, then just return the value
			if(!async && callback){
				callback.call(callbackContext, results);
			}

			// return the result anyways
			return results;
		};
	};

	var expressionEngine = new JSEE();
	var logger = SVMX.getLoggingService().getLogger("SVMX-expressions");

	/**
	 * @param {String|String[]} exprs One or an array of string expressions to be evaluated "a + b" or ["a + b", "a - b"]
	 * @param {Object} context Data values to be available to the expression {a: 5, b: 10}
	 * @param {null|Function} callback If async is true, then results are provided to this callback instead of simply returning a value
	 * @param {Object} callbackContext If async is true, callbackContext will be the "this" context for the callback function
	 * @param {Boolean} async If assync is false, return the value, if true, pass value to callback
	 */

	SVMX.executeExpressions = function(exprs, context, callback, callbackContext, async){
		try {
			var ret = expressionEngine.evalExpressions($.isArray(exprs) ? exprs : [exprs], context, callback, callbackContext, async);
		} catch(e) {
			logger.error("executeExpression: error in expression: " + exprs);
		}
		return $.isArray(exprs) ? ret : ret[0];
	};


    var CONSTANTS = {
        INVALID : 0
    };

    SVMX.executeExpressionsResultInvalid = function(result) {return result === CONSTANTS.INVALID;};
})();

// end of file

