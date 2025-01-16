;(function() {
	angular.module('ngCPQ')
		.service('RemoteService', RemoteService); 
	
	RemoteService.$inject = ['$q', '$log', 'RemoteActions'];
	
	function RemoteService($q, $log, RemoteActions) {
		var service = this;
		var lastTransaction = {};

		/**
		 * Each method passes its fully-qualified name and its
		 * 	arguments to invokeRemoteAction. The arguments passed
		 * 	to this function should just match the signature of 
		 * 	the Apex method. 
		 * @return {promise} resolves with the result of the remote action
		 */
		service.getCategories = function getCategories() {
			return invokeRemoteAction(RemoteActions.getCategories, arguments);

		};
		service.getProducts = function getProducts() {
			return invokeRemoteAction(RemoteActions.getProducts, arguments);

		};
		service.searchProducts = function searchProducts() {
			return invokeRemoteAction(RemoteActions.searchProducts, arguments);

		};
		service.getConfigurationData = function getConfigurationData() {
			return invokeRemoteAction(RemoteActions.getConfigurationData, arguments);

		};
		service.getCartLineItems = function getCartLineItems() {
			return invokeRemoteAction(RemoteActions.getCartLineItems, arguments);

		};
		service.getCart = function getCart() {
			return invokeRemoteAction(RemoteActions.getCart, arguments);

		};
		service.addToCart = function addToCart() {
			return invokeRemoteAction(RemoteActions.addToCart, arguments);

		};
		service.deleteLineItems = function deleteLineItems() {
			return invokeRemoteAction(RemoteActions.deleteLineItems, arguments);

		};
		service.updatePrice = function updatePrice() {
			return invokeRemoteAction(RemoteActions.updatePrice, arguments);

		};
		service.updateCart = function updateCart() {
			return invokeRemoteAction(RemoteActions.updateCart, arguments);

		};
		service.performAction = function performAction() {
			return invokeRemoteAction(RemoteActions.performAction, arguments);

		};
		service.getLineItemDetails = function getLineItemDetails() {
			return invokeRemoteAction(RemoteActions.getLineItemDetails, arguments);

		};
		service.getProductDetails = function getProductDetails() {
			return invokeRemoteAction(RemoteActions.getProductDetails, arguments);

		};
		service.getConfigurationData = function getConfigurationData() {
			return invokeRemoteAction(RemoteActions.getConfigurationData, arguments);

		};
		service.getAssetLineItems = function getAssetLineItems() {
			return invokeRemoteAction(RemoteActions.getAssetLineItems, arguments);
		};
		service.getAssetFilters = function getAssetFilters() {
			return invokeRemoteAction(RemoteActions.getAssetFilters, arguments);
		}

		//Expose general-purpose method
		service.invokeRemoteAction = invokeRemoteAction;
		
		/**
		 * Helper for calling visualforce remoting. 
		 *  
		 * @param 	{string}	actionName 	the remote action to invoke
		 * @param 	{array}		actionParams	any number of parameters to pass to remote
		 *          												action before callback 
		 * @return {promise} a $q promise that resolves with result of remote action
		 *
		 * Example: 
		 * 		<code>
		 * 		var thenable = invokeRemoteAction(RemoteActions.getCartLineItems, [cartRequest]);
		 * 		thenable.then(function (result) {
		 * 			useResult(result);
		 * 		});
		 * 		</code>
		 * Here, thenable will be a promise that gets resolved with the result of the remote action 
		 */
		function invokeRemoteAction(actionName, actionParams) {
			//Constuct deferred object for return
			var deferred, errorMessage, remoteActionWithParams, resolver, remotingParams;
			deferred = $q.defer();
			if (!actionName || typeof actionName !== 'string') {
				errorMessage = "Error - Could not invoke remote action: action name invalid!";
				$log.error(errorMessage);
				deferred.reject(errorMessage);
				return deferred.promise;

			}
			//Construct list with aciton name and parameters to pass to invokeAction
			remoteActionWithParams = [actionName];
			for (var argIndex = 0, nextArg; argIndex < actionParams.length; argIndex++) {
				nextArg = actionParams[argIndex];
				if (!nextArg) {
					errorMessage = "Error - Could not construct remote action parameters. Parameter #" + argIndex +" is undefined!";
					$log.error(errorMessage);
					deferred.reject(errorMessage);
					return deferred.promise;

				}
				remoteActionWithParams.push(nextArg);

			}
			//Add the resolve function and remoting params to argument array
			resolver = function resolveRemoteAction(result, event) {
				if (event.status) {
					deferred.resolve(result);
					
				} else {
					errorMessage = 'Error - Could not invoke remote action: ' + actionName; 
					$log.error(errorMessage, actionParams, event.message);
					deferred.reject(event.message);

				}
				
			};
			remoteActionWithParams.push(resolver);

			//Add the default parameters for remoting call
			remotingParams = {
				"buffer": false, 
				"escape": false, 
				"timeout": 30000
			};
			remoteActionWithParams.push(remotingParams);

			//Try to call visualforce remoting invokeAction with the parameters we built 
			try {
				Visualforce.remoting.Manager.invokeAction.apply(Visualforce.remoting.Manager, remoteActionWithParams);

			} catch(ex) {
				errorMessage = 'Error - Could not invoke remote action: ' + actionName; 
				$log.error(errorMessage, actionParams, ex);
				deferred.reject(errorMessage);
					
			}
			return deferred.promise;

		}

	}

})();