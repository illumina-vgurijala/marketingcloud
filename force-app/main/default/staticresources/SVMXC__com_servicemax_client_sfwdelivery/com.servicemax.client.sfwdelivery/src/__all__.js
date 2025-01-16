// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfwdelivery\src\commands.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfwdelivery.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfwCommands = SVMX.Package("com.servicemax.client.sfwdelivery.commands");

	sfwCommands.init = function(){

		sfwCommands.Class("GetWizardInfo", com.servicemax.client.mvc.api.Command, {

		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFWDELIVERY.GET_WIZARD_INFO"});
		}
	}, {});

};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfwdelivery\src\engine.js
    /**
 * SFW delivery engine
 * @class com.servicemax.client.sfwdelivery.engine
 * @author Jon Kinsting
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

    var engine = SVMX.Package("com.servicemax.client.sfwdelivery.engine");

engine.init = function(){
    // imports
    var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFWDELIVERY");


    engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {
        __logger : null,
        __root : null,
        __eventBus : null,
        __dataModel : null,
        __loadMask : null,
        __translation : null,
		__view : null,
        __getRecord : null, // Optionally provided by the invoker to avoid having to requery for the record data
        __constructor : function(){
            this.__base();
            this.__logger = SVMX.getLoggingService().getLogger("SFW-ENGINE-IMPL");
        },

        initAsync : function(options){
            if (options.getRecord) {
                this.__getRecord = SVMX.proxy(options.context, options.getRecord);
            }
            var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();

            // create the named default controller
            ni.createNamedInstanceAsync("CONTROLLER",{ handler : function(controller){

                // now create the named default model
                ni.createNamedInstanceAsync("MODEL",{ handler : function(model){
                    controller.setModel(model);

                     ni.createNamedInstanceAsync("SFWDELIVERY.VIEW",{ handler : function(view){
                        this.__view = view;
                        options.handler.call(options.context);
                    }, context: this, additionalParams: {eventBus: this.getEventBus()}});

                }, context : this});

            }, context : this, additionalParams : { eventBus : this.getEventBus() }});

        },

        getEventBus : function(){
            if(!this.__eventBus) {
                this.__eventBus = SVMX.create("com.servicemax.client.sfwdelivery.impl.SFWDeliveryEngineEventBus", {});
            }
            return this.__eventBus;
        },

        getDataModel : function(){
            if(!this.__dataModel){
                this.__dataModel = SVMX.create("com.servicemax.client.sfwdelivery.engine.WizardInfoModel", this);
            }
            return this.__dataModel;
        },

        getRoot : function(){
            return this.__root;
        },

        // WARNING: Those who create this engine expect it to load synchronously, not asynchronously.
        // TAGS are preloaded in offline version; make sure they are preloaded in online version before using.
        // Probably best just to load an empty tag structure synchronously until then.
        run : function(options){
            this.__logger.debug("Wizard is running!!!");
            this.options = options || {};

            this.__root = this.__view.createComponent("ROOTCONTAINER", {
                deliveryEngine : this,
                dataModel : this.getDataModel(),
                msgInit : this.options.msgInit,
                msgEmpty : this.options.msgEmpty
            });

            // onReady indicates root would be rendered/added by parent
            if(this.options.onReady == null){
                this.__root.render(SVMX.getDisplayRootId());
                this.options.recordId = SVMX.getUrlParameter("RecordId");
                if (!SVMX.getClient().getApplicationParameter("svmx-sfm-no-window-resize")) {
                    SVMX.onWindowResize(function(){
                        var size = {
                            width : Ext.getBody().getViewSize().width,
                            height : Ext.getBody().getViewSize().height
                        };
                        this.onResize(size);
                    }, this);
                }
            }

            if(this.options.recordId){
                this.update(this.options.recordId);
            } else if(this.options.onReady){
                this.options.onReady.handler.call(this.options.onReady.context || this);
            }
        },

        translate : function(key){
            var ret = this.__translation[key];
            if(ret === undefined) ret = key;

            return ret;
        },

        reload : function() {
            this.update(this.options.recordId, this.options.objectName);
        },


        update : function(recordId, objectName){
            if(!recordId) return;

            this.options.recordId = recordId;
            this.options.objectName = objectName;

            var supportedActionTypes = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.sfw.platformspecifics").getInstance().getSupportedActionTypes();

            // get wizard data
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "SFWDELIVERY.GET_WIZARD_INFO", this, {
                        request : {
                            RecordId : recordId,
                            Record : this.__getRecord ? this.__getRecord() : null, // optional
                            objectName : objectName,
                            ActionTypes : supportedActionTypes
                        },
                        responder : SVMX.create("com.servicemax.client.sfwdelivery.responders.GetWizardInfoResponder", this)
                    }
            );
            if (this.getRoot()) this.getRoot().setSpinnerMsg();
            this.getEventBus().triggerEvent(evt);
        },

        /**
         * Clears the wizard panel of any content
         */
        clearContent : function() {
            var root = this.getRoot();
            if (root) root.clearMessagePanel();
        },

        /**
         * @event
         * @param   {data}
         */
        onGetWizardInfoCompleted: function(data){
            this.getDataModel().processData(data);
            if (this.getRoot()) {
                this.getRoot().run();
                if (data.SFWs.length) {
    			     this.getRoot().clearMessagePanel();
                }
            }

            if(this.options.onReady){
                this.options.onReady.handler.call(this.options.onReady.context || this);
            }

            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "DATA_LOADED", this, this.getDataModel());
            this.getEventBus().triggerEvent(evt);
        },

        /**
         * Handles the wizard data fetch fail event; sets the no data msg
         *
         * @event
         * @param   {data}
         */
        onGetWizardInfoFailed: function(error) {
            this.getRoot().setEmptyMsg();
        },

        onResize : function(size){
            if (this.getRoot()) {
                this.getRoot().resize( size );
            }
        }

    }, {});

    /**
     * Wizard Info Model
     */
    engine.Class("WizardInfoModel", com.servicemax.client.lib.api.Object, {
         __wizardModels : null, record: null, recordId : null, __deliveryEngine : null,
         availableActions : null,

         __constructor : function(deliveryEngine) {
            this.__deliveryEngine = deliveryEngine;
         },

         // Morph the very dense verbose 'data' object into a concise, easily accessed array //
         processData : function(data){          // data is expected OBJECT returned from APEX call
             this.recordId = data.RecordId;
             this.record = data.Record; // currently only exists in offline version.
             this.availableActions = data.availableActions || [];
             this.__wizardModels = [];

            // create wizard tab models
            for (var i = 0; i < data.SFWs.length; i++){
                this.__wizardModels[i] = SVMX.create("com.servicemax.client.sfwdelivery.engine.SFWDetailModel",
                        this, data.SFWs[i]);
            }
         },

         getWizards : function() {
// var emptyArr = [];   // to simulate a 'no data' condition
// return emptyArr;
             return this.__wizardModels;
         },

         getDeliveryEngine : function(){
            return this.__deliveryEngine;
         }

    }, {});

    /**
     * SFW wizard detail data model
     */
    engine.Class("SFWDetailModel", com.servicemax.client.lib.api.Object, {
        __parent : null, __data : null,
        __actionModels : [],
        __constructor : function(parent, data){
            this.__parent = parent;
            this.__data = data;

            // XSS protection
            if (this.__data.SFWDef[SVMX.OrgNamespace + "__Name__c"]) {
                this.__data.SFWDef[SVMX.OrgNamespace + "__Name__c"] = Ext.String.htmlEncode(this.__data.SFWDef[SVMX.OrgNamespace + "__Name__c"]);
            }

            var __theActionModels = [];
            for (var i = 0; i < data.actions.length; i++){
                __theActionModels[i] = SVMX.create("com.servicemax.client.sfwdelivery.engine.SFWActionModel",
                        this, data.actions[i]);
            }
            this.__actionModels = __theActionModels;
        },

        getId : function(){
            return this.__data.SFWDef.Id;
        },

        getName : function(){
            return this.__data.SFWDef[SVMX.OrgNamespace + "__Name__c"];
        },

        getActions : function(){
            return this.__actionModels;
        },

        getRoot : function(){
            return this.__parent;
        }
    }, {});

    /**
     * SFW wizard detail data model
     */
    engine.Class("SFWActionModel", com.servicemax.client.lib.api.Object, {
        __parent : null, __data : null,
        enabled : true,
        actionType : null, enableConfirmationDialog : false, modeOfExecution : null, handOver : false,
        confirmationMessage : null,

        __constructor : function(parent, data) {    // NOTE that data is an array
            this.__parent = parent;
            this.__data = data;

            // read action attributes
            if(data.Enabled === false) {
                this.enabled = false;
            }else{
                this.enabled = true;
            }

            // XSS protection
            if (this.__data.actionDef[SVMX.OrgNamespace + "__Name__c"]) {
                this.__data.actionDef[SVMX.OrgNamespace + "__Name__c"] = Ext.String.htmlEncode(this.__data.actionDef[SVMX.OrgNamespace + "__Name__c"]);
            }
            if (this.__data.actionDef[SVMX.OrgNamespace + "__Description__c"]) {
                this.__data.actionDef[SVMX.OrgNamespace + "__Description__c"] = Ext.String.htmlEncode(this.__data.actionDef[SVMX.OrgNamespace + "__Description__c"]);
            }
            if (this.__data.actionDef[SVMX.OrgNamespace + "__Confirmation_Message__c"]) {
                this.__data.actionDef[SVMX.OrgNamespace + "__Confirmation_Message__c"] = Ext.String.htmlEncode(this.__data.actionDef[SVMX.OrgNamespace + "__Confirmation_Message__c"]);
            }

            this.actionType = data.actionDef[SVMX.OrgNamespace + "__Action_Type__c"];
            this.customActionType = data.actionDef[SVMX.OrgNamespace + "__Custom_Action_Type__c"];
            this.enableConfirmationDialog = data.actionDef[SVMX.OrgNamespace + "__Enable_Confirmation_Dialog__c"];
            this.modeOfExecution = data.actionDef[SVMX.OrgNamespace + "__Mode_Of_Execution__c"];
            this.handOver = data.actionDef[SVMX.OrgNamespace + "__Handover__c"];
            this.confirmationMessage = data.actionDef[SVMX.OrgNamespace + "__Confirmation_Message__c"];
        },

        getId : function(){
            return this.__data.actionDef.Id;
        },

        getName : function(){
            return this.__data.actionDef[SVMX.OrgNamespace + "__Name__c"];
        },

        getData : function(){
            return this.__data;
        },

        getRoot : function(){
            return this.__parent.getRoot();
        }

    }, {});
};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfwdelivery\src\impl.js
/**
 * This file needs a description
 * @class com.servicemax.client.sfwdelivery.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfwImpl = SVMX.Package("com.servicemax.client.sfwdelivery.impl");

	sfwImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
			this._logger = SVMX.getLoggingService().getLogger("SFW-IMPL");
		},

		beforeInitialize : function(){
			com.servicemax.client.sfwdelivery.engine.init();
			com.servicemax.client.sfwdelivery.commands.init();
			com.servicemax.client.sfwdelivery.responders.init();
		},

		initialize : function(){
			// hack: force DEFAULT theme (temporary)
			/*var origMethod = SVMX.getUrlParameter;
			SVMX.getUrlParameter = function(name){
				if(name == 'theme'){
					return 'DEFAULT';
				}
				return origMethod(name);
			};*/
		},

		afterInitialize : function(){
		}

	});

	sfwImpl.Class("SFWDeliveryEngineEventBus", com.servicemax.client.lib.api.EventDispatcher, {
		__constructor : function(){ this.__base(); },

		triggerEvent : function(e) {
			SVMX.getLoggingService().getLogger("SFWDeliveryEngineEventBus").info("Trigger event : " + e.type);
			return this.__base(e);
		}

	}, {});

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfwdelivery\src\responders.js
/**
 * #package#
 * SFW delivery responders
 *
 * @class com.servicemax.client.sfwdelivery.responders
 * @author Jon Kinsting
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfwResponders = SVMX.Package("com.servicemax.client.sfwdelivery.responders");

sfwResponders.init = function(){

    /**
     * SFW delivery responders
     *
     * @class       com.servicemax.client.sfwdelivery.responders.GetWizardInfoResponder
     * @extends     com.servicemax.client.mvc.api.Responder
     * @author      Jon Kinsting
     * @copyright   2013 ServiceMax, Inc.
     */
	sfwResponders.Class("GetWizardInfoResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

        /**
         * Handles the success condition
         *
         * @param   {data}
         */
		result : function(data) {
			this.__parent.onGetWizardInfoCompleted( data );
		},

        /**
         * Handles the fault condition
         *
         * @param   {error}
         */
        fault : function(error) {
			this.__parent.onGetWizardInfoFailed( error );
		}

	}, {});


};
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sfwdelivery\src\wizarddata.js
/**
 * SFW (wizard) data
 * 
 * @author Jon Kinsting
 */
(function(){
	
	var wizardData = SVMX.Package("com.servicemax.client.sfwdelivery.wizarddata");
	
wizardData.init = function(){
	/**
	 * SFW model
	 */
	SVMX.define("com.servicemax.client.sfwdelivery.wizarddata.SFWData",{
		extend : 'com.servicemax.client.lib.api.Object',
		alias : 'widget.sfw.data',
//		eventModel : "com.servicemax.client.sfmeventdelivery.ui.sfmcalendar.EventModel",
//		userId : null,
		
		constructor : function(config){
//			this.__logger = SVMX.getLoggingService().getLogger('SFM-CALENDAR');
			
			this.callParent([config]);
		},
		
		initComponent : function(){
//			this.superclass.initComponent.call(this);
//			
//			// apply user id to new events
//			this.on('eventadded', function(data){
//				if(this.userId){
//					data.record.set({OwnerId : 'USER-'+this.userId});
//				}
//			});
		}
	});
};
})();

