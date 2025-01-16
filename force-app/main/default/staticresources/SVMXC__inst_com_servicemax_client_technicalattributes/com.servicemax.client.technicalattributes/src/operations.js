(function(){
    var technicalattributeoperations = SVMX.Package("com.servicemax.client.technicalattributes.operations");

technicalattributeoperations.init = function(){
    var Module = com.servicemax.client.technicalattributes.impl.Module; 
    
    technicalattributeoperations.Class("GetMetaData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            technicalAttributeOnWeb.JsrGetMetadata('', function(result, evt){               
                responder.result(result);
            }, this);
        }
    },{});

    technicalattributeoperations.Class("GetTemplateData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder) {
            var me = this;
            var requestData = request.recordId;
            technicalAttributeOnWeb.JsrGetAttributesTemplateInstanceForIB(requestData, function(result, evt){               
                responder.result(result);
            }, this);
        }

    }, {});

    technicalattributeoperations.Class("SaveTechnicalAttribute", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder) {

            technicalAttributeOnWeb.JsrSaveTechnicalAttributeDetails(request.instanceObject, function(result, evt){               
                responder.result(result);
            }, this);
        }

    }, {});

    technicalattributeoperations.Class("GetHistoryRecord", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
            var module = Module.instance;
            Module.instance.createServiceRequest({handler : function(sRequest){
                var payload = SVMX.getCustomFieldName('SM_Attr_Payload');
                var capturedOn = SVMX.getCustomFieldName('SM_Captured_On');
                var timeZone = request.timeZone;
                sRequest.bind("REQUEST_COMPLETED", function(evt){
                    var records = evt.data.records;
                    if (records.length > 0) {
                        var object = records[0];
                        var capturedOnDate = object[capturedOn];
                        var payloadJson = object[payload];
                        var data = {};
                        data["capturedOn"] = capturedOnDate;
                        data["template"] = payloadJson;
                        responder.result(data);
                    }
                    else {
                        responder.result([]);
                    }
                }, this);
                sRequest.bind("REQUEST_ERROR", function(evt){
                    responder.result([]);
                }, this);
                var table = SVMX.getCustomFieldName('SM_IB_Attributes_History');
                var IB_Id = SVMX.getCustomFieldName('SM_Installed_Product_Id');
                var filterOnCapturedOnDate = '';
                var previousCapturedOnDate ;
                if(request.presentCapturedOnDate){
                    previousCapturedOnDate = request.presentCapturedOnDate;
                    var prevDateM = moment.tz(previousCapturedOnDate,timeZone);
                    var prevDate = prevDateM._d;
                    prevDate = new Date(prevDate.valueOf() + prevDate.getTimezoneOffset() * 60000);
                    var formattedDate;
                    if (request.isPreviousRecord) {
                        formattedDate = Ext.Date.format(prevDate,'Y-m-d 00:00:00');
                    } else {
                        formattedDate = Ext.Date.format(prevDate,'Y-m-d 23:59:59');
                    }
                    var newDate = new Date(formattedDate);
                    var gmtDate = new Date(newDate.valueOf() - prevDateM._offset * 60000);
                    var newFormattedString = Ext.Date.format(gmtDate,'Y-m-d\\TH:i:s.000\\Z');
                    previousCapturedOnDate = newFormattedString;

                } 
                if(request.isPreviousRecord){
                    filterOnCapturedOnDate = ' AND '+capturedOn+' < ' + previousCapturedOnDate + " order by " + capturedOn + " desc limit 1  ";
                }else{
                    filterOnCapturedOnDate = ' AND '+capturedOn+' > ' + previousCapturedOnDate + " order by " + capturedOn + " asc limit 1  ";
                }
                //var query = encodeURI("select " + capturedOn + "," + payload + " from "+ table + " where " + IB_Id + " = '" + request.recordId + "' order by " + capturedOn + " desc limit 1 offset " + request.offset);
                var query = encodeURI("select " + capturedOn + "," + payload + " from "+ table + " where " + IB_Id + " = '" + request.recordId + "'" + filterOnCapturedOnDate);
                sRequest.callApiAsync({url : "query?q=" + query});
            }, context : this}, this);  
            
        }

    }, {}); 

};
})();