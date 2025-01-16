(function() {
    var featurepermissioncommands = SVMX.Package("com.servicemax.client.featurepermission.commands");

    featurepermissioncommands.init = function() {
        featurepermissioncommands.Class("GetMetaData", com.servicemax.client.mvc.api.CommandWithResponder, {
            __cbContext: null,
            __constructor: function() { this.__base(); },

            executeAsync: function(request, responder) {
                this.__cbContext = request.context;
                this._executeOperationAsync(request, this, { operationId: "FEATUREPERMISSION.GET_META_DATA" });
            },

            result: function(data) {
                this.__cbContext.onGetMetaDataComplete(data);
            }

        }, {});

        featurepermissioncommands.Class("GetUserData", com.servicemax.client.mvc.api.CommandWithResponder, {
            __cbContext: null,
            __constructor: function() { this.__base(); },

            executeAsync: function(request, responder) {
                this.__cbContext = request.context;
                this._executeOperationAsync(request, this, { operationId: "FEATUREPERMISSION.GET_USER_DATA" });
            },

            result: function(data) {
                this.__cbContext.onGetUserDataComplete(data);
            }

        }, {});

        featurepermissioncommands.Class("SaveData", com.servicemax.client.mvc.api.CommandWithResponder, {
            __cbContext: null,
            __constructor: function() { this.__base(); },

            executeAsync: function(request, responder) {
                this.__cbContext = request.context;
                this._executeOperationAsync(request, this, { operationId: "FEATUREPERMISSION.SAVE_DATA" });
            },

            result: function(data) {
                this.__cbContext.saveDataComplete(data);
            }

        }, {});
    };
})()