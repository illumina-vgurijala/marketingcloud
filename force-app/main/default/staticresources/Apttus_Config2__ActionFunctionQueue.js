;jQuery.aptActionFunctionQueue = 
(function($) {

    // Private variables 
    var _queuedFunctions = [],		// Queued function awaiting processing
    	_lastProcessed,				// Last processed function
    	_lastProcessedIdx = {},		// indecies of last batch of functions submitted
    	_pendingButtonSpinners = {},// pending button spinners
    	_settings = {				
	    	automaticQueue: false,	// Process queue automatically (don't rely on prior completion)
	    	debugMode:false,		// Turn logging on/off
	    	skipToEndOfQueue:[], 	// skip to end of queue (abandon the rest)
	    	queuedPrecedence:{},	// Function precedence used to handle the order of submission 
	    	callbacks:{				// Various callbacks 
	    		queueEmpty:[],
	    		resumeHandler : [],		
	    		resetHandler : [],		
	    		pauseHandler : [],
	    		noneHandler: []		
	    	},
	    	isQueuePaused: false,	// Used to pause queue (all calls to processNext will be ignored)	   
	    	usePauseHandling: false,
	    	queuedPauseHandling: {} // Hash each enqueued function to its pause/resume handling behavior
	    };    

	// public functions
	return {

		/**
		 * Return the functions which are queued		 
		 * @return true is function type is queued, false otherwise
		 */
		getQueuedFunctions: function() {
			
			return _queuedFunctions;		
		},

		/**
		 * Get the indecies of last batch of functions submitted 
		 * @return indecies of last batch of functions submitted
		 */
		getLastProcessed: function() {
			return _lastProcessedIdx;

		},

		/**
		 * Add item to queue and execute.
		 *
		 * Note: This is specific to VF ActionFunctions 
		 * Thus the onComplete method of the ActionFunction must
		 * call processNext() to keep the queue moving.
		 *
		 * @param 	actionFunctionRef
		 *			the action function to execute
		 *
		 * @param 	functionArgs
		 *			arguments as an array, single argument or 
		 *			key/value object pair
		 *
		 * @param 	disableBuffering
		 *			disable buffering flag
		 *		
		 * @return deferred object which status follows the progress of
		 *		   the context action function
		 */
		execute: function(actionFunction, functionArgs, properties) {
			return $.Deferred(
				function(dfd) {	        				
					// Create queue function object
					_log('Creating queue object.');

					// create default properties
					var defaultProperties = {
						disableBuffering:false,
						loadingLabel:'',
						showLoadingLabel:true,
						spinners:undefined,
						pauseHandling: 'None',
						isActionFunction:true
					}

					// pass on to queue creation object
					var queuedFunctionObj = _createQueueObject(actionFunction, functionArgs, dfd, $.extend( {}, defaultProperties, properties));
					_log(queuedFunctionObj);

					// Expect to process if new item is first item in queue
					var handleNext = _queuedFunctions.length == 0;
					if (_settings.usePauseHandling) {
						var pauseHandling = _settings.queuedPauseHandling[_hashFunction(actionFunction.toString())]
						if (pauseHandling === 'Pause') {
							_settings.isQueuePaused = true;
							handleNext = false;

						} else if (pauseHandling === 'Resume') {
							handleNext = handleNext || _settings.isQueuePaused;
							_settings.isQueuePaused = false;

						} else if (pauseHandling === 'Reset') {
							_settings.isQueuePaused = false;
							_queuedFunctions.length = 0;
							handleNext = true;

						} else {
							pauseHandling = 'None';

						}
						_invokePauseHandler(pauseHandling);

					}
					// Add to queue
					_queuedFunctions.push(queuedFunctionObj);
					if(_settings.isQueuePaused) {
						_log('Queue has been paused, abandoning...');
						return;
					}

					if (handleNext) {
						_log('Execute triggered popQueue, processing...');	
						_popQueue();
					} 
				}	
			);
		},

		/**
		 * Check if function type is queued;
		 * Either not finished processing OR not processed
		 *
		 * @param 	functionRef
		 *			the function to check if queued
		 * 
		 * @return true is function type is queued, false otherwise
		 */
		isQueued: _isQueued,

		/**
		 * Check if queue is paused
		 *		 
		 * @return true is queue is paused, false otherwise
		 */
		getIsQueuePaused: function() {
			return _settings.isQueuePaused;

		},

		/**
		 * Process the next queued item(s)
		 * Note: This method should be called by the VF ActionFunction's
		 * "oncomplete" method or queue will be stuck.	
		 *
		 * @return true if there are still queue items related to the
		 * 				last processed queue item, false otherwise
		 */
		processNext: function() {	
			j$('.apt-gen-spinner').remove();
			if(_settings.isQueuePaused) {
				_log('Queue has been paused, abandoning process next...');
				return; // return value of undefined indicates queue is paused 
			}

			// Cleanup previously processed functions
			_log('Removing previously processed items from queue...');
			var justProcessed = _getIndexesFromQueue(_queuedFunctions, _lastProcessedIdx);			
			_queuedFunctions = _cleanUpProcessedIdxsFromQueue(_queuedFunctions, _lastProcessedIdx);
			_lastProcessedIdx = {};
	
			// signal complete for last processed action function
			// of this type
			var hasMoreQueueItems = false;			
			if(_lastProcessed) {
				hasMoreQueueItems = _isQueued(_lastProcessed.actionFunction);
				_log('Still queue items for last processed type?... ' + hasMoreQueueItems);
				
				if(!hasMoreQueueItems) {
					_log('All done, signal queue complete...');

					// Resolve last processed deferred object for this particular function
					_lastProcessed.deferredObj.resolveWith(_lastProcessed, [_lastProcessed]);
				}
				
				// decrement button spinner counts				
				j$.each(justProcessed, function() {
					if(this.properties.spinners !== undefined) {				
						var uniqueSpinnersForAction = _pendingButtonSpinners[this.properties.spinners.uniqueIdentifier];
						var newSpinnersForAction = [];
						if(uniqueSpinnersForAction !== undefined) {
							j$.each(uniqueSpinnersForAction, function() {
								this.decrement();
								if(this.spinnerCount > 0) {
									newSpinnersForAction.push(this);
								}
							});

							if(newSpinnersForAction.length > 0) {
								_pendingButtonSpinners[this.properties.spinners.uniqueIdentifier] = newSpinnersForAction;

							} else {

								delete _pendingButtonSpinners[this.properties.spinners.uniqueIdentifier];
							}
						}
					}
				});


				var rerenderedSpinners = {};	//rerender necessary spinners
				j$.each(_queuedFunctions, function() {
					if(this.properties.spinners !== undefined) {						
						if(this.properties.spinners.rerenderOnProcessNext === true) {
							var alreadyRerendered = rerenderedSpinners[this.properties.spinners.uniqueIdentifier];
							if(alreadyRerendered === undefined) {
								var uniqueSpinnersForAction = _pendingButtonSpinners[this.properties.spinners.uniqueIdentifier];
								if(uniqueSpinnersForAction !== undefined) {
										j$.each(uniqueSpinnersForAction, function() {
											this.reRender();											
										});
								}

								rerenderedSpinners[this.properties.spinners.uniqueIdentifier] = true;
							}
						}
					}
				});

			}
			
			// If items still remain in queue, process...
			if(_queuedFunctions.length > 0) {		
				_log('Items still in queue, moving along...');
				_popQueue();
			} else {
				_log('Empty queue...');

				// invoke on queue complete
				_log('Invoking queue complete callback(s)...');
				_invokeOnQueueEmpty();

				// remove ref to last processed element
				_log('Removing last processed ref...');
				_lastProcessed = null;
			}

			return hasMoreQueueItems;

		},

		/**
		 * Remove all instances of functionRef from queue
		 *
		 * @param 	functionRef
		 *			the function to remove
		 * 
		 * @return old queue
		 */
		removeFromQueue: _removeFromQueue,

		/**
		 * Set function precedence.
		 * Note: Setting to undefined is equivalent to 
		 * setting the highest precedence possible. Two
		 * undefined functions have the same precedence
		 *
		 * @param	ctxFunction
		 *			the context function
		 *
		 * @param	precedence
		 *			the precedence to set given function
		 */
		setPrecedence: function(ctxFunction, precedence) {	
			if (ctxFunction && (ctxFunction instanceof Function)) {
				_settings.queuedPrecedence[_hashFunction(ctxFunction.toString())] = precedence;

			} else if (ctxFunction) {
				for (var key in ctxFunction) {
					_settings.queuedPrecedence[_hashFunction(key.toString())] = ctxFunction[key];
				}
			}
		},


		/**
		 * Set function pause handling behavior.
		 * Note: Setting to undefined is equivalent to 
		 * setting to 'None', i.e. executing the function
		 * will not effect queue pause state
		 * 
		 * @param	ctxFunction
		 *			the context function
		 *
		 * @param	handling
		 *			the handling to set given function
		 */
		setPauseHandling: function(ctxFunction, handling) {
			handling = (!handling || handling.length == 0 
										? 'None'
										: handling);
			if (ctxFunction && (ctxFunction instanceof Function)) {
				_settings.queuedPauseHandling[_hashFunction(ctxFunction.toString())] = handling;

			} else if (ctxFunction) {
				for (var key in ctxFunction) {
					_settings.queuedPauseHandling[_hashFunction(key.toString())] = ctxFunction[key];
				}
			}
		},

		/**
		 * Set function to abandon multiple 
		 * invocations and only process the 
		 * last item in the queue
		 *
		 * @param	ctxFunction
		 *			the context function	
		 */
		setSkipToEndOfQueue: function(ctxFunction) {
			if(ctxFunction && (ctxFunction instanceof Function)) {
				_settings.skipToEndOfQueue[_hashFunction(ctxFunction.toString())] = true;

			} else if(ctxFunction && Array.isArray(ctxFunction)) {
				for (var i = 0; i < ctxFunction.length; i++) {
					_settings.skipToEndOfQueue[_hashFunction(ctxFunction[i].toString())] = true;
				}
			} else if (ctxFunction) { // assume key/value
				for (var key in ctxFunction) {
					_settings.skipToEndOfQueue[_hashFunction(key[i].toString())] = ctxFunction[key];					
				}
			}
		},

		/**
			* Set queue empty function(s).
			*
			*
			* @param    ctxFunction
			*           the context function(s) that will run when queue is empty
			*/
		setOnQueueEmpty: function(ctxFunction) {    
			if(ctxFunction && (ctxFunction instanceof Function)) {
				_settings.callbacks.queueEmpty.push(ctxFunction);

			} else if(ctxFunction && Array.isArray(ctxFunction)) {
				for (var i = 0; i < ctxFunction.length; i++) {
					var queueFunction = ctxFunction[i];
					if(queueFunction && (queueFunction instanceof Function)) {
						_settings.callbacks.queueEmpty.push(queueFunction);
					}
				}
			}
		},

		/**
			* Set queue empty function(s).
			*
			*
			* @param    ctxFunction
			*           the context function(s) that will run when queue is empty
			*/
		setPauseHandler: function(handling, ctxFunction) {
			handling = handling.toLowerCase() + 'Handler';
			var handlingFunctions = _settings.callbacks[handling];
			if (!handlingFunctions) {
				return;
			}
			if(ctxFunction && (ctxFunction instanceof Function)) {
				handlingFunctions.push(ctxFunction);

			} else if(ctxFunction && Array.isArray(ctxFunction)) {
				for (var i = 0; i < ctxFunction.length; i++) {
					var queueFunction = ctxFunction[i];
					if(queueFunction && (queueFunction instanceof Function)) {
						handlingFunctions.queueEmpty.push(queueFunction);
					}
				}
			}
		},

		/**
		 * Set whether the queue is paused or not.
		 *
		 * @param	isQueuePaused
		 *			is queue paused flag
		 *
		 * @return	the previous value
		 */
		setIsQueuePaused: function(isQueuePaused) {	
			var wasQueuePaused = _settings.isQueuePaused;
			_settings.isQueuePaused = isQueuePaused;

			return wasQueuePaused;
		},

		/**
		 * Override current setting
		 *
		 * @param	key
		 *			the settings key
		 *
		 * @param	value
		 *			the value to set
		 *
		 * @return	the previous value		 
		 */
		updateSetting: function (key, value) {
			var oldVal = _settings[key];			
			_settings[key] = value;

			return oldVal;

		}
	};

	// private functions

	/**
	 * Create hash of function provided string
	 *
	 * @param 	str
	 *			String to be hashed
	 * 
	 * @return hashed string
	 */
	function _hashFunction(str) {
	    var hash = 5381;
	    for (i = 0; i < str.length; i++) {
	        char = str.charCodeAt(i);
	        hash = ((hash << 5) + hash) + char; /* hash * 33 + c */
	    }

	    return hash;

	}

	/**
	 * check if argument is an object
	 *
	 * @param 	obj
	 *			test argument
	 * 
	 * @return true if obj is an object, false otherwise
	 */
	function _isObject(obj) {
	    return (!!obj) && (obj.constructor === Object);
	}

	/**
	 * log arguments
	 *
	 * @param 	obj
	 *			argument to log	 
	 */
	function _log(obj) {
		if(typeof console !== "undefined" && _settings.debugMode) {
			console.log(obj);

		}
	}

	/**
	 * Signal that the queue is empty
	 * and has processed all functions.
	 *
	 * @param 	lastProcessed
	 *			the action function last processed
	 */
	function _invokeOnQueueEmpty() {
		_log('Queue on Empty Invoked...');
		_log('Empty queue callbacks array=');
		_log(_settings.callbacks.queueEmpty);

		// Call each callback one after the other.
		for(var idx = 0; idx < _settings.callbacks.queueEmpty.length; idx++) {
			var queueFunction = _settings.callbacks.queueEmpty[idx];
    		if(queueFunction && (queueFunction instanceof Function)) {
    			try {
    				queueFunction(); // call it	
    			} catch(err) {
    				_log('Problem processing complete callback #' + idx);
    				_log(err.message);
    				throw err; // Re-throw after logging to get user's attention.
    			}
    		}
		}
	}

	/**
	 * Signal that a pause handling event
	 * has occurred and has processed all functions.
	 *
	 * @param 	handling
	 *			name of pause handling event
	 */
	function _invokePauseHandler(handling) {
		_log('Queue on ' + handling + ' Invoked...');
		handlerName = handling.toLowerCase() + 'Handler';
		var handlingFunctions = _settings.callbacks[handlerName];
		if (!handlingFunctions) {
			_log('Invalid pause event: ' + handling);
			return;
		}

		_log(handling + ' callbacks array=');
		_log(handlingFunctions);

		// Call each callback one after the other.
		for(var idx = 0; idx < handlingFunctions.length; idx++) {
			var queueFunction = handlingFunctions[idx];
    		if(queueFunction && (queueFunction instanceof Function)) {
    			try {
    				queueFunction(); // call it	
    			} catch(err) {
    				_log('Problem processing complete callback #' + idx);
    				_log(err.message);
    				throw err; // Re-throw after logging to get user's attention.
    			}
    		}
		}
	}

	/**
	 * Remove processed items from the queue
	 *
	 * @param 	queuedFunctions
	 *			the current queue
	 *
	 * @param 	lastProcessedIdx
	 *			indexes of items within queue which 
	 *			have been processed
	 *
	 * @return the new queue
	 */
	function _cleanUpProcessedIdxsFromQueue(queuedFunctions, lastProcessedIdx) {
		var newQueue = [];	

		// Cleanup queue
		for(var i=0; i < queuedFunctions.length; i++) {			
			if(!(i in lastProcessedIdx)) {	// ready for processing
				newQueue.push(queuedFunctions[i]);

			}			
		}

		return newQueue;
	}

	/**
	 * Get items from the queue
	 *
	 * @param 	queuedFunctions
	 *			the current queue
	 *
	 * @param 	index
	 *			indexes of items within queue
	 *
	 * @return the new queue
	 */
	function _getIndexesFromQueue(queuedFunctions, indexes) {
		var newQueue = [];	

		// Cleanup queue
		for(var i=0; i < queuedFunctions.length; i++) {			
			if(i in indexes) {	// ready for processing
				newQueue.push(queuedFunctions[i]);

			}			
		}

		return newQueue;
	}

	/**
	 * Check if function type is queued;
	 * Either not finished processing OR not processed
	 *
	 * @param 	functionRef
	 *			the function to check if queued
	 * 
	 * @return true is function type is queued, false otherwise
	 */
	 function _isQueued(functionRef, idx) {
		var isQueued = false;

		if(functionRef && _queuedFunctions.length) {			
			var checkHash = _hashFunction(functionRef.toString());
			for(var i= (idx || 0); i < _queuedFunctions.length; i++) {				
				var queuedHash = _hashFunction(_queuedFunctions[i].actionFunction.toString());
				if(checkHash == queuedHash){
					isQueued = true;
					break;
				}
			}
		}

		return isQueued;
	}




	/**
	 * Remove all references to function from queue;
	 * Either not finished processing OR not processed
	 *
	 * @param 	functionRef
	 *			the function to check if queued
	 * 
	 * @return true is function type is queued, false otherwise
	 */
	 function _removeFromQueue(functionRef, idx) {
		var oldQueue = _queuedFunctions;
		var newQueue = [];

		if(functionRef && _queuedFunctions.length) {			
			var checkHash = _hashFunction(functionRef.toString());
			for(var i= (idx || 0); i < _queuedFunctions.length; i++) {				
				var queuedHash = _hashFunction(_queuedFunctions[i].actionFunction.toString());
				if(checkHash != queuedHash){
					newQueue.push(_queuedFunctions[i]);					
				}
			}
		}

		_queuedFunctions = newQueue;

		return oldQueue;
	}

	/**
	 * Create queue object	 
	 *
	 * @param 	actionFunctionRef
	 *			the action function to execute
	 *
	 * @param 	functionArgs
	 *			arguments as an array, single argument or 
	 *			key/value object pair
	 *
	 * @param 	disableBuffering
	 *			disable buffering flag
	 *
	 * @param 	onQueueComplete
	 *			call back to execute after queue complete
	 *
	 * @param 	dfd
	 *			deferred object which status follows the progress of
	 *		    the context action function
	 * 
	 * @return the queue object
	 */
	function _createQueueObject(actionFunction, functionArgs, dfd, properties) {
		
		// Create queue function object
		var queuedFunctionObj = {
			actionFunction: actionFunction,
			actionFunctionArgs: function() {
				var functionArguments;
				// generate function arguments array for function call...									
				if(Array.isArray(functionArgs)) {
					_log('Function arguments already an array, no update.');
					functionArguments = functionArgs

				} else {			
					if(!_isObject(functionArgs)) {
						_log('Single argument...');
						functionArguments = [functionArgs];
					} else {
						_log('Argument as object, converting properties into arguments...');
						functionArguments = [];
						for(var i in functionArgs) {
							functionArguments[i] = functionArgs[i];

						}
					}
				}

				// Creating object, if already an object this will
				// just have the effect of copying the object
				if(!this.properties.disableBuffering) { // buffering args key/value map
					var bufferedArguments = {};
					for(var i in functionArguments) {
						bufferedArguments[i] = functionArguments[i];

					}

					functionArguments = bufferedArguments;
				}

				return functionArguments;
			},

			deferredObj: dfd,
			properties:properties
		//	disableBuffering: disableBuffering,
		//	loadingLabel: loadingLabel
		};

		// turn on button spinner if necessary
		if(queuedFunctionObj.properties.spinners !== undefined) {	
			var uniqueSpinnersForAction = _pendingButtonSpinners[queuedFunctionObj.properties.spinners.uniqueIdentifier];
			if(uniqueSpinnersForAction === undefined) {
				uniqueSpinnersForAction = [];

				var buttonSpinnersForAction = queuedFunctionObj.properties.spinners.buttonSpinners;
				var actionSpinnersForAction = queuedFunctionObj.properties.spinners.actionSpinners;
				if(buttonSpinnersForAction !== undefined) {
					j$.each(buttonSpinnersForAction, function() {
						var pendingSpinner = new Spinner(this.button, this.buttonSpinnerImage, true, this.disableWhenProcessing);
						uniqueSpinnersForAction.push(pendingSpinner);

					});
				}

				if(actionSpinnersForAction !== undefined) {
					j$.each(actionSpinnersForAction, function() {
						var pendingSpinner = new Spinner(this.actionSpinner);
						uniqueSpinnersForAction.push(pendingSpinner);

					});
				}
			}

			j$.each(uniqueSpinnersForAction, function() {
				this.increment(); //increment internal counter, start spinner

			});

			_pendingButtonSpinners[queuedFunctionObj.properties.spinners.uniqueIdentifier] = uniqueSpinnersForAction;

		}

		return queuedFunctionObj;
	}

	/**
	 * Process the next item(s) from the queue
	 */
	function _popQueue() {
		// STEP I - push first function into nextRound
		//next round to be processed
		var nextRound = [];

		_lastProcessed = _queuedFunctions[0];				
		var lastProcessedFunctionHash = _hashFunction(_lastProcessed.actionFunction.toString());
		var skipToEnd = lastProcessedFunctionHash in _settings.skipToEndOfQueue;

		// push function into queue for processing
		nextRound.push(_lastProcessed);
		_lastProcessedIdx[0] = 0;
		
		// STEP II - Buffer like functions and/or execute higher
		// precedence functions first
		for(var i=1; i < _queuedFunctions.length; i++) {				
			var quedFunction = _queuedFunctions[i];
			var queuedFunctionHash = _hashFunction(quedFunction.actionFunction.toString());
			var quedFunctionPrec = _settings.queuedPrecedence[queuedFunctionHash]; 
			var lastProcessedPrec = _settings.queuedPrecedence[lastProcessedFunctionHash];				

			_log('lastProcessedFunctionHash');
			_log(lastProcessedFunctionHash);
			_log('queuedFunctionHash');
			_log(queuedFunctionHash);

			// Check if next item belongs to same queue
			if(queuedFunctionHash == lastProcessedFunctionHash) {
				// Flush queue if next item does not want to be 
				// buffered with the others already in next round.				
				if(quedFunction.properties.disableBuffering ||
					_lastProcessed.disableBuffering) {
					if(!skipToEnd) {
						_log('Disabled buffering and not skip to end, breaking to process...');
						break; //process single item
					}
				}	

				_log('Same type, buffering function...');												
			} else {	// If not check queue precedence
				_log('Different functions, check precedence...');
				if(lastProcessedPrec == undefined ||	//If not equal and last processed has no prec
				   lastProcessedPrec == null) {
				    _log('No precedence defined for last processed...');				   	
				   	// Allow loop to trace entire queue for last item
				   	if(!skipToEnd || !_isQueued(quedFunction.actionFunction, i+1)) {
				   		_log('Not set to skip to end OR no more "like" functions queued, process next round...');
				   		break; //process any left over				   		 
				   	} else if(skipToEnd) {
				   		_log('Set to skip to end AND queue contains more like items, skipping over this item...');
				   		continue;
				   	}	
///*** Start Obeying Precedence
				} else if(quedFunctionPrec != undefined &&
				   quedFunctionPrec != null) {	//Else if next in queue has prec
				   	_log('Precedence defined for both....check which is higher');
					if(lastProcessedPrec > quedFunctionPrec) {	//And its prec is larger than last prec
						_log('Last processed has higher precedence, skipping this one...');
						continue;

					} else if(lastProcessedPrec == quedFunctionPrec) {
						_log('Same precedence, break to process...');
						break;

					}
					_log('Last processed has lower precedence, resetting this round....');
					// Reset next round list
					nextRound = [];	
					// reset processed indexes
					_lastProcessedIdx = {};
					// Reset skip to end flag for new ctx	
					skipToEnd = queuedFunctionHash in _settings.skipToEndOfQueue;		
					_log('New ctx skip to eng flag=' + skipToEnd);	
				} else if(lastProcessedPrec != undefined ||	//next in queue is of higher precedence
				   		  lastProcessedPrec != null) {
					_log('No precedence defined for queued, resetting this round...');
					// Reset next round list
					nextRound = [];	
					// reset processed indexes
					_lastProcessedIdx = {};					
					// Reset skip to end flag for new ctx					
					skipToEnd = queuedFunctionHash in _settings.skipToEndOfQueue;		
					_log('New ctx skip to eng flag=' + skipToEnd);							
///*** End Obeying Precedence			
				} else { //both undefined, just process first next round as is...
					// Allow loop to trace entire queue for last item
					_log('No precedence defined for either....');
				   	if(!skipToEnd || !_isQueued(quedFunction.actionFunction, i+1)) {
				   		_log('Not set to skip to end OR no more "like" functions queued, process next round...');
				   		break; //process any left over				   		 
				   	} else if(skipToEnd) {
				   		_log('Set to skip to end AND queue contains more like items, skipping over this item...');
				   		continue;
				   	}		
				}								
			}

			_log('Adding quedFunction to buffer...');
			// add to next round
			nextRound.push(quedFunction);
			// pop item from queued functions
			_lastProcessedIdx[i] = i;
			//set last processed
			_lastProcessed = quedFunction;
			// set last processed hash
			lastProcessedFunctionHash = _hashFunction(_lastProcessed.actionFunction.toString());			

			// Buffering disable, submit
			if(!skipToEnd && _lastProcessed.properties.disableBuffering) {
				_log('Not set to skip to end AND buffering is disabled, breaking to process...');
				break; //process single item
			
			}
		}

		// STEP III - process next round of functions
		if(skipToEnd && _lastProcessed.properties.disableBuffering) { //skip buff req to skipToEnd
			_processQueuedFunctionNoBuffer(nextRound[nextRound.length -1]); 

		} else if(_lastProcessed.properties.disableBuffering) {
			_processQueuedFunctionNoBuffer(nextRound[0]);

		} else {
			if(!_lastProcessed.properties.disableBuffering) {						
				_processQueuedFunctions(nextRound);

			} else {

				_processQueuedFunctionNoBuffer(nextRound[0]);
			}
		}

		// if last action wasn't an action function, process the next action in the queue
		if(!_lastProcessed.properties.isActionFunction) {
			j$.aptActionFunctionQueue.processNext();

		}

		_log('Processed indexes...');
		_log(_lastProcessedIdx);			
	}	

	/**
	 * Build queue arguments and execute action
	 * function(s)
	 *
	 * @param 	queuedFunctions
	 *			the queued functions to submit 
	 */
	function _processQueuedFunctions(queuedFunctions) {		
		//Build arguments object
		var apexQueuedArguments = [];
		_log('Processing queued functions (buffered)...');
		_log(_hashFunction(queuedFunctions[0].actionFunction.toString()));
		for(var i=0; i < queuedFunctions.length; i++) {
			var arg = { 
						idx: i,
						actionFunctionArgs: queuedFunctions[i].actionFunctionArgs()
					  };
			apexQueuedArguments.push(arg);
		}

		// generate buffered objects json	
		var bufferedArgs = JSON.stringify(apexQueuedArguments);		
		
		_log('Queued function (buffered) arguments...');
		_log(bufferedArgs);
		_log('Executing actionFunction...');

		// Call function passing buffered objects
		queuedFunctions[0].actionFunction(bufferedArgs);
		//show loading label
		_showLoading(queuedFunctions[0]);

		for(var i=0; i < queuedFunctions.length; i++) {
			var queuedFunction = queuedFunctions[i];
			// Notify of processing submittal
			queuedFunctions[i].deferredObj.notifyWith(queuedFunction, [queuedFunction]);
		}
	}

	/**
	 * Process single queue item (unbuffered)
	 *
	 * @param 	queuedFunction
	 *			the queued function to submit 
	 */
	function _processQueuedFunctionNoBuffer(queuedFunction) {
		var functionArguments;
		_log('Processing queued functions (non-buffered)...');
		_log(_hashFunction(queuedFunction.actionFunction.toString()));

		_log('Queued function (non-buffered) arguments...');
		_log(queuedFunction.actionFunctionArgs());		

		//execute callback
		_log('Executing actionFunction...');
		queuedFunction.actionFunction.apply(queuedFunction.actionFunction, queuedFunction.actionFunctionArgs());
		// show loading label
		_showLoading(queuedFunction);		
		// Notify of processing submittal
		queuedFunction.deferredObj.notifyWith(queuedFunction, [queuedFunction]);

	}

	/**
	 * Show page loading spinner and text
	 *
	 * @param 	queuedFunction
	 *			the queued function of reference 
	 */
	function _showLoading(queuedFunction){

		if(queuedFunction.properties.showLoadingLabel) {
			j$('.apt-gen-spinner').remove();
			newSpinnerHtml = '<div class="apt-gen-spinner"><img src="/img/loading.gif" alt="'+queuedFunction.properties.loadingLabel+'"/><span>'+queuedFunction.properties.loadingLabel+'</span></div>';
			j$('#aptGeneralSpinner').append(newSpinnerHtml);
		}
	}

	/**
	 * Button spinner control
	 */
	function Spinner(spinnerButton, spinnerImageSelector, isButtonSpinner, disableButton) {	
		this.spinnerCount = 0;
		this.spinnerButton = spinnerButton;
		this.spinnerImageSelector = spinnerImageSelector;

		this.increment = function() {
			this.spinnerCount = this.spinnerCount+1;
			this.renderSpinner();
		};

		this.decrement = function() {
			if(this.spinnerCount > 0) {
				this.spinnerCount = this.spinnerCount-1;
			}

			this.renderSpinner();
		};

		this.reRender = function() {
			this.renderSpinner();
		};

		this.renderSpinner = function() {			
			if(this.spinnerButton === 'undefined' 
					|| this.spinnerButton == null) {
				return;

			}

			if(isButtonSpinner) {
				j$(this.spinnerButton).children('img').remove();

			}

			if(this.spinnerCount > 0) {
				if(isButtonSpinner) {
					if(this.spinnerImageSelector) {
						startSpinner(this.spinnerImageSelector, this.spinnerButton);

					}

					if(disableButton) { //disable button
						j$(this.spinnerButton).attr('disabled', 'disabled');
						j$(this.spinnerButton).addClass('aptButtonDisabled');
						j$(this.spinnerButton).attr("onClick","return false; replaceThis; " + j$(this.spinnerButton).attr("onClick"));

					}

				} else {
					j$(this.spinnerButton).show();

				}
				
			} else {
				if(isButtonSpinner && disableButton) { //re-enable button					
					j$(this.spinnerButton).removeClass('aptButtonDisabled');					
					j$(this.spinnerButton).removeAttr('disabled');
					j$(this.spinnerButton).attr("onClick",j$(this.spinnerButton).attr("onClick").replace(new RegExp("return false; replaceThis; ", 'g'),""));

				}

			}
		};

	};

})(jQuery);	