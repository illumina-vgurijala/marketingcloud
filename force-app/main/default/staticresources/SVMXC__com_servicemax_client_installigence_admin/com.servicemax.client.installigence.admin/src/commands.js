/**
 * This file needs a description 
 * @class com.servicemax.client.sfmopdocdelivery.commands
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	var installigenceadmincommands = SVMX.Package("com.servicemax.client.installigence.admin.commands");
	
installigenceadmincommands.init = function(){
	
	installigenceadmincommands.Class("GetSetupMetadata", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_SETUP_METADATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onGetSetupMetadataComplete(data);
		}
		
	},{});
	
	installigenceadmincommands.Class("SaveSetupData", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.SAVE_SETUP_DATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onSaveSetupDataComplete(data);
		}
		
	},{});
	
	installigenceadmincommands.Class("BackToSetupHome", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.BACK_TO_SETUP_HOME"});
		},
	
		result : function(data) {
		}
		
	},{});
	
	installigenceadmincommands.Class("GetTopLevelIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.FIND_TOPLEVEL_IBS"});
		},
	
		result : function(data) { 
			this.__cbContext.__findComplete(data);
		}
		
	},{});
	
	installigenceadmincommands.Class("GetTemplateFromIB", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_TEMPLATE_FROM_IB"});
		},
	
		result : function(data) { 
			this.__cbContext.GetTemplateFromIBComplete(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetAllProducts", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_ALL_PRODUCTS"});
		},
	
		result : function(data) { 
			this.__cbContext.__findComplete(data);
		}
		
	},{});
	installigenceadmincommands.Class("GetAllTechnicalAttributesTemplates", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_ALL_ATTRIBUTESTEMPLATES"});
		},
	
		result : function(data) { 
			this.__cbContext.__reloadTemplateGrid(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetTemplateCount", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_TEMPLATE_COUNT"});
		},
	
		result : function(data) { 
			this.__cbContext.__getTemplateCountForSearchValueCompleted(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetTechnicalAttributesTemplateCriteria", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_TA_TEMPLATE_CRITERIA"});
		},
	
		result : function(data) { 
			this.__cbContext.__getTemplateCriteriaInfoCompleted(data);
		}
		
	},{});

	installigenceadmincommands.Class("GetAllTAPicklistDefination", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.GET_ALL_TA_PICKLIST_DEFINATION"});
		},
	
		result : function(data) { 
			this.__cbContext.__onFetchingPicklistComplete(data);
		}
		
	},{});

	installigenceadmincommands.Class("SavePicklistData", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.SAVE_PICKLIST_DATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onSaveSetupPicklistDataComplete(data);
		}
		
	},{});

	installigenceadmincommands.Class("DeletePicklistData", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },
		
		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCEADMIN.DELETE_PICKLIST_DATA"});
		},
	
		result : function(data) { 
			this.__cbContext.onPicklistDeleteComplete(data);
		}
		
	},{});
	
};
})();

// end of file