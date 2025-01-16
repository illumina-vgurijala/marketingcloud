/**
 * This file needs a description
 * @class com.servicemax.client.sfmsearchdelivery.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {
    var sfmsearchdeliverycommands = SVMX.Package("com.servicemax.client.sfmsearchdelivery.commands");

    sfmsearchdeliverycommands.init = function() {

        sfmsearchdeliverycommands.Class("GetSearchInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_SEARCH_INFO"
                });
            }
        }, {});

        sfmsearchdeliverycommands.Class("GetSearchResults", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_SEARCH_RESULTS"
                });
            }
        }, {});
		sfmsearchdeliverycommands.Class("GetUserInfo", com.servicemax.client.mvc.api.Command, {

		__constructor : function(){ this.__base(); },

		/**
		 *
		 * @param request
		 * @param responder
		 */
			executeAsync : function(request, responder){
			this._executeOperationAsync(request, responder, {operationId : "SFMSEARCHDELIVERY.GET_USERINFO"});
		}
	}, {});
		
        sfmsearchdeliverycommands.Class("ChangeApplicationState", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                request.deliveryEngine.changeApplicationState(request.state);
            }
        }, {});
        

        sfmsearchdeliverycommands.Class("GetOnlineResults", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_ONLINE_RESULTS"
                });
            }
        }, {});

         sfmsearchdeliverycommands.Class("DownloadRecordOnDemand", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.DOWNLOAD_RECORD_ON_DEMAND"
                });
            }
        }, {});

        sfmsearchdeliverycommands.Class("GetSearchResultLimitSettings", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMSEARCHDELIVERY.GET_SEARCH_RESULT_LIMIT_SETTINGS"
                });
            }
        }, {});
};

})();

// end of file
