/**
 * ServiceMax 
 * @class com.servicemax.client.featurepermission.api
 */
(function() {
    var appImpl = SVMX.Package("com.servicemax.client.featurepermission.api");
    appImpl.init = function() {

        appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication, {
            __constructor: function() {},

            beforeRun: function(options) {
                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();

                this.__eventBus = SVMX.create("com.servicemax.client.featurepermission.impl.EventBus", {});
                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                            },
                            context: this
                        });
                    },
                    context: this,
                    additionalParams: { eventBus: this.__eventBus }
                });
                options.handler.call(options.context);
            },

            getEventBus: function() {
                return this.__eventBus;
            },

            run: function() {
                this.getMetaData();
            },

            getMetaData: function() {
                this.blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "FEATUREPERMISSION.GET_META_DATA", this, {
                        request: {
                            context: this,
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },


            onGetMetaDataComplete: function(metaData) {
                var me = this;
                me.unblockUI();
                me.__processTranslations(metaData.translations);
                SVMX.create('com.servicemax.client.featurepermission.root.RootPanel', {
                    collapsible: false,
                    titleAlign: 'center',
                    frame: 'true',
                    metaData: metaData,
                    app: me
                });
            },
            __processTranslations: function(translationsArr) {
                var i, ilength = translationsArr.length;
                var translations = {};
                for (i = 0; i < ilength; i++) {
                    translations[translationsArr[i].Key] = Ext.String.htmlEncode(translationsArr[i].Text) ;
                }
                window.$TR = translations;
            },
            blockUI: function() {
                if (this.__spinner) {
                    this.__spinner.spin($("#" + SVMX.getDisplayRootId())[0]);
                } else {
                    var top = window.innerHeight / 2 - 100;
                    var opts = {
                        lines: 25, // The number of lines to draw
                        length: 25, // The length of each line
                        width: 5, // The line thickness
                        radius: 30, // The radius of the inner circle
                        corners: 1, // Corner roundness (0..1)
                        rotate: 0, // The rotation offset
                        direction: 1, // 1: clockwise, -1: counterclockwise
                        color: '#ffa384', // #rgb or #rrggbb or array of colors
                        speed: 3, // Rounds per second
                        trail: 60, // Afterglow percentage
                        shadow: false, // Whether to render a shadow
                        hwaccel: false, // Whether to use hardware acceleration
                        className: 'spinner', // The CSS class to assign to the spinner
                        zIndex: 2e9, // The z-index (defaults to 2000000000)
                        top: top
                    };
                    this.__spinner = new Spinner(opts).spin($("#" + SVMX.getDisplayRootId())[0]);
                }
            },

            unblockUI: function() {
                this.__spinner.stop();
            },
        });
    }

})();