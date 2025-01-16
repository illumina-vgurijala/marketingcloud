/**
 * This file needs a description
 * @class com.servicemax.client.sfmconsole.commands
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function() {
    var sfmconsolecommands = SVMX.Package("com.servicemax.client.sfmconsole.commands");

    sfmconsolecommands.init = function() {
        // moved all the commands to delivery engines

        // not used; getUserInfo is instead retrieved via the sync engine for laptop client, and by sfmdelivery for online client
        sfmconsolecommands.Class("GetUserInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMCONSOLE.GET_USERINFO"
                });
            }
        }, {});


        /**
         * GetAppInfo operation returns an appinfo object that can be used in about screens across platforms.
         *
         * {
         *   version: 'app version number (ex: 15.49.002)',
         *   server_version: 'server version number (ex: 15.20000)',
         *   org_type: 'production or sandbox',
         *   org_tag: 'translation tag',
         *   user_name: 'logged in user name',
         *   user_login: 'logged in user email address'
         * }
         *
         * @class com.servicemax.client.offline.sal.model.sfmconsole.operations.GetAppInfo
         * @extends com.servicemax.client.mvc.api.Operation
         */
        sfmconsolecommands.Class("GetAppInfo", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            /**
             * executeAsync performs the command body (usually performing an operation)
             *
             * @param request
             * @param responder
             */
            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMCONSOLE.GET_APP_INFO"
                });
            }
        }, {});

        // TODO: Move this to responders.js
        sfmconsolecommands.Class("GetUserInfoResponder", com.servicemax.client.mvc.api.Responder, {
            __parent: null,
            __constructor: function(parent) {
                this.__base();
                this.__parent = parent;
            },

            result: function(data) {
                this.__parent.onGetUserInfoCompleted(data);
            },

            fault: function(data) {
                // TODO:
            }

        }, {});

        sfmconsolecommands.Class("RetrieveDisplayTags", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMCONSOLE.RETRIEVE_DISPLAY_TAGS"
                });
            }
        }, {});

        sfmconsolecommands.Class("RetrieveDisplayTagsResponder", com.servicemax.client.mvc.api.Responder, {
            __parent: null,
            __callback: null,
            __constructor: function(parent, callback) {
                this.__base();
                this.__parent = parent;
                this.__callback = callback;
            },

            result: function(translationService) {
                this.__parent.onRetrieveDisplayTags(translationService, null, this.__callback);
            },

            fault: function(translationService, errorMsg) {
                this.__parent.onRetrieveDisplayTags(translationService, errorMsg, this.__callback);
            }
        }, {});

        /**
         * Sign a user out, currently only relevant to phones and tablets.
         *
         */
        sfmconsolecommands.Class("SignOutUser", com.servicemax.client.mvc.api.Command, {

            __constructor: function() {
                this.__base();
            },

            /**
             *
             * @param request
             * @param responder
             */
            executeAsync: function(request, responder) {
                this._executeOperationAsync(request, responder, {
                    operationId: "SFMCONSOLE.SIGNOUT"
                });
            }
        }, {});

    };

})();

// end of file
