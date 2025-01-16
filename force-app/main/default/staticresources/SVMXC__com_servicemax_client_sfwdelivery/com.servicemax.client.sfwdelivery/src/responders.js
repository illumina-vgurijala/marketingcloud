/**
 * #package#
 * SFW delivery responders
 *
 * @class com.servicemax.client.sfwdelivery.responders
 * @author Jon Kinsting
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	var sfwResponders = SVMX.Package("com.servicemax.client.sfwdelivery.responders");

sfwResponders.init = function(){

    /**
     * SFW delivery responders
     *
     * @class       com.servicemax.client.sfwdelivery.responders.GetWizardInfoResponder
     * @extends     com.servicemax.client.mvc.api.Responder
     * @author      Jon Kinsting
     * @copyright   2013 ServiceMax, Inc.
     */
	sfwResponders.Class("GetWizardInfoResponder", com.servicemax.client.mvc.api.Responder, {
		__parent : null,
		__constructor : function(parent) {
			this.__base();
			this.__parent = parent;
		},

        /**
         * Handles the success condition
         *
         * @param   {data}
         */
		result : function(data) {
			this.__parent.onGetWizardInfoCompleted( data );
		},

        /**
         * Handles the fault condition
         *
         * @param   {error}
         */
        fault : function(error) {
			this.__parent.onGetWizardInfoFailed( error );
		}

	}, {});


};
})();