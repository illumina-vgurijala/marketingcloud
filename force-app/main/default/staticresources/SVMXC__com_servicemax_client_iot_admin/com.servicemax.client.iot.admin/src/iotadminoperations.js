(function() {
    var iotadminoperations = SVMX.Package("com.servicemax.client.iot.admin.operations");
    iotadminoperations.init = function() {
        var Module = com.servicemax.client.installigence.ui.components.impl.Module;
        iotadminoperations.Class("GetSetupMetadata", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var requestData = {
                };
                InstalligenceSetupJsr.JsrGetSetupMetadata(requestData, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
        iotadminoperations.Class("Save", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var requestData = {
                    events: request.events,
                    deletedEvents: request.deletedEvents,
                    compositeKey: request.compositeKey,
                    objectMapEvents: request.objectMapEvents,
                    deletedObjectMap: request.deletedObjectMap

                };
                InstalligenceSetupJsr.JsrSave(requestData, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
        iotadminoperations.Class("BackToSetupHome", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var requestData = {};
                InstalligenceSetupJsr.JsrBackToSetupHome(requestData, function(result, evt) {
                }, this);
            }
        }, {});
        iotadminoperations.Class("DescribeObject", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                InstalligenceSetupJsr.JsrDescribeObject(request.requestData, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
        iotadminoperations.Class("GetAllEventTemplates", com.servicemax.client.mvc.api.Operation, {
            __constructor: function() {
                this.__base();
            },
            performAsync: function(request, responder) {
                var module = Module.instance;
                Module.instance.createServiceRequest({
                    handler: function(sRequest) {
                        sRequest.bind("REQUEST_COMPLETED", function(evt) {
                            if (module.checkResponseStatus("GetAllEventTemplates", evt.data, false, this) == true) {
                                responder.result(evt.data.records);
                            }
                        }, this);
                        sRequest.bind("REQUEST_ERROR", function(evt) {
                            if (module.checkResponseStatus("GetAllEventTemplates", evt.data, false, this) == true) {
                                responder.result([]);
                            }
                        }, this);
                        var query = encodeURI('SELECT Id,' + SVMX.OrgNamespace + '__SM_Event_Name__c,' + SVMX.OrgNamespace + '__SM_Description__c ,' + SVMX.OrgNamespace + '__SM_JSON_Payload__c  FROM ' + SVMX.OrgNamespace + '__SM_IoT_Field_Mapping__c');
                        sRequest.callApiAsync({ url: "query?q=" + query });
                    },
                    context: this
                }, this);
            }
        }, {});
    };
})();

// end of file