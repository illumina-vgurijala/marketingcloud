/**
 * @description This file acts as a bridge between the snippet and the jsee.
 * @class com.servicemax.client.sfmconsole.expressionbridge
 * @author Indresh MS
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var bridgeImpl = SVMX.Package("com.servicemax.client.sfmconsole.expressionbridge");

bridgeImpl.init = function(){

	if(window.$EXPR == undefined || window.$EXPR == null) window.$EXPR = {};

	/////////////////////////////// CORE ///////////////////////////

	/**
	 * The core API method to evaluate the JS expression
	 *
	 * @param expression String the expression that needs to be evaluated
	 * @param context Object the contextual data that this expression works on
	 * @param callId String the unique identifier assigned to a particular call. This serves as a index to the call back function
	 */
	$EXPR.SVMXEvalExpression = function(expression, context, callbackHandler, callBackContext){
		// simulate the asynchronous nature by executing the rest of the method on a timeout
		setTimeout(function(){
			var callbackContext = {
					callbackHandler : callbackHandler,
					callBackContext : callBackContext,
					handler : function(result){
						this.callbackHandler.call(this.callBackContext, result);
					}
			};

			try{
			// trigger the evaluation
			$EXPR.executeExpression(
				expression, context, callbackContext.handler, callbackContext, true);
			}catch(e){
				$EXPR.Logger.error("Error while performing EVAL! Please check for syntax error in the JS snippet! =>" + e);
				callbackContext.handler(context);
			}
		}, 0);
	};

	$EXPR.showMessage = function(options){
		SVMX.getCurrentApplication().getApplicationMessageUIHandler().showMessage(options);
	};

	/////////////////////////// END CORE ///////////////////////////

};

})();
