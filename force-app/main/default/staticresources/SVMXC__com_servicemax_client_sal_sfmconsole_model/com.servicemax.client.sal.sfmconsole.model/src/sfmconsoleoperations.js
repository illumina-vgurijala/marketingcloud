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