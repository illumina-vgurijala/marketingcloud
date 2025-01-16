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
