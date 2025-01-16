(function() {
    var engine = SVMX.Package("com.servicemax.client.appointment.engine");

    engine.init = function() {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("APPOINTMENT");
        engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
            __metaModel: null,
            __root: null,
            __loadMask: null,
            __isContainerExternal: null,
            __parent: null,
            __translation: null,
            __view: null,
			__appointmentSettings: null,
            __workOrderDetailInfo: null,
            __offerAppointmentsInfo: null,			
            __constructor: function() {
                this.__base();
                this.__isContainerExternal = false;
            },

            initAsync: function(options) {
                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
                this.__eventBus = SVMX.create("com.servicemax.client.appointment.impl.APPOINTMENTEngineEventBus", {});

                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                                ni.createNamedInstanceAsync("APPOINTMENT.VIEW",{ handler : function(view){
                                    this.__view = view;
                                    options.handler.call(options.context);
                                }, context: this, additionalParams: {eventBus: this.getEventBus()}});
                            },
                            context: this
                        });
                    },
                    context: this,
                    additionalParams: {
                        eventBus: this.__eventBus
                    }
                });
            },

            getEventBus: function() {
                return this.__eventBus;
            },

            translate: function(key) {
                return TS.T(key);
            },

            getAllTranslation: function() {
                return this.__translation;
            },

            __appCurrentState: "",
            changeApplicationState: function(newState) {
                if (this.__appCurrentState === newState) return;

                this.__appCurrentState = newState;
                if (newState == "block") {
                    if (!this.__loadMask) {
                        this.__loadMask = new com.servicemax.client.ui.components.utils.LoadMask({
                            parent: this.__root
                        });
                    }
                    this.__loadMask.show({});
                    this.__loadMask.setZIndex(50000);
                } else if (newState == "unblock" && this.__loadMask !== null) {
                    if (this.__loadMask !== null) {
                        this.__loadMask.hide();
                    }
                }
            },

            reset: function() {
                this.getRoot().destroy();
                this.__root = null;
                this.run(this.options);
            },

            triggerEvent: function(evt) {
                this.__eventBus.triggerEvent(evt);
            },

            run: function(options) {
                this.changeApplicationState("block");
                this.options = options || {};
				var workOrderId = SVMX.getUrlParameter('id');
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "APPOINTMENT.GET_APPOINTMENT_SETTINGS", this, {
                    request: {headerId: workOrderId}, 
                    responder: SVMX.create("com.servicemax.client.appointment.responders.GetAppointmentSettings", this)
                }); 
                this.triggerEvent(evt);
            }, 
			
			onGetAppointmentSettingsCompleted: function(data){
                this.changeApplicationState("unblock");
				if(!data.success) {
					SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(data.messageList[0]), 300000, 'success');
				}
                this.__appointmentSettings = data.appointmentSettings;
                var workOrderId = SVMX.getUrlParameter('id');

                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "APPOINTMENT.GET_WORKDETAILS", this, {
                    request: {headerId: workOrderId}, 
                    responder: SVMX.create("com.servicemax.client.appointment.responders.GetWorkDetails", this)
                });

                this.triggerEvent(evt);
            },
            getAppointmentSettings: function(){
                return this.__appointmentSettings;
            },

            setAppointmentSettings: function(settingValues){
                this.__appointmentSettings = settingValues;
            },

            onGetWorkDetailsCompleted: function(data, callback){
                this.changeApplicationState("unblock");   
                this.__workOrderDetailInfo = data;
                this.__metaModel = SVMX.create("com.servicemax.client.appointment.engine.APPOINTMENTMetaModel", this, data);
                this.__root = this.__view.createComponent("ROOTCONTAINER", {
                    deliveryEngine: this, __engine: this
                });
                this.__root.render(SVMX.getDisplayRootId());
                callback && callback(data);
            },

            getWorkOrderDetailInfo: function(){
                return this.__workOrderDetailInfo;
            },

            bookAppointment: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "APPOINTMENT.BOOK_APPOINTMENT", this, {
                    request:config, 
                    responder: SVMX.create("com.servicemax.client.appointment.responders.BookAppointment", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            /*startOptimaxJob: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "APPOINTMENT.START_OPTIMAX_JOB", this, {
                    request:config, 
                    responder: SVMX.create("com.servicemax.client.appointment.responders.StartOptimaxJob", this, callback)
                }); 
                this.triggerEvent(evt);
            },*/

            onBookAppointmentCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            /*onStartOptimaxJobCompleted: function(data, callback){
                this.changeApplicationState("unblock");				
				if(!data.success) {
					SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(data.messageList[0]), 300000, 'success');
				}
                callback && callback(data);
            },*/
            getOfferAppointmentsInfo: function(){
                return this.__offerAppointmentsInfo;
            },

            setOfferAppointmentsInfo: function(offerAppointments){
                this.__offerAppointmentsInfo = offerAppointments;
            },		

            getOfferAppointments: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "APPOINTMENT.GET_OFFER_APPOINTMENTS", this, {
                    request:config, 
                    responder: SVMX.create("com.servicemax.client.appointment.responders.GetOfferAppointments", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onGetOfferAppointmentsCompleted: function(data, callback){
                this.changeApplicationState("unblock");				
				if(!data.success) {
					SVMX.getCurrentApplication().getApplicationQuickMessageHandler().showQuickMessage(Ext.String.htmlEncode(data.messageList[0]), 15000, 'success');
				}
				__offerAppointmentsInfo = data.headerRecord;
                callback && callback(data);
            },

            getMetaModel: function(){
                return this.__metaModel;
            },

            getRoot: function() {
                return this.__root;
            },

            onResize: function(size) {
                this.getRoot().resize(size);
            }
        }, {});

        engine.Class("APPOINTMENTMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null, __data: null, 
            __processDetails: {},
            __defaults: {},
			__appointmentSettings: {},

            __constructor: function(engine, data) {
                this.__parent = engine;
                this.__data = data;
            },
			
			getAppointmentSettings: function(){
                return this.__appointmentSettings;
            },

            destroy: function() {
                this.__data = null;
            }
        }, {});
    };
})();