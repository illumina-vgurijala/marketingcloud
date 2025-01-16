;(function() {
	angular.module('ngCPQ')
		.service('CartDataService', CartDataService); 
			
	CartDataService.$inject = [
		'$http',
		'$rootScope',
		'$q',
		'$log',
		'LineItemCache',
		'LineItemSupport',
		'RemoteService',
		'ActionQueueService',
		'ConfigurationDataService',
		'ConstraintRuleDataService',
		'OptionDataService'
	];

	function CartDataService($http, $rootScope, $q, $log, LineItemCache, LineItemSupport, RemoteService, ActionQueueService, ConfigurationDataService, ConstraintRuleDataService, OptionDataService) {
		var service = this;
		var lineItemArray = []; //This object is always returned by methods that modify the cart
		var totalItemsArray = [];
		var updateEvents;
		var cartHeader;
		var txnPrimaryLineNumber = 10001;
		
		service.transactionJSON = {};
		
		service.getCartHeader = getCartHeader;
		service.getQuoteSummary = getQuoteSummary;
		service.getCartLineItems = getCartLineItems;
		service.getCartLineItemsNew = getCartLineItems;
		service.getLineItem = getLineItem;
		service.getLineItemDetails = getLineItemDetails;
		service.getCartColumns = getCartColumns;
		service.getDisplayActions = getDisplayActions;
		service.getCartTotalsDisplayData = getCartTotalsDisplayData;
		service.getCartTotalSummaryColumns = getCartTotalSummaryColumns;
		service.isProductInCart = isProductInCart;

		service.addToCart = addToCart;
		service.updateCartLineItems = updateCartLineItems;
		service.configureCartLineItems = configureCartLineItems;
		service.getCartTotal = getCartTotal;
		service.removeFromCart = removeFromCart;
		service.resetCart = resetCart;
		// service.createLineItemDO = createLineItemDO;
		// service.createLineItemDOForProduct = createLineItemDOForProduct;
		service.newLineItemFromProductOption = newLineItemFromProductOption;

		//Initialize the action queue with the relevent functions.
		//ActionQueueService.registerActionQueue(registerAllActions());
		//Trying queueing with precedence
		registerAllActions();

		/**
		 * Update the object that is sync'd with the view.
		 * The variable lineItemArray maintians all changes to the line items.
		 *  
		 * @return {Array} reference to the single line item array object
		 */
		function updateLineItemArray() {
			Array.prototype.splice.apply(lineItemArray, [0,lineItemArray.length].concat(LineItemCache.getLineItems()));
			return lineItemArray;

		}
		function updateTotalItemArray(newTotalItems) {
			Array.prototype.splice.apply(totalItemsArray, [0,totalItemsArray.length].concat(newTotalItems));
			return totalItemsArray;

		}


		function getCartHeader() {
			if (cartHeader) {
				return $q.when(cartHeader);

			}
			var includeParams = ['cart'];
			var cartRequest = ConfigurationDataService.createCartRequestDO(null, null, null, includeParams);
			var requestPromise = RemoteService.getCart(cartRequest);

			return requestPromise.then(function(result) {
				cartHeader = result.cart;
				return cartHeader;

			});

		}

		/**
		 * get quote summary for business object id
		 */
		function getQuoteSummary(businessObjectId) {
			return $http.get('/'+businessObjectId+'/m?isAjaxRequest=1').then(function(response) {
				return response.data;
			
			});
		
		}

		/**
		 * Get the line items in the cart. If the cache items are valid,
		 * 	get those instead. Otherwise, call out to remote service for cart.
		 * 
		 * @return {promise}	promise that resolves with a shallow 
		 * 	                  copy of the array of cart line items.
		 */
		function getCartLineItems() {
			// Get cached items by default
			if (LineItemCache.isValid) {
				var lineItems = updateLineItemArray();
				logTransaction(lineItems);
				return $q.when(lineItems);
				// return getCartColumns().then(function (columns) {
				// 	return copyLineItemsForDisplay(LineItemCache.getLineItems(), columns);

				// });

			}
			var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
			var cartRequest = ConfigurationDataService.createCartRequestDO(null, null, null, includeParams);
			var requestPromise = RemoteService.getCartLineItems(cartRequest);

			return requestPromise.then(function(result) {
				logTransaction(result, cartRequest);
				var lineItemData = result.lineItems;
				LineItemCache.putLineItems(lineItemData);
				ConstraintRuleDataService.updateRuleActions(result.ruleActions);				
				return updateLineItemArray();
				//return LineItemCache.getLineItems();
				// return getCartColumns().then(function (columns) {
				// 	return copyLineItemsForDisplay(LineItemCache.getLineItems(), columns);

				// });
			});
			
		}

		/**
		 * Get a line item by its id, i.e. must be an existing line item.
		 * Will resolve with undefined if id is not found.
		 * @param  {string} lineItemId 
		 * @return {promise} resolves with a lineItemDO
		 */
		function getLineItem(txnPLN) {
			return getCartLineItems().then(function(result) {
				return getLineItemDetails(txnPLN);
			// 	return LineItemCache.getLineItem(txnPLN);
			});

		}

		function getLineItemDetails(txnPLN) {
			var lineItemDO = LineItemCache.getLineItem(txnPLN);
			//ToDo: fix this awful conditional
			if (lineItemDO.optionLines && lineItemDO.chargeLines && lineItemDO.chargeLines[0] && lineItemDO.chargeLines[0].lineItemSO.AttributeValueId__r) {
				return $q.when(lineItemDO);
				
			}
			var lineItems = [angular.copy(lineItemDO)];
			
			var includeParams = ['attributeValues'];
			var detailRequst = ConfigurationDataService.createCartRequestDO(lineItems, false, false, includeParams);			
			var requestPromise = RemoteService.getLineItemDetails(detailRequst);

			return requestPromise.then(function(response) {
				var responseLineItem = response.lineItems[0];
				if (responseLineItem) {
					if (!responseLineItem.optionLines) {
						responseLineItem.optionLines = [];

					}
					LineItemCache.putLineItem(responseLineItem);
					return responseLineItem;

				}
				return lineItemDO;

			});

		}

		
		/**
		 * Check whether a particular product exists in a top-level line item.
		 * ToDo: Check against cache.
		 * 
		 * @param  {String}  productId Id of the product.
		 * @return {Boolean}           True if product is in cart.
		 */
		function isProductInCart(productId) {
			return false;

		}

		/**
		 * Experimental, unused. Idea is to pass back copies of the line items with all
		 * 	fields that are to be displayed filled in appropriately and all hidden
		 * 	fields omitted.
		 * 	
		 * @param  {[type]} lineItems      [description]
		 * @param  {[type]} displayColumns [description]
		 * @return {[type]}                [description]
		 */
		function copyLineItemsForDisplay(lineItems, displayColumns) {
			var newItem, newSO, newItems, nextItem, nextSO, nextFieldName, referenceFieldName;
			newItems = [];
			$log.debug(displayColumns);
			for (var itemIndex = 0, itemLength = lineItems.length; itemIndex < itemLength; itemIndex++) {
				nextItem = lineItems[itemIndex];
				nextSO = nextItem.lineItemSO;
				newItem = {};//angular.extend({}, nextItem);
				newSO = {};
				newItem.lineItemSO = newSO;
				for (var colIndex = 0, colLength = displayColumns.length; colIndex < colLength; colIndex++) {
					nextFieldName = displayColumns[colIndex].FieldName;
					if (nextSO[nextFieldName]) {
						fieldValue = nextSO[nextFieldName];

						if (displayColumns[colIndex].FieldType === 'DATE') {
							fieldValue = new Date(fieldValue);

						} else if (displayColumns[colIndex].FieldType === 'REFERENCE') {
							newSO[nextFieldName] = fieldValue;
							nextFieldName = nextFieldName.replace('__c', '__r');
							fieldValue = angular.copy(nextSO[nextFieldName]);

						}
						$log.debug(fieldValue, nextfieldName);
						newSO[nextFieldName] = fieldValue;

					}

				}
				newItems.push(newItem);

			}
			return newItems;

		}


		/**
		 * Get the columns to display for a cart line item.
		 * @return {[type]} [description]
		 */
		function getCartColumns() {
			return ConfigurationDataService.getDisplayColumns().then(function (result) {
				var columnData = angular.copy(result.cartLineItemColumns);
				return columnData;

			});

		}


		/**
		 * 
		 * @return {[type]} [description]
		 */
		function getCartTotalsDisplayData() {
			if (totalItemsArray && totalItemsArray.length) {
				return $q.when(totalItemsArray);

			}
			var includeParams = ['totalLines'];
			var cartRequest = ConfigurationDataService.createCartRequestDO(null, null, true, includeParams);
			return RemoteService.getCart(cartRequest).then(function (result) {
				return updateTotalItemArray(result.totalItems);

			});


		}

		/**
		 * 
		 * @return {[type]} [description]
		 */
		function getCartTotalSummaryColumns() {
			return ConfigurationDataService.getDisplayColumns().then(function (result) {
				var columnData = angular.copy(result.cartTotalItemColumns);
				return columnData;

			});

		}


		/**
		 * Get the action buttons to display 
		 * @return {[type]} [description]
		 */
		function getDisplayActions() {
			return ConfigurationDataService.getDisplayActions().then(function (result) {
				var columnData = angular.copy(result.cartPageActions);
				return columnData;

			});

		}

		/**
		 * Add an array of line items to the cache's temporary items,
		 * 	then schedule an action to sync items with the server. 
		 * 	Line items are in lineItemDO format, and could be generated
		 * 	with createLineItemDO(). 
		 * 
		 * @param {array} 		lineItems 
		 * @return {promise}	promise that resolves with the 
		 */
		// function addToCart(lineItems) {
		// 	lineItems = [].concat(lineItems);
		// 	LineItemCache.putTempLineItems(lineItems);
		// 	updateLineItemArray();
		// 	return ActionQueueService.scheduleSync();

		// }
		function addToCart(product) {
			//Use helper method to wrap product in line item
			return LineItemSupport.newLineItemForProduct(product.productSO, product.quantity)
				.then(function (lineItem) {
					//Cache maintains item structure
					LineItemCache.putTempLineItems([lineItem]);
					updateLineItemArray();
					ActionQueueService.scheduleAction('add');
					return ActionQueueService.scheduleAction('finish');
				});

		}


		/**
		 * Remove an array of line items from cart. These items can be
		 * 	from the server or temporary items -- the cache handles 
		 * 	organizing what to delete.
		 * 	
		 * @param  {array} 	lineItems 
		 * @return {promise}	promise that resolves with the cart line
		 *                    items either immediately or after the 
		 *                    delete has ben sync'd
		 */
		function removeFromCart(lineItems) {
			lineItems = [].concat(lineItems);
			//Set line action
			setLineItemAction(lineItems, 'delete');
			//Remove all items that haven't been sync'd
			var needSync = LineItemCache.removeLineItems(lineItems);
			if (needSync) {
				// return ActionQueueService.scheduleSync();
				ActionQueueService.scheduleAction('remove');
				return ActionQueueService.scheduleAction('finish');

			}
			return $q.when(updateLineItemArray());

		}

		/**
		 * Set one or more line items to have the action 'update' then put them
		 * 	in the modified in cache, then schedule a sync action
		 * 	to make sure the update runs.
		 *
		 * @param  {[type]} lineItems 
		 * @return {promise} promise that will resolve with the cart line
		 *                   items after sync has finished.
		 */
		function updateCartLineItems(lineItems) {
			lineItems = [].concat(lineItems);
			setLineItemAction(lineItems, 'update');
			LineItemCache.putModifiedLineItems(lineItems);
			// return ActionQueueService.scheduleSync();
			ActionQueueService.scheduleAction('update');
			return ActionQueueService.scheduleAction('finish');

		}

		/**
		 * Set one or more line items to have the action 'configure' then put them
		 * 	in the modified in cache, then schedule a sync action
		 * 	to make sure the update runs.
		 *
		 * @param  {[type]} lineItems 
		 * @return {promise} promise that will resolve with the cart line
		 *                   items after sync has finished.
		 */
		function configureCartLineItems(lineItems) {
			lineItems = [].concat(lineItems);
			setLineItemAction(lineItems, 'configure');
			LineItemCache.putModifiedLineItems(lineItems);
			// return ActionQueueService.scheduleSync();
			ActionQueueService.scheduleAction('update');
			return ActionQueueService.scheduleAction('finish');

		}

		/**
		 * Loops through an array of line items at puts the lineAction string
		 * 	on all all of them. If a line item has had its status set to 'configure'
		 * 	the status will not be set. 
		 */
		function setLineItemAction(lineItems, lineAction) {
			var nextItem;
			for (var itemIndex = lineItems.length - 1; itemIndex >= 0; itemIndex--) {
				nextItem = lineItems[itemIndex];
				if (nextItem && nextItem.lineAction != 'configure') {
					nextItem.lineAction = lineAction;

				}

			}
			return lineItems;

		}

		/**
		 * Marks the cache as invalid so that a call to getCartLineItems
		 * 	will perform a remote call
		 * 	 
		 * @return {boolen} whether the cache was valid before
		 */
		function resetCart() {
			var wasValid = LineItemCache.isValid;
			LineItemCache.isValid = false;
			return wasValid;

		}

		/**
		 * Get the javscript-calculated total price. 
		 * 
		 * @return {number} total
		 */
		function getCartTotal() {
			return LineItemCache.getLineItems().total;

		}


		/**
		 * --- Depricated ---
		 * Currently used to notify view of new line items when response 
		 * 	comes back from server.
		 */
		// function broadcastUpdateEvents() {
		// 	updateLineItemArray();
		// 	var broadcastDate = new Date();
		// 	angular.forEach(updateEvents, function(value, key){
		// 		value.lastBroadcast = broadcastDate;
		// 		$rootScope.$broadcast(key);
		// 	});
		// 	return lineItemArray;

		// }

		// function registerUpdateEvent(eventName) {
		// 	if (typeof eventName !== 'string') {
		// 		return void(0);

		// 	}
		// 	if (!updateEvents) {
		// 		updateEvents = {};
				
		// 	}
		// 	if (!updateEvents[eventName]) {
		// 		//Creating a little object to track broadcasts
		// 		updateEvents[eventName] = {
		// 			registered: new Date(),
		// 			lastBroadcast: "N/A"
		// 		};

		// 	}
		// 	return updateEvents;

		// }

		/**
		 * If another action should be executed, add it here.
		 * 
		 * Builds a queue of functions for synchronizing the cache with 
		 * 	the server. Each action checks if a request should be made,
		 * 	and returns a promise that resolves when its request is complete.
		 * Actions that may 
		 * 	
		 * Order of actions:
		 * 	1: If there are modified items, send them in an update action.
		 * 	2: If there are temporary additions, the temp line
		 * 			items are made pending and a request to add them is
		 * 			submitted. 
		 * 	3: If there are temp deletions, those are made pending 
		 * 			and a request to remove them is submitted.
		 *  ?: TODO: Constraint rules go here
		 * 	4: If there are items with price pending, a request 
		 * 			is sumbmitted to continue processing pricing.
		 * 	5: A final action is always added. This may schedule
		 * 			another sync event (if price is pending), and it
		 * 			resolves by getting items from the cart. 
		 * 			
		 * @return {Array of Functions} the actions in the order to execute.
		 */
		function registerAllActions() {
			actionQueue = [
				update,
				add,
				remove,
				reprice,
				finish
			];
			ActionQueueService.registerAction(update, 10, 'update');
			ActionQueueService.registerAction(add, 9, 'add');
			ActionQueueService.registerAction(remove, 8, 'remove');
			ActionQueueService.registerAction(reprice, 7, 'reprice');
			ActionQueueService.registerAction(finish, 6, 'finish');
			return actionQueue;


			/**
			 * For now, just pass the rejected promise up.
			 */
			function onRejection(reason) {
				return $q.reject(reason);

			}
			
			function update() {
				var pendingUpdatesKey = LineItemCache.generatePendingUpdates();
				if (pendingUpdatesKey) {
					var pendingUpdates = LineItemCache.getPendingUpdates(pendingUpdatesKey);
					var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
					var cartRequest = ConfigurationDataService.createCartRequestDO(pendingUpdates, true, true, includeParams);
					var actionPromise = RemoteService.updateCart(cartRequest);
					return actionPromise.then(
						function(result) {
							var lineItemData = result.lineItems;
							LineItemCache.putLineItems(lineItemData, pendingUpdatesKey);
							ConstraintRuleDataService.updateRuleActions(result.ruleActions);
							return updateLineItemArray();
							
						}, 
						onRejection
					);
					
				}

			}

			function add() {
				//$log.debug('Addding?');
				var pendingAdditionsKey = LineItemCache.generatePendingAdditions();
				if (pendingAdditionsKey) {
					//$log.debug('Addding -- yep');
					var pendingAdditionItems = LineItemCache.getPendingAdditions(pendingAdditionsKey);
					var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
					var cartRequest = ConfigurationDataService.createCartRequestDO(pendingAdditionItems, true, false, includeParams);
					var actionPromise = RemoteService.addToCart(cartRequest);
					return actionPromise.then(
						function(result) {
							var lineItemData = result.lineItems;
							LineItemCache.putLineItems(lineItemData, pendingAdditionsKey);
							ConstraintRuleDataService.updateRuleActions(result.ruleActions);
							return updateLineItemArray();
							
						}, 
						onRejection
					);
					
				}

			}

			function remove() {
				var pendingDeletionsKey = LineItemCache.generatePendingDeletions();
				if (pendingDeletionsKey) {
					var pendingDeletionItems = LineItemCache.getPendingDeletions(pendingDeletionsKey);
					var includeParams = ['cartLines', 'chargeLines', 'ruleActions'];
					var cartRequest = ConfigurationDataService.createCartRequestDO(pendingDeletionItems, true, false, includeParams);
					var actionPromise = RemoteService.deleteLineItems(cartRequest);
					return actionPromise.then(
						function(result) {
							var lineItemData = result.lineItems;
							LineItemCache.putLineItems(lineItemData, pendingDeletionsKey);
							ConstraintRuleDataService.updateRuleActions(result.ruleActions);
							return updateLineItemArray();
							
						}, 
						onRejection
					);
					
				}

			}

			function reprice() {
				//$log.debug('Repricing?');
				if (LineItemCache.getIsPricePending()) {
					//$log.debug('Repricing? -- yep');
					var includeParams = ['cartLines', 'chargeLines', 'ruleActions', 'totalLines'];
					var cartRequest = ConfigurationDataService.createCartRequestDO(null, false, true, includeParams);
					var actionPromise = RemoteService.updatePrice(cartRequest);
					return actionPromise.then(
						function(result) {
							var lineItemData = result.lineItems;
							var totalsData = result.totalItems;
							updateTotalItemArray(totalsData);
							LineItemCache.putLineItems(lineItemData);
							return updateLineItemArray();
							
						}, 
						onRejection
					);

				}
				return $q.when(updateLineItemArray());

			}

			function finish() {
				//$log.debug('Finishing?');
				if (LineItemCache.getIsPricePending()) {
					//$log.debug('Finishing -- repricing');
					// ActionQueueService.scheduleSync();
					ActionQueueService.scheduleAction('reprice');
					ActionQueueService.scheduleAction('finish');


				}
				return updateLineItemArray();

			}

		}

		function newLineItemFromProductOption(productOptionComponenet) {
			return LineItemSupport.newOptionLineItemForComponent(productOptionComponenet)
				.then(function (optionLineItem) {
					var productId = productOptionComponenet.ComponentProductId__c;
					newOptionLinesForProduct(productId)
						.then(function (newOptionLines) {
							optionLineItem.optionLines = newOptionLines;
							
						});
					return optionLineItem;

				});

		}

		function newOptionLinesForProduct(productId) {
			return OptionDataService.getOptionGroups(productId).then(function (optionGroups) {
				var nextGroup, nextOption, subOptionPromises;
				subOptionPromises = [];
				if (optionGroups)	{
					for (var groupIndex = 0, groupsLength = optionGroups.length; groupIndex < groupsLength; groupIndex++) {
						nextGroup = optionGroups[groupIndex];
						for (var optionIndex = 0, optionsLength = nextGroup.options.length; optionIndex < optionsLength; optionIndex++) {
							nextOption = nextGroup.options[optionIndex];
							//ToDo: Namespace prefix
							if (nextOption.Default__c) {
								subOptionPromises.push(newLineItemFromProductOption(nextOption));

							}
						
						} 		
					}
					return $q.all(subOptionPromises);

				}
				return [];

			});

		}


		function getNextTxnPrimaryLineNumber() {
			return txnPrimaryLineNumber ++;

		}

		function logTransaction(response, request) {
			transaction = {};
			if (!request) {
				transaction.request = "cache";

			} else {
				transaction.request = request;
				
			}
			transaction.response = response;
			service.transactionJSON = transaction;

		}
		
	

	
	}

})();