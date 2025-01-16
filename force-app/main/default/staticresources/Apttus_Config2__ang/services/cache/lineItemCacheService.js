(function() {
	angular.module('ngCPQ')
		.service('LineItemCache', LineItemCache); 

	/**
	 * Structure for maintaining available line items in cart.
	 * Importantly, used to keep line items in three states:
	 * 		- tempLineItems: have been added locally, but not submitted to server
	 * 		- pendingLineItems: have been submitted but their response has not come back  
	 * 		- lineItems: have been retrieved from server
	 *
	 *  Has been broken into its own service.
	 */
	function LineItemCache () {
		var hashCount = 0; 
		var pendingAdditionsSize = 0;
		var pendingDeletionsSize = 0;
		var lineItemTotal = 0;
		var isPricePending = true;
		var isAllItemsValid = false;
		var isItemsModified = false;

		var allItemsList = [];
		//var lineItems = [];
		var mainLineItemSet = new LineItemSet();
		var tempLineItems = [];
		var modifiedSet = new LineItemSet();
		var tempDeletionsSet = new LineItemSet();
		//Maps: hashKey => lineItemDO
		var pendingAdditionsMap = {};
		var pendingDeletionsMap = {};
		var pendingUpdatesMap = {};

		//Cach interface
		var cache = {
			isValid: false,
			getLineItems: getLineItems,
			getLineItem: getLineItem,
			getSize: getSize,
			getIsPricePending: getIsPricePending,
			putLineItems: putLineItems,
			putLineItem: putLineItem,
			putTempLineItems: putTempLineItems,
			putModifiedLineItems: putModifiedLineItems,
			removeLineItems: removeLineItems,
			generatePendingAdditions: generatePendingAdditions,
			generatePendingDeletions: generatePendingDeletions,
			generatePendingUpdates: generatePendingUpdates,
			getPendingAdditions: getPendingAdditions,
			getPendingDeletions: getPendingDeletions,
			getPendingUpdates: getPendingUpdates
			
		};
		return cache;

		/* - Method declarations - */

		/**
		 * Return the array of items in all states. 
		 * If called multiple times, this will only have to concat
		 * 	all the items into a list once.
		 * @return {array of line items}
		 */
		function getLineItems() {
			if (!isAllItemsValid) {
				refreshAllItemsList();

			}
			return allItemsList;

		}
		/** Get a line item in the cache by id */
		function getLineItem(lineItemId) {
			return mainLineItemSet.getItem(lineItemId);

		}
		/**
		 * Concat line items from all states into a list for display
		 * Does not perform a deep copy -- i.e. modifications elsewhere
		 *  change the cache. Upside is that this won't use extra space,
		 *  except the size of the arrray.
		 * Modifications to lineItems and pendingLineItems will not be submitted to server
		 * @return {list of line items} 
		 */
		function refreshAllItemsList() {
			if (!cache.isValid) {
				allItemsList = [];
				return allItemsList;

			}
			allItemsList = mainLineItemSet.getAllItems();
			// if (lineItems.length > 0) {
			// 	allItemsList = allItemsList.concat(lineItems);
				
			// }
			//Loop accross object could be done with angular.forEach instead
			for (var hashKey in pendingAdditionsMap) {
				if (pendingAdditionsMap.hasOwnProperty(hashKey)) {
					allItemsList = allItemsList.concat(pendingAdditionsMap[hashKey]);
				
				}

			}
			if (tempLineItems.length > 0) {
				allItemsList = allItemsList.concat(tempLineItems);

			}
			isAllItemsValid = true;
			allItemsList.total = lineItemTotal;
			return allItemsList;

		}
		function getSize() {
			if (!cache.isValid) {
				return 0;

			}
			return (mainLineItemSet.size +
							pendingAdditionsSize +
							tempLineItems.length);

		}
		function getIsPricePending() {
			return isPricePending;

		}
		function putLineItems(items, pendingHashKey) {
			cache.isValid = !!items;
			isAllItemsValid = false;
			isItemsModified = false;
			// lineItems = items;
			//Should this merge them?
			mainLineItemSet = new LineItemSet(items);
			//Need do an overwrite instead of a merge because charge lines are coming
			// back at the wrong level. 
			//mainLineItemSet.mergeAllItems(items);
			if (pendingHashKey && pendingAdditionsMap[pendingHashKey]) {
				pendingAdditionsSize -= pendingAdditionsMap[pendingHashKey].length;
				delete pendingAdditionsMap[pendingHashKey];

			} else if (pendingHashKey && pendingDeletionsMap[pendingHashKey]) {
				delete pendingDeletionsMap[pendingHashKey];

			} else if (pendingHashKey && pendingUpdatesMap[pendingHashKey]) {
				delete pendingUpdatesMap[pendingHashKey];

			}
			processLineItems();

		}
		function putLineItem(item) {
			isAllItemsValid = false;
			mainLineItemSet.mergeItem(item);

		}
		function putTempLineItems(items) {
			isAllItemsValid = false;
			items = (items || []);
			tempLineItems = (tempLineItems || []).concat(items);

		}
		//TODO: track the modified in a set
		function putModifiedLineItems(items) {
			isItemsModified = true;
			modifiedSet.addAllItems(items);

		}
		function removeLineItems(itemsToRemove) {
			isAllItemsValid = false;
			itemsToRemove = removeTempLineItems(itemsToRemove);
			var realItemToDelete = false;
			var nextItem;
			for (var i = 0; i < itemsToRemove.length; i++) {
				nextItem = itemsToRemove[i];
				if (mainLineItemSet.hasItem(nextItem)) {
					realItemToDelete = true;
					nextItem.lineAction = 'delete';
					tempDeletionsSet.addItem(nextItem);
					mainLineItemSet.deleteItem(nextItem);

				}

			}
			return realItemToDelete;

		}
		function removeTempLineItems(itemsToRemove) {
			var newTempItems = [];
			var nextItem, itemFound, i, j;
			for (i = 0; i < tempLineItems.length; i++) {
				nextItem = tempLineItems[i];
				itemFound = false;
				for (j = 0; j < itemsToRemove.length; j++) {
					if (nextItem === itemsToRemove[j]) {
						itemFound = true;
						break;

					}

				}
				if (itemFound) {
					itemsToRemove.splice(j, 1);

				} else {
					newTempItems.push(nextItem);

				}

			}
			tempLineItems = newTempItems;
			return itemsToRemove;

		}
		function generatePendingAdditions() {
			var hashKey;
			if (tempLineItems.length === 0) {
				return hashKey;

			}
			hashKey = generateHash();
			pendingAdditionsMap[hashKey] = angular.copy(tempLineItems);
			pendingAdditionsSize += tempLineItems.size;
			tempLineItems = [];
			return hashKey;

		}
		function generatePendingDeletions() {
			var hashKey;
			var itemsToDelete = tempDeletionsSet.getAllItems();
			if (itemsToDelete.length === 0) {
				return hashKey;

			}
			hashKey = generateHash();
			pendingDeletionsMap[hashKey] = angular.copy(itemsToDelete);
			tempDeletionsSet = new LineItemSet();
			return hashKey;

		}
		function generatePendingUpdates() {
			var hashKey;
			var itemsToUpdate = modifiedSet.getAllItems();
			if (itemsToUpdate.length === 0) {
				return hashKey;

			}
			hashKey = generateHash();
			pendingUpdatesMap[hashKey] = angular.copy(itemsToUpdate);
			modifiedSet = new LineItemSet();
			return hashKey;

		}
		//TODO: get only those items which have changes.
		function getPendingUpdates(hashKey) {
			if (hashKey && pendingUpdatesMap[hashKey]) {
				return pendingUpdatesMap[hashKey];

			}
			return [];

		}
		function getPendingAdditions(hashKey) {
			if (hashKey && pendingAdditionsMap[hashKey]) {
				return pendingAdditionsMap[hashKey];

			}
			return [];

		}
		function getPendingDeletions(hashKey) {
			if (hashKey && pendingDeletionsMap[hashKey]) {
				return pendingDeletionsMap[hashKey];

			}
			return [];

		}
		//Used for giving unique hash code to items in pending items map
		//Originally the system time string + random int, now just a count.
		function generateHash() {
			return String(hashCount ++);
			// var dateStr = (new Date()).toISOString();
			// var randInt = (Math.random() * 100000).toFixed();
			// return (dateStr + randInt);

		}	

		/**
		 *	--- Going to remove this processing to keep cached copy clean ---
		 * 
		 * Any repeat processing of all line items should be handled here.
		 * Modifies the line items in-place.
		 */
		function processLineItems() {
			var total = 0;
			var priceAsNum;
			var nextItem;
			var sObject;
			var isPending = false;
			var dateFields = ['StartDate__c', 'EndDate__c'];
			var lineItems = mainLineItemSet.getAllItems();
			for (var itemIndex = lineItems.length - 1; itemIndex >= 0; itemIndex--) {
				nextItem = lineItems[itemIndex];
				if (!(nextItem && nextItem.chargeLines && nextItem.chargeLines[0])) {
					continue;
					
				}
				sObject = nextItem.chargeLines[0].lineItemSO;
				if (!sObject) {
					continue;

				}
				//Check if item has been marked for deletion
				if (tempDeletionsSet.hasId(sObject.Id)) {
					nextItem.lineAction = "delete";
					mainLineItemSet.deleteItem(nextItem);
					continue;

				}
				//Format date
				// for (var dateIndex = dateFields.length - 1; dateIndex >= 0; dateIndex--) {
				// 	dateField = dateFields[dateIndex];
				// 	if (sObject[dateField]) {
				// 		sObject[dateField] = new Date(sObject[dateField]);

				// 	}

				// }
				//Get pricing information
				if (sObject.PricingStatus__c === "Pending") {
					isPending = true;

				} else  {
					priceAsNum = Number(sObject.NetPrice__c);
					if (priceAsNum && !isNaN(priceAsNum)) {
						total += priceAsNum;
					
					}  

				}

			}
			lineItemTotal = total;
			isPricePending = isPending;

		}


		/**
		 * Constructor for making a set specifically for line items. This lets
		 * 	us try out different ways of hashing and merging line items to keep
		 * 	the DO's on the client side in sync with the server responses.
		 * 	
		 * @param {array} initItems [items to add to the set immediately.]
		 */
		function LineItemSet(initItems) {
			return new ItemSet(initItems, lineItemHashFunction, lineItemMergeFunction, lineItemComparatorFunction);

			function lineItemHashFunction(lineItemDO) {
				var itemId = lineItemDO.txnPrimaryLineNumber;
				return itemId;

			}

			function lineItemMergeFunction(firstItem, secondItem) {
				return angular.extend(firstItem, secondItem);

			}

			function lineItemComparatorFunction(firstItem, secondItem) {
				function getSequence(item) {
					var sequence;
					if (item && item.chargeLines && item.chargeLines[0] && item.chargeLines[0].lineItemSO) {
						sequence = item.chargeLines[0].lineItemSO.ItemSequence__c;

					}
					sequence = Number(sequence || item.txnPrimaryLineNumber || 0);
					return sequence;

				}
				var firstSequence = getSequence(firstItem);
				var secondSequence = getSequence(secondItem);
				return firstSequence - secondSequence;

			}

		}

		/**
		 * Set used for stashing various types of things by a hash value.
		 * Used with lineItemHashFunction to save line items by their Id.
		 * Keeping this general for now so that it can be moved out to 
		 * 	a utility service.
		 * 
		 */
		function ItemSet(initItems, customHash, customMerge, customCompare) {
			var items = new Object(null);
			var itemSet = this;
			var hash = defaultHash;
			var merge = defaultMerge;
			var compare;
			
			itemSet.size = 0;
			itemSet.hasItem = hasItem;
			itemSet.hasId = hasId;
			itemSet.getItem = getItem;
			itemSet.getAllItems = getAllItems;
			itemSet.addItem = addItem;
			itemSet.addAllItems = addAllItems;
			itemSet.mergeItem = mergeItem;
			itemSet.mergeAllItems = mergeAllItems;
			itemSet.deleteItem = deleteItem;

			init();

			function init() {
				if (typeof customHash === 'function') {
					hash = customHash;

				}
				if (typeof customMerge === 'function') {
					merge = customMerge;

				}
				if (typeof customCompare === 'function') {
					compare = customCompare;

				}
				addAllItems(initItems);
				
			}

			function defaultHash(item) {
				var hashVal;
				if (typeof item === 'object') {
					hashVal = JSON.stringify(item);

				} else if (typeof item === 'function') {
					hashVal = item.prototype.constructor.toString();

				} else {
					hashVal = '' + item;

				} 
				return hashVal;

			}

			function defaultMerge(firstItem, secondItem) {
				return angular.extend(firstItem, secondItem);

			}

			function hasItem(item) {
				var itemId  = hash(item);
				return !!(items[itemId]);

			}
			function hasId(id) {
				if (!id || typeof id === 'object') {
					return false;

				}
				return !!(items[id]);

			}
			function getItem(id) {
				if (!id || !items[id]) {
					return void(0);

				}
				return items[id];

			}
			function addItem(item) {
				var itemId;
				if (item) {
					itemId = hash(item);

				}
				if (itemId) {
					if (!items[itemId]) {
						itemSet.size ++;

					}
					items[itemId] = item;
					
				} 
				return itemSet;

			}
			function addAllItems(allItems) {
				if (allItems) {
					for (var i = 0; i < allItems.length; i ++) {
						addItem(allItems[i]);

					}

				}
				return itemSet;

			}
			//Experimenting with merging line items	
			function mergeItem(item) {
				var itemId;
				if (item) {
					itemId = hash(item);

				}
				if (itemId) {
					var existing = items[itemId];
					if (!existing) {
						items[itemId] = item;
						itemSet.size ++;

					} else {
						merge(existing, item);

					}
					
				} 
				return itemSet;

			}
			function mergeAllItems(allItems) {
				if (allItems) {
					for (var i = 0; i < allItems.length; i ++) {
						mergeItem(allItems[i]);

					}

				}
				return itemSet;

			}	
			function deleteItem(item) {
				var itemId;
				if (item) {
					itemId = hash(item);

				}
				if (itemId && items[itemId] && delete items[itemId]) {
					itemSet.size --;
					return true;
					
				} 
				return false;

			}
			function getAllItems() {
				var nextItem;
				var allItems = [];
				for (var key in items) {
					nextItem = getItem(key);
					if (nextItem) {
						allItems.push(nextItem);
						
					}

				}
				allItems.sort(compare);
				return allItems;

			}

		}


	}
})();