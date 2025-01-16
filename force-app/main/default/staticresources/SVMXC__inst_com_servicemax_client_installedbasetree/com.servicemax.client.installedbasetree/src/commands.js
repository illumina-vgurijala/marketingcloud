(function(){
	var ibTreecommands = SVMX.Package("com.servicemax.client.installedbasetree.commands");
	
	ibTreecommands.init = function(){

		ibTreecommands.Class("GetMetaData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.GET_META_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetMetaDataComplete(data);
			}
			
		},{});
		
		ibTreecommands.Class("GetTreeData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.GET_TREE_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetTreeDataComplete(data);
			}
			
		},{});

		ibTreecommands.Class("LoadMoreData", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.GET_LOAD_MORE_DATA"});
			},
		
			result : function(data) { 
				this.__cbContext.onGetLoadMoreDataComplete(data);
			}
			
		},{});

		ibTreecommands.Class("treeConfigureColumns", com.servicemax.client.mvc.api.CommandWithResponder, {
			__cbContext : null,
			__constructor : function(){ this.__base(); },
			
			executeAsync : function(request, responder){
				this.__cbContext = request.context;
				this._executeOperationAsync(request, this, {operationId : "IBTREE.TREE_CONFIGURE_COLUMN"});
			},
		
			result : function(data) { 
				this.__cbContext.onConfigureColumnsComplete(data);
			}
			
		},{});
	};
})()
