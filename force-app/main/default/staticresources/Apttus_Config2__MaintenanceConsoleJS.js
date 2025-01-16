/**
 *	Apttus Config & Pricing
 *	MaintenanceConsole.js
 *	 
 *	@2012-2015 Apttus Inc. All rights reserved.
 * 
 */
 
		
	// Queue Update Bundle calls.
	function UpdateBundleQueue(button, id) {
		var spinnerElement = document.getElementsByClassName('bundle-spinner '+ id);
		var messageElement = document.getElementsByClassName('bundle-message '+ id);
			
		j$(spinnerElement).prepend('<img src="/img/loading.gif" />');
		j$(messageElement).html(j$.APTTUS.bundleUpdatingLabel);

		j$.aptActionFunctionQueue.execute(UpdateBundleProduct, [ button, spinnerElement, messageElement, id ], {
			disableBuffering : true
			
		});

	}

	// updates bundle. 
	function UpdateBundleProduct(button, spinnerElement, messageElement, id) {
		Visualforce.remoting.Manager
			.invokeAction(
				j$.APTTUS.RemoteController.updateBundle, id,
					function(result, event) {
						if (event.status) {
							j$(button).remove();
								if(result == j$.APTTUS.bundleUpdateCompletedMessage) {
									j$(spinnerElement).find("img").remove();
									j$(messageElement).html('<img src="/img/msg_icons/confirm24.png" width="15" height="15"/>').attr("title", result);
										
									j$.aptActionFunctionQueue.processNext();
								} else if(result == j$.APTTUS.bundleIsAlreadyScheduledMessage) {
									j$(spinnerElement).find("img").remove();
									j$(messageElement).html('<img src="/img/msg_icons/warning24.png" width="15" height="15" />').attr("title", result);
										
									j$.aptActionFunctionQueue.processNext();
								} else {
									j$(spinnerElement).find("img").remove();
									j$(messageElement).html('<img src="/img/msg_icons/error24.png" width="15" height="15" />').attr("title", result);
										
									j$.aptActionFunctionQueue.processNext();
								}
									
							}

						});

		}

		// updates constraint rule.
		function updateConstraintRule(button, id) {
			var spinnerElement = document.getElementsByClassName('constraint-spinner '+id);
			var messageElement = document.getElementsByClassName('constraint-message '+id);

			j$(spinnerElement).prepend('<img src="/img/loading.gif" />');
			j$(messageElement).html(j$.APTTUS.ruleUpdatingLabel);

			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.updateConstraintRule, id,
						function(result, event) {
							if (event.status) {
								j$(button).remove();
								j$(spinnerElement).find("img").remove();

								if (result == j$.APTTUS.constraintRuleUpdateCompleteMessage) {
									j$(messageElement).html( '<img src="/img/msg_icons/confirm24.png"  width="15" height="15"  />').attr("title", result);
										
								} else if (result == j$.APTTUS.constraintRuleIsInActiveMessage) {
									j$(messageElement).html( '<img src="/img/msg_icons/confirm24.png"  width="15" height="15"  />').attr("title", result);
										
								} else {
									j$(messageElement).html( '<img src="/img/msg_icons/error24.png"  width="15" height="15"  />').attr("title", result);
									
								}

							}

					});

		}
		
		// check result length. return true if result has no records, return false otherwise.
		function hasNoResult(result) {
			if(result.length == 0) {
				return true;
				
			} else {
				return false;
				
			}
		
		}
		
		// check if result has too many records. return true if result lenght is greater than display cutoff, return false otherwise.
		function hasTooManyRecords(result) {
			var recordDisplayCutOff = 10;
			
			if(result.length > recordDisplayCutOff) {
				return true;
				
			} else {
				return false;
				
			}
			
		}
		
		// Queue Refresh products call.
		function refreshPendingBundles() {
			j$.aptActionFunctionQueue.execute(invokeDoFindPendingBundles, {
				disableBuffering : true
			
			});
			
		}
		
		// reset all the states when refresh icon on the bundle section is clicked.
		function resetBundleSection() {
			j$("#idProductResults tbody").empty();
			j$("#idProductResults").hide();
			j$('#idPendingBundlesMessage').empty();
			j$('.bundleSpinnerPanel').show();
			
		}

		/**
		 * displayBundles - function to display bundle records on bundle maintenance panel
		 * @param  records - set of bundles
		 * @param  isOneClick - boolean flag to indicate if it's a one click maintenance 
		 */
		var displayBundles = function(records, isOneClick) {
			if (hasNoResult(records)) {
				j$('#idPendingBundlesMessage').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br> </br>");
				j$('#idProductResults').hide();
				bundlesToUpdate = [];
				
			} else if (hasTooManyRecords(records)) {
				j$('#idPendingBundlesMessage').html("<b>" + j$.APTTUS.tooManyRecordsToUpdateLabel + "</b>");
				j$('#idPendingBundlesMessage').append("<p>" + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.bundleMaintenancePage + " target=\"_blank\"><b>" + j$.APTTUS.bundleMaintenanceLabel + " " + "</b></a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateAllLabel + " " + j$.APTTUS.bundleProductsLabel + "</p>");
				bundlesToUpdate = records;
					
			} else {
				j$('#idPendingBundlesMessage').html("<span>" + j$.APTTUS.pendingRecordsToUpdate + "</span> <br> </br>");
				j$("#idProductResults").show();
				bundlesToUpdate = records;
				j$.each(records,function(index, record) {
					var row = j$("#bundleResultTemplate").tmpl(record);
					row.appendTo("#idProductResults tbody");
					// if one click maintenance, show error/warning messages with symbols
					if(isOneClick) {
						if(record.message == j$.APTTUS.bundleIsAlreadyScheduledMessage) {
							j$("[class='bundle-message " + record.Id + "']").html('<img src="/img/msg_icons/warning24.png" width="15" height="15" />').attr("title", record.message);
						
						} else {
							j$("[class='bundle-message " + record.Id + "']").html('<img src="/img/msg_icons/error24.png" width="15" height="15" />').attr("title", record.message);	
						
						}
						
					}
				});
			}
		}

		// search for pending bundles to update.
		var bundlesToUpdate;
		function invokeDoFindPendingBundles() {
			resetBundleSection();
			
			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.doFindPendingBundles,
						function(result, event) {
							if (event.status && event.result) {
								bundlesToUpdate = result;
								displayBundles(result, false);

							} else {
								j$('#idPendingBundlesMessage').html("<b>" + event.message + "</b>");
								j$('#idPendingBundlesMessage').append("<p>" + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.bundleMaintenancePage + " target=\"_blank\"><b>" + j$.APTTUS.bundleMaintenanceLabel + " " + "</b></a>" + j$.APTTUS.pageLabel + ", " + j$.APTTUS.UpdateInBatchMode);

							}

							j$('.bundleSpinnerPanel').hide();
							j$.aptActionFunctionQueue.processNext();

						}, {
							escape : true
				});

		}

		var starter, updateAllBundlesPromise, updateAllConstraintRulesPromise, updateAllConstraintCritFieldsPromise, updateAllPricingCriteriaFieldsPromise, updateAllProductFiltersPromise;
		
		var definePromises = function() {
			starter = jQuery.Deferred();
			updateAllBundlesPromise = starter.then(updateAllBundles);
			updateAllConstraintRulesPromise = updateAllBundlesPromise.then(updateAllConstraintRules);
			updateAllConstraintCritFieldsPromise = updateAllConstraintRulesPromise.then(updateAllConstraintCritFields);
			updateAllPricingCriteriaFieldsPromise = updateAllConstraintCritFieldsPromise.then(updateAllPricingCriteriaFields);
			updateAllProductFiltersPromise = updateAllPricingCriteriaFieldsPromise.then(updateAllProductFilters); 

		}

		/**
		 * function to initiate one click maintenance
		 */
		function updateAll() {
			j$('.updateAllSpinnerPanel').show();
			j$('.updateAllStatusPanel').show();
			// kick off one click maintenance
			starter.resolve();
		}

		/**
		 * function to update all bundles as a part of one click maintenance
		 * @return deferred promise with appropriate state
		 */
		function updateAllBundles() {
			j$('#idCurrentMaintenanceJob').html(j$.APTTUS.bundleMaintenanceLabel + ' ' + j$.APTTUS.fastModeStartTextLabel);
			var deferred = j$.Deferred();
			var failedBundles = new Array();
			
			if(!bundlesToUpdate) {
				// if no data available, or some errors happened before, move on to next job
				return deferred.resolve();
			} else if(bundlesToUpdate.length == 0) {
				// if no bundles to update, no need to run maintenance
				return deferred.resolve();
			}
			// initiate bundle maintenance
			var bundleMaintenanceTracker = new Array(bundlesToUpdate.length);
			j$('#idUpdateAllRecordCounts').html(1 + '/' + bundlesToUpdate.length + ' ');
			j$.each(bundlesToUpdate, function(index, value){
				bundleMaintenanceTracker[index] = false;
				var bundleId = value.Id;
				// updating bundles
				Visualforce.remoting.Manager.invokeAction(
					j$.APTTUS.RemoteController.updateBundle, bundleId,
						function(result, event) {
							if(result == j$.APTTUS.bundleUpdateCompletedMessage) {
								j$('#idUpdateAllRecordCounts').html(index + '/' + bundlesToUpdate.length + ' ');

							} else {
								var failedBundle = bundlesToUpdate[index];
								failedBundle['message'] = result;
								failedBundles.push(failedBundle);

							}

							bundleMaintenanceTracker[index] = true;
							if(bundleMaintenanceTracker.every(function(status, index, array) { return status==true; })) { // if all the elements in the tracker are true
								j$("#idProductResults tbody").empty();
								displayBundles(failedBundles, true);
								// resolve the deferred object to execute next maintenance
								deferred.resolve();

							}
						}
				);
			});
			return deferred.promise();
		}

		/**
		 * function to update all constraint rules as a part of one click maintenance
		 * @return deferred promise with appropriate state
		 */
		function updateAllConstraintRules() {
			j$('#idCurrentMaintenanceJob').html(j$.APTTUS.constraintRuleMaintenanceLabel + ' ' + j$.APTTUS.fastModeStartTextLabel);
			var deferred = j$.Deferred();
			var failedConstraintRules = new Array();
			if(!constraintRulesToUpdate) {
				// if no data available, or some errors happened before, move on to next job
				return deferred.resolve();

			} else if(constraintRulesToUpdate.length == 0) {
				// if no constraint rules to update, no need to run maintenance
				return deferred.resolve();

			}
			// initiate constraint rule maintenance
			var constraintRuleMaintenanceTracker = new Array(constraintRulesToUpdate.length);
			j$('#idUpdateAllRecordCounts').html(1 + '/' + constraintRulesToUpdate.length + ' ');
			j$.each(constraintRulesToUpdate, function(index, value) {
				constraintRuleMaintenanceTracker[index] = false;
				var constraintRuleId = value.Id;
				Visualforce.remoting.Manager.invokeAction(
					j$.APTTUS.RemoteController.updateConstraintRule, constraintRuleId,
						function(result, event) {
							if (result) {
								j$('#idUpdateAllRecordCounts').html(index+1 + '/' + constraintRulesToUpdate.length + ' ');

							} else {
								var failedRule = value;
								failedRule['message'] = event.message;
								failedConstraintRules.push(failedRule);

							}
							constraintRuleMaintenanceTracker[index] = true;

							if(constraintRuleMaintenanceTracker.every(function(status, index, array) { return status==true; })) { // if all the elements in the tracker are true
								j$("#idConstraintRuleResults tbody").empty();
								displayConstraintRules(failedConstraintRules, true);
								// resolve the deferred object to execute next maintenance
								deferred.resolve();

							}
							
						}
				);
			});
			return deferred.promise();
		}

		/**
		 * function to update all constraint criteria fields as a part of one click maintenance
		 * @return deferred promise with appropriate state
		 */
		function updateAllConstraintCritFields() {
			j$('#idCurrentMaintenanceJob').html(j$.APTTUS.constraintCritFieldMaintenanceLabel + ' ' + j$.APTTUS.fastModeStartTextLabel);
			j$('#idUpdateAllRecordCounts').html('');
			var deferred = j$.Deferred();
			if(!isConCriteriaUpToDate) { // Update Criteria only if they are not uptodate
				Visualforce.remoting.Manager.invokeAction(
					j$.APTTUS.RemoteController.updateConstraintConditionCriteria, function(result, event) {
						if(result == j$.APTTUS.updateComplete) {
							j$('#idCriteriaFieldsToUpdate').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel +"</b>");	
							isConCriteriaUpToDate = true;
						} else {
							// check if governor limits are hit or some other exception is thrown based on event.status
							var message = event.status ? result : event.message;
							j$('#idCriteriaFieldsToUpdate').html("<b>" + message + "</b> ");
							j$('#idCriteriaFieldsToUpdate').append("<p>" + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " +"<a href=" + j$.APTTUS.criteriaUpdatePage + " target=\"_blank\"><b>" + j$.APTTUS.criteriaUpdateLabel + " " + "</b> </a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateConstraintFieldsLabel + "</p>");
						}
						deferred.resolve();
					}
				);
			} else {
				deferred.resolve();
			}
			return deferred.promise();
		}

		/**
		 * function to update all pricing criteria fields as a part of one click maintenance
		 * @return deferred promise with appropriate state
		 */
		function updateAllPricingCriteriaFields() {
			j$('#idCurrentMaintenanceJob').html(j$.APTTUS.pricingCriteriaFieldMaintenanceLabel + ' ' + j$.APTTUS.fastModeStartTextLabel);
			j$('#idUpdateAllRecordCounts').html('');
			var deferred = j$.Deferred();
			if(!isPricingCritUpToDate) {
				Visualforce.remoting.Manager.invokeAction(
					j$.APTTUS.RemoteController.updatePricingCriteria, function(result, event) {
						if(result == j$.APTTUS.updateComplete) {
							j$('#idPricingCriteriaToUpdate').hide();
							j$('#idNoPricingCriteriaToUpdate').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br> </br>");
							isPricingCritUpToDate = true;

						} else {
							// check if governor limits are hit or some other exception is thrown based on event.status
							var message = event.status ? result : event.message;
							j$('#idPricingCriteriaToUpdate').html("<b>" + message + "</b>");
							j$( "#idPricingCriteriaToUpdate" ).append( "<p>" + " " + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.criteriaUpdatePage + " " + " target=\"_blank\"><b>" + j$.APTTUS.criteriaUpdateLabel +  " " + "</b></a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updatePricingFieldsLabel + "</p>" );

						}
						deferred.resolve();
					}
				);
			} else {
				deferred.resolve();

			}
			return deferred.promise();

		}

		/**
		 * function to update all product filter criteria as a part of one click maintenance
		 * @return deferred promise with appropriate state
		 */
		function updateAllProductFilters() {
			j$('#idCurrentMaintenanceJob').html(j$.APTTUS.productFilterMaintenanceLabel + ' ' + j$.APTTUS.fastModeStartTextLabel);
			j$('#idUpdateAllRecordCounts').html('');
			var deferred = j$.Deferred();
			if(!isProductFiltersUpToDate) {
				Visualforce.remoting.Manager.invokeAction(
					j$.APTTUS.RemoteController.updateProductFiltersInFastMode, function(result, event) {
						if(result == j$.APTTUS.updateComplete) {
							j$('#idProductFiltersText').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br />");
							isProductFiltersUpToDate = true;

						} else {
							j$('#idProductFiltersText').html("<b>" + result + "</b> <br />");
							j$( "#idProductFiltersText" ).append( "<p>" + " " + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.productFiltersUpdatePage + " target=\"_blank\"><b>" + j$.APTTUS.productFilterMaintenanceLabel +  " " + "</b></a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateProductFiltersLabel + "</p>" );

						}
						j$('.updateAllSpinnerPanel').hide();
						j$('#idCurrentMaintenanceJob').empty();
						deferred.resolve();
					}
				);
			} else {
				j$('.updateAllSpinnerPanel').hide();
				j$('#idCurrentMaintenanceJob').empty();
				deferred.resolve();
				definePromises();

			}
			return deferred.promise();

		}

		function refreshPendingConstraintRules() {
			// refresh Pending Records to Update
			j$.aptActionFunctionQueue.execute(
					invokeDoFindPendingConstraintRules, {
						disableBuffering : true
			
			});

			// refresh list of rules with Criteria Formula Fields
			getRulesWithFormulaFields();
		
		}

		// reset all the states when refresh icon on the constraint rule section is clicked.
		function resetConstraintRulesSection() {
			j$("#idConstraintRuleResults tbody").empty();
			j$("#idConstraintRuleResults").hide();
			j$('#idPendingConstraintRuleMessage').empty();
			j$('.idConstraintSpinnerPanel').show();
		
		}
		
		// reset the state for the 2nd block within Constraint Rule section
		function resetConstraintRulesWithFormulaFieldsSection() {
			j$('#idConstraintRulesFormulaResults tbody').empty();
			j$('#idConstraintRulesFormulaFieldsPanel').hide();
			j$('#idRulesWithFormulaFieldsSpinnerPanel').show();

		}
		
		/**
		 * displayConstraintRules - function to display cosntraint rules records on constraint rule maintenance panel
		 * @param  records - set of constraint rules
		 * @param  isOneClick - boolean flag to indicate if it's a one click maintenance 
		 */
		var displayConstraintRules = function(records, isOneClick) {
			if (hasNoResult(records)) {
				j$('#idPendingConstraintRuleMessage').html("<span class='maintenanceConsoleText'> <b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br> </br> </span>");
				j$("#idConstraintRuleResults").hide();
				constraintRulesToUpdate = [];

			} else if (hasTooManyRecords(records)) {
				constraintRulesToUpdate = records;
				j$('#idPendingConstraintRuleMessage').html("<b>" + j$.APTTUS.tooManyRecordsToUpdateLabel + "</b>");
				j$('#idPendingConstraintRuleMessage').append("<p>" + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.constraintRulesMaintenancePage +"><b>" + j$.APTTUS.constraintRuleMaintenanceLabel+ " " + "</b></a>" + " " + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateAllLabel + " " + j$.APTTUS.constraintRulesLabel + "</p>");

			} else {
				constraintRulesToUpdate = records;
				j$('#idPendingConstraintRuleMessage').html("<div class='maintenanceConsoleText'>" + j$.APTTUS.pendingRecordsToUpdate + "</div> <br/>");
				j$('#idConstraintRuleResults').show();
				j$.each(records, function(index, record) {
					var row = j$("#constraintViewResultTemplate").tmpl(record);
					row.appendTo("#idConstraintRuleResults tbody");
					// if one click maintenance, show error/warning messages with symbols
					if(isOneClick) {
						if(record.message == j$.APTTUS.constraintRuleIsInActiveMessage) {
							j$("[class='constraint-message " + record.Id + "']").html('<img src="/img/msg_icons/warning24.png" width="15" height="15" />').attr("title", record.message);
					
						} else {
							j$("[class='constraint-message " + record.Id + "']").html('<img src="/img/msg_icons/error24.png" width="15" height="15" />').attr("title", record.message);	
					
						}
						
					}
				});
			}

		}
		// search for pending constraint rules to update.
		var constraintRulesToUpdate;
		function invokeDoFindPendingConstraintRules() {	
			resetConstraintRulesSection();
			
			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.doFindPendingConstraintRules,
						function(result, event) {
							if (event.status && event.result) {
								constraintRulesToUpdate = result;
								displayConstraintRules(result, false);

							} else {
								j$('#idPendingConstraintRuleMessage').html("<b>" + event.message + "</b>");
								j$('#idPendingConstraintRuleMessage').append("<p>" + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.constraintRulesMaintenancePage +" target=\"_blank\"><b>" + j$.APTTUS.constraintRuleMaintenanceLabel+ " " + "</b></a>" + " " + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateAllLabel + " " + j$.APTTUS.constraintRulesLabel + "</p>");

							}
							j$('.idConstraintSpinnerPanel').hide();
							j$.aptActionFunctionQueue.processNext();

						}, {
							escape : true
							
				});

		}

		// execute remote action by adding and executing from the action queue
		function getRulesWithFormulaFields() {
			j$.aptActionFunctionQueue.execute(invokeGetRulesWithFormulaFields, {disableBuffering: true});
		}

		// get and process a list of constraint rules whose condition or action criteria contain formula fields
		function invokeGetRulesWithFormulaFields() {
			resetConstraintRulesWithFormulaFieldsSection();
			Visualforce.remoting.Manager.invokeAction(
				j$.APTTUS.RemoteController.getRulesWithFormulaFields,
				function(result, event) {
					j$('#idRulesWithFormulaFieldsSpinnerPanel').hide();
					if (event.status && event.result && result.length > 0) {
						j$('#idConstraintRulesFormulaFieldsPanel').show();
						j$.each(result, function(index, record) {
							var row = j$("#constraintWithFormulaFieldsTemplate").tmpl(record);
							row.appendTo("#idConstraintRulesFormulaResults tbody");
						});
					}
					j$.aptActionFunctionQueue.processNext();
				},
				{
					escape : true
				}
			);
		}

		function refreshPendingConCriteriaFields() {  
			j$.aptActionFunctionQueue.execute( 
					invokeIsConCriteriaUpToDate, {  
						disableBuffering : true
			
			});
		
		}

		// search for pending constraint rule criteria to update.
		var isConCriteriaUpToDate = true;
		function invokeIsConCriteriaUpToDate() {
			j$('.idConstraintConditionCriteriaFieldPanel').show();
			j$('#idCriteriaFieldsToUpdate').empty();

			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.isConstraintCriteriaUpToDate,
						function(result, event) {
							j$('.idConstraintConditionCriteriaFieldPanel').hide();
								if (event.status && event.result) {
									isConCriteriaUpToDate = true;
									j$('#idCriteriaFieldsToUpdate').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel +"</b>");	
									
								} else {
									isConCriteriaUpToDate = false;
									j$('#idCriteriaFieldsToUpdate').html("<b>" + j$.APTTUS.tooManyRecordsToUpdateLabel + "</b> ");
									j$('#idCriteriaFieldsToUpdate').append("<p>" + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " +"<a href=" + j$.APTTUS.criteriaUpdatePage +"> <b>" + j$.APTTUS.criteriaUpdateLabel + " " + "</b> </a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateConstraintFieldsLabel + "</p>");
										
								}
								
							j$.aptActionFunctionQueue.processNext();
						}, {
							escape : true
							
						});

		}
		
		function refreshPendingPricingMaintenance() {
			j$.aptActionFunctionQueue.execute( 
					invokeIsPricingCriteriaUpToDate, {  
						disableBuffering : true
			
			});
		
		}
		
		var isPricingCritUpToDate;
		function invokeIsPricingCriteriaUpToDate() {
			j$('.idPricingCriteriaFieldPanel').show();
			j$('#idPricingCriteriaToUpdate').empty();
			j$('#idNoPricingCriteriaToUpdate').empty();
			
			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.isPricingCriteriaUpToDate,
						function(result, event) {
							j$('.idPricingCriteriaFieldPanel').hide();
								if (event.status && event.result) {
									// No Records to Update
									isPricingCritUpToDate = true;
									j$('#idNoPricingCriteriaToUpdate').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br> </br>");
									
								} else {
									// Update All Pricing Criteria Fields 
									isPricingCritUpToDate = false;
									j$('#idPricingCriteriaToUpdate').html("<b>" + j$.APTTUS.tooManyRecordsToUpdateLabel + "</b>");
									j$( "#idPricingCriteriaToUpdate" ).append( "<p>" + " " + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.criteriaUpdatePage + " " + "><b>" + j$.APTTUS.criteriaUpdateLabel +  " " + "</b></a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updatePricingFieldsLabel + "</p>" );
										
								}
									
								j$.aptActionFunctionQueue.processNext();
							}, {
					escape : true
			});	
		}

		// Queue product filters function call
		function refreshPendingProductFiltersMaintenance() {
			j$.aptActionFunctionQueue.execute(
				invokeIsProductFiltersUpToDate, {
					disableBuffering: true
			});

		}

		var isProductFiltersUpToDate;
		function invokeIsProductFiltersUpToDate() {
			j$('#idProductFiltersText').empty();
			j$('#idProductFiltersText').hide();
			j$('#idProductFiltersPanel').show();

			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.isProductFiltersUpToDate,
					function(result, event) {
						j$('#idProductFiltersPanel').hide();
						j$('#idProductFiltersText').show()
						if(result) {
							isProductFiltersUpToDate = true;
							j$('#idProductFiltersText').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br />");

						} else {
							j$('#idProductFiltersText').html("<b>" + j$.APTTUS.tooManyRecordsToUpdateLabel + "</b>");
							j$('#idProductFiltersText').append("<p>" + " " + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.productFiltersUpdatePage + " target=\"_blank\"><b>" + j$.APTTUS.productFilterMaintenanceLabel +  " " + "</b></a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateProductFiltersLabel + "</p>" );
							j$('#idProductFiltersText').append("<p>" + " " + j$.APTTUS.Or + " " + "<a href=javascript:updateProductFilters();><b>" + j$.APTTUS.ClickHere + "</b></a>" + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.UpdateInFastMode);
							isProductFiltersUpToDate = false;

						}
					}, {
						escape : true
					}
			);
		}

		// function to update product filters in fast mode
		function updateProductFilters() {
			j$('#idProductFiltersText').empty();
			j$('#idProductFiltersText').hide();
			j$('#idProductFiltersPanel').show();
			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.updateProductFiltersInFastMode,
					function(result, event) {
						j$('#idProductFiltersPanel').hide();
						j$('#idProductFiltersText').show();
						if(result == j$.APTTUS.updateComplete) {
							j$('#idProductFiltersText').html("<b>" + j$.APTTUS.noRecordsToUpdateLabel + "</b> <br> </br>");
						} else {
							// check if governor limits are hit or some other exception is thrown based on event.status
							var message = event.status ? result : event.message;
							j$('#idProductFiltersText').html("<b>" + message + "</b>");
							j$( "#idProductFiltersText" ).append( "<p>" + " " + j$.APTTUS.goLabel + " " + j$.APTTUS.toLabel + " " + "<a href=" + j$.APTTUS.productFiltersUpdatePage + " " + "><b>" + j$.APTTUS.productFilterMaintenanceLabel +  " " + "</b></a>" + j$.APTTUS.pageLabel + " " + j$.APTTUS.toLabel + " " + j$.APTTUS.updateProductFiltersLabel + "</p>" );
						}

					}, {
						escape : true
					}
			);
		}

		// Queue refresh PricelistItemSequence call
		function refreshPricelistItemSequence(button) {
			j$(button).remove();
			j$.aptActionFunctionQueue.execute(invokeRefreshPricelistItemSequence, {
				disableBuffering : true
			});
		}

		function invokeRefreshPricelistItemSequence() {			
			j$('#priceListItemSequenceUpdatePanel').show();

			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.updatePriceListItemSequence,
						function(result, event) {
							if (event.status && event.result) {
									j$('#priceListItemSequenceUpdateMessage').html("<b>" + event.result +"</b>");	
									
							}

							j$('#priceListItemSequenceUpdatePanel').hide();	
							j$.aptActionFunctionQueue.processNext();
						}, {
					escape : true
			});	
		}

		// Queue refresh metadata call
		function refreshFieldMetadata(button) {
			j$(button).remove();
			j$.aptActionFunctionQueue.execute(invokeRefreshFieldMetadata, {
				disableBuffering : true
			
			});
			
		}

		function invokeRefreshFieldMetadata() {			
			j$('#idFieldMetadataPanel').show();

			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.refreshFieldMetadata,
						function(result, event) {
							if (event.status && event.result) {
									j$('#idFieldMetadataMessage').html("<b>" + event.result +"</b>");	
									
							}

							j$('#idFieldMetadataPanel').hide();	
							j$.aptActionFunctionQueue.processNext();
						}, {
					escape : true
			});	
		}

		// Queue update inclusion criteria call
		function updateInclusionCriteria(button) {
			j$(button).remove();
			j$.aptActionFunctionQueue.execute(updateInclusionCriteria, {
				disableBuffering : true
			
			});
			
		}

		function updateInclusionCriteria() {			
			j$('#idInclusionCriteriaPanel').show();

			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.updateInclusionCriteria,
						function(result, event) {
							if (event.status && event.result) {
									j$('#idInclusionCriteriaMessage').html("<b>" + event.result +"</b>");	
									
							}

							j$('#idInclusionCriteriaPanel').hide();	
							j$.aptActionFunctionQueue.processNext();
						}, {
					escape : true
			});	
		}

		function updateAttributeRuleActions(button) {			
			j$(button).remove();
			j$.aptActionFunctionQueue.execute(
				function() {
					j$('#idAttributeRuleActionPanel').show();

					Visualforce.remoting.Manager
						.invokeAction(
							j$.APTTUS.RemoteController.updateAttributeRuleActions,
								function(result, event) {
									if (event.status && event.result) {
											j$('#idAttributeRuleActionMessage').html("<b>" + event.result +"</b>");	
											
									}

									j$('#idAttributeRuleActionPanel').hide();	
									j$.aptActionFunctionQueue.processNext();
								}, {
							escape : true
					});	
				}, 
				{
					disableBuffering : true
				
				}
			);
			
		}

		// queues update account hierarchy call
		function updateAccountHierarchy(button) {
			j$(button).remove();
			j$.aptActionFunctionQueue.execute(
				function() {
					j$('#idAccountHierarchyUpdatePanel').show();
					Visualforce.remoting.Manager
						.invokeAction(
							j$.APTTUS.RemoteController.updateAccountHierarchy,
								function(result, event) {
									if (event.status && event.result) {
										j$('#idAccountHierarchyUpdateMessage').html("<b>" + event.result +"</b>");
									}
									j$('#idAccountHierarchyUpdatePanel').hide();
									j$.aptActionFunctionQueue.processNext();
								}, {
							escape: true
					});
				},
				{
					disableBuffering: true
				}
			);
		}		

		// checks whether account hierarchy update job is running or not
		function invokeIsAccountHierarchyJobRunning() {
			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.isAccountHierarchyJobRunning,
					function(result, event) {
						j$('#idAccountHierarchyUpdateMessage').show();
						if (event.status && event.result) {
							j$('#idAccountHierarchyUpdateMessage').html("<b>" + j$.APTTUS.accountHierarchyUpdateRunningLabel + "</b> <br />");
						}
					}, {
						escape: true
					}
			);
		}

		//FieldExpression Evaluation/Verification
		function refreshFieldExpressions() {
			j$.aptActionFunctionQueue.execute(
					invokeDoVerifyFieldExpressions, {
						disableBuffering : true
			
			});
		
		}

		//FieldExpression Evaluation/Verification
		function resetFieldExpressionSection() {
			j$("#idFieldExpressionResults tbody").empty();
			j$("#idFieldExpressionResults").hide();
			j$('#idFieldExpressionMessage').empty();
			j$('.idFieldSpinnerPanel').show();
		
		}
		
		//FieldExpression Evaluation/Verification
		function invokeDoVerifyFieldExpressions() {	
			resetFieldExpressionSection();
			
			Visualforce.remoting.Manager
				.invokeAction(
					j$.APTTUS.RemoteController.doVerifyFieldExpressions,
						function(result, event) {
							if (event.status && event.result) {
								if (hasNoResult(result)) {
									j$('#idFieldExpressionMessage').html("<span class='maintenanceConsoleText'> <b>" + j$.APTTUS.noInvalidFieldsLabel + "</b> <br> </br> </span>");
								
								} else {
									j$('#idFieldExpressionMessage').html("<div class='maintenanceConsoleText'>" + j$.APTTUS.haveInvalidFieldsLabel + "</div> <br/>");
									j$('#idFieldExpressionResults').show();
									j$.each(event.result, function() {
										var row = j$("#fieldExpressionResultTemplate").tmpl(this);
										row.appendTo("#idFieldExpressionResults tbody");

									});

								}

							} else {
								j$('#idFieldExpressionMessage').html("<span class='maintenanceConsoleText'> <b>" + event.message + "</b> <br> </br> </span>");

							}
							j$('.idFieldSpinnerPanel').hide();
							j$.aptActionFunctionQueue.processNext();

						}, {
							escape : true
							
				});

		}