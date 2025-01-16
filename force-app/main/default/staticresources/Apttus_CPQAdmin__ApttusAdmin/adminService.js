webpackJsonp([0],[
/* 0 */
/***/ (function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__(1);


/***/ }),
/* 1 */
/***/ (function(module, exports, __webpack_require__) {

	(function() {
	    'use strict';
	    __webpack_require__(2);
	    __webpack_require__(4);
	    module.exports = angular.module('cpqAdmin.adminServices', [])
	        .provider('i18nService', __webpack_require__(6))
	        .provider('remoteService', __webpack_require__(7))
	        .service('UtilService', __webpack_require__(8))
	        .service('ObjectConstants', __webpack_require__(9))
	        .service('ActionQueueService', __webpack_require__(10))
	        .config(__webpack_require__(11));
	})();


/***/ }),
/* 2 */,
/* 3 */,
/* 4 */,
/* 5 */,
/* 6 */
/***/ (function(module, exports) {

	(function() {
		module.exports = [function() {
			
			var provider = this;
			//Set defaults
			var i18nData = {
				'CustomLabel': {},
				'CustomField': {},
				'dateFormat': 'MM/DD/YYYY',
				'dateTemplate': '12/31/1999',
				'currencyTemplate': '$1,234.00',
				'quantityTemplate': '1,234.00',
				'precision': {
					'currency': 2,
					'quantity': 2
				},
				'locale': 'en_US'
			};
	
			this.$get = function() {
				return new i18nService(i18nData);
	
			};
			provider.setCustomLabel = function(newLabels) {
				angular.extend(i18nData.CustomLabel, newLabels);
			};
			provider.setCustomField = function(newFields) {
				angular.extend(i18nData.CustomField, newFields);
			};
			provider.setDateFormat = function(newFormat) {
				if (newFormat) {
					i18nData.dateFormat = newFormat;
				}
			};
			provider.setLocale = function(newLocale) {
				if (newLocale) {
					i18nData.locale = newLocale;
				}
			};
			provider.setPrecision = function(key, value) {
				if (typeof key === 'string' && angular.isDefined(value)) {
					i18nData.precision[key] = Number(value);
	
				} else if (typeof key === 'object') {
					angular.extend(i18nData.precision, key);
	
				}
			};
			provider.setDateTemplate = function(newTemplate) {
				if (newTemplate) {
					i18nData.dateTemplate = newTemplate;
				}
			};
			provider.setCurrencyTemplate = function(newTemplate) {
				if (newTemplate) {
					i18nData.currencyTemplate = newTemplate;
				}
			};
			provider.setQuantityTemplate = function(newTemplate) {
				if (newTemplate) {
					i18nData.quantityTemplate = newTemplate;
				}
			};
	
			function i18nService(i18nData) {
				var service = i18nData;
				service.currencySettings = buildNumberSettings(i18nData.currencyTemplate, i18nData.precision.currency);
				service.quantitySettings = buildNumberSettings(i18nData.quantityTemplate, i18nData.precision.quantity);
				service.dateSettings = buildDateSettings(i18nData.dateTemplate);
				service.timeZoneOffset = (new Date()).getTimezoneOffset() * 60 * 1000;
				return service;
	
				function buildNumberSettings(template, precision) {
					var settings = {
						symbol: '',
						isSymbolBefore: true,
						separator: ',',
						groupLength: 3,
						decimal: '.',
						precision: angular.isNumber(precision) ? precision : 2,
						groupingExp: undefined
	
					};
	
					/**
					 * Regex for capturing groups of number separators
					 * Matched groups: 
					 *      0      ignore     1          2        3        4       5     ignore     6    			 			
					 * [Symbol(s)][spaces][digit(s)][separator][digits][decimal][digits][spaces][Symbol(s)]
					 */
					var templateRegex = /^(\D*)(?:\s*)([\d\.\,\'\s\-]+)([\.\,\'\s\-])(\d{3,4})(\.|\,)(\d{2,})(?:\s*)(\D*)$/;
					var matches = template.match(templateRegex);
					if (matches) {
						//Discard first element -- the full string match
						matches.shift();
						//Check symbol and where it was matched
						if (matches[0]) {
							settings.symbol = matches[0];
							settings.isSymbolBefore = true;
	
						} else {
							settings.symbol = matches[6];
							settings.isSymbolBefore = false;
	
						}
						//Get the rest of the matches
						settings.separator = matches[2];
						settings.groupLength = matches[3].length;
						settings.decimal = matches[4];
	
					}
	
					/**
					 * Compile the grouping regexp for fast reuse
					 * Matching groups: 
					 *        0               1         ignored         2
					 * [leading digits][grouped digits][decimal][fraction digits]
					 */
					var regexpStr = '^(\\d{1,' + settings.groupLength + '})?' + '((?:\\d{' + settings.groupLength + '})*)' + '(?:[\.\,](\\d*))?$';
					settings.groupingExp = new RegExp(regexpStr);
					return settings;
	
				}
	
				/**
				 * Construct settings required for date rendering. May turn this into
				 * 	a way of making salesforce date format compatible with the 'moment'
				 * 	library so that the date filter can take advantage of moment.
				 * 	 
				 */
				function buildDateSettings(dateTemplate) {
					var settings = {
						separator: '/',
						ordering: ['mm', 'dd', 'yyyy'],
						groupingExp: undefined
					};
	
					/**
					 * Regex for capturing date digits
					 * Matched groups: 
					 *      0           1         2           ignore          3
					 * [1-4 digits][separator][1|2 digits][same separator][2-4 digits]
					 */
					var templateRegex = /(\d{1,4})([\/\s\-\.])(\d{1,2})(?:\2)(\d{1,4})/;
					var matches = dateTemplate.match(templateRegex);
					if (matches) {
						//Discard first element -- the full string match
						matches.shift();
						settings.separator = matches[1] || '/';
						[0, 2, 3].forEach(function(matchIndex, loopIndex) {
							var digits = matches[matchIndex];
							var component = '';
							var str = '';
							var numVal = Number(digits);
							if (numVal <= 12) {
								component = 'm';
	
							} else if (numVal <= 31) {
								component = 'd';
	
							} else {
								component = 'y';
	
							}
	
							// TODO : .repeat method is part of ES6 and not compatible with IE and safari 
							// settings.ordering[loopIndex] = component.repeat(digits.length);
	
							// put the simple logic instead of .repeat method to fix the issue
							for (var i = 0; i < digits.length; i++) {
								str += component;
							}
	
							settings.ordering[loopIndex] = str;
	
						});
	
					}
					/**
					 * Compile the grouping regexp for fast reuse
					 * Matching groups: 
					 *    ignored     0       ignored    1       ignored    2       ignored
					 * [whitespace][digits][separator][digits][separator][digits][whitespace]
					 */
					var paddingExp = '\\s*';
					var separatorExp = paddingExp + '\\' + settings.separator + '?' + paddingExp;
					var regexpStr = ['^', paddingExp, '(\\d{1,4})', separatorExp, '(\\d{1,4})?', separatorExp, '(\\d{1,4})?', paddingExp, '$'].join('');
					settings.groupingExp = new RegExp(regexpStr);
					return settings;
	
				}
	
			}
		}];
	
	
	})();

/***/ }),
/* 7 */
/***/ (function(module, exports) {

	(function() {
	    module.exports = [function() {
	
	        var provider = this;
	        var actionsMap = {};
	        var redirectOnFail = '/';
	        var trackAllRemoteCalls = false;
	
	        provider.setRemoteActions = function(newActions) {
	
	            angular.extend(actionsMap, newActions);
	            return provider;
	        };
	
	        provider.setRedirectLocation = function(newLocation) {
	            redirectOnFail = newLocation ? newLocation : false;
	            return provider;
	        };
	
	        provider.setTrackAllRemoteCalls = function(isEnabled) {
	            trackAllRemoteCalls = isEnabled;
	            return provider;
	        };
	
	        function RemoteServiceFactory($q, $log, $window) {
	            return new RemoteService($q, $log, $window, actionsMap, redirectOnFail);
	
	        }
	
	        RemoteServiceFactory.$inject = ['$q', '$log', '$window'];
	
	        this.$get = RemoteServiceFactory;
	
	        function RemoteService($q, $log, $window, RemoteActions, redirectOnFail) {
	            var service = {};
	            var lastTransaction = {};
	            initRemoteActionFunctions();
	            return service;
	
	            function initRemoteActionFunctions() {
	                var actionKey, actionName, isProp, isStr;
	                for (actionKey in RemoteActions) {
	                    isProp = RemoteActions.hasOwnProperty(actionKey);
	                    isStr = typeof actionKey === 'string';
	                    if (isProp && isStr) {
	                        actionConfig = getRemoteActionConfig(actionKey);
	                        service[actionKey] = createRemoteActionFunction(actionConfig);
	
	                    }
	                }
	            }
	
	            /*
	             * This method will check RemoteAction[key] contains action string or action config object
	             * according to that it will create actionConfig object and returns it 
	             */
	            function getRemoteActionConfig(actionKey) {
	                var config = {}
	                if (angular.isDefined(RemoteActions[actionKey])) {
	                    var actionConf = RemoteActions[actionKey];
	                    if (angular.isString(actionConf)) {
	                        config.actionName = actionConf;
	                        config.skipLoader = false;
	
	                    } else if (angular.isObject(actionConf)) {
	                        config.actionName = (angular.isDefined(actionConf.actionName)) ? actionConf.actionName : null;
	                        config.skipLoader = (angular.isDefined(actionConf.skipLoader)) ? actionConf.skipLoader : false;
	
	                    }
	
	                }
	                return config;
	            }
	
	            /**
	             * Used for generating methods that can be called on the service by the name
	             *  declared in the RemoteActions object.
	             * Each method passes its fully-qualified name and its
	             *  arguments to invokeRemoteAction. The arguments passed
	             *  to this function should just match the signature of 
	             *  the Apex method. 
	             * @return {promise} resolves with the result of the remote action
	             */
	            function createRemoteActionFunction(actionConfig) {
	                var actionFunction = function() {
	                    return invokeRemoteAction(actionConfig, arguments);
	
	                };
	                return actionFunction;
	
	            }
	            /**
	             * Helper for calling visualforce remoting. 
	             *  
	             * @param   {string}    actionName  the remote action to invoke
	             * @param   {array}     actionParams    any number of parameters to pass to remote
	             *                                                          action before callback 
	             * @return {promise} a $q promise that resolves with result of remote action
	             *
	             * Example: 
	             *      <code>
	             *      var thenable = invokeRemoteAction(RemoteActions.getCartLineItems, [cartRequest]);
	             *      thenable.then(function (result) {
	             *          useResult(result);
	             *      });
	             *      </code>
	             * Here, thenable will be a promise that gets resolved with the result of the remote action 
	             */
	            function invokeRemoteAction(actionConfig, actionParams) {
	                // $log.debug('invokeRemoteAction-->'+actionConfig.actionName, actionParams);
	
	                //Constuct deferred object for return
	                var deferred, errorMessage, remoteActionWithParams, resolver, remotingParams, actionName;
	                deferred = $q.defer();
	                actionName = actionConfig.actionName;
	
	                setRemoteServiceCount(actionConfig, true);
	
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
	                    /*if (!nextArg) {
	                        errorMessage = "Error - Could not construct remote action parameters. Parameter #" + argIndex + " is undefined!";
	                        $log.error(errorMessage);
	                        deferred.reject(errorMessage);
	                        return deferred.promise;
	
	                    }*/
	                    remoteActionWithParams.push(nextArg);
	
	                }
	                //Add the resolve function and remoting params to argument array
	                resolver = function resolveRemoteAction(result, event) {
	                    if (event.status) {
	
	                        if (result) {
	                            $log.debug('Resolved "' + actionName + '"' +
	                                ', Time taken: ' + result.timeTaken / 1000 + ' sec.' +
	                                ', Query count: ' + result.queryCount);
	
	                            if (result.timeDetail) {
	                                $log.debug('Timings for ' + actionName, result.timeDetail);
	                            }
	                        }
	                        deferred.resolve(result);
	
	
	                    } else {
	                        errorMessage = 'Error - Could not resolve remote action: ' + actionName;
	                        $log.error(errorMessage, actionParams, event.message);
	                        //Currently the only way to check whether request failed due to user logout
	                        var isLoggedOut = event.message.toLowerCase().indexOf('logged') >= 0;
	                        if (isLoggedOut && redirectOnFail) {
	                            $window.location.href = redirectOnFail;
	
	                        }
	
	                        if (event.message === "Remoting request invalid for your session.  Refresh page and re-submit request" || event.message.toLowerCase().indexOf('logged') >= 0) {
	                            $window.location = getRedirectLocation($window.location.hostname);
	                        } else {
	                            //alert(event.message);
	                        }
	
	                        deferred.reject(event);
	
	                    }
	
	                    setRemoteServiceCount(actionConfig, false);
	                };
	                remoteActionWithParams.push(resolver);
	
	                //Add the default parameters for remoting call
	                remotingParams = {
	                    "buffer": false,
	                    "escape": false,
	                    "timeout": 120000
	                };
	                remoteActionWithParams.push(remotingParams);
	
	                //Try to call visualforce remoting invokeAction with the parameters we built 
	                try {
	                    Visualforce.remoting.Manager.invokeAction.apply(Visualforce.remoting.Manager, remoteActionWithParams);
	
	                } catch (ex) {
	                    errorMessage = 'Error - Could not invoke remote action: ' + actionName;
	                    $log.error(errorMessage, actionParams, ex);
	                    deferred.reject(errorMessage);
	
	                }
	                return deferred.promise;
	
	            }
	
	            function getRedirectLocation(hostName) {
	                var hostNameIsContainsNA = hostName.toLowerCase().indexOf('na');
	                var hostNameIsContainsCS = hostName.toLowerCase().indexOf('cs');
	                if (hostNameIsContainsNA >= 0) {
	                    if (!isNaN(hostName[hostNameIsContainsNA + 2])) {
	                        return "https://login.salesforce.com";
	                    }
	                } else if (hostNameIsContainsCS >= 0) {
	                    if (!isNaN(hostName[hostNameIsContainsCS + 2])) {
	                        return "https://test.salesforce.com";
	                    }
	                } else {
	
	                }
	            }
	
	            /*
	             * This method sets pendingRemoteServiceCount of $q service (decorrated in queueWrapperService.js) 
	             * based on actionConfig.skip and LoggerLevel
	             */
	            function setRemoteServiceCount(actionConfig, incrementFlag) {
	                //$log.debug('setRemoteServiceCount-->', actionConfig, incrementFlag);
	                if (!actionConfig.skipLoader || trackAllRemoteCalls) {
	                    if (incrementFlag) {
	                        $q.incrementRemoteServiceCount();
	
	                    } else {
	                        $q.decrementRemoteServiceCount();
	
	                    }
	
	                }
	            }
	
	        }
	
	    }];
	
	})();


/***/ }),
/* 8 */
/***/ (function(module, exports) {

	(function() {
	    module.exports = ['lodash', function(_) {
	        var service = this;
	
	        service.frequencyConstants = {
	            FREQUENCY_HOURLY: 'Hourly',
	            FREQUENCY_DAILY: 'Daily',
	            FREQUENCY_WEEKLY: 'Weekly',
	            FREQUENCY_MONTHLY: 'Monthly',
	            FREQUENCY_QUARTERLY: 'Quarterly',
	            FREQUENCY_HALFYEARLY: 'Half Yearly',
	            FREQUENCY_YEARLY: 'Yearly'
	        };
	
	        service.priceTypesConstants = {
	            PRICETYPE_ONETIME: 'One Time',
	            PRICETYPE_RECURRING: 'Recurring',
	            PRICETYPE_USAGE: 'Usage',
	            PRICETYPE_INCLUDED_USAGE: 'Included Usage'
	        };
	
	        /**
	         * Use string-to-number conversion to compensate for floating point 
	         * 	errors in standard javascript rounding.
	         * @param  {Number/String} value
	         * @param  {Number/String} precision 	these can be numbers or strings
	         *                                    representing numbers
	         * @return {Number}	Rounded value
	         */
	        service.round = function(value, precision) {
	            precision = precision ? precision : 0;
	            var roundExpPos = "e+" + precision;
	            var roundExpNeg = "e-" + precision;
	            return Number(Math.round(value + roundExpPos) + roundExpNeg);
	
	        };
	
	        /**
	         * Check whether a nmber is within a min/max range. If min or max is not
	         * 	of type number, it the value is assumed to automatically meet the 
	         * 	criteria. If the value to check is not a number type, it automatically
	         * 	fails.
	         * @param  {Number}  minVal    
	         * @param  {Number}  maxVal    
	         * @param  {Number}  betweenVal
	         * @param  {Boolean}  strictly		Whether to compare strictly. False by default.
	         * @return {Boolean}           
	         */
	        service.isBetween = function(minVal, maxVal, betweenVal, strictly) {
	            if (!angular.isNumber(betweenVal)) {
	                return false;
	
	            }
	            var minSatisfied, maxSatisfied;
	            if (!strictly) {
	                minSatisfied = angular.isNumber(minVal) ? betweenVal >= minVal : true;
	                maxSatisfied = angular.isNumber(maxVal) ? betweenVal <= maxVal : true;
	
	            } else {
	                minSatisfied = angular.isNumber(minVal) ? betweenVal > minVal : true;
	                maxSatisfied = angular.isNumber(maxVal) ? betweenVal < maxVal : true;
	
	            }
	            return minSatisfied && maxSatisfied;
	
	        };
	
	        /**
	         * Replicate Java string format where you can pass an string that has
	         * 	groups such as {0}, {1}, ... and an array of strings to insert at
	         * 	the appropriate indicies. Used for filling in custom labels.
	         * @param  {[type]} baseString [description]
	         * @param  {[type]} inserts    [description]
	         * @return {[type]}            [description]
	         */
	        service.stringFormat = function(baseString, inserts) {
	            if (!baseString) {
	                return '';
	
	            }
	            if (!angular.isArray(inserts)) {
	                return baseString;
	
	            }
	            var stringGroups = baseString.split(/\{(\d+)\}/),
	                formattedString = '',
	                isInsert = false,
	                insertIndex = 0,
	                nextInsert = '';
	            for (var stringIndex = 0; stringIndex < stringGroups.length; stringIndex++) {
	                if (isInsert) {
	                    isInsert = false;
	                    insertIndex = parseInt(stringGroups[stringIndex]);
	                    nextInsert = insertIndex < inserts.length ? inserts[insertIndex] : '';
	                    formattedString += nextInsert;
	
	                } else {
	                    isInsert = true;
	                    formattedString += stringGroups[stringIndex];
	
	                }
	
	            }
	            return formattedString;
	
	        };
	
	        /**
	         * returns true when the parameter passed is undefined or null or empty array or blank string
	         * @param obj any kind of parameter 
	         */
	        service.isEmpty = function(obj) {
	            if (angular.isDefined(obj) && obj !== null) {
	                if (angular.isArray(obj) && obj.length === 0 || obj === '') {
	                    return true;
	
	                }
	                return false;
	
	            }
	            return true;
	
	        };
	
	        /**
	         * Construct a date object in which the time is set to 12:00 AM GMT.
	         * This is used to match salesforce UTC milliseconds standard for dates.
	         * 
	         * @param  {Number} year  year as numerical value
	         * @param  {Number} month month value, where January = 0
	         * @param  {Number} date  date as numerical value
	         * @return {Date}
	         */
	        service.newUTCDate = function(year, month, date) {
	            var newDate = new Date();
	            newDate.setUTCHours(0, 0, 0);
	            if (angular.isNumber(year)) {
	                newDate.setUTCFullYear(year);
	
	            }
	            if (angular.isNumber(month)) {
	                newDate.setUTCMonth(month);
	
	            }
	            if (angular.isNumber(date)) {
	                newDate.setUTCDate(date);
	
	            }
	            return newDate;
	
	        }
	
	        /**
	         * Computes the new date for adding days to the given date 
	         * @param date current date
	         * @param days number of days to add
	         * @return the new date
	         */
	        service.addDays = function(date, days) {
	            return date + 86400000 * days;
	        }
	
	        /**
	         * Computes the end date for the given start date and term parameters
	         * @param startDate the term start date
	         * @param term the term 
	         * @param frequency the frequency associated with the term
	         * @return the end date
	         */
	        service.computeEndDate = function(startDate, term, frequency) {
	            var newEndDate = new Date(startDate);
	
	            if (frequency === service.frequencyConstants.FREQUENCY_HOURLY) {
	                // hourly
	                newEndDate = newEndDate.setDate(newEndDate.getDate() + (1 / 24 * term));
	
	            } else if (frequency === service.frequencyConstants.FREQUENCY_DAILY) {
	                // daily
	                newEndDate = newEndDate.setDate(newEndDate.getDate() + term);
	
	            } else if (frequency === service.frequencyConstants.FREQUENCY_WEEKLY) {
	                // weekly
	                newEndDate = newEndDate.setDate(newEndDate.getDate() + (term * 7));;
	
	            } else if (frequency === service.frequencyConstants.FREQUENCY_MONTHLY) {
	                // monthly
	                newEndDate = service.computeEndDateByMonths(startDate, term, 1);
	
	            } else if (frequency === service.frequencyConstants.FREQUENCY_QUARTERLY) {
	                // quarterly
	                newEndDate = service.computeEndDateByMonths(startDate, term, 3);
	
	            } else if (frequency === service.frequencyConstants.FREQUENCY_HALFYEARLY) {
	                // half yearly
	                newEndDate = service.computeEndDateByMonths(startDate, term, 6);
	
	            } else if (frequency === service.frequencyConstants.FREQUENCY_YEARLY) {
	                // yearly
	                newEndDate = service.computeEndDateByMonths(startDate, term, 12);
	
	            } else {
	                //Added for app to not break as start date from ms is converted to date object
	                newEndDate = startDate;
	            }
	
	            return newEndDate;
	
	        };
	
	        /**
	         * compute end date for monthly, quartely, half-yearly or yearly term 
	         * @param startDate line item start date
	         * @param term number of months plus extra days / 30 
	         * @param frequencyInMonths 1-monthly, 3-quarterly 6-half-yearly 12-yearly 
	         */
	        service.computeEndDateByMonths = function(startDate, term, frequencyInMonths) {
	            var months = (term * frequencyInMonths);
	
	            var newEndDate = new Date(startDate);
	            newEndDate = newEndDate.setMonth(newEndDate.getMonth() + months);
	
	            var dateToFindDays = new Date(newEndDate);
	            dateToFindDays = dateToFindDays.setDate(dateToFindDays.getDate() + 1);
	
	            var daysInMonths = service.daysInMonth(new Date(dateToFindDays).getFullYear(), new Date(dateToFindDays).getMonth());
	            var remainingTerms = ((term * frequencyInMonths) - months);
	            var extraDays = Math.round(remainingTerms * daysInMonths);
	
	            newEndDate = new Date(newEndDate);
	            newEndDate = newEndDate.setDate(newEndDate.getDate() + (extraDays - 1));
	
	            return newEndDate;
	        };
	
	        /**
	         * reorder elements within an array such that when a matching key is found, the element is moved to the 
	         * head of that array - this check is repeated for every element of the array.
	         * @param - source array
	         * @param - predicate, callback function; Must return true if element should move to the head of the array
	         */
	        service.reorderArray = function(array, callback) {
	            if (_.isArray(array) == false || array.length == 0 || _.isFunction(callback) == false) {
	                return;
	            }
	
	            var spliceIdx = [];
	
	            for (var i = 0; i < array.length; i++) {
	                // callback should return true/false
	                if ((i > 1) && callback(array[i])) {
	                    spliceIdx.push(i);
	                }
	            }
	
	            spliceIdx.forEach(function(idx) {
	                var culled = array.splice(idx, 1);
	                array.splice(0, 0, culled[0]);
	            });
	        };
	
	        /**
	         * compute days in given year and a month
	         * @param year
	         * @param month
	         * return days in month
	         */
	        service.daysInMonth = function(year, month) {
	            return new Date(year, month, 0).getDate();
	        };
	
	        service.removeTempUIAttributes = function(obj) {
	            Object.keys(obj).forEach(function(key) {
	                if (_.startsWith(key, '@@') || _.startsWith(key, '$$')) {
	                    delete obj[key];
	                } else if (angular.isObject(obj[key])) {
	                    service.removeTempUIAttributes(obj[key]);
	                }
	            });
	        }
	
	        service.validateEndDate = function(date) {
	            var now = new Date();
	            if (now.getTime() > date) {
	                return false;
	            }
	            return true;
	        };
	
	        service.validateDate = function(date) {
	            var date_regex = /^(0[1-9]|1[0-2])\/(0[1-9]|1\d|2\d|3[01])\/(19|20)\d{2}$/; //Validates the format (MM/DD/YYYY), with a year between 1900 and 2099
	            if (angular.isUndefined(date) || date === null) {
	                return false;
	            } else if (date.toString().trim().length < 1) {
	                return false;
	            } else if (date_regex.test(date)) {
	                return false;
	            }
	            return true;
	        }
	
	        service.uniq = function(inputArray) {
	            var tempArray = [];
	            var tempObj = {};
	            _.forEach(inputArray, function(value, key) {
	                if (!tempObj[value.id]) {
	                    tempArray.push(value);
	                    tempObj[value.id] = value.id;
	                }
	            });
	            return tempArray;
	        }
	
	        service.intersection = function(inputArray) {
	            var tempArray = [];
	            _.forEach(inputArray, function(value, key) {
	                tempArray.push(value.actionArr);
	            });
	            return _.intersection.apply(_, tempArray);
	        }
	
	        /**
	         * Get the object corresponding to field name
	         * @param contextSO the "starting" sObject
	         * @param fieldAPIName the fully qualified field API name
	         * @return the object specified by fieldName
	         */
	        service.sObjectFromField = function(contextSO, fieldAPIName) {
	            //set new value
	            var path = fieldAPIName.split('.');
	            var curObject = contextSO;
	            for (var i = 0, max = path.length - 1; i < max; i++) {
	                if (typeof(curObject) !== 'undefined' && curObject != null) {
	                    curObject = curObject[path[i]];
	                }
	            }
	
	            return curObject;
	        }
	
	        /**
	         * create popup for Product Information list
	         * @param product Object
	         */
	        service.createPopup = function(product) {
	            var infoURL = "";
	            if (product.productInformationList.length > 0) {
	                if (product.productInformationList[0].InformationType__c == "Attached File") {
	                    infoURL = "/servlet/servlet.FileDownload?file=" + product.productInformationList[0].FileId__c;
	
	                } else if (product.productInformationList[0].InformationType__c == "Embedded Code") {
	                    infoURL = product.productInformationList[0].EmbedCode__c;
	
	                } else if (product.productInformationList[0].InformationType__c == "URL Address") {
	                    infoURL = product.productInformationList[0].ContentUrl__c;
	
	                }
	            } else {
	                return;
	            }
	
	            var header = product.productInformationList.length > 0 ? product.productInformationList[0].Name : "";
	            var isEmbed = product.productInformationList[0].InformationType__c == "Embedded Code" ? true : false;
	
	            if (infoURL == "" || infoURL == null) {
	                return false;
	            }
	
	            var url = isEmbed ? '' : infoURL;
	
	            var infoModal = window.open(url, 'Product Information', 'menubar=1,resizable=1,width=712,height=500');
	            if (isEmbed) {
	                infoModal.document.write('<html><head><title>Product Information</title></head>');
	                infoModal.document.write('<body><center><h3>' + header + '</h3>');
	                infoModal.document.write(infoURL);
	                infoModal.document.write('</center></body></html>');
	            }
	            if (window.focus) {
	                infoModal.focus();
	            }
	        }
	
	        return service;
	
	    }];
	})();
	


/***/ }),
/* 9 */
/***/ (function(module, exports) {

	(function() {
	    module.exports = [function() {
	        var service = this;
	
	        service.DisplayActions = {
	            ACTION_ABANDON: 'Abandon',
	            ACTION_FINALIZE: 'Finalize',
	            ACTION_MORE: 'More',
	            ACTION_REVALIDATE: 'Revalidate'
	
	        };
	
	        service.LineItem = {
	            LINETYPE_PRODUCT: 'Product/Service',
	            LINETYPE_OPTION: 'Option',
	            LINETYPE_MISC: 'Misc',
	
	            PRICETYPE_ONETIME: 'One Time',
	            PRICETYPE_RECURRING: 'Recurring',
	            PRICETYPE_USAGE: 'Usage',
	            PRICETYPE_INCLUDED_USAGE: 'Included Usage',
	
	            PRICEMETHOD_PERUNIT: 'Per Unit',
	            PRICEMETHOD_FLATPRICE: 'Flat Price',
	            PRICEMETHOD_PERCENTAGE: 'Percentage',
	            PRICEMETHOD_RELATEDPRICE: 'Related Price',
	            PRICEMETHOD_TIERED_RATE: 'Tiered Rate',
	            PRICEMETHOD_TIERPRICE: 'Tier Price',
	
	            FREQUENCY_HOURLY: 'Hourly',
	            FREQUENCY_DAILY: 'Daily',
	            FREQUENCY_WEEKLY: 'Weekly',
	            FREQUENCY_MONTHLY: 'Monthly',
	            FREQUENCY_QUARTERLY: 'Quarterly',
	            FREQUENCY_HALFYEARLY: 'Half Yearly',
	            FREQUENCY_YEARLY: 'Yearly',
	            FREQUENCY_ONETIME: 'One Time',
	
	            STATUS_NEW: 'New',
	            STATUS_EXISTING: 'Existing',
	            STATUS_INCREMENTED: 'Incremented',
	            STATUS_AMENDED: 'Amended',
	            STATUS_RENEWED: 'Renewed',
	            STATUS_UPGRADED: 'Upgraded',
	            STATUS_CANCELLED: 'Cancelled',
	            STATUS_TRANSIENT: 'Transient',
	
	            SYNC_STATUS_PENDING: 'Pending',
	            SYNC_STATUS_SYNCHRONIZED: 'Synchronized',
	
	            CONFIG_STATUS_NA: 'NA',
	            CONFIG_STATUS_DEFAULT_PENDING: 'Default Pending',
	            CONFIG_STATUS_PENDING: 'Pending',
	            CONFIG_STATUS_COMPLETE: 'Complete',
	
	            PRICING_STATUS_PENDING: 'Pending',
	            PRICING_STATUS_COMPLETE: 'Complete',
	
	            PRICEGROUP_PRICERAMP: 'Price Ramp',
	            PRICEGROUP_NONE: 'None',
	
	            COLLABORATION_STATUS_NOT_ASSIGNED: 'Not Assigned',
	            COLLABORATION_STATUS_SUBMITTED: 'Submitted',
	            COLLABORATION_STATUS_ACCEPTED: 'Accepted',
	            COLLABORATION_STATUS_COMPLETED: 'Completed'
	
	        };
	
	        service.assetStatusMap = {
	            CANCELLED: "Pending Cancellation",
	            AMENDED: "Pending Change",
	            RENEWED: "Pending Renewal",
	            DEFAULT: "Pending Asset Action"
	        };
	
	        service.ChargeType = {
	            // known charge types
	            CHARGETYPE_NONE: 'None',
	            CHARGETYPE_STANDARD_PRICE: 'Standard Price',
	            CHARGETYPE_LICENSE_FEE: 'License Fee',
	            CHARGETYPE_SUBSCRIPTION_FEE: 'Subscription Fee',
	            CHARGETYPE_IMPLEMENTATION_FEE: 'Implementation Fee',
	            CHARGETYPE_INSTALLATION_FEE: 'Installation Fee',
	            CHARGETYPE_MAINTENANCE_FEE: 'Maintenance Fee',
	            CHARGETYPE_ADJUSTMENT: 'Adjustment',
	
	            // miscellaneous charge types
	            CHARGETYPE_SALESTAX: 'Sales Tax',
	            CHARGETYPE_SHIPPING_HANDLING: 'Shipping & Handling'
	
	        };
	
	        service.FieldType = {
	            // known field types
	            FIELDTYPE_DATE: 'DATE',
	            FIELDTYPE_MULTIPICKLIST: 'MULTIPICKLIST',
	            FIELDTYPE_CURRENCY: 'CURRENCY',
	            FIELDTYPE_PERCENT: 'PERCENT',
	            FIELDTYPE_PICKLIST: 'PICKLIST',
	            FIELDTYPE_REFERENCE: 'REFERENCE',
	            FIELDTYPE_NUMBER: 'NUMBER'
	        };
	
	        // Quote Collaboration Status Constants
	        service.CollaborationStatus = {
	            NOT_ASSIGNED: 'Not Assigned',
	            SUBMITTED: 'Submitted',
	            COMPLETED: 'Completed',
	            ACCEPTED: 'Accepted'
	        };
	
	        // Quote Collaboration Priorities Constants
	        service.CollaborationPriorities = {
	            P1: 'P1',
	            P2: 'P2',
	            P3: 'P3',
	            P4: 'P4',
	            P5: 'P5'
	        };
	
	        // Quote Collaboration Priorities Constants
	        service.CollaborationConfigCols = {
	            PRODUCT: 'Product',
	            LIST_PRICE: 'List Price',
	            BASE_PRICE: 'Base Price',
	            QUANTITY: 'Quantity',
	            SELLING_TERM: 'Selling Term'
	        };
	
	        service.allowedActions = {
	            CANCEL: 'Cancel',
	            AMEND: 'Amend',
	            UPGRADE: 'Swap',
	            RENEW: 'Renew',
	            INCREMENT: 'Increment',
	            DECREMENT: 'Decrement'
	        }
	
	        service.PackageNamespace = {
	            QPCONFIG: 'Apttus_QPConfig',
	            CMCONFIG: 'Apttus_CMConfig'
	        }
	
	        service.ProductConfiguration = {
	            ROBJECT_NAME_PROPOSAL: 'Proposald__r',
	            ROBJECT_NAME_AGREEMENT: 'AgreementId__r',
	            ROBJECT_NAME_ORDER: 'OrderId__r',
	
	            BOTYPE_PROPOSAL: 'Proposal',
	            BOTYPE_AGREEMENT: 'Agreement',
	            BOTYPE_ORDER: 'Order',
	
	            STATUS_APPROVAL_REQUIRED: 'Approval Required',
	            STATUS_PENDING_APPROVAL: 'Pending Approval',
	            STATUS_READY_FOR_APPROVALS: 'Ready For Approvals'
	        }
	
	        service.ApprovalStatusField = {
	            PROPOSAL_APPROVAL_STAGE: 'Apttus_Proposal__Approval_Stage__c',
	            AGREEMENT_STATUS: 'Apttus__Status__c',
	            ORDER_STATUS: 'Status__c'
	        }
	
	        service.RenewalDateTypes = {
	            PROPOSAL_END_DATE: 'PROPOSALENDDATE',
	            CURRENT_ASSET_END_DATE: 'CURRENTASSETENDDATE',
	            FARTHEST_ASSET_END_DATE: 'FARTHESTASSETENDDATE',
	            USER_RENEWAL_DATE: 'RENEWALDATE'
	        };
	
	        service.CollaborationIconClass = {
	            ASSIGNED_CLASS: 'fa-plus-circle',
	            SUBMITTED_CLASS: 'fa-arrow-circle-right',
	            ACCEPTED_CLASS: 'fa-check-circle',
	            COMPLETED_CLASS: 'fa-exclamation-circle'
	        };
	
	        service.BusinessObjectType = {
	            COLLABORATION_REQUEST: 'Collaboration Request'
	        };
	
	        service.RevalidationStatus = {
	            STATUS_REVALIDATION_PENDING: 'Pending',
	            STATUS_REVALIDATION_NOT_APPLICABLE: 'NA'
	        };
	
	        return service;
	    }];
	})();


/***/ }),
/* 10 */
/***/ (function(module, exports) {

	(function() {
	    module.exports = ['$q', '$log', function($q, $log) {
	
	        var service = this;
	        var isScheduled = false;
	        var processingActions = false;
	        var tail = $q.when(true);
	        var actionQueue = [];
	        var scheduledActionQueue = [];
	        var hashedActionsMap = {};
	        var settings = {
	            logTime: true,
	            maxPrecedence: 1024
	        };
	
	        /* -- Public methods -- */
	
	        //Used to register indiviudal actions and schedule them seperately
	        service.registerAction = registerAction;
	        service.scheduleAction = scheduleAction;
	        service.isProcessingActions = isProcessingActions;
	
	        /* -- Method Declarations -- */
	
	
	        /**
	         * Register a function in the action queue, optionally assignign it a 
	         * 	precedence in execution and a actionKey with which to hash. If the function
	         * 	parameter is not valid, does nothing. 
	         *
	         * @param  {function}	functionObject 	A function that can be executed by the queue.
	         * @param  {number}		precedence     	Precedence with which to execute function. 
	         *                                   	Higher = execute sooner
	         *                                   	Undefined = Max (first)
	         * @param  {string} 	actionKey       Key with which to hash the function. If provided,
	         *                                   	the function is to be queued by this key instead
	         *                                   	of by passing it as an object. Defaults to funciton.toString
	         * @return {actionQueue}              Reference to this service to allow chainging.
	         */
	        function registerAction(functionObject, precedence, actionKey) {
	            var hashVal, existed;
	            var max = settings.maxPrecedence;
	            if (!(functionObject instanceof Function)) {
	                return service;
	
	            }
	            //Calculate values
	            if (!angular.isNumber(precedence)) {
	                precedence = max;
	
	            } else {
	                precedence = Math.min(precedence, max);
	
	            }
	            hashVal = actionKey ? hashObject(actionKey) : hashObject(functionObject);
	            //Store information
	            //existed = hashedActionsMap[hashVal];
	            hashedActionsMap[hashVal] = {
	                "action": functionObject,
	                "precedence": precedence,
	                "isScheduled": false
	            };
	
	            return service;
	
	        }
	
	        /**
	         * Adapted from ActionFunctionQueue; converts any object into a string
	         * 	that has a toString method then hashes that string to an integer value.
	         * 	
	         * @param  {object} 	objectToHash
	         * @return {integer}  hashed integer value
	         */
	        function hashObject(objectToHash) {
	            var str = objectToHash.toString();
	            var hash = 5381;
	            for (i = 0; i < str.length; i++) {
	                char = str.charCodeAt(i);
	                hash = ((hash << 5) + hash) + char; /* hash * 33 + c */
	
	            }
	            return hash;
	
	        }
	
	
	        /**
	         * Schedule a particular action or array of actions. Actions should be 
	         * 	in scheudled using the same function object or prototype with
	         * 	which they were registered. 
	         *
	         * Note: if parameter is an array, the order of actions does not influence
	         * 	the order in which actions will be enqueued. Instead, the registered
	         * 	precedence will be respected.
	         * 	
	         * @param {String|Function|Array} actionKey  action or collection of actions
	         * @return {promise} Resolves with the result of the action. Resolve waits until the queue finishes running.
	         */
	        function scheduleAction(actionKey) {
	            if (angular.isUndefined(actionKey) || actionKey === null) {
	                return tail;
	
	            }
	            var actionArr = [];
	            if (angular.isArray(actionKey)) {
	                actionArr = actionKey;
	
	            } else {
	                actionArr.push(actionKey);
	
	            }
	            var actionIndex, nextActionKey, newSchedule;
	            var resultPromises = [];
	            for (actionIndex = 0; actionIndex < actionArr.length; actionIndex += 1) {
	                nextActionKey = actionArr[actionIndex];
	                queuedResult = queueByPrecedence(nextActionKey);
	                if (queuedResult) {
	                    resultPromises.push(queuedResult);
	                }
	                if (!isScheduled) {
	                    isScheduled = true;
	                    tail = tail.then(fireSync);
	
	                }
	
	            }
	            if (resultPromises.length == 1) {
	                return resultPromises[0];
	
	            } else if (resultPromises.length > 1) {
	                return $q.all(resultPromises);
	
	            }
	            return tail;
	
	        }
	
	        /**
	         * Put a particular action's info into the queue.
	         * @param  {object} actionKey 	Key used to reference object
	         * @return {Boolean}           	True if action becomes scheduled, else False.
	         */
	        function queueByPrecedence(actionKey) {
	            if (!actionKey) {
	                return false; //Invalid; do nothing.
	
	            }
	
	            var hashVal = hashObject(actionKey);
	            var actionInfo = hashedActionsMap[hashVal];
	            //Invalid or already scheduled.
	            if (!actionInfo) {
	                return false;
	
	            } else if (actionInfo.isScheduled) {
	                return actionInfo.deferred.promise;
	
	            }
	
	            var actionIndex = scheduledActionQueue.length; //add at the end for the least precendence action
	            for (var index = 0; index < scheduledActionQueue.length; ++index) {
	                var nextActionInfo = scheduledActionQueue[index];
	                if (actionInfo.precedence > nextActionInfo.precedence) {
	                    actionIndex = index;
	                    break;
	
	                }
	
	            }
	
	            scheduledActionQueue.splice(actionIndex, 0, actionInfo);
	            actionInfo.isScheduled = true;
	            actionInfo.deferred = $q.defer();
	            return actionInfo.deferred.promise;
	
	        }
	
	        /**
	         * Returns true when the action function queue has begun processing actions, false when
	         * the queue has completed and is idle.
	         * @return {Boolean} True when actions are processing, false otherwise.
	         */
	        function isProcessingActions() {
	            return processingActions;
	
	        }
	
	        /**
	         * Fires a sync event. The new event is chained onto the tail of the
	         *  previous event, meaning events will run sequentially.
	         * If the actions in the queue are rejected, i.e. throw errors,
	         * 	the tail of schedlued sync is reset, the rejection is returned.
	         * Optionally logs the information about how long the process took.
	         * 
	         * @return {Promise} tail of scheduled queue
	         */
	        function fireSync() {
	            isScheduled = false;
	            processingActions = true;
	            var sentTime = new Date();
	            if (settings.logTime) {
	                $log.info("Action Queue Submitted: " + sentTime.toGMTString());
	
	            }
	            //Build and run queue of actions
	            return fireScheduledActionQueue().then(
	                function onQueueResolve(result) {
	                    if (settings.logTime) {
	                        var receivedTime = new Date();
	                        var delta = Number(receivedTime - sentTime) / 1000;
	                        $log.info("Sync Transaction Time: " + delta + " seconds.");
	
	                    }
	                    processingActions = false;
	                    return result;
	
	                },
	                function onQueueReject(reason) {
	                    $log.error('Action Queue was Rejected');
	                    isScheduled = false;
	                    tail = $q.when(true);
	                    processingActions = false;
	                    return $q.reject(reason);
	
	                }
	            );
	
	        }
	
	        /**
	         * New variant of fireActionQueue that uses the queue of action infos,
	         * 	which are in order of decreasing precedence.
	         * Creates a chain of primises: start with an empty defer, and add each
	         *  function as a "then" to execute when the previous promise completes.
	         * The whole chain is constructed, then the head of the chain is resolved, 
	         * 	letting the execution begin.
	         * 	
	         * @return {promise} the last promise in the chain
	         */
	        function fireScheduledActionQueue() {
	            var queue = $q.defer(),
	                pendingDeferreds = [],
	                pendingPromises = [],
	                nextActionInfo,
	                nextPromise;
	
	            nextPromise = queue.promise;
	            for (var actionIndex = 0; actionIndex < scheduledActionQueue.length; actionIndex++) {
	                nextActionInfo = scheduledActionQueue[actionIndex];
	                nextPromise = nextPromise.then(nextActionInfo.action);
	                pendingDeferreds.push(nextActionInfo.deferred);
	                pendingPromises.push(nextPromise);
	                nextActionInfo.isScheduled = false; //Allow future scheduling
	                nextActionInfo.deferred = null;
	
	            }
	            // Resolve all promises created during enqueue.
	            $q.all(pendingPromises).then(
	                function resolvePending(allResults) {
	                    for (var dfdIndex = 0; dfdIndex < pendingDeferreds.length; dfdIndex++) {
	                        if (pendingDeferreds[dfdIndex]) {
	                            pendingDeferreds[dfdIndex].resolve(allResults[dfdIndex]);
	                        }
	                    }
	                },
	                function rejectPending(reason) {
	                    for (var dfdIndex = 0; dfdIndex < pendingDeferreds.length; dfdIndex++) {
	                        if (pendingDeferreds[dfdIndex]) {
	                            pendingDeferreds[dfdIndex].reject(reason);
	                        }
	                    }
	                }
	            );
	            scheduledActionQueue = [];
	            queue.resolve();
	            return nextPromise;
	
	        }
	        return service;
	    }];
	})();


/***/ }),
/* 11 */
/***/ (function(module, exports) {

	(function() {
	    module.exports = ['$provide', function($provide) {
	        /*
	         * This decorator intercepts the creation $q service to add pendingPromissesCount & pendingRemoteServiceCount.
	         */
	        $provide.decorator('$q', ['$delegate', '$rootScope', '$log', function($delegate, $rootScope, $log) {
	
	            /*
	             *	Total pending Prmosses Count
	             * Count is maintained through Overloaded Defered method and Finally handller.
	             */
	            var pendingPromisses = 0;
	
	            /*
	             *	Total pending Remote Services Count 
	             * Count will be maintained through incremental and decrimental methods
	             * Incremental and Decrimental methods are consumed in RemoteService.js
	             */
	            var pendingRemoteServiceCount = 0;
	
	            var $q = $delegate;
	
	            /*
	             * Defer Method over loading for maintaining pendingPromissesCount
	             * It returns same promise ($q.defer()) object with finally handler to maintain pendingPromissesCount
	             */
	            var origDefer = $q.defer;
	
	            $q.defer = function() {
	                var defer = origDefer();
	                pendingPromisses++;
	
	                defer.promise.finally(function() {
	                    pendingPromisses--;
	                });
	
	                return defer;
	            };
	
	            $q.incrementRemoteServiceCount = function() {
	                pendingRemoteServiceCount++;
	            };
	
	            $q.decrementRemoteServiceCount = function() {
	                pendingRemoteServiceCount--;
	            };
	
	            $q.getPendingRemoteServiceCount = function() {
	                return pendingRemoteServiceCount;
	            };
	
	            $q.getPendingPromisses = function() {
	                return pendingPromisses;
	            };
	
	            return $q;
	        }]);
	
	    }];
	})();


/***/ })
]);
//# sourceMappingURL=adminService.js.map