// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.sfmconsole.model\src\impl.js
/**
 * This file needs a description
 * @class com.servicemax.client.sal.sfmconsole.model.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var salModelImpl = SVMX.Package("com.servicemax.client.sal.sfmconsole.model.impl");

	salModelImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		useJsr : false,
		__constructor : function(){
			this.__base();
			this.__self.instance = this;
			this.__logger = SVMX.getLoggingService().getLogger("SAL-MODEL");
		},

		beforeInitialize : function(){

		},

		initialize : function(){
			// check if jsr should be used, only valid when running from web
			var useJsr = SVMX.getClient().getApplicationParameter("svmx-sfm-sal-model-use-jsr");
			if(useJsr && useJsr === true){
				this.useJsr = true;
				this.__logger.info("JSR is enabled. Will use this for server communication.");
			}else{
				this.useJsr = false;
			}
		},

		afterInitialize : function(){
			com.servicemax.client.sal.model.sfmconsole.operations.init();
		},


		registerForSALEvents : function(serviceCall, operationObj){
			if(!operationObj){
				SVMX.getLoggingService().getLogger().warn("registerForSALEvents was invoked without operationObj!");
			}

			serviceCall.bind("REQUEST_ERROR", function(errEvt){

				// unblock the UI if is blocked
				var currentApp = operationObj ? operationObj.getEventBus() : SVMX.getCurrentApplication();
				//var de = operationObj ? operationObj.getEventBus().getDeliveryEngine() : null;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.CHANGE_APP_STATE", this, {request : {state : "unblock"}, responder : {}});
				currentApp.triggerEvent(evt);

			    var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SFMDELIVERY");
 				var message = TS.T("TAG015");
 				try{ message  += "::" + errEvt.data.xhr.statusText + "=>" + errEvt.data.xhr.responseText; }catch(e){}
 				// notify about the error
				evt = SVMX.create("com.servicemax.client.lib.api.Event",
					"SFMDELIVERY.NOTIFY_APP_ERROR", this, {request : {message : message }, responder : {}});
 				currentApp.triggerEvent(evt);

				this.__logger.error(message);
			}, this);
		},

		// params = {handler : , context : , options : {type : , endPoint : , namespace :}}
		createServiceRequest : function(params, operationObj){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
			servDef.getInstanceAsync({handler : function(service){
				var options = params.options || {};
				var p = {type : options.type || "REST", endPoint : options.endPoint || "SFMDeliveryServiceIntf",
									nameSpace : options.namespace === null ? null : SVMX.OrgNamespace};
				var sm = service.createServiceManager(p);
				var sRequest = sm.createService();
				this.registerForSALEvents(sRequest, operationObj);
				params.handler.call(params.context, sRequest);
			}, context:this });
		},

		getErrorMessage : function(data){


			var ret = true, message = "", msgDetail = "";

			// the success attributes are available in the response from ServiceMax APEX services
			if(data){
				if(data.response && (data.response.success === false || data.response.success === "false")){
					ret = false;

					// user friendly data
					if(data.response.msgDetails && data.response.msgDetails.message){
						message = data.response.msgDetails.message;
						msgDetail = data.response.msgDetails.details;
					}else{
						message = data.response.message;
					}
				}else if(data.success === false || data.success === "false"){
					ret = false;

					// user friendly data
					if(data.msgDetails && data.msgDetails.message){
						message = data.msgDetails.message;
						msgDetail = data.msgDetails.details;
					}else{
						message = data.message;
					}
				}
			}
			if (msgDetail) this.__logger.error(message + "; " + msgDetail);
			return message || !ret; // if no message but there is still an error, then at least return true to getErrorMessage.
		}
	}, {
		instance : null
	});


})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.sfmconsole.model\src\sfmconsoleoperations.js
/**
 * This file needs a description
 * @class com.servicemax.client.sal.model.sfmconsole.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var packageimpl = SVMX.Package("com.servicemax.client.sal.model.sfmconsole.operations");

packageimpl.init = function(){

	// imports
	var Module = com.servicemax.client.sal.sfmconsole.model.impl.Module;
	// end imports



	packageimpl.Class("RetrieveDisplayTags", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		/* TODO: Currently we only look at the first element of the moduleIds array; we'll need
		 * to eventually be able to handle a set of moduleIds
		 */
		performAsync : function(request, responder) {
			var translationService = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.translation").getInstance();

			if (window["svmx_display_tags"]) {
				SVMX.forEachProperty(window["svmx_display_tags"], function(inKey, inValue) {
					translationService.addData(inValue, inKey);
				});
				responder.result(translationService);
				return;
			}

			var modulesToRequest = request.moduleIds;
			if (modulesToRequest.length == 0) {
				responder.result(translationService);
				return;
			}

			var moduleToRequest = modulesToRequest[0];
			var moduleIdToRequest = moduleToRequest["module-id"];
			var internalModuleId = moduleToRequest["local-id"] || "IPAD";

			var cache = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.cache");
			var module = Module.instance;
			var count = modulesToRequest.length;
			var errorMsg = "";

			var execute = SVMX.proxy(this, function(moduleIdToRequest, internalModuleId) {
				var data = {moduleId: moduleIdToRequest};
				var key = data.moduleId + "-DISPLAY_TAGS";
				var ret = cache ? cache.getItem(key) : null;
				if(ret){
					setTimeout(function(){
						translationService.addData(ret, internalModuleId);
						count--;
						if (count === 0) {
							if (!errorMsg) {
								responder.result(translationService);
							} else {
								responder.fault(translationService, errorMsg);
							}
						}
					}, 1);
				}else{
					if(Module.instance.useJsr){
						SVMXJsr.JsrRetrieveDisplayTags(data, function(result, evt){
							var currentErrorMsg = module.getErrorMessage(result);
							if (!currentErrorMsg && cache) cache.setItem(key, result);
							if (!currentErrorMsg) {
								translationService.addData(result, internalModuleId);
							} else {
								errorMsg += currentErrorMsg + "; ";
							}
							count--;
							if (count === 0) {
								if (!errorMsg) {
									responder.result(translationService);
								} else {
									responder.fault(translationService, errorMsg);
								}
							}

						}, this);
					}else{
						Module.instance.createServiceRequest({handler : function(sRequest){
							sRequest.bind("REQUEST_COMPLETED", function(evt){
								var currentErrorMsg = module.getErrorMessage(evt.data);
								if (!currentErrorMsg && cache) cache.setItem(key, evt.data);
								if (!currentErrorMsg) {
									translationService.addData(evt.data, internalModuleId);
								} else {
									errorMsg += currentErrorMsg + "; ";
								}
								count--;
								if (count === 0) {
									if (!errorMsg) {
										responder.result(translationService);
									} else {
										responder.fault(translationService, errorMsg);
									}
								}
							}, this);

							sRequest.callMethodAsync({methodName : "retrieveDisplayTags", data : data});
						}, context : this}, this);
					}
				}
			});

			for (var i = 0; i < modulesToRequest.length; i++) {
				execute(modulesToRequest[i]["module-id"], modulesToRequest[i]["local-id"]);
			}
		}

	}, {});

};
})();

// end of file

