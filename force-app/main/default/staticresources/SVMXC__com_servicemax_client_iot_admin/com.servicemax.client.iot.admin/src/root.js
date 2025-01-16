(function() {
    var root = SVMX.Package("com.servicemax.client.iot.admin.root");

    root.init = function() {
        Ext.define("com.servicemax.client.iot.admin.root.RootPanel", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            metadata: null,
            __spinner: null,
            constructor: function(config) {
                var me = this;

                config = config || {};
                config.renderTo = SVMX.getDisplayRootId();
                config.title = "<span class='title-text'>" + $TR.IOT_SETUP + "</span>";
                metadata = config.metadata;

                var otherSettings = SVMX.create('com.servicemax.client.iot.admin.OtherSettings', {
                    metadata: metadata
                });
                var iotEventMap = SVMX.create('com.servicemax.client.iot.admin.ioteventmap', {
                    metadata: metadata
                });

                var compositeKey = SVMX.create('com.servicemax.client.iot.admin.CompositeKey', {
                    metadata: metadata
                });

                var tabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel', {
                    height: 465,
                    tabPosition: 'left',
                    tabRotation: 0,
                    cls: 'iot-setup-tab-body',
                    tabBar: {
                        border: false,
                        cls: 'iot-setup-left-nav'
                    },
                    margin: '4 4 0 4',
                    ui: 'setup-tabpanel',
                    defaults: {
                        textAlign: 'left',
                        bodyPadding: 7,
                        cls: 'iot-setup-content-body',
                    }
                });
                tabPanel.add(iotEventMap);
                tabPanel.add(compositeKey);
                tabPanel.setActiveTab("EM");
                var saveButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.SAVE,
                    cls: 'iot-setup-save',
                    handler: function() {
                        me.save(compositeKey, iotEventMap);
                    }
                });

                var closeButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.BACK_TO_SETUP_HOME,
                    cls: 'iot-setup-back-to-home',
                    docked: 'left',
                    rigion: 'left',
                    align: 'left',
                    handler: function() {
                        //me.backToSetupHome();
                        //Added for the story BAC-4797
                        var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup";
                            sforce.one.navigateToURL(urlString);
                        }
                        else{
                            window.location.href = urlString;
                        }
                    }
                });

                var tools = [closeButton];
                config.tools = tools;

                var saveCloseButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.CANCEL,
                    cls: 'iot-setup-cancel',
                    handler: function() {
                        window.location.reload();
                    }
                });


                var toolBarItems = ['->', saveButton, saveCloseButton];
                var savencloseToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                    style: 'border-top-width: 0 !important',
                    cls: 'iot-setup-profile-selection',
                    dock: 'top',
                    items: toolBarItems

                });


                config.items = [];
                config.items.push(savencloseToolbar);
                config.items.push(tabPanel);
                this.callParent([config]);
            },
            backToSetupHome: function() {
                this.blockUI();
                var me = this;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "IOT.BACK_TO_SETUP_HOME", me, { request: { context: me } });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            save: function(compositeKey, events) {
                var me = this;
                var shouldAllowSave = me.__shouldAllowSave(events);
                if (!shouldAllowSave.isValid) {
                    SVMX.getCurrentApplication().showQuickMessage('error', shouldAllowSave.message);
                } else {
                    me.blockUI();
                    var recs = events.getData();
                    var keys = compositeKey.getData();
                    var mappingRecs = events.getMappingRecords();
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "IOT.SAVE", me, {
                            request: {
                                context: me,
                                events: recs.data,
                                deletedEvents: recs.deletedEvents,
                                compositeKey: keys,
                                objectMapEvents: mappingRecs.data,
                                deletedObjectMap: mappingRecs.deletedEventMapIds
                            }
                        });
                    SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
                }
            },
            __shouldAllowSave: function(events) {
                return events.shouldSave();
            },
            onSaveComplete: function(data) {
                this.unblockUI();
                metadata = data;
                this.dataSavedSucessfullyMessage();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "SAVE_SUCCESS", this, data);
                SVMX.getClient().triggerEvent(evt);

            },

            dataSavedSucessfullyMessage: function(msg) {
                var messageToShow = $TR.SAVE_SUCCESS; //"Data Saved Successfully.";
                if (msg)
                    messageToShow = msg;

                var mb = Ext.Msg.alert({
                    title: $TR.INFO,
                    msg: messageToShow,
                    closable: false,
                    buttonText: { ok: $TR.OK },
                    fn: function(btn) {} // singleton
                });

            },

            blockUI: function() {
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
                    zIndex: 2e9 // The z-index (defaults to 2000000000)
                };

                this.__spinner = new Spinner(opts).spin($("#" + SVMX.getDisplayRootId())[0]);
            },

            unblockUI: function() {
                this.__spinner.stop();
            }
        });

    }

})();