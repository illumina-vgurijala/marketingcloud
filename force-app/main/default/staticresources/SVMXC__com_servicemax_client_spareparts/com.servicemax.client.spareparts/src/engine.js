(function() {
    var engine = SVMX.Package("com.servicemax.client.spareparts.engine");

    engine.init = function() {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPAREPARTS");
        engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
            __metaModel: null,
            __root: null,
            __loadMask: null,
            __isContainerExternal: null,
            __parent: null,
            __translation: null,
            __view: null,
             __constructor: function() {
                this.__base();
                this.__isContainerExternal = false;
            },

            initAsync: function(options) {
                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
                this.__eventBus = SVMX.create("com.servicemax.client.spareparts.impl.SPAREPARTSEngineEventBus", {});

                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                                ni.createNamedInstanceAsync("SPAREPARTS.VIEW",{ handler : function(view){
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
                var config = {};
                
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SPAREPARTS.GET_PROFILE_DATA", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.spareparts.responders.GetProfileData", this)
                }); 
                this.triggerEvent(evt);
            }, 

            onGetProfileDataCompleted: function(data){
                this.changeApplicationState("unblock");
                this.__profileData = null;
                
                if(data.success){
                    this.__profileData = data.profilelist;
                }

                this.__metaModel = SVMX.create("com.servicemax.client.spareparts.engine.SPAREPARTSMetaModel", this, data);
                this.__root = this.__view.createComponent("ROOTCONTAINER", {
                    deliveryEngine: this, __engine: this
                });
                this.__root.render(SVMX.getDisplayRootId());
    
            },

            getSparePartConfig: function(profileId, callback){
                this.changeApplicationState("block");
                var config = {};
                config.profileId = profileId;
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SPAREPARTS.GET_SPAREPART_CONFIG", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.spareparts.responders.GetSparePartConfig", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onGetSparePartConfigCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            saveSparePartConfig: function(config, callback){
                this.changeApplicationState("block");

                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SPAREPARTS.SAVE_SPAREPART_CONFIG", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.spareparts.responders.SaveSparePartConfig", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onSaveSparePartConfigCompleted: function(data, callback){
                this.changeApplicationState("unblock");
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

        engine.Class("SPAREPARTSMetaModel", com.servicemax.client.lib.api.Object, {
            __parent: null, __data: null, 
            
            __constructor: function(engine, data) {
                this.__parent = engine;
                this.__data = data;
            },

            destroy: function() {
                this.__data = null;
            }
        }, {});
    };
})();