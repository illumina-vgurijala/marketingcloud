

(function(){
	var iotadmincommands = SVMX.Package("com.servicemax.client.iot.admin.commands");
	
iotadmincommands.init = function(){
	
	iotadmincommands.Class("GetSetupMetadata", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.GET_SETUP_METADATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onGetSetupMetadataComplete(data);
		}
		
	},{});

	iotadmincommands.Class("Save", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.SAVE"});
		},
	
		result : function(data) { 
			this.__cbContext.onSaveComplete(data);
		}
		
	},{});

	iotadmincommands.Class("BackToSetupHome", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.BACK_TO_SETUP_HOME"});
		},
	
		result : function(data) {
		}
		
	},{});

	iotadmincommands.Class("DescribeObject", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__isRefobj : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			var me = this;
			me.__isRefobj = request.isRefobj;
			me.__cbContext = request.context;
			me._executeOperationAsync(request, me, {operationId : "IOT.DESCRIBE_OBJECT"});
		},
	
		result : function(data) {
			var me = this;
			if(me.__isRefobj){
				me.__cbContext.describeReferenceObjectComplete(data);
			}else{
				me.__cbContext.describeSelectedObjectComplete(data);
			}
		}
		
	},{});
	iotadmincommands.Class("GetAllEventTemplates", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "IOT.GET_ALL_EVENT_TEMPLATES"});
		},
	
		result : function(data) {
			this.__cbContext.loadAllEventTemplatesComplete(data);
		}
		
	},{});
	
};
})();

// end of file