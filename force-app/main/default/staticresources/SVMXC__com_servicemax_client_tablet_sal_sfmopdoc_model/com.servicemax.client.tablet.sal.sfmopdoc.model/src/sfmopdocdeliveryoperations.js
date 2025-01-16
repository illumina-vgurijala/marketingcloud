/**
 * This file needs a description
 * @class com.servicemax.client.tablet.sal.sfmopdoc.model.operations
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
    var sfmopdocdeliveryoperations = SVMX.Package("com.servicemax.client.tablet.sal.sfmopdoc.model.operations");

sfmopdocdeliveryoperations.init = function(){

	sfmopdocdeliveryoperations.Class("GetUserInfo", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {

            };

			GetUserInfo(requestData, function(result, evt){
        com.servicemax.client.lib.datetimeutils.DatetimeUtil.setAmPmText(result.amText, result.pmText);

				result.Now = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(result.Now, result.DateFormat + " " + result.TimeFormat);
				result.Today = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(result.Today,result.DateFormat);
				result.Tomorrow = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(result.Tomorrow,result.DateFormat);
				result.Yesterday = com.servicemax.client.lib.datetimeutils.DatetimeUtil.getFormattedDatetime(result.Yesterday,result.DateFormat);
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

		 	GetTemplate(requestData, function(result, evt){
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
        }

    }, {});

    sfmopdocdeliveryoperations.Class("CreatePDF", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            var requestData = {
                DocumentId: request.documentId,
				RecordId: request.recordId
            };
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

			SubmitQuery(requestData,function(result, evt){
				callback.call(context, result);
			}, this);
        },

        performAsync: function(request, responder){
			responder.result("");

        }

    }, {});

    sfmopdocdeliveryoperations.Class("ViewDocument", com.servicemax.client.mvc.api.Operation, {

        __constructor: function(){
            this.__base();
        },

        performAsync: function(request, responder){

            //SVMX.navigateTo("/apex/OPDOC_DocumentViewer?SVMX_AttID=" + request.attachmentId + "&SVMX_RecId=" + request.recordId);
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

			GetDocumentMetadata(requestData, function(result, evt){
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

			GetDocumentData(requestData, function(result, evt){
                responder.result(result);
        	}, this);

        }

    }, {});

	sfmopdocdeliveryoperations.Class("DescribeObject", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var requestData = {objectName : request.objectName};

			DescribeObject(requestData,function(result, evt){

				responder.result(result);
			}, this);
		}

	}, {});

	sfmopdocdeliveryoperations.Class("CaptureSignature", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var requestData = {
				ProcessId   : request.processId,
				RecordId    : request.recordId,
				UniqueName  : request.uniqueName,
				ImgHeight		: request.imgHeight,
				ImgWidth		: request.imgWidth,
				CaptureSignature : request.captureSignature
			};

			CaptureSignature(requestData,function(result, evt){

				responder.result(result);
			}, this);
		}

	}, {});

	sfmopdocdeliveryoperations.Class("Finalize", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {
			var requestData = {
				ProcessId   : request.processId,
				RecordId    : request.recordId,
				HTMLContent : request.htmlContent
			};

			Finalize(requestData,function(result, evt){

				//responder.result(result);
			}, this);
		}

	}, {});

	sfmopdocdeliveryoperations.Class("GetDisplayTags", com.servicemax.client.mvc.api.Operation, {

		__constructor : function(){ this.__base(); },

		performAsync : function(request, responder) {

			var requestData = {};
			GetDisplayTags(requestData,function(result, evt){
				
				responder.result(result);
			}, this);
		}
	}, {});

};
})();

// end of file
