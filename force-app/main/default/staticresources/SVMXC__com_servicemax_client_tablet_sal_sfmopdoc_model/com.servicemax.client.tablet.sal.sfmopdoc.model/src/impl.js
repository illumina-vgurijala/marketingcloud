/**
 * This file needs a description 
 * @class com.servicemax.client.tablet.sal.sfmopdoc.model.impl
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	var sfmopdocdeliveryModelImpl = SVMX.Package("com.servicemax.client.tablet.sal.sfmopdoc.model.impl");
	
	sfmopdocdeliveryModelImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize : function(){
			com.servicemax.client.tablet.sal.sfmopdoc.model.operations.init();
		},
		
		initialize : function(){
			// register with the READY client event
			SVMX.getClient().bind("SFMOPDOCDELIVERY.JSEE_CREATED", function(evt) {
				var jsee = evt.data.jsee;
				var imageCache = {}, me = this;
				jsee.addInterceptor("$IMAGE", function(value, params){
					if(params && params.node){
						if (imageCache[value] != null) {
							$(params.node).attr("src", imageCache[value]);
						}
						else {						
							var q = new com.servicemax.client.tablet.sal.sfmopdoc.model.operations.SubmitQuery();
							params.pendingNodeItems.addItem(value, value);
							var result = q._performInternal({
								queryConfig: {
									api: "Document",
									fields: "Name, Type",
									condition: "DeveloperName='" + value + "'"
								}
							}, function(result){
								params.pendingNodeItems.removeItem(value);
								if (result && result.length > 0) {
									var imageName = result[0].Name + "." + result[0].Type;
									imageCache[value] = imageName;
									$(params.node).attr("src", imageCache[value]);
									//to parse the image names in server
									$(params.node).attr("svmx-data", value);
								}							
							}, me);
							
						}
					}else{
						if(jsee  != null && jsee.getProperty("ImageNameId")&& jsee.getProperty("ImageNameId")[value]){
							return jsee.getProperty("ImageNameId")[value];
						}
						else{
							SVMX.getLoggingService().getLogger().error("Image was not found in collection: " + value);
							return '';
						}
					}
				});
			});
		}
	}, {});	
	
	/**
	 * !!!! There can be only one cache service implementation. !!! Until OP Docs is running independently
	 * this can stay. DELETE THIS ASAP.
	 */
	sfmopdocdeliveryModelImpl.Class("CacheService", com.servicemax.client.lib.api.Object, {

		__constructor : function(){ },
		
		getItem : function(key){
			return null;
		},
		
		setItem : function(key, value){ },
		clear : function(key){ },
		reset : function(){ }
	}, {});
	
	sfmopdocdeliveryModelImpl.Class("PlatformSpecifics", com.servicemax.client.lib.api.Object, {
		__constructor : function(){
			
		},
		
		getQualificationInfo : function(recordID, processId, callback, context){

			var isQualified = window['svmx_sfm_opdoc_delivery_is_qualified'] === undefined ? 
									true : window['svmx_sfm_opdoc_delivery_is_qualified'];
									
			var errorMessage = window['svmx_sfm_opdoc_delivery_error_message'] === undefined ? 
									"" : window['svmx_sfm_opdoc_delivery_error_message'];
			
			callback.call(context, {isQualified : isQualified,
				errorMessage : errorMessage});
		},
				
		navigateBack : function(retUrl){
			if(retUrl && retUrl != ""){
				if(retUrl.indexOf("%2F") != -1)
					retUrl = "/" + retUrl.substring(3, retUrl.length); // decodeURI does't work! TODO:
				SVMX.navigateTo(retUrl);
			}
		},
		
		alert : function(msg){
			alert(msg);
		},
		
		confirm : function(msg){
			return confirm(msg);
		},
		
		getSettingsInfo : function(){						
			return {};
		}
		 
	}, {});
	
})();
