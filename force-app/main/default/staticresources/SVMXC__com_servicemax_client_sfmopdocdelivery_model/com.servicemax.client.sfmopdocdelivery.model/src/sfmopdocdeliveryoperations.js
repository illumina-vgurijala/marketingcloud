/**
 * This file needs a description
 * @class com.servicemax.client.sfmopdocdelivery.model.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
    var sfmopdocdeliveryoperations = SVMX.Package("com.servicemax.client.sfmopdocdelivery.model.operations");

sfmopdocdeliveryoperations.init = function(){

	sfmopdocdeliveryoperations.Class("GetUserInfo", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {

            };
            SvmxOpDocDeliveryJsr.JsrGetUserInfo(requestData, function(result, evt){
				//set the time format
				if(UserContext){
					var timeFormat = UserContext.timeFormat;
					result.TimeFormat = timeFormat;
                    if(UserContext.ampm) {
                        result.amText = UserContext.ampm[0];
                        result.pmText = UserContext.ampm[1];
                    }
					result.Locale = UserContext.locale;
				}
                responder.result(result);
            }, this);
        }

    }, {});

    sfmopdocdeliveryoperations.Class("GetTemplate", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {
                ProcessId : request.processId
            };

            SvmxOpDocDeliveryJsr.JsrGetTemplate(requestData, function(result, evt){
                responder.result(result);
            }, this);
        }

    }, {});

    sfmopdocdeliveryoperations.Class("SubmitDocument", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {
                Document: request.document
            };

            SvmxOpDocDeliveryJsr.JsrSubmitDocument(requestData, function(result, evt){
                responder.result(result);
            }, this);
        }

    }, {});

    sfmopdocdeliveryoperations.Class("CreatePDF", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {
                DocumentId: request.documentId,
				RecordId: request.recordId,
				ProcessId: request.processId
            };

            SvmxOpDocDeliveryJsr.JsrCreatePDF(requestData, function(result, evt){

            	var message = "";
            	if(evt.status == false && evt.type == "exception"){
            		message = evt.message;
            	}else if(result.Status == false){
            		message = result.Message;
				}

            	if(message.length > 0){
            		var baseUrl = SVMX.getClient().getApplicationParameter("svmx-base-url");
        			if (baseUrl) {
        				if (baseUrl.indexOf("/") != 0) {
        					baseUrl = "/" + baseUrl;
        				}
        			} else {
        				baseUrl = "";
        			}
            		var ps = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sfmopdoc.platformspecifics").getInstance();
					ps.alert(message);
					ps.navigateBack( baseUrl + request.returnUrl);
            	}else{
					responder.result(result);
				}
            }, this);
        }

    }, {});

    sfmopdocdeliveryoperations.Class("SubmitQuery", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        _performInternal: function(request, callback, context){

            var qc = request.queryConfig;
            var q = "SELECT " + qc.fields + " FROM " + qc.api;
            if (qc.condition && qc.condition != "") {
                q += " WHERE " + qc.condition;
            }
            var requestData = {
                Query: q
            };

            SvmxOpDocDeliveryJsr.JsrSubmitQuery(requestData, function(result, evt){
                callback.call(context, result);
            }, this);
        },

        performAsync: function(request, responder){

        }

    }, {});

    sfmopdocdeliveryoperations.Class("ViewDocument", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){
        	var baseUrl = SVMX.getClient().getApplicationParameter("svmx-base-url");
        	var nameSpace = SVMX.getClient().getApplicationParameter("org-name-space");
			if (baseUrl) {
				if (baseUrl.indexOf("/") != 0) {
					baseUrl = "/" + baseUrl;
				}
			} else {
				baseUrl = "";
			}
            SVMX.navigateTo(baseUrl + "/apex/" + nameSpace + "__OPDOC_DocumentViewer?SVMX_AttID=" + request.attachmentId + "&SVMX_RecId=" + request.recordId);
        }

    }, {});

    sfmopdocdeliveryoperations.Class("GetDocumentMetadata", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

			var requestData = {
                ProcessId   : request.processId
            };

            SvmxOpDocDeliveryJsr.JsrGetDocumentMetadata(requestData, function(result, evt){
                responder.result(result);
            }, this);

        }

    }, {});

	sfmopdocdeliveryoperations.Class("GetDocumentData", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

			       var requestData = {
                ProcessId   : request.processId,
				        RecordId    : request.recordId
            };

            SvmxOpDocDeliveryJsr.JsrGetDocumentData(requestData, function(result, evt){

              if (result.Status == false) {
            	    var ps = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sfmopdoc.platformspecifics").getInstance();
            	    ps.alert(result.Message);
            	    ps.navigateBack(request.returnUrl);
            	} else {
            	    var count = result.DocumentData.length;
            	    for (var index = 0; index < count; index++) {

            	        var records = result.DocumentData[index]["Records"];
            	        var SpecialFields = result.DocumentData[index]["SpecialFields"];
            	        var key = result.DocumentData[index]["Key"];


            	        if (key != undefined && key.indexOf("Checklist") >= 0) {
            	            var newRecords = [];
            	            SVMX.array.forEach(records, function(record) {
            	                if (record[SVMX.OrgNamespace + '__SM_Checklist_Group_Id__c'] != undefined && record[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'] != undefined) {
            	                    var exits = newRecords.some(function(uniqueElement) {
            	                        return uniqueElement[SVMX.OrgNamespace + '__SM_Checklist_Group_Id__c'] === record[SVMX.OrgNamespace + '__SM_Checklist_Group_Id__c'];
            	                    });
            	                    if (!exits) {
            	                        newRecords.push(record);
            	                    } else {
            	                        var filteredArray = newRecords.filter(function(filterElement) {
            	                            return filterElement[SVMX.OrgNamespace + '__SM_Checklist_Group_Id__c'] === record[SVMX.OrgNamespace + '__SM_Checklist_Group_Id__c'];
            	                        });
            	                        if (filteredArray.length > 0) {
            	                            var masterRecord = filteredArray[0];
            	                            if (masterRecord.hasOwnProperty([SVMX.OrgNamespace + '__ChecklistMetaJSON__c'])) {
            	                                masterRecord[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'] = masterRecord[SVMX.OrgNamespace + '__ChecklistMetaJSON__c'].concat(record[[SVMX.OrgNamespace + '__ChecklistMetaJSON__c']])
            	                            }
            	                        }
            	                    }
            	                } else {
            	                    newRecords.push(record);
            	                }
            	            });
            	            result.DocumentData[index]["Records"] = newRecords;
            	        }
            	    }
            	    responder.result(result);
            	}
            	}, this);
        }

    }, {});

	sfmopdocdeliveryoperations.Class("DescribeObject", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			var requestData = {objectName : request.objectName};
			SvmxOpDocDeliveryJsr.JsrDescribeObject(requestData, function(result, evt){
				responder.result(result);
			}, this);
		}
	}, {});

	sfmopdocdeliveryoperations.Class("TargetUpdates", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			var requestData = {
                ProcessId   : request.processId,
				RecordId    : request.recordId
            };
			SvmxOpDocDeliveryJsr.JsrTargetUpdates(requestData, function(result, evt){
				responder.result(request.pdf);
			}, this);
		}
	}, {});

	sfmopdocdeliveryoperations.Class("GetDisplayTags", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var requestData = {};
			SvmxOpDocDeliveryJsr.JsrGetDisplayTags(requestData, function(result, evt){
				responder.result(result);
			}, this);
		}
	}, {});

};
})();

// end of file
