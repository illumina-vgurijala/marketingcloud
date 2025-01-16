/**
 * This package contains the sfmconsole toolbar configuration.
 * Currently only the user context menu api is implemented
 *
 * @class com.servicemax.client.sfmconsole.engine
 * @singleton
 * @author Boonchanh Oupaxay
 *
 * @copyright 2013 ServiceMax, Inc.
 */
;(function(){
    var consoleEngine = SVMX.Package("com.servicemax.client.sfmconsole.engine");
    var TS = null;
    /**
     * Package initialization
     *
     * @method  init
     */
    consoleEngine.init = function(){
    	var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("IPAD");
        /**
    	 * This console toolbar NamedInstance
    	 *
    	 * @class  com.servicemax.client.sfmconsole.engine.ConsoleToolbarNameInstance
    	 * @extend com.servicemax.client.runtime.api.AbstractNamedInstance
    	 */
        consoleEngine.Class("ConsoleToolbarNameInstance", com.servicemax.client.runtime.api.AbstractNamedInstance, {
            __menuitems: null,
            __app: null,
    		__constructor : function(){
    	        this.__menuitems = [];
                TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation");
    		},

            /*
             *
             */
            __processMenuItem: function(item){
                var hash = {
                    title: "text",
                    "icon-class": "iconCls",
                };

                //create the click event handler object
                if (!!item.handler) {
                    if (SVMX.typeOf(item.handler) != "function") {
                        var that = this;
                        var eventClassObject = SVMX.create(item.handler);

                        //processor object
                        item.processor = eventClassObject;

                        //click event handling
                        item.handler = function(){
                            eventClassObject.eventHandler.call(this, {
                                application: that.__app
                            });
                        }
                    }
                }

                var config = {};
                for (var idx in item) {
                    //check if the attribute is an object
                    if (!hash[idx]) {
                        config[idx] = item[idx];
                    } else {
                        config[hash[idx]] = item[idx];
                    }
                }

                return config;
            },

    		/**
    		 *
    		 * @method
    		 * @param     (String)    name        Namedinstance name
    		 * @param     (Object)    data        configuration data object {module.json}
    		 * @param     (Object)    params      additional parameters
    		 */
            initialize: function(name, data, params){
                if (!this.__app) {
                    if (!!params && !!params.application) {
                        this.__app = params.application;
                    } else {
                        this.__app = SVMX.getCurrentApplication();
                    }
                }

                for (var i=0; i < data.length; i++) {
                    var items = data[i].data;
                    for (var k=0; k < items.length; k++) {
                        var item = this.__processMenuItem(items[k]);
                        this.__menuitems.push(item);
                    }
                }
                return this;
            },

            /**
             * @method
    		 * @return     (Array)    processed menu items
    		 */
            getMenuConfigItems: function() {
                return this.__menuitems;
            }

    	}, {});

        /**
    	 * Abstract toolbar menu item handler
    	 *
    	 * @class  com.servicemax.client.sfmconsole.engine.AbstractConsoleToolbarMenuItem
    	 * @extend com.servicemax.client.runtime.api.Object
    	 */
        consoleEngine.Class("AbstractConsoleToolbarMenuItem", com.servicemax.client.runtime.api.Object, {
        	__constructor: function(){
                return null
            },

            /**
             * use by the processMenuItem method to do the translation
             */
            __translateMenuItem: function(item) {
                var defer = $.Deferred();
                //var collection = this.__findTagModules(item);

                for (var idx in item) {
                    item[idx] = this.__translateItems(idx, item[idx]);
                }

                defer.resolve();
                return defer;
            },

            /*
             * checks the items to see if translation is needed,
             * only items is the checkhash are valid
             */
            __translateItems: function(idx, item) {
                var tservice = TS;
                var checkhash = {
                    title: true,
                    tooltip: true,
                    text: true,
                    displayText: true ,
                    path: true
                };

                if (checkhash[idx]) {
                    if (SVMX.typeOf(item) == "Object") {
                        if (idx == "path") {
                            return this.__translatePathObject(item);
                        } else {
                            return tservice.T(item.module+'.'+item.tag, item.text);
                        }
                    } else {
                        return item;
                    }
                }

                return item;
            },

            /*
             * translate the path object
             */
            __translatePathObject: function(item) {
                var tservice = TS;
                var textcollection = item.text.split("/");
                var tagcollection =  item.tag.split("/");
                var finalcollection = [];

                for (var i=0; i < tagcollection.length; i++) {
                    finalcollection.push(tservice.T(item.module+'.'+tagcollection[i], textcollection[i]));
                }

                return finalcollection.join("/");
            },
            /*
             * check to see if a value exist in an array
             */
            __isValueExist: function(collection, value) {
                for (var i=0; i < collection.length;i++) {
                    if (collection[i] == value) {
                        return true;
                    }
                }

                return false;
            },

            /**
             * Default event handler emthod
             *
             * @method
    		 * @param     (Object)    data    additional parameters
    		 * @return    (Object)    namedinstance object
    		 */
    		eventHandler: function(data){
                return null;
            },

            /**
             * use by the handler to add the menu item
             * @method
    		 * @param       (Object)        sfmconsole      sfmconsole toolbar reference
             * @param       (Object)        item            menu item config object
             * @param       (Object)        callback        optional callback
    		 */
            translateMenuItem: function(sfmconsole, item, callback) {
                this.__translateMenuItem(item)
                    .done(function(){
                        //sfmconsole.addConsoleMenuItem(item);
                        callback();
                    });
            }

    	}, {});
    };
})();
