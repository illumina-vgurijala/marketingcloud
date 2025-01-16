// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplan\src\commands.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplan.commands");

	impl.init = function(){

	    impl.Class("ChangeAppState", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            request.deliveryEngine.changeApplicationState(request.state);
	        }
	    }, {});

	    impl.Class("GetPMPlanData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_PMPLAN_DATA"});
	        }
	    }, {});

	    impl.Class("GetPMTemplateData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_PMTEMPLATE_DATA"});
	        }
	    }, {});

	    impl.Class("SavePMPlanData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.SAVE_PMPLAN_DATA"});
	        }
	    }, {});

	    impl.Class("GetCoverageScheduleData", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_COVERAGE_SCHEDULE_DATA"});
	        }
	    }, {});

	    impl.Class("GetCoverageTechnicalAtt", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.GET_COVERAGE_TECHNICAL_ATTRIBUTE"});
	        }
	    }, {});

	    impl.Class("ValidateExpression", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.VALIDATE_EXPRESSION"});
	        }
	    }, {});

	    impl.Class("SearchObject", com.servicemax.client.mvc.api.Command, {
	        __constructor : function(){ this.__base(); },

	        executeAsync : function(request, responder){
	            this._executeOperationAsync(request, responder, {operationId : "PMPLAN.OBJECT_SEARCH"});
	        }
	    }, {});
	};

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplan\src\engine.js
(function() {
    var engine = SVMX.Package("com.servicemax.client.pmplan.engine");

    engine.init = function() {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");
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
                this.__eventBus = SVMX.create("com.servicemax.client.pmplan.impl.PMPLANEngineEventBus", {});

                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                                ni.createNamedInstanceAsync("PMPLAN.VIEW",{ handler : function(view){
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
                //----Start-----Added for the story BAC-3268 to translate Date and DateTime component language based on user language by calling below event
                var userInfo = SVMX.toObject(SVMX.getClient().getApplicationParameter('svmx-pmplan-userinfo'));
                var client = SVMX.getClient();
                var evtUserInfo = SVMX.create('com.servicemax.client.lib.api.Event', 'GLOBAL.HANDLE_USER_INFO', this, userInfo);
                client.triggerEvent(evtUserInfo);
                //----End-----Added for the story BAC-3268 to translate Date and DateTime component language based on user language by calling below event
                
                this.changeApplicationState("block");
                this.options = options || {};
                this.__planId = SVMX.getUrlParameter('pmPlanId');
                this.__sourceId = SVMX.getUrlParameter('sourceId');
                this.__mode = SVMX.getUrlParameter('mode');
                
                var config = {};
                config.pmPlanId = this.__planId;
                config.sourceId = this.__sourceId;
                config.mode = this.__mode; 
                
                // On page load, if plan Id is present then, retrieve PM Plan record details and populat the values
                // Always retriev values for Plan Template, Service/Maintenance Contract, Account, SLA terms 

                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.GET_PMPLAN_DATA", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.GetPMPlanData", this)
                }); 
                this.triggerEvent(evt);
            }, 

            onGetPMPlanDataCompleted: function(data){
                this.changeApplicationState("unblock");
                this.__pmplanData = data; 
                this.__metaModel = SVMX.create("com.servicemax.client.pmplan.engine.PMPLANMetaModel", this, data);
                this.__root = this.__view.createComponent("ROOTCONTAINER", {
                    deliveryEngine: this, __engine: this
                });
                this.__root.render(SVMX.getDisplayRootId());
            },

            searchObject: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.OBJECT_SEARCH", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.SearchObject", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onSearchObjectCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            getPMTemplateData: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.GET_PMTEMPLATE_DATA", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.GetPMTemplateData", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onGetPMTemplateData: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            savePMPlan: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.SAVE_PMPLAN_DATA", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.SavePMPlanData", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onSavePMPlanCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            getCoverageScheduleData: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.GET_COVERAGE_SCHEDULE_DATA", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.GetCoverageScheduleData", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onGetCoverageScheduleDataCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            getCoverageTechnicalAtt: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.GET_COVERAGE_TECHNICAL_ATTRIBUTE", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.GetCoverageTechnicalAtt", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onGetCoverageTechnicalAttCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            validateExpression: function(config, callback){
                this.changeApplicationState("block");
                evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "PMPLAN.VALIDATE_EXPRESSION", this, {
                    request: config, 
                    responder: SVMX.create("com.servicemax.client.pmplan.responders.ValidateExpression", this, callback)
                }); 
                this.triggerEvent(evt);
            },

            onValidateExpressionCompleted: function(data, callback){
                this.changeApplicationState("unblock");
                callback && callback(data);
            },

            getAccount: function(){
                 // Update Account
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.accountList != null){
                    return this.__pmplanData.pmPlanRecord.accountList;
                }else{
                    return [];   
                }
            },

            getServiceContract: function(){
                // Update Service Contract
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.serviceContractList != null){
                    return this.__pmplanData.pmPlanRecord.serviceContractList;
                }else{
                    return [];   
                }
            },

            getCoverageType: function(){
                 // Update SLA picklist
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.coverageType != null){
                    return this.__pmplanData.pmPlanRecord.coverageType;
                }else{
                    return [];   
                }
            },

            getScheduleType: function(){
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.scheduleType != null){
                    return this.__pmplanData.pmPlanRecord.scheduleType;
                }else{
                    return [];   
                }
            },

            getSLAlist: function(){
                 // Update SLA picklist
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.slaList != null){
                    return this.__pmplanData.pmPlanRecord.slaList;
                }else{
                    return [];   
                }
            },

            getLocationlist: function(){
                 // Update SLA picklist
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.locationList != null){
                    return this.__pmplanData.pmPlanRecord.locationList;
                }else{
                    return [];   
                }
            },

            getPMTemplatelist: function(){
                // Update PM template List
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.pmTemplateList != null){
                    return this.__pmplanData.pmPlanRecord.pmTemplateList;
                }else{
                    return [];   
                }    
            },

            getWOPurposelist: function(){
               if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.woPurposeList != null){
                    return this.__pmplanData.pmPlanRecord.woPurposeList;
                }else{
                    return [];   
                }  
            },

            getActivityDateList: function(){
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.activityDateList != null){
                    return this.__pmplanData.pmPlanRecord.activityDateList;
                }else{
                    return [];   
                }  
            },

            getCovergaeList: function(){
                if(this.__pmplanData.success && this.__pmplanData.pmPlanRecord.coverageList != null){
                    return this.__pmplanData.pmPlanRecord.coverageList;
                }else{
                    return [];   
                }  
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

        engine.Class("PMPLANMetaModel", com.servicemax.client.lib.api.Object, {
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplan\src\impl.js

(function(){

	var impl = SVMX.Package("com.servicemax.client.pmplan.impl");

	impl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("APP-IMPL");
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        	com.servicemax.client.pmplan.commands.init();
        	com.servicemax.client.pmplan.responders.init();
        	com.servicemax.client.pmplan.engine.init();
        },

        afterInitialize: function() {
        }

	}, {
		instance : null
	});

	impl.Class("PMPLANEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
	       __constructor: function() {
	           this.__base();
	       },

	       triggerEvent: function(e) {
	           SVMX.getLoggingService().getLogger("PMPLANEngineEventBus").info("Trigger event : " + e.type);
	           return this.__base(e);
	       }

	   }, {});
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.pmplan\src\responders.js

(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplan.responders");

	
    impl.init = function(){ 
		impl.Class("GetPMPlanData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine) { 
				this.__engine = engine;
				this.__base(); 

			},

			result : function(data) {
				this.__engine.onGetPMPlanDataCompleted(data);
			}
		}, {});

		impl.Class("GetPMTemplateData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetPMTemplateData(data, this.__callback);
			}
		}, {});

		impl.Class("SearchObject", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onSearchObjectCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("SavePMPlanData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onSavePMPlanCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("GetCoverageScheduleData", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetCoverageScheduleDataCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("GetCoverageTechnicalAtt", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onGetCoverageTechnicalAttCompleted(data, this.__callback);
			}
		}, {});

		impl.Class("ValidateExpression", com.servicemax.client.mvc.api.Responder, {
			__constructor : function(engine, callback) { 
				this.__engine = engine;
				this.__base(); 
				this.__callback = callback;
			},

			result : function(data) {
				this.__engine.onValidateExpressionCompleted(data, this.__callback);
			}
		}, {});
	};

})();

