/**
 * This file needs a description
 * @class com.servicemax.client.sfmopdocdelivery.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfmopdocdeliverycommands = SVMX.Package("com.servicemax.client.sfmopdocdelivery.commands");

sfmopdocdeliverycommands.init = function(){

	sfmopdocdeliverycommands.Class("GetUserInfo", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.GET_USERINFO"});
		}

	},{});

	sfmopdocdeliverycommands.Class("GetTemplate", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.GET_TEMPLATE"});
		}

	},{});

	sfmopdocdeliverycommands.Class("SubmitDocument", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.SUBMIT_DOCUMENT"});
		},

		result : function(data) {
			this.__cbContext.onSubmitDocumentComplete(data);
		},

		fault : function(data) {
			// TODO:
		}
	}, {});

	sfmopdocdeliverycommands.Class("CreatePDF", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.CREATE_PDF"});
		},

		result : function(data) {
			this.__cbContext.onCreatePDFComplete(data);
		},

		fault : function(data) {
			// TODO:
		}
	}, {});

	sfmopdocdeliverycommands.Class("ViewDocument", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.VIEW_DOCUMENT"});
		},

		result : function(data) {

		},

		fault : function(data) {
			// TODO:
		}
	}, {});

	sfmopdocdeliverycommands.Class("GetDocumentMetadata", com.servicemax.client.mvc.api.Command, {
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.GET_DOCUMENT_METADATA"});
		}
	}, {});

	sfmopdocdeliverycommands.Class("GetDocumentData", com.servicemax.client.mvc.api.Command, {
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.GET_DOCUMENT_DATA"});
		}
	}, {});

	sfmopdocdeliverycommands.Class("DescribeObject", com.servicemax.client.mvc.api.Command, {
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.DESCRIBE_OBJECT"});
		}
	}, {});

	sfmopdocdeliverycommands.Class("CaptureSignature", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbHandler : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbHandler = request.handler;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.CAPTURE_SIGNATURE"});
		},

		result : function(data) {
			this.__cbHandler(data);
		},

		fault : function(data) {
			// TODO:
		}
	}, {});

	sfmopdocdeliverycommands.Class("CaptureHtmlSignature", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbHandler : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbHandler = request.handler;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.CAPTURE_HTML_SIGNATURE"});
		},

		result : function(data) {
			this.__cbHandler(data);
		},

		fault : function(data) {
			// TODO:
		}
	}, {});

	/**
	 * Clean up any signature files and/or database records that are not tied to any active document.
	 */
	sfmopdocdeliverycommands.Class("PurgeOrphanSignatures", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbHandler : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbHandler = request.handler;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.PURGE_ORPHAN_SIGNATURES"});
		},

		result : function(data) {
			this.__cbHandler(data);
		},

		fault : function(data) {
			// TODO:
		}
	}, {});

	sfmopdocdeliverycommands.Class("Finalize", com.servicemax.client.mvc.api.Command, {
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.FINALIZE"});
		}
	}, {});

	sfmopdocdeliverycommands.Class("TargetUpdates", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, this, {operationId : "SFMOPDOCDELIVERY.TARGET_UPDATES"});
		},

		result : function(data) {
			this.__cbContext.onTargetUpdatesComplete(data);
		},

		fault : function(data) {
		// TODO:
		}

	}, {});

	sfmopdocdeliverycommands.Class("NotifyDataChange", com.servicemax.client.mvc.api.Command, {

		__constructor : function(){ this.__base(); },

		/**
		 *
		 * @param request
		 * @param responder
		 */
		executeAsync : function(request, responder){
			var app = SVMX.getCurrentApplication();
			var forEachConsoleApp = app.forEachConsoleApp;
			app.forEachConsoleApp && forEachConsoleApp.call(app, function(consoleApp) {
				var notifyDataChange = consoleApp.notifyDataChange;
				notifyDataChange && notifyDataChange.call(consoleApp, request);
			});
		}
	}, {});

	sfmopdocdeliverycommands.Class("GetDisplayTags", com.servicemax.client.mvc.api.CommandWithResponder, {
		__cbContext : null,
		__constructor : function(){ this.__base(); },

		executeAsync : function(request, responder){
			this.__cbContext = request.context;
			this._executeOperationAsync(request, responder, {operationId : "SFMOPDOCDELIVERY.GET_DISPLAY_TAGS"});
		}

	},{});

};
})();

// end of file