// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.sfmsearch.model\src\impl.js
/**
 * This file needs a description
 * @class com.servicemax.client.sal.sfmsearch.model.impl
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var sfmsearchImpl = SVMX.Package("com.servicemax.client.sal.sfmsearch.model.impl");

	sfmsearchImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		useJsr : false, __logger : null,
		__constructor : function(){
			this.__base();
			this.__self.instance = this;
			this.__logger = SVMX.getLoggingService().getLogger("SAL-SEARCH-MODEL");
		},

		beforeInitialize : function(){
			com.servicemax.client.sal.model.sfmsearchdelivery.operations.init();
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
		setUserInfo : function(userInfo){
			// This is under the assumption that the service is already loaded
			var serv = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache").getInstance();;

			var key = userInfo.UserId + "-SFMSEARCHDELIVERY-USERLANGUAGE", language = serv.getItem(key);
			if(language){
				if(language != userInfo.Language){

					// user language or user has changed. reset the cache
					this.__logger.info("User language OR User login has changed. Will clear cache");
					this.clearCache();
				}
			}

			//the user time format; UserContext defined in index.html
			if(UserContext){
				var timeFormat = UserContext.timeFormat;
				userInfo.TimeFormat = timeFormat;
			}

			sfmsearchImpl.ModelState.getInstance().add("userInfo", userInfo);
			serv.setItem(key, userInfo.Language);


            SVMX.getCurrentApplication().setUserInfo(userInfo);
		},

        clearCache : function(){
			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.cache");

			// This is under the assumption that the service is already loaded
			var serv = servDef.getInstance();
			this.__logger.info("Clearing cache...");
			serv.reset();
		},
        
		registerForSALEvents : function(serviceCall, operationObj){

			if(!operationObj){
				SVMX.getLoggingService().getLogger().warn("registerForSALEvents was invoked without operationObj!");
			}

			serviceCall.bind("REQUEST_ERROR", function(errEvt){
				// TODO: unblock the UI if is blocked

 				var message = "";
 				try{ message  += "::" + errEvt.data.xhr.statusText + "=>" + errEvt.data.xhr.responseText; }catch(e){}

 				// TODO: notify about the error

				this.__logger.error(message);
			}, this);
		},

		// params = {handler : , context : , options : {type : , endPoint : , namespace :}}
		createServiceRequest : function(params, operationObj){

			var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
			servDef.getInstanceAsync({handler : function(service){
				var options = params.options || {};
				var p = {type : options.type || "REST", endPoint : options.endPoint || "SFMSearchDeliveryServiceIntf",
									nameSpace : options.namespace === null ? null : SVMX.OrgNamespace};
				var sm = service.createServiceManager(p);
				var sRequest = sm.createService();
				this.registerForSALEvents(sRequest, operationObj);
				params.handler.call(params.context, sRequest);
			}, context:this });
		},

		checkResponseStatus : function(operation, data, hideQuickMessage, operationObj){
			//TODO:
			return true;
		}
	}, {
		instance : null
	});

	sfmsearchImpl.Class("ModelState", com.servicemax.client.lib.api.Object, {
		__state : null,
		__constructor : function(){
			this.__state = {};
		},

		add : function(key, value){
			this.__state[key] = value;
		},

		get : function(key){
			return this.__state[key];
		},

		remove : function(key){
			var val = null;
			try{
				val = this.__state[key];
			}catch(e){}

			this.__state[key] = null;
			return val;
		}

	}, {
		getInstance : function(){
			if(this.__instance == null){
				this.__instance = new sfmsearchImpl.ModelState();
			}
			return this.__instance;
		},

		__instance : null
	});

	sfmsearchImpl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
		__constructor : function(){

		},

		showRecord : function(info){
			//Take in account the on-line CustomerCommunity page, without this the user will not
			//be able to click the links and get to where they need to go
			// "app-config" : {
			//   "svmx-base-url" : "{!$Site.Name}"
			// }
			//Must exist in the SFMSearchDelivery VisualForce page.
			var baseUrl = SVMX.getClient().getApplicationParameter("svmx-base-url") || "";
			if (baseUrl && baseUrl.indexOf("/") != 0) {
				baseUrl = "/" + baseUrl;
			}

			SVMX.openInBrowserWindow(baseUrl + "/" + info.key + "?isdtp=");
		}

	}, {});
})();

// end of file

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.sal.sfmsearch.model\src\sfmsearchdeliveryoperations.js
/**
 * This file needs a description
 * @class com.servicemax.client.sal.model.sfmsearchdelivery.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){

	var operationsImpl = SVMX.Package("com.servicemax.client.sal.model.sfmsearchdelivery.operations");

operationsImpl.init = function(){

	// imports
	var Module = com.servicemax.client.sal.sfmsearch.model.impl.Module;
	// end imports

	var lastSearchInfo;

	operationsImpl.Class("GetSearchInfo", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var module = Module.instance, me = this;

			if(		window["svmx_sfmsearch_delivery_search_info"] != undefined
				&& 	window["svmx_sfmsearch_delivery_search_info"] != null ){

				setTimeout(function(){
					var searchInfo = window["svmx_sfmsearch_delivery_search_info"];
					searchInfo = SVMX.toObject(searchInfo);
					window["svmx_sfmsearch_delivery_search_info"] = null;
					me.__handleResponse(request, responder, searchInfo);
				}, 1);

			}else if(module.useJsr){
				SVMXJsr.JsrGetSearchInfo(request, function(result, evt){
					this.__handleResponse(request, responder, result);
				}, this);
			}else{
				module.createServiceRequest({handler : function(sRequest){

					sRequest.bind("REQUEST_COMPLETED", function(evt){
						this.__handleResponse(request, responder, evt.data);

					}, this);

					sRequest.callMethodAsync({methodName : "getSearchInfo", data : {}});
				}, context : this}, this);
			}
		},

		__handleResponse : function(request, responder, data){
			var module = Module.instance;
			if(module.checkResponseStatus("GetSearchInfo", data, false, this) == true){
				lastSearchInfo = SVMX.cloneObject(data);
				responder.result(data);
			}
		}
	}, {});
	operationsImpl.Class("GetUserInfo", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			// if user information is embeded into the container html/vf
			if(window["svmx_sfmsearch_delivery_userinfo"] != undefined && window["svmx_sfmsearch_delivery_userinfo"] != null ){
				setTimeout(function(){
					ret = window["svmx_sfmsearch_delivery_userinfo"];
					ret = SVMX.toObject(ret);
					Module.instance.setUserInfo(ret);
					responder.result(ret);
				}, 1);
			}else{

				Module.instance.createServiceRequest({handler : function(sRequest){

					sRequest.bind("REQUEST_COMPLETED", function(evt){

						Module.instance.setUserInfo(evt.data);
						responder.result(evt.data);

					});

					sRequest.callMethodAsync({methodName : "getUserInfo", data : request});
				}, context : this}, this);
			}
		}
	}, {});


	operationsImpl.Class("GetSearchResults", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var module = Module.instance;
			var requestData = {
				ProcessId : request.ProcessId,
	    		ProcessName: request.ProcessName,
				ObjectId : request.ObjectId,
				KeyWord : request.KeyWord,
				Operator: request.Operator,
				RecordLimit: request.RecordLimit
			};
			if(module.useJsr){
				SVMXJsr.JsrGetSearchResult(requestData, function(result, evt){
					this.__handleResponse(request, responder, result);
				}, this);
			}else{
				module.createServiceRequest({handler : function(sRequest){

					sRequest.bind("REQUEST_COMPLETED", function(evt){
						this.__handleResponse(request, responder, evt.data);
					}, this);

					sRequest.callMethodAsync({methodName : "getSearchResult", data : requestData});
				}, context : this}, this);
			}
		},

		__getSearchDef: function(request) {
			var parentSearchDef = SVMX.array.get(lastSearchInfo.lstSearchInfo, function(item) {
            	return item.searchDef.Id == request.ProcessId;
            });
            var searchDef = SVMX.array.get(parentSearchDef.searchDetails, function(item) {
            	return item.objectDetails.Id == request.ObjectId;
            });
			return searchDef;
		},

		__getSearchObjectFromDef: function(searchDef) {
			return searchDef.objectDetails[SVMX.OrgNamespace + "__Target_Object_Name__c"];
		},

		__handleResponse : function(request, responder, data){
			var module = Module.instance;
			if(module.checkResponseStatus("GetSearchResult", data, false, this) == true){
				this.__convertResponse(request, responder, data);
				responder.result(data);
			}
		},

		__convertResponse: function(request, responder, data) {
	        var items = data.MapStringMap;
	        if(items){
	        	var searchDef = this.__getSearchDef(request);
	            var searchObj = this.__getSearchObjectFromDef(searchDef);
	            var searchDefFields = searchDef.fields;

			    for(var i = 0; i < items.length; i++) {
			        var fieldValues = items[i].valueMap;
			        for (var j = 0; j < fieldValues.length; j++) {
			        	this.__convertResponseItem(fieldValues[j], searchDefFields[j], searchObj);
			        }
			    }
	        }
		},

		__convertResponseItem: function(valueItem, fieldDef, searchObj) {
            var fieldDefObjName = fieldDef[SVMX.OrgNamespace + "__Object_Name2__c"];
            var fieldName = fieldDef[SVMX.OrgNamespace + "__Field_Name__c"];
            var parentReferenceName = fieldDef[SVMX.OrgNamespace + "__Lookup_Field_API_Name__c"];
            if (fieldDefObjName && fieldDefObjName != searchObj) {
            	valueItem.key = parentReferenceName + "-" + fieldName;
            } else {
            	valueItem.key = fieldName;
            }

            // TODO: Server should send us server formated datetime, and the ui layer should handle the rendering
            // TODO: Server should send "" not "--" for empty values.
            if (valueItem.type == "DATETIME") {
               // valueItem.value = valueItem.value ? this.__getDateTimeInSaveFormat(valueItem.value) : "--";
				valueItem.value = (valueItem.value == "--" || valueItem.value == "" ) ? "--" : this.__getDateTimeInSaveFormat(valueItem.value);

            }
			else if (valueItem.type == "DATE") {
				//valueItem.value = valueItem.value ? this.__getDateInSaveFormat(valueItem.value) : "--";
				valueItem.value = (valueItem.value == "--" || valueItem.value == "" ) ? "--" : this.__getDateInSaveFormat(valueItem.value);
			}
        },
		__getDateTimeInSaveFormat: function(data) {
			var DateTimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
			var userDate = DateTimeUtils.parseGMTDate(data, DateTimeUtils.getDefaultDatetimeFormat());
			return DateTimeUtils.convertToTimezone(userDate, null, true);
		},
		__getDateInSaveFormat: function(data) {
			var DateTimeUtils = com.servicemax.client.lib.datetimeutils.DatetimeUtil;
			var userDate = DateTimeUtils.parseDate(data, DateTimeUtils.getDefaultDateFormat());
			return DateTimeUtils.getFormattedDatetime(userDate, DateTimeUtils.getSaveFormat('date'));

		}

	}, {});

	operationsImpl.Class("GetSearchResultLimitSettings", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			responder.result({maxLimit:null,defaultLimit:null});
		}
	}, {});
}

})();

// end of file

