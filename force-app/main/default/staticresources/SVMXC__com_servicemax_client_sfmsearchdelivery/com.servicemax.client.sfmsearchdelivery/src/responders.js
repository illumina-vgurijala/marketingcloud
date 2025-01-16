/**
 * This file needs a description
 * @class com.servicemax.client.sfmsearchdelivery.responders
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function() {

    var sfmsearchdeliveryresponders = SVMX.Package("com.servicemax.client.sfmsearchdelivery.responders");

    sfmsearchdeliveryresponders.init = function() {

        sfmsearchdeliveryresponders.Class("GetSearchInfoResponder", com.servicemax.client.mvc.api.Responder, {
            __parent: null,
            __constructor: function(parent) {
                this.__base();
                this.__parent = parent;
            },

            result: function(data) {
                this.__parent.onGetSearchInfoCompleted(data);
            },

            fault: function(data) {
                // TODO:
            }

        }, {});

        sfmsearchdeliveryresponders.Class("GetSearchResultResponder", com.servicemax.client.mvc.api.Responder, {
            __parent: null,
            __constructor: function(parent) {
                this.__base();
                this.__parent = parent;
            },

            result: function(data) {},

            fault: function(data) {
                // TODO:
            }

        }, {});
    };
})();

// end of file
