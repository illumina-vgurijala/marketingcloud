(function(){
	var technicalattributecommands = SVMX.Package("com.servicemax.client.technicalattributes.commands");
	
	technicalattributecommands.init = function(){
		technicalattributecommands.Class("GetMetaData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.GET_META_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetMetaDataComplete(data);
			}
			
		},{});
		
		technicalattributecommands.Class("GetTemplateData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.GET_TEMPLATE_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetTemplateDataComplete(data);
			}
			
		},{});

		technicalattributecommands.Class("SaveTechnicalAttribute", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.SAVE_TA"});
			},
		
			result : function(data) { 
				this.__cbContext.onSaveComplete(data);
			}
			
		},{});

		technicalattributecommands.Class("GetHistoryRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "TECHNICALATTRIBUTE.GET_HISTORY_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onHistoryFetchComplete(data);
			}
			
		},{});

	};
})()
