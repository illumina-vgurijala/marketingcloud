/**
 * # Package #
 * This package provides the profiling features for the framework.
 *
 * @class com.servicemax.client.profiler.impl
 * @singleton
 * @author Boonchanh Oupaxay
 *
 * @copyright 2014 ServiceMax, Inc.
 */
;(function($){
    "use strict";

    var profilerImpl = SVMX.Package("com.servicemax.client.profiler.impl");

    /**
     * Profiler module activator class
     */         
    profilerImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor : function(){
            this.__base();
            this.__profiler = SVMX.getProfilingService();

            // register with the READY client event
            SVMX.getClient().bind("READY", this.__onClientReady, this);
            $("#client_display_root").ready(function(){
                console.log("ready");
            });
        },

        /**
         * Client ready handler
         * @private         
         */                 
        __onClientReady : function(){
            this.__init();
        },

        /**
         * Initailize the UI when the client is ready
         * @private         
         */                 
        __init: function() {
            //1) unbind the ready
            SVMX.getClient().unbind("READY", this.__onClientReady, this);

            //2) build the container
            var ui = SVMX.create("com.servicemax.client.profiler.api.ProfilerConsole");
            var config = {
                id: "profiler_panel",
                baseCls: "x-panel",
                title: "ServiceMax Profiler Console"
            };

            ui.init(config);
        },

        /**
         * Load the profiler api class and support methods
         */                 
        beforeInitialize : function(){
            com.servicemax.client.profiler.api.init();
        },
        initialize : function(){},
        afterInitialize : function(){}
    }, {});
    
    
})(jQuery);