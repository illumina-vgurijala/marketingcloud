/**
 * 
 */

(function(){
    var commandsImpl = SVMX.Package("com.servicemax.client.installigence.commands");
    
commandsImpl.init = function(){
    
    commandsImpl.Class("GetMetadata", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_METADATA"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetMetadataComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("FindByIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FIND_BY_IB"});
        },
    
        result : function(data) { 
            this.__cbContext.onSearchByIBComplete(data);
        },

        error : function(data) {
            this.__cbContext.onSearchByIBError();
        }
        
    },{});
    
    commandsImpl.Class("GetTopLevelIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_TOP_LEVEL_IBS"});
        },
    
        result : function(data) {
            this.__cbContext.onGetTopLevelIBsComplete(data);
        }
        
    },{});

    commandsImpl.Class("FetchToplevelAccounts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FETCH_TOPLEVEL_ACCOUNTS"});
        },
    
        result : function(data) {
            this.__cbContext.onGetTopLevelAccountsComplete(data);
        }
        
    },{});

    commandsImpl.Class("FindSelectedIBRecordInLocalDB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "FIND_SELECTED_IB_IN_LOCAL_DB"});
        },
    
        result : function(data) { 
            this.__cbContext.onSearchBySelectedIBComplete(data);
        }
        
    },{});
    
     commandsImpl.Class("FetchCustomFieldName", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FETCH_CUSTOM_FIELD"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
     commandsImpl.Class("UpdateRecordNameTable", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_RECORD_NAME_TABLE"});
        },
    
        result : function(data) { 
            this.__cbContext.recordNameUpdateSuccess(this.__cbContext, data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("GetPageLayout", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_PAGELAYOUT"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetPageLayoutCompleted(data);
        }
        
    },{});
    
    commandsImpl.Class("GetPageData", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_PAGEDATA"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetPageDataCompleted(data);
        }
        
    },{});
    
    commandsImpl.Class("GetLocAccDetails", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LOC_ACC_DETAILS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetLocationAndAccountDetailsCompleted(data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("GetMoreIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_MORE_IBS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetMoreIBsCompleted(data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("FindProducts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FIND_PRODUCTS"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
     commandsImpl.Class("SearchInstallBase", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SEACH_INSTALLBASE"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
     commandsImpl.Class("FetchValue", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FETCH_VALUES"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("GetRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_RECORDS"});
        },
    
        result : function(data, isValid, parentNodeId) { 
            this.__cbHandler.call(this.__cbContext, data, isValid, parentNodeId);
        }
        
    },{});

    commandsImpl.Class("GetLocations", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LOCATIONS"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});
    
    commandsImpl.Class("CreateRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.CREATE_RECORDS"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});

    commandsImpl.Class("DeleteRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.DELETE_RECORDS"});
        },
    
        result : function(success) { 
            this.__cbHandler.call(this.__cbContext, success, this.__params);
        }
        
    },{});

    commandsImpl.Class("UpdateIBHierarchy", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this.__params = request.params;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_IB_HIERARCHY"});
        },
    
        result : function(data) { 
            this.__cbHandler.call(this.__cbContext, data, this.__params);
        }
        
    },{});

    commandsImpl.Class("ApplyFieldUpdate", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null, __params : null, __cbHandler : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.APPLY_FIELD_UPDATE"});
        },
    
        result : function(data) { 
            this.__cbContext.onApplyFieldUpdateComplete.call(this.__cbContext, data);
        }
        
    },{});
    
    commandsImpl.Class("GetLMTopLevelIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LM_TOP_LEVEL_IBS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetLMTopLevelIBsComplete(data);
        }
        
    },{});

    commandsImpl.Class("GetLMAccountsLocations", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LM_ACCOUNTS_LOCATIONS"});
        },
    
        result : function(accountIds, locationIds) {
            this.__cbContext.onGetLMAccountsLocationsComplete(accountIds, locationIds);
        }
        
    },{});

    commandsImpl.Class("GetLMProducts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LM_PRODUCTS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetLMProductsComplete(data);
        }
        
    },{});

     commandsImpl.Class("SaveMultipleRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_MULTIPLE_RECORDS"});
        },
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("SaveRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_RECORD"});
        },
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});

    commandsImpl.Class("SaveRecordConfirm", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_RECORD_CONFIRM"});
        },
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});

    commandsImpl.Class("CloneRecord", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.CLONE_RECORD"});
        },
    
        result : function(data) { 
            this.__cbContext.onCloneComplete(data);
        }
        
    },{});

    commandsImpl.Class("CloneMultipleRecords", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.CLONE_MULTIPLE_RECORDS"});
        },
    
        result : function(data) { 
            this.__cbContext.onCloneComplete(data);
        }
        
    },{});

    commandsImpl.Class("SaveState", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_STATE"});
        },
    
        result : function(data) { 
            //
        }
        
    },{});

    commandsImpl.Class("GetSyncConflicts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_SYNC_CONFLICTS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetSyncConflictsComplete(data);
        }
        
    },{});

    commandsImpl.Class("UpdateSyncConflicts", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_SYNC_CONFLICTS"});
        },
    
        result : function(data) { 
            this.__cbContext.onUpdateSyncConflictsComplete(data);
        }
        
    },{});

    commandsImpl.Class("GetAllParentIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_ALL_PARENT_IBS"});
        },
    
        result : function(data) { 
            this.__cbContext.onAllParentIBsComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("SendExternalMessage", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SEND_EXTERNAL_MSG"});
        },
    
        result : function(data) { 
            this.__cbContext.onSendExternalMessageComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("ExecuteAPI", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.EXECUTE_API"});
        },
    
        result : function(data) { 
            this.__cbContext.onExecuteAPIComplete(data);
        }
        
    },{});
    
    commandsImpl.Class("GetApplicationFocus", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_APP_FOCUS"});
        },
    
        result : function(data) { 
            this.__cbContext.onGetAppFoucsComplete(data);
        }
        
    },{});
    commandsImpl.Class("GetLookupConfig", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_LOOKUPCONFIG"});
        }, 
    
        result : function(data) { 
            //this.__cbContext.__findComplete(data.data,true,data.parentNodeId,data.displayCols);
            this.__cbHandler.call(this.__cbContext, data.data,true,data.parentNodeId,data.displayCols);
        }
        
    },{});

    commandsImpl.Class("GetAllChildIBs", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_ALL_CHILD_IBS"});
        }, 
    
        result : function(data) { 
           this.__cbHandler.call(this.__cbContext, data);
        }
        
    },{});
    
    commandsImpl.Class("IBSearchConfig", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.GET_IBSEARCHCONFIG"});
        }, 
    
        result : function(data) { 
            this.__cbContext.onGetMetadataCompleteForAdvanceSearch(data);
        }
        
    },{});

    commandsImpl.Class("FindTechnicalAttributeTemplateForIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
           // debugger;
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.FIND_TA_TEMPLATE_FOR_SELECTD_IB"});
        }, 
    
        result : function(data) { 
            //debugger;
            this.__cbContext.__findTemplateComplete(data);
        }
        
    },{});

   

    commandsImpl.Class("SaveTechnicalAttributeTemplateInstanceForIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.SAVE_TA_TEMPLATE_INSTANCE_FOR_SELECTD_IB"});
        }, 
    
        result : function(data) { 
            this.__cbContext.onSaveComplete(data);
        }
        
    },{});

    commandsImpl.Class("UpdateTechnicalAttributeTemplateForIB", com.servicemax.client.mvc.api.CommandWithResponder, {
        __cbContext : null,
        __constructor : function(){ this.__base(); },
        
        executeAsync : function(request, responder){
            this.__cbContext = request.context;
            this.__cbHandler = request.handler;
            this._executeOperationAsync(request, this, {operationId : "INSTALLIGENCE.UPDATE_TA_TEMPLATE_FOR_SELECTD_IB"});
        }, 
    
        result : function(data) { 
            this.__cbContext.onUpdateComplete(data);
        }
        
    },{});
    
    
};
})();

// end of file
