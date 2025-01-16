(function() {
    var featurepermissionoperations = SVMX.Package("com.servicemax.client.featurepermission.operations");

    featurepermissionoperations.init = function() {
        var Module = com.servicemax.client.featurepermission.impl.Module;

        featurepermissionoperations.Class("GetMetaData", com.servicemax.client.mvc.api.Operation, {

            __constructor: function() {
                this.__base();
            },

            performAsync: function(request, responder) {
                featurepermissionObject.JsrGetMetadata('', function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});


        featurepermissionoperations.Class("GetUserData", com.servicemax.client.mvc.api.Operation, {

            __constructor: function() {
                this.__base();
            },

            performAsync: function(request, responder) {
                var requestString = {
                    profileId:request.profileId,
                    searchValue:request.searchValue
                }
                featurepermissionObject.JsrGetUserData(requestString, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});


        featurepermissionoperations.Class("SaveData", com.servicemax.client.mvc.api.Operation, {

            __constructor: function() {
                this.__base();
            },

            performAsync: function(request, responder) {
                featurepermissionObject.JsrSaveData(request.modifiedUsers, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
    };
})();