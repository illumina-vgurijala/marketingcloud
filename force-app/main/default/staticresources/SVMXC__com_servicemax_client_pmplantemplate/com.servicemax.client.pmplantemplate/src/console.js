/**
 * PMPLAN console app
 * @author Manish
 * @copyright 2017 ServiceMax, Inc.
 */
(function() {

    var console = SVMX.Package("com.servicemax.client.pmplantemplate.console");

    console.init = function() {
        console.Class("ConsoleAppImpl", com.servicemax.client.sfmconsole.api.AbstractConsoleApp, {
            engine: null,
            __options: null,

            start: function(options) {
                options = options || {};

                this.__options = options;

                this.showLoadMask();

                var engine = SVMX.create("com.servicemax.client.pmplantemplate.engine.DeliveryEngineImpl");
                this.engine = engine.getInterface();

                this.engine.initAsync({
                    handler: this.__onEngineInit,
                    context: this
                });
            },

            __onEngineInit: function() {
                this.engine.run({
                    onReady: {
                        handler: this.__onEngineReady,
                        context: this
                    }
                });
            },

            __onEngineReady: function() {
                this.setRootContainer(this.engine.getRoot());
                this.hideLoadMask();

                this.setAppInfo({
                    groupName: '',
                    windowTitle: this.engine.translate("TAG0002")
                });
            },

            onClose: function() {

            },

            onAppHide: function(event) {
                // TODO: got to sleep
            },

            // On waking up, refresh all showing search results
            onAppShow: function(event) {
                // TODO: wake up
            },

            // On reset, refresh all searches and either clear all searches or refresh all searches
            reset : function() {
                if (this.engine) {
                    this.engine.reset();
                }
            },

            onAppResize: function(event) {
                if (this.engine.getRoot()) {
                    this.engine.getRoot().resize(event);
                }
            }

        }, {});

    };
})();
