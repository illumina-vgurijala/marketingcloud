(function(){
    var ibTreeoperations = SVMX.Package("com.servicemax.client.installedbasetree.operations");

ibTreeoperations.init = function(){
    var Module = com.servicemax.client.installedbasetree.impl.Module; 

    ibTreeoperations.Class("GetMetaData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var objName;
            if (request.objName == SVMX.getCustomFieldName('Site')) {
                objName = 'SITE';
            } else {
                objName = 'IB';
            }
            ibTreeOnWeb.JsrGetMetadata(objName, function(result, evt){               
                responder.result(result);
            }, this);
        }
    },{});

    ibTreeoperations.Class("GetTreeData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var requestObj = {"recordId":request.recordId, "reload":request.reload};
            var requestData = JSON.stringify(requestObj);
            if (request.objName == SVMX.getCustomFieldName('Site')) {
                ibTreeOnWeb.JsrGetLocationTreeViewData(requestData, function(result, evt){               
                    responder.result(result);
                }, this);
            } else {
                ibTreeOnWeb.JsrGetTreeViewData(requestData, function(result, evt){               
                    responder.result(result);
                }, this);
            }
        }
    },{});

    ibTreeoperations.Class("LoadMoreData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var parentNode = request.parentNode;
            var requestData = JSON.stringify(request.requestData);
            ibTreeOnWeb.JsrGetChildren(requestData, function(result, evt){ 
                var response = {
                    result: result,
                    parentNode: parentNode
                } 
                responder.result(response);
            }, this);
        }
    },{});

    ibTreeoperations.Class("treeConfigureColumns", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var requestData = JSON.stringify(request.configuredData);
            ibTreeOnWeb.JsrSaveConfiguredColumnsForIB(requestData, function(result, evt){               
                responder.result(result);
            }, this);
        }
    },{});
};
})();
