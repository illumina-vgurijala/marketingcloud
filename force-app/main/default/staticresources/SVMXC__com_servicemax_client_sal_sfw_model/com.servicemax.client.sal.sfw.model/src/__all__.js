// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.sfw.model\src\impl.js
/**
 * This file needs a description
 * @class com.servicemax.client.sal.sfw.model.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var salModelImpl = SVMX.Package("com.servicemax.client.sal.sfw.model.impl");

	salModelImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		useJsr : false, __settings : null,

		__constructor : function(){
			this.__base();
			this.__self.instance = this;
			this.__logger = SVMX.getLoggingService().getLogger("SAL-SFW-MODEL");
		},

		beforeInitialize : function(){
			com.servicemax.client.sal.sfw.model.operations.init();
		},

		initialize: function(){
			// check if jsr should be used, only valid when running from web
			var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");

			if(useJsr && useJsr === true){
				this.useJsr = true;
				this.__logger.info("JSR is enabled. Will use this for server communication.");
			}
		},

		updateSettings : function(settings){
			this.__settings = {};

			var i , l = settings.length;
			for(i = 0; i < l; i++){
				this.__settings[settings[i].Key] = settings[i].Value;
			}
		},

		getSettings : function(){
			return this.__settings;
		}
	}, {
		instance : null
	});

	/**
	  * SFM wizard service request helper
	  */
	salModelImpl.Class("ServiceRequest", com.servicemax.client.lib.api.Object, {
		__constructor : function(params){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");

			servDef.getInstanceAsync({handler : function(service){
				var options = params.options || {};

				var p = {
						type : options.type || "REST",
						endPoint : options.endPoint || "SFMWizardDeliveryServiceIntf",
						nameSpace : (options.namespace === null ? null : SVMX.OrgNamespace)
				};
				var sm = service.createServiceManager(p);
				var sRequest = sm.createService();
				params.handler.call(params.context, sRequest);
			}, context : this});
		}
	}, {});

	salModelImpl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
		__logger : null,

		__constructor : function(){
			this.__logger = SVMX.getLoggingService().getLogger("SFW:Online:PlatformSpecifics");
		},

		getSupportedActionTypes : function(){
			return [];
		},

		performAction : function(action){
			var me = this, de = action.getRoot().getDeliveryEngine();
			if(action.confirmationMessage){
				// show confirmation dialog before proceeding
				SVMX.MessageBox.show({
		        	title : de.translate("SFW_TITLE"), buttons : SVMX.MessageBox.YESNO, icon : SVMX.MessageBox.QUESTION,
		        	buttonText : {yes : de.translate("SFW_YES_BTN"), no : de.translate("SFW_NO_BTN")}, msg : action.confirmationMessage,
		        	fn : function(btn){
		        		if(btn == 'yes'){
		        			me.__performAction(action);
		        		}
		        	}
		        });

			}else{
				this.__performAction(action);
			}
		},

		__performAction : function(action){
			var type = action.actionType;

			if(type == "SFM"){
				this.__performSFMAction(action);
			}else if(type == "RECEIPT"){
				this.__performRECEIPTAction(action);
			}else if(type == "DELIVERY"){
				this.__performDELIVERYAction(action);
			}else if(type == "PICK_MOVE"){
				this.__performPICKANDMOVEAction(action);
			}else if(type == "SHIP"){
				this.__performSHIPAction(action);
			}else if(type == "FULFILLMENT"){
				this.__performFULFILLMENTAction(action);
			}else if(type == "INVENTORY"){
				this.__performINVENTORYAction(action);
			}else if(type == "INITIATE_RETURN"){
				this.__performINITIATERETURNAction(action);
			}else if(type == "OUTPUT_DOCUMENT"){
				this.__performOUTPUTDOCUMENTAction(action);
			}else if(type == "OTHERS"){
				this.__performOTHERSAction(action);
			}else{
				this.__performUnknownAction(action);
			}
		},

		__performOTHERSAction : function(action){
			// TODO;
			var data = action.getData();
			var type = data.customActionRecord[SVMX.OrgNamespace + "__Custom_Action_Type__c"];
			var targetUrl = new salModelImpl.TargetUrl(action);
			var page = data.customActionRecord[SVMX.OrgNamespace + "__Target_URL__c"];

			// set up params
			var params = data.customActionParams || [], i, l = params.length;
			for(i = 0; i < l; i++){
				targetUrl.addParam(params[i].key, params[i].value);
			}
			// end params

			if(type == "URL"){
				// nothing more
			}else if(type == "Web-Service"){
				// TODO:
				var title = data.customActionRecord[SVMX.OrgNamespace + "__Name__c"];
				targetUrl.addParam("SVMX_title", title);
				var processId = data.customActionRecord[SVMX.OrgNamespace + "__ProcessID__c"];
				targetUrl.addParam("SVMX_processId", processId);
				page = this.__getPageUrl("SFM_ExecuteAPEX");
			}

			this.__navigate(page, targetUrl);
		},

		__performOUTPUTDOCUMENTAction : function(action){
			this.__logger.info("Performing OUTPUT_DOCUMENT action => " + action.getName());
			var page = this.__getPageUrl("OPDOC_Delivery"), targetUrl = null, de = action.getRoot().getDeliveryEngine();

			var selectTplAtRuntime = action.getData()
				.actionDef[SVMX.OrgNamespace + "__Select_Template_At_Runtime__c"], me = this;
			if(selectTplAtRuntime === true){
				getUserSelection(function(selection){
					targetUrl = new salModelImpl.TargetUrl(action, {SVMX_processId : selection.pid});
					targetUrl.addProcessId();
					targetUrl.addRecordId();
					targetUrl.addReturnUrl();
					me.__navigate(page, targetUrl);
				});
			}else{
				targetUrl = new salModelImpl.TargetUrl(action);
				targetUrl.addProcessId();
				targetUrl.addRecordId();
				targetUrl.addReturnUrl();
				this.__navigate(page, targetUrl);
			}

			function getUserSelection(callback){
				var actions = action.getRoot().availableActions, i , l = actions.length,
					validActions = [];
				for(i = 0; i < l; i++){
					if(actions[i][SVMX.OrgNamespace + "__Purpose__c"] == "OUTPUT DOCUMENT"){
						validActions.push({
							pid   : actions[i][SVMX.OrgNamespace + "__ProcessID__c"],
							name  : actions[i][SVMX.OrgNamespace + "__Name__c"],
							desc  : actions[i][SVMX.OrgNamespace + "__Description__c"]
						});
					}
				}

				var win = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXWindow", {
					width : 500, height : 300, modal : true, resizable : false,
					title : de.translate("CONF016_TAG113"),
					items : [
					    {	xtype : "svmx.listcomposite", height : 240, store : {xtype : "svmx.store", fields : ['name'], data : validActions},
					    	columns: [{ text: '',  dataIndex: 'name', flex : 1 }],
					    	viewConfig: {emptyText : de.translate("CONF016_TAG115"), deferEmptyText: false},
			    	        listeners : {
			    	        	itemdblclick : function(dataview, record, item, index, e) {
			    	        		callback(record.raw);
			    	        		win.close();
			    	        	}
			    	        }
					    }
					],
					dockedItems : [
					    {
					    	xtype : "svmx.toolbar", dock : "bottom",
					    	items : [
					    	    { xtype: 'tbfill' },
					    	    { xtype : "svmx.button", text : de.translate("CONF016_TAG114"), handler : function(){
					    	    		var lst = win.items.getAt(0);
					    	    		var selected = lst.getSelectionModel().getSelection();
					    	    		if(selected && selected.length > 0){
					    	    			callback(selected[0].raw);
					    	    			win.close();
					    	    		}
					    	    	}
					    	    },
					    	    { xtype : "svmx.button", text : de.translate("CONF016_TAG032"), handler : function(){ win.close(); } }
					    	]
					    }
					]
				}).show();
			}
		},

		__performINVENTORYAction : function(action){
			this.__logger.info("Performing INVENTORY action => " + action.getName());
			var targetUrl = new salModelImpl.TargetUrl(action);
			var page = this.__getPageUrl("INVT_SmartEngine");

			targetUrl.addProcessId("SMid");
			targetUrl.addRecordId("hdrId");

			this.__navigate(page, targetUrl);
		},

		__performSPRLAction : function(pageName, action){
			this.__logger.info("Performing action => " + action.actionType + "::" + action.getName());
			var page = this.__getPageUrl(pageName);
			var targetUrl = new salModelImpl.TargetUrl(action);

			targetUrl.addProcessId();
			targetUrl.addRecordId();
			targetUrl.addReturnUrl();

			if(action.handOver === true){
				targetUrl.addNextStepId();
			}

			this.__navigate(page, targetUrl);
		},

		__performINITIATERETURNAction : function(action){
			this.__performSPRLAction("APL_InitiateReturn", action);
		},

		__performFULFILLMENTAction : function(action){
			this.__performSPRLAction("APL_FulfillmentConsole", action);
		},

		__performSHIPAction : function(action){
			this.__performSPRLAction("APL_ConfirmShipment", action);
		},

		__performPICKANDMOVEAction : function(action){
			this.__performSPRLAction("APL_PickAndMove", action);
		},

		__performDELIVERYAction : function(action){
			this.__performSPRLAction("APL_DeliveryOnReceipt", action);
		},

		__performRECEIPTAction : function(action){
			this.__performSPRLAction("APL_ProcessReceipts", action);
		},

		__performSFMAction : function(action){
			this.__logger.info("Performing SFM action => " + action.getName());
			var settings = salModelImpl.Module.instance.getSettings();
			var targetUrl = new salModelImpl.TargetUrl(action);

			var page = this.__getPageUrl("ServiceMaxConsole");
			if(settings["GBL021"] == "FLEX" || action.modeOfExecution == "Background"){
				page = this.__getPageUrl("SFM_TDM_Delivery");
			}

			// TODO: May be this can part of metamodel rather than reading from data, only if applicable
			// for all target types
			targetUrl.addProcessId();
			targetUrl.addRecordId();
			targetUrl.addReturnUrl();

			// if this is a background process
			if(action.modeOfExecution == "Background"){
				targetUrl.addBackgroundExecutionMode();
			}

			// if this process should handover
			if(action.handOver === true){
				targetUrl.addNextStepId();
			}

			this.__navigate(page, targetUrl);
		},

		__performUnknownAction : function(action){
			this.__logger.info("Unknown action => " + action.getName() + " of type " + action.actionType);
		},

		__getPageUrl : function(page){
			return "/apex/" + SVMX.OrgNamespace + "__" + page;
		},

		__navigate : function(page, url){
			page += "?" + url.getUrlString();
			var openInSameWindow = SVMX.getClient().getApplicationParameter("svmx-sfw-open-in-window");

			//Take in account the on-line CustomerCommunity page, without this the user will not
			//be able to click the links and get to where they need to go
			// "app-config" : {
			//   "svmx-base-url" : "{!$Site.Name}"
			// }
			//Must exist in the corresponding VisualForce page.
			var baseUrl = SVMX.getClient().getApplicationParameter("svmx-base-url") || "";
		    if (baseUrl && baseUrl.indexOf("/") != 0) {
		        baseUrl = "/" + baseUrl;
		    }

		    page = baseUrl + page;

			if (openInSameWindow) {
				SVMX.navigateTopTo(page);
			} else {
				//This method call is commented since it is not working for Salesforce lightning mode
				//SVMX.openInBrowserWindow(page);
				//New method call added for handling Salesforce lightning mode
				SVMX.openInBrowserWindowLightning(page);
			}
		}
	}, {});

	salModelImpl.Class("TargetUrl", com.servicemax.client.lib.api.Object, {
		__uri : null, __params : null, __action : null, __overrides : null,

		__constructor : function(action, overrides){
			this.__uri = "";
			this.__params = {};
			this.__action = action;
			this.__overrides = overrides;
		},

		addParam : function(name, value){
			this.__params[name] = value;
		},

		addRecordId : function(key){
			var k = key || "SVMX_recordId";
			var value = this.__action.getRoot().recordId;
			this.addParam(k, value);
		},

		addNextStepId : function(){
			var value = this.__action.getData().actionDef[SVMX.OrgNamespace + "__Process1__c"];
			this.addParam("SVMX_NxtStepID", value);
		},

		addReturnUrl : function(){
			var value = "/" + this.__action.getRoot().recordId;
			this.addParam("SVMX_retURL", value);
		},

		addBackgroundExecutionMode : function(){
			this.addParam("SVMX_Execution_Mode", "SVMXAUTO");
		},

		addProcessId : function(key){
			var k = key || "SVMX_processId", value = "";

			if(this.__overrides && this.__overrides[k]){
				value = this.__overrides[k];
			}else{
				value = this.__action.getData()
					.actionDef[SVMX.OrgNamespace + "__Process__r"][SVMX.OrgNamespace + "__ProcessID__c"];
			}

			this.addParam(k, value);
		},

		getUrlString : function(){
			var name, ret = [], i = 0;
			for(name in this.__params){
				ret[i++] = name + "=" + this.__params[name];
			}
			return ret.join("&");
		}
	});

})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.sfw.model\src\operations.js
/**
 * This file needs a description
 * @class com.servicemax.client.sal.sfw.model.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfwOperations = SVMX.Package("com.servicemax.client.sal.sfw.model.operations");

sfwOperations.init = function(){
	 // imports
	 var Module = com.servicemax.client.sal.sfw.model.impl.Module;

	 // end imports

	 sfwOperations.Class("GetWizardInfo", com.servicemax.client.mvc.api.Operation, {
		 __constructor : function(){ this.__base(); },

		 performAsync : function(request, responder) {
	   		 var me = this;
	   		 var r = {RecordId : request.RecordId};

			 if(Module.instance.useJsr){
				SVMXJsr.JsrGetWizardInfo(r, function(result, evt){
					// TODO: Error handling
					me.__handleResponse(request, responder, result);
				}, this);
			 } else {
				 SVMX.create("com.servicemax.client.sal.sfw.model.impl.ServiceRequest", {
					 handler : function(sRequest){
						 sRequest.callMethodAsync({data : r, methodName : "getWizardInfo"});

						 sRequest.bind("REQUEST_COMPLETED", function(evt){
 							 if(evt.data){
								 me.__handleResponse(request, responder, evt.data);
							 }else{
								 responder.fault(evt.data);
							 }
						 });
					 }
				 });
			 }
		 },

		 __handleResponse : function(request, responder, resp){
            var sfwInfo = resp.SFWInfo;
            var settings = resp.Settings;

            if (sfwInfo.SFWs) {
                sfwInfo.SFWs.sort(this.__sequenceSFW);
            }

		 	Module.instance.updateSettings(settings);
		 	responder.result(sfwInfo);
		 },

         /*
          * sort function
          */
         __sequenceSFW : function(a, b) {
            // make the single digit string into double
            function makeDoubleDigit(value) {
                 var rtn = "";
                 var str = String(value);
                 if (str.length == 1) {
                    rtn = "0" + value;
                 } else {
                    rtn = str;
                 }
                return rtn;
            }

            var aseq= parseInt(a.row + "" + makeDoubleDigit(a.col));
            var bseq= parseInt(b.row + "" + makeDoubleDigit(b.col));

            return (aseq - bseq);
         }

	 }, {});

};
})();

