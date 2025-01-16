/**
 *	Apttus Config & Pricing
 *	cpqcart.js
 *	 
 *	@2012-2013 Apttus Inc. All rights reserved.
 * 
 */
 	j$.APTTUS.leftAdjust = 0;
	j$.APTTUS.topAdjust = 0;
		
	j$(document).ready(function(){
        //hack to stop chatter form from interfering with page form.
			//moves chatter from bottom of page to top.
		relocateChatter();
		j$('#cartHeaderDiv').hide();
		
        var items =  j$('#detailsTable2');				
		if(!localStorage.getItem("detailsTable2"))
		{
			j$('#detailsTable2').hide();
			localStorage.setItem('detailsTable2', 'none'); 
		}
		else
		{
			items.css('display',localStorage.getItem('detailsTable2'));
		}

		// on change, update dynamic classes
		j$(document).on('change', '[class^=aptAdjustmentType]', function(){			
			j$.APTTUS.applyDynamicClasses(j$(this));
			j$.APTTUS.formatFields(j$.APTTUS.currencyFieldPrecision, j$.APTTUS.percentageFieldPrecision, j$.APTTUS.quantityFieldPrecision);
				
		})

		j$(document).on( 'mouseover', '#aptTopButtons', function(){
			j$('.datePicker').hide();
			j$('body').append(j$('.datePicker'));
		});

		j$(document).on( 'mouseover', '.incentiveInfoIcon', function(){
			j$(this).next('.applied-incentives-info').show();
		});

		j$(document).on( 'mouseleave', '.applied-incentives-info', function(){
			j$(this).fadeOut();
		});

		j$(document).on( 'mouseover', '.pageButtons', function(){
			j$('.datePicker').hide();
			j$('body').append(j$('.datePicker'));
		});

		doCheckAndRepriceLineItems();
				
		j$( window ).resize(function() {
			itemsTableOverflowCheck();
			
		});
		
    });

    function relocateChatter(){
    	//if cartHeaderDiv has not been added add it.
    	if(!j$('#relocateChatter #cartHeaderDiv').length){
    		j$('#relocateChatter').html(j$('#cartHeaderDiv').html());

    	}
		
    }
    
    /**
     * Check if cart line items table is overflowing if so adjust datepicker location else put datepicker back in origin.
     */
    function itemsTableOverflowCheck(){
    	if( document.getElementById('itemsTable').offsetWidth < document.getElementById('itemsTable').scrollWidth){
			//position datepicker on mouseover if hidden
			j$(document).on( 'mouseover', '#itemsTable .dateInput', function(){
				var leftAdjust = 0;
				if(j$('.datePicker').is(':visible') == false) {
					j$(this).parent('span').append(j$('.datePicker'));
					adjustPosition(this,'.lineItemsTable');
				}
			});
			
			//position datepicker on click
			j$(document).on( 'click', '#itemsTable span.dateInput input', function(){
				adjustPosition(this,'.lineItemsTable');
				j$(this).parent('span').append(j$('.datePicker'));
				j$('.datePicker').css({'left':j$.APTTUS.leftAdjust + 'px','top':j$.APTTUS.topAdjust+'px'});
			});
			
		}else{
			j$('body').append(j$('.datePicker'));
			
		}
		
    }
    
    /**
     * Set position of datepicker depending on its position.
     */
	function adjustPosition(thisElem, containerElem){
		var containerRight = j$(containerElem).offset().left + j$(containerElem).width();
		var inputRight = j$(thisElem).offset().left + j$(thisElem).width();
		var pickerRight = inputRight + 200;
		
		j$.APTTUS.topAdjust = -(j$('.datePicker').height()/2 + 20);
		
		j$.APTTUS.leftAdjust = j$(thisElem).width() + 10;
		
		//if datepicker is overflowing move it to the left
		if(pickerRight > containerRight){
			j$.APTTUS.leftAdjust = -240;
		}
		
		if(j$(thisElem).parent().hasClass('aptFirstRowInput') == true){
			j$.APTTUS.topAdjust = -50;
		
		}
		
	}
    
   	//Implements the view cart function
	function invokeDoViewCart (){
		sfdcInvokeDoViewCart();
	
	}
        
	/**
     * Display the advanced approval dialog
     */
	function showApprovalDialog( approvalURL ) {
		j$('.idApprovalDialog').dialog({			
			modal: true,			
			dialogClass:'approvalDialog',
			open: function(){
	        	j$('.idApprovalDialog > iframe').attr('src', approvalURL);
	        },
	        width:765,
	        height:450,
	        //resizable:false,
	        //draggable:false,
	        autoOpen:true,	    	
	    	title:j$.APTTUS.ApprovalDialogTitle
	    });

		j$('.idApprovalDialog').dialog('option', 'position', 'center');
	   // j$('.approvalDialog .ui-dialog-titlebar').hide();	 
	}
	
	//setup the dialog box for price breakdown panel
	function setupPriceBreakdownPanel(){
		j$('#priceBreakdownPanel').dialog({
			modal:true,
			width:1000,
			title:j$.APTTUS.PriceBreakdown,
			dialogClass:'PriceBreakdownDialog',
			close:function(){
				j$(this).dialog('destroy');
				
			},
			create:function(){
				j$('.PriceBreakdownDialog .ui-dialog-titlebar a span').html('');
				j$('.PriceBreakdownDialog .ui-dialog-titlebar a span').removeClass('ui-icon ui-icon-closethick');
				j$('.PriceBreakdownDialog .ui-dialog-titlebar a span').addClass('aptRampCloseDialogIcon');
				
			}
			
		});
	}
	
    
    function showRampList() {
    	j$('body').append(j$('.datePicker'));
    	j$.APTTUS.rampsDialog = j$('.rampItemsPanel').dialog({
			width: 1000,
			modal: true,
			title: j$.APTTUS.PricingRampsLabel,
			dialogClass:'rampsDialog',
			resizable:false,
			open: function(event) {
				//openDialogSetup();				
				j$.APTTUS.rampsModified = false;
				j$.APTTUS.rampsNeedPricing = false;
				
				j$('.rampItemsPanel .rampErrorImg').each(function(){
					j$.APTTUS.rampsModified = true;
				});

				j$('.rampItemsPanel input').change(function(){
					j$.APTTUS.rampsModified = true;
					j$.APTTUS.rampsSaved = false;
				});
				 j$.APTTUS.wrapSpan();
			},
			beforeClose: function(event) {
				if(j$.APTTUS.rampsModified === true){
					if(j$.APTTUS.hasErrors){
						showQuitRampWithValidationErrorsConfirmation(this);
						return false;
					} else {
						showQuitRampConfirmation(this);
						return false;
					}
					
				} else {
					revertOptionListHTML();
					destroyRampActionMenus();

				    var position = j$('#itemsTable').offset();
				    j$('.aptLoadingOverlay').css( { position: 'absolute', left: position.left, top: position.top });
				    j$('.aptLoadingOverlay').width(j$('#itemsTable').width());
				    j$('.aptLoadingOverlay').height(j$('#itemsTable').height());
				    j$('.aptLoadingOverlay').show();
				    
					if (j$.APTTUS.rampsSaved == false) {
						rollbackLineItemChanges();	
						
					} else if(j$.APTTUS.rampsNeedPricing === true){
		          		j$.aptActionFunctionQueue.processNext();j$.aptActionFunctionQueue.execute(doInvokeUpdatePriceForCart, [], {disableBuffering:true, loadingLabel:j$.APTTUS.updatingPriceLabel});
		          		
		          	} else {
		          		//invokeDoReloadCart();
		          		doReload();
		          		
		          	}
		          	
					
				}
			},
			create:function(){
				j$('.rampsDialog .ui-dialog-titlebar a span').html('');
				j$('.rampsDialog .ui-dialog-titlebar a span').removeClass('ui-icon ui-icon-closethick');
				j$('.rampsDialog .ui-dialog-titlebar a span').addClass('aptRampCloseDialogIcon');
				//j$('.rampsDialog .ui-dialog-content').css('max-height','350px');
				
			}
			
		});
		
		
		j$('.rampItemsPanel').css('height','auto');
    }

    function showQuitRampConfirmation(dialog) {
		j$("#rampsQuitPanel").dialog({
			autoOpen: false,
			draggable: true,
			modal: true,
			resizable: false,
			position: 'center',
			buttons: {
		        "Yes": function() {
		        	revertOptionListHTML();
		        	j$( this ).dialog( "destroy" );
		          	j$('.rampItemsPanel').dialog('destroy');
		          	var position = j$('#itemsTable').offset();
				    j$('.aptLoadingOverlay').css( { position: 'absolute', left: position.left, top: position.top });
				    j$('.aptLoadingOverlay').width(j$('#itemsTable').width());
				    j$('.aptLoadingOverlay').height(j$('#itemsTable').height());
				    j$('.aptLoadingOverlay').show();

		          	destroyRampActionMenus();
		          	rollbackLineItemChanges();
					//invokeDoReloadCart();//rerender after rollback

					return true;
		          	
		        },
		        No: function() {
					j$( this ).dialog( "destroy" );
		           return false;
		        }
		       
		    }
			
		});

		j$("#rampsQuitPanel").dialog('open');
	}
	
	function showQuitRampWithValidationErrorsConfirmation(dialog) {
		j$("#rampsValidationErrorPanel").dialog({
			autoOpen: false,
			draggable: true,
			modal: true,
			resizable: false,
			position: 'center',
			buttons: {
		        Ok: function() {
					j$( this ).dialog( "destroy" );
		           return false;
		        }
		       
		    }
			
		});

		j$("#rampsValidationErrorPanel").dialog('open');
	}
    
    /**
     * invokes save price ramp
     */
    function invokeSavePriceRamp(lineItemId){
    	//alert(lineItemId);
    	doUpdatePriceRamp(lineItemId);
    	
    }
    
    /**
	 * invokes action function to delete line item
	 */
	 function invokeDoDeleteLineItem(){
	 	j$.APTTUS.hideRemoveConfirmation();
	 	j$.aptActionFunctionQueue.execute(sfdcDoDeleteLineItem, [j$.APTTUS.LineNumber], {disableBuffering:true, loadingLabel:j$.APTTUS.deletingLineItemLabel});
	 	
	 }
    
    function showUsageTiers() {
    	j$('.usageTiersPanel').dialog({
			width:800,
			title: 'Usage Price Tiers',
			modal: true,
			dialogClass:'usageTiersDialog',
		    open: function(event) {
			     //openDialogSetup();				
				j$('.tiersTable .tierErrorImg').each(function(){
					j$.APTTUS.tierChanges++;
				});

				j$('.tiersTable input').change(function(){

					if(j$.APTTUS.tierChanges==0) {
						j$.APTTUS.tierChanges++;
					}
					
				});
			 },
			 beforeClose: function(event) {
				//openDialogSetup();
				if(j$.APTTUS.tierChanges > 0) {
					//return confirm('Are you sure you want to close without saving?')
					showQuitTierConfirmation(this);
					return false;
				}
				destroyTiersActionMenus();
			}
		});

		j$('.usageTiersPanel').dialog('open');
		
    }
    
    //destroy existing tiers action menus
    function destroyTiersActionMenus(){
    	j$("div[id^='tiers-actions-']:visible").each(function(){
			j$(this).dialog("destroy");
			
		});
		return true;
    }
    
    //destroy existing ramp action menus
    function destroyRampActionMenus(){
    	j$("div[id^='actions-']:visible").each(function(){
			j$(this).dialog("destroy");
			
		});
		return true;
    }

    function showQuitTierConfirmation(dialog) {
		j$("#tiersQuitPanel").dialog({
			autoOpen: false,
			draggable: true,
			modal: true,
			resizable: false,
			position: 'center',
			buttons: {
		        "Yes": function() {
		        	j$.APTTUS.tierChanges = 0;
		          	j$( this ).dialog( "destroy" );
		          	j$('.usageTiersPanel').dialog("destroy");
		          	j$("div[class^='usageTiersDialog']").each(function(){
					j$(this).dialog("destroy");
					
				});
		          	return true;
		        },
		        No: function() {
		          j$( this ).dialog( "destroy" );
		          //j$(dialog).dialog('close');
		          //showRampList();
		           return false;
		        }
		       
		    }
			
		});

		j$("#tiersQuitPanel").dialog('open');
	}


    /**
     * Fixes the Dialog decimal point issues
     */
    function openDialogSetup() {
    
    	j$('div[role=dialog] button').removeClass();
		j$('div[role=dialog] button').addClass('aptListButton');
    	
    	j$(".dataTypedouble").each(function(){
			if(j$(this).val().indexOf(".") > 0){
				var qty = j$(this).val().substring(0, j$(this).val().indexOf("."));
				j$(this).val(qty);
			}
		});
		
		j$(".dataTypecurrency").each(function(){
                  var re = new RegExp(".\\d{3,}");
                  var re2 = new RegExp("\\(");
                  if(j$(this).is("input")){
                  		
			    		var matches =re.test(j$(this).val());
			    		var matches2 = re2.test(j$(this).val());
			    		//check if string matches a decimal format
			    		if (matches){
			    			j$(this).val(j$(this).val().substring(0,j$(this).val().indexOf(".")+3));
			    			//check if value is a negative value the add closing parenthesis
			    			if (matches2){
			    				j$(this).val(j$(this).val()+")");
			    			
			    			}
			   			}
                  }
                  else{
                  		j$(this).children().each(function(){
		    			var matches =re.test(j$(this).html());
		    			var matches2 = re2.test(j$(this).html());
		    			//check if string matches a decimal format
		    			if (matches){
		    				j$(this).html(j$(this).html().substring(0,j$(this).html().indexOf(".")+3));
		    				//check if value is a negative value the add closing parenthesis
		    				if (matches2){
		    					j$(this).html(j$(this).html()+")");
		    			
		    				}
		   				}
                  		
                  		
                  		})
                  	
                  	}
                    
          });
    	
    }
    
    /**
     * displays pricing guidance in the pricing guidance panel
     */
    function showPricingGuidance(jsonData, thisElem){
    	var jsonData2 = typeof jsonData === "string" ? JSON.parse(jsonData) : jsonData;
    	//get pricing guidance tabl  	
    	var guidancePanel = j$('#pricingGuidancePanel');

    	if(guidancePanel.is(':visible')) {
    		guidancePanel.hide();
    		return;

    	}
    	// clear body
    	guidancePanel.find('.pricingGuidanceTable tbody tr').remove();
    	// clear dimension info
    	guidancePanel.children('.apt-dimensions-container').remove();

		// add new dimension information
		if(jsonData2.DimensionLabels.length) { // Expecting that only one of the entries will contain dimension info
			var dimensionPanel = '<div class="apt-dimensions-container"><div style="text-align:left;font-weight:bold;padding-bottom: 10px;margin-left: 2px;">';
			dimensionPanel += j$.APTTUS.guidanceParametersLabel + ':</div>';
			dimensionPanel+= '<div class="apt-dimension-details">';

			j$.each(jsonData2.DimensionLabels, 
				function(index) {
					dimensionPanel+= '<div class="clearfix apt-dimension-info">';
					dimensionPanel+= '<div class="apt-pull-left apt-dimension-label">' + this + ':</div>';
					dimensionPanel+= '<div class="apt-pull-left apt-dimension-value">' + jsonData2.DimensionValues[index] + '</div>';						
					dimensionPanel+= '</div>';		
				}
			);
			dimensionPanel+= '</div></div>';
			guidancePanel.children('.pricingGuidanceTable').before(dimensionPanel);
		}

		// hide percentile?
		if(jsonData2.HidePercentile) {
			j$('.percentFromHeading').hide();
			j$('.percentToHeading').hide();				
		} else {
			j$('.percentFromHeading').show();
			j$('.percentToHeading').show();	
		}

		// hide price?
		if(jsonData2.HidePrice) {
			j$('.priceFromHeading').hide();
			j$('.priceToHeading').hide();	
		} else {
			j$('.priceFromHeading').show();
			j$('.priceToHeading').show();
		}

    	//construct rows in new table
		j$.each(jsonData2.Entries, function(index, item) {
			var entryRow = '<tr id="'+item.Sequence+'"';

			// border around item rating
			if(item.IsItemRating == true) {
				entryRow += 'style="border: 3px solid '+item.Rating+';"';
			}

			// add rating color and name
			entryRow += '">';
			entryRow += '<td ><div class="apt-guidance-stop-light" style="background-color:'+item.Rating+'"/><div style="text-align: left;line-height: 25px;">'+item.RangeName+'</div></td>';
			
			// //add percentile
			if(!jsonData2.HidePercentile) {
				var percentileColumns = '<td>'+item.PercentileFrom+'</td><td>'+item.PercentileTo+'</td>';
				if(item.MeasureType == 'HighLow'
				&& item.PriceFrom == 99999) {
					percentileColumns = '<td colspan="2">'+ item.PercentileTo + ' ' + j$.APTTUS.aboveLabel + '</td>';
				}

				entryRow += percentileColumns;					
			}

			// add price discount
			if(!jsonData2.HidePrice) {
				var priceColumns = '<td>'+item.PriceFrom+'</td><td>'+item.PriceTo+'</td>';
				if(item.MeasureType == 'HighLow'
				&& item.PriceFrom == 99999) {
					priceColumns = '<td colspan="2">'+ item.PriceTo + ' ' + j$.APTTUS.aboveLabel + '</td>';
				}

				entryRow += priceColumns;				
			}

			entryRow += '</tr>';
			guidancePanel.children('.pricingGuidanceTable').append(j$(entryRow));

		}); 
		
        j$('#itemsTable').on('scroll', function() {guidancePanel.hide();});
        j$(window).on('click', function(e) {
        	if(!j$(this).hasClass('apt-guidance-toggle')) {
        		e.stopPropagation();
        	} else {
        		guidancePanel.hide();
        	}
        });

		guidancePanel.show();
		guidancePanel.css('position', 'absolute');        
        guidancePanel.css('top', (j$(thisElem).offset().top + 30) + 'px');
        guidancePanel.css('right', 0);
        guidancePanel.css('left', (j$(thisElem).offset().left - 420.5) + 'px');
    }
    
    //hides the pricing guidance dialog
    function hidePricingGuidance(){
    	j$('.pricingGuidanceTable').hide();
    }

	/**
	 * first cleanup option table for current row and then create new table 
	 */
    function createOptionRow(rowId) {
    	removeOptionTable(rowId, function() {
			j$('#'+rowId+'-row').after('<tr class="optionTableRow"><td colspan="20" class="optionsTd" ><div class="optTable"></div></td></tr>');	
        	j$('.optTable').append('<center id="loadingBar" ><img src="/img/loading.gif"/></center>');
        	j$('.hideOptionButton').hide();
        	j$('.showOptionButton').show();
		});
		
    }

    function copyOptionTable() {
    	j$('#loadingBar').remove();
    	j$('.idOptionsList').appendTo('.optTable');
    	j$('.idOptionsList').slideDown(400);
    	
    }
    

    function loadingNextOptionPage() {
		    var position = j$('.aptLineItemOptionsTable').offset();
		    j$('.aptLoadingOverlay').css( { position: 'absolute', left: position.left, top: position.top });
		    j$('.aptLoadingOverlay').width(j$('.aptLineItemOptionsTable').width());
		    j$('.aptLoadingOverlay').height(j$('.aptLineItemOptionsTable').height());
		    j$('.aptLoadingOverlay').show();
    }


    function loadingNextPage(className) {
    		//console.log('invoked loadingNextPage  = '+className);
		    var position = j$('.'+className).offset();
		    j$('.aptLoadingOverlay').css( { position: 'absolute', left: position.left, top: position.top });
		    j$('.aptLoadingOverlay').width(j$('.'+className).width());
		    j$('.aptLoadingOverlay').height(j$('.'+className).height());
		    j$('.aptLoadingOverlay').show();

		    revertOptionListHTML(); // AO - CPQ-458: To allow proper rerendering of "idResultStatsPanel"
    }
	
	/**
	 * remove option table for a row
	 */
    function removeOptionTable(rowId, callback) {
		j$('.idOptionsList').slideUp(400, function(){
    	
    		revertOptionListHTML();

    		if (callback && typeof(callback) === "function") {  
    			//console.log('calling callback');
		 		callback();
		 	}

		 	j$('.showOption-'+rowId).toggle();
    		j$('.hideOption-'+rowId).toggle();
    	});
    	
    }

    /**
	 * Revert Option Table HTML to its sate when
	 * the list was rendered
	 */
    function revertOptionListHTML() {
    	j$('.idOptionsList').appendTo('#optionListContainer');
    	j$('.optionTableRow').remove();
    }

	/**
	 * Show pricing wait dialog
	 */
	j$.APTTUS.showPricingWaitPanel = function() { 	
	  	// Create and open dialog window
	  	j$.APTTUS.pricingWaitPanel = 
		 	j$("#pricingWaitPanel").dialog({
		 		dialogClass: "no-close pricingWaitPanel",
		 		autoOpen: true,	 			 		
		 		resizable: false,
		 		modal: true,
		 		position: 'center',
		 		draggable: true,
		 		height:110,
		 		create:function(){
					j$('.pricingWaitPanel .ui-dialog-titlebar').remove();
				}
		 	});
	
	  	return false;
	  	
	}
	
	/**
	 * Hide the pricing wait dialog
	 */
	j$.APTTUS.hidePricingWaitPanel = function () {
		if(typeof j$.APTTUS.pricingWaitPanel !== 'undefined') {
			j$.APTTUS.pricingWaitPanel.dialog("close");
		}
	
	}
	
	/**
	 * Show loading wait dialog
	 */
	j$.APTTUS.showLoadingWaitPanel = function() { 	
	  	// Create and open dialog window
	  	j$.APTTUS.loadingWaitPanel = 
		 	j$("#loadingWaitPanel").dialog({
		 		dialogClass: "no-close loadingWaitPanel",
		 		autoOpen: true,	 			 		
		 		resizable: false,
		 		modal: true,
		 		position: 'center',
		 		draggable: true,
		 		height:110,
		 		create:function(){
					j$('.loadingWaitPanel .ui-dialog-titlebar').remove();
				}
		 	});
	
	  	return false;
	  	
	}
	
	/**
	 * Hide the pricing wait dialog
	 */
	j$.APTTUS.hideLoadingWaitPanel = function () {
		if(typeof j$.APTTUS.loadingWaitPanel !== 'undefined') {
			j$.APTTUS.loadingWaitPanel.dialog("close");
		}
	
	}
	
    function rampTableSetup() {

		j$('.rampLevel:last .AddBtn').show();

		//j$('#'+optionId+'-Remove:first').remove();
		

		j$('.rampsTable th:first + th').addClass('no-border-left');
		j$('.rampsTable th:first').addClass('no-border-right');

		j$('.rampsTable tbody tr:last').click();

		j$('.rampsTable tbody tr').off('click').on('click', function(){
			//console.log(j$(this).closest('.aptActiveRampsRow'));
			j$('.rampsTable tbody tr').closest('.aptActiveRampsRow').find('.actionsMenu').hide();
			j$('.rampsTable tbody tr').closest('.aptActiveRampsRow').removeClass('aptActiveRampsRow');
			j$(this).addClass('aptActiveRampsRow');
			//console.log(j$(this).find('.actionsMenu'));
			j$(this).find('.actionsMenu').show();
		});
		
		if(j$.APTTUS.rampsDialog !== undefined){
      		j$('.rampItemsPanel').dialog("option", "height", "auto");
      		
      	}

		j$('.actionsMenu').off('click').on('click', function(){
			
			var className = j$(this).attr('class').split(' ')[1];
			
			destroyRampActionMenus();
			j$( '#'+className).dialog({
				autoOpen: false,
				position: { my: "left top", at: "left middle", of: this },
				resizable: false,
				dialogClass: "no-close actionsMenuDialog",
				draggable: false,
				closeOnEscape: true,
				width: 110,
				height: 125,
				show: {
					effect: "fade",
					duration: 500
				},
				hide: {
					effect: "fade",
					duration: 250
				},
				open: function(event, ui){
					
					j$('.actionsMenuDialog:visible').mouseleave(
						function(){
							j$('body').off('mouseup').on('mouseup',function (e) {
					    
							    var container = j$('.actionsMenuDialog:visible');

							    if (container.has(e.target).length === 0)
							    {

							        j$('body').off('mouseup');
							        //j$('#'+className+':visible' ).dialog('destroy');
							    }
							    
							    j$('#'+className ).dialog('destroy');
							});
					});
				},
				close: function(event, ui) {
					
					j$( '#'+className).removeAttr('style');
					j$(this).dialog('destroy');
				}

		    });

		    j$('#'+className ).dialog('open');
		});
		j$('.rampItemsPanel').css('height','auto');
		
		j$( ".rampsTable" ).change(function() {
  			j$.APTTUS.rampsModified = true;
		});
		
	}


	  function tiersTableSetup() {


		j$('.tierLevel:last .AddBtn').show();

		//j$('#'+optionId+'-Remove:first').remove();
		

		j$('.tiersTable th:first + th').addClass('no-border-left');
		j$('.tiersTable th:first').addClass('no-border-right');

		j$('.tiersTable tbody tr:last').click();

		j$('.tiersTable tbody tr').off('click').on('click', function(){
			j$('.tiersTable tbody tr').closest('.aptActiveTiersRow').find('.tiersActionsMenu').hide();
			j$('.tiersTable tbody tr').closest('.aptActiveTiersRow').removeClass('aptActiveTiersRow');
			j$(this).addClass('aptActiveTiersRow');
			j$(this).find('.tiersActionsMenu').show();
		});

		j$('.tiersActionsMenu').off('click').on('click', function(){
			
			destroyTiersActionMenus();
			var className = j$(this).attr('class').split(' ')[1];
			j$( '#'+className).dialog({
				autoOpen: false,
				position: { my: "left top", at: "left middle", of: this },
				resizable: false,
				dialogClass: "no-close actionsMenuDialog",
				draggable: false,
				closeOnEscape: true,
				width: 110,
				height: 125,
				show: {
					effect: "fade",
					duration: 500
				},
				hide: {
					effect: "fade",
					duration: 250
				},
				open: function(event, ui){
					
					j$('.actionsMenuDialog:visible').mouseleave(
						function(){
							j$('body').off('mouseup').on('mouseup',function (e) {
					    
							    var container = j$('.actionsMenuDialog:visible');
							    if (container.has(e.target).length === 0)
							    {
							        j$('body').off('mouseup');
							        //j$('#'+className+':visible' ).dialog('destroy');
							    }
							    
							    j$('#'+className+':visible' ).dialog('destroy');
							    
							});
					});
				},
				close: function(event, ui) {
					
					j$( '#'+className).removeAttr('style');
					j$(this).dialog('destroy');
				}

		    });

		    j$('#'+className ).dialog('open');
		});
	}

	function showRemoveRampRowConfirmation(rowId) {
		j$("#rampsConfirmationPanelJQuery").dialog({
			autoOpen: false,
			draggable: true,
			modal: true,
			resizable: false,
			position: 'center',
			buttons: {
		        "Yes": function() {
		        	j$(rowId).click();
		          	j$( this ).dialog( "destroy" );
		        },
		        No: function() {
		          j$( this ).dialog( "destroy" );
		        }
		    }
			
		});

		j$("#rampsConfirmationPanelJQuery").dialog('open');
	}


	function showRemoveTierRowConfirmation(rowId) {
		j$("#tiersRemoveDialog").dialog({
			autoOpen: false,
			draggable: true,
			modal: true,
			resizable: false,
			position: 'center',
			buttons: {
		        "Yes": function() {
		        	j$(rowId).click();
		          	j$( this ).dialog( "destroy" );
		        },
		        "No": function() {
		          j$( this ).dialog( "destroy" );
		        }
		    }
			
		});

		j$("#tiersRemoveDialog").dialog('open');
	}

    /**
     * Initializes the call
     */
    function initCall() {
    
        try {
            sforce.connection.sessionId = j$.APTTUS.SessionID ; //to avoid session timeout
        } catch(e) {
            cp_erroralert(cp_cERROR_UNKNOWN,e);
            
        }
    
    }
    
    /**
     * Callback when the action button is clicked
     */
    function onActionClick() {
        // show the modal panel
        j$.APTTUS.showLoadingWaitPanel();
        // return false to allow the action to proceed
        return false;
        
    }
    
    /**
     * Callback when the action is completed
     */
    function onActionComplete() {
    	if(typeof j$.APTTUS.aptShowBundlOptions == 'function'){
    		j$.APTTUS.aptShowBundlOptions();
    	}
        // hide the modal panel
        j$.APTTUS.hideLoadingWaitPanel();
        
        j$.aptActionFunctionQueue.processNext();
        
    }
    
   

   
    /**
     * Callback when the add miscellaneous item button is clicked
     */
    function onAddMiscItemClick() {
        
        // reset panel field values
        fldMiscChargeType.value = "";
        fldMiscDescription.value = "";
        fldMiscAmount.value = "";
        // show the modal panel
        j$( "#miscItemPanel" ).dialog({
        	modal:true,
        	title:j$.APTTUS.AddMiscellaneousItem,
        	maxWidth:800,
        	width:600,
        	minHeight:30,
        	dialogClass:'miscItemPanelDialog',
        	height:"auto"
        });
        
    }       
    
    /**
     * Callback when the ok action button is clicked
     */
    function onOkActionClick() {
        // hide the miscellaneous line item panel
        j$( '#miscItemPanel' ).dialog('close');
        // show modal panel
        j$.APTTUS.showLoadingWaitPanel();
        // return false to allow the action to proceed
        return false;
        
    }
    
    /**
     * Callback when the ok action is completed
     */
    function onOkActionComplete() {
        // hide the modal panel
        j$.APTTUS.hideLoadingWaitPanel();
        
    }
    
    /**
	 * Callback when the reprice callback is started
	 */
	function onRepriceCallbackStart() {
		// show the modal panel
		j$.APTTUS.showPricingWaitPanel();
		// return false to allow the action to proceed
		return false;
  	
	}
	
	/**
	 * Callback when the reprice callback is started
	 */
	function onRepriceCallbackComplete() {
		// hide the modal panel
		j$.APTTUS.hidePricingWaitPanel();
  	
	}
	
	/**
	 * Schedules the reprice all call
	 */
	function invokeDoAddProductToCart(productId) {
		// show the modal panel
		//console.log('invokeDoAddProductToCart '+productId);
		j$.APTTUS.showPricingWaitPanel();
		// delay to display progress message	
		
		
       	
           	setTimeout(function() {
           		// reprice all
         		sfdcDoAddProductToCart(productId);
          	}, 10);
      	
      	
	}
	
	
	
	/**
	 * Schedules the reprice all call
	 */
	function scheduleRepriceAllCall() {
		// show the modal panel
		j$.APTTUS.showPricingWaitPanel();
		// delay to display progress message	
       	setTimeout(function() {
       		// reprice all
     		doRepriceAll();
      	}, 10);
      	
	}
	
	/**
	 * Schedules the reprice call
	 */
	function scheduleRepriceCall() {
		// show the modal panel
		j$.APTTUS.showPricingWaitPanel();
		// current configuration id
		var configId = j$.APTTUS.configurationId;
      	// update price
	  	doUpdatePriceForCart(configId);
	  	//**********************************
		// delay to display progress message	
       	//setTimeout(function() {
       		// reprice pending line item
     		//doRepricePendingLineItems();
      	//}, 10);
      	//*******************************************
	}
    
    /**
     * Reprices all line items in the current configuration
     */
    function doRepriceAll() {
        
        // get parameters
        // current configuration id
        var configId = j$.APTTUS.configurationId;
    
        try {
            
            // STEP I - initialize the call
            initCall();
        
            // STEP II - get summary line items from the configuration
            var result = getSummaryLineItemsForConfiguration(configId);
            
            var numItems = result.length;
            
            // STEP III - Reprice each summary line item
            for (var i = 0; i < numItems; i++) {
                // compute base price
                computeBasePriceForItemColl(configId, result[i].LineNumber);
                
            }
            
            // STEP IV - Compute total price
            computeTotalPriceForCart(configId);
            
        } catch(ex) {
            // hide modal panel
            j$.APTTUS.hidePricingWaitPanel();
            // display the error
            cp_erroralert(cp_cERROR_UNKNOWN, ex);
            
        } finally {
            // reload the page
            doReload();
            
        }
        
    }
    
    /**
     * Callback when the reprice line item action button is clicked
     */
    function onRepriceLineItemClick() {
        // show the modal panel
        j$.APTTUS.showPricingWaitPanel();
        // return false to allow the action to proceed
        return false;
        
    }
    
    /**
     * Callback when the apply adjustment action button is clicked
     */
    function onApplyAdjustmentClick() {
        // show the modal panel
        j$.APTTUS.showLoadingWaitPanel();
        // return false to allow the action to proceed
        return false;
        
    }
    
    /**
     * Reprices the given line item
     */
    function doCheckAndRepriceLineItems() {
        
        // chck if price is pending
        var isPricePending = j$.APTTUS.IsPricePending;
        
        if (isPricePending.toLowerCase() == 'false') {
            // no price pending. abort
            return;
            
        }
        
        // get parameters
        // current configuration id
        var configId = j$.APTTUS.configurationId;
        
        try {
        
            // STEP I - get summary line items from the configuration
            var numItems = j$.APTTUS.NumOfLineItemsAwaitingPrice;
            
            // STEP II - Reprice the line item
            if (numItems > 0) {
                //alert(numItems);
                // show the modal panel
                j$.APTTUS.showPricingWaitPanel();
                // reprice line item
                doRepriceLineItem(configId, numItems, 0);
                
            } else {
                // show the modal panel
                j$.APTTUS.showPricingWaitPanel();
                // compute total price
                doComputeTotalPrice(configId);
            
            }

        } catch(ex) {
            // hide modal panel
            j$.APTTUS.hidePricingWaitPanel();
            // display the error
            cp_erroralert(cp_cERROR_UNKNOWN, ex);
        
        } 
        
    }
    
    /**
     * Reprices the pending line items
     */
    function doRepricePendingLineItems() {
      	
      	// get parameters
		// current configuration id
		var configId = j$.APTTUS.configurationId;
	
		try {
			
			// STEP I - initialize the call
			initCall();
		
			// STEP II - update price
			updatePriceForCart(configId);
			
		} catch(ex) {
			// hide modal panel
			j$.APTTUS.hidePricingWaitPanel();
			// display the error
			cp_erroralert(cp_cERROR_UNKNOWN, ex);
			
		} finally {
			// reload the page
			doReload();
			
		}
		
    }
    
    /**
     * Reprices the pending line items
     */
    function doRepricePendingLineItems2() {
      
        // get parameters
        // current configuration id
        var configId = j$.APTTUS.configurationId;
        
        try {
            // STEP I - get the price pending status
            // Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController
            Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doGetPricePendingInfo,configId, function(result, event) {
             
                // check response status
                if (event.status) {
                    // ok response (check the result)
                    //alert(result.numItems);
                    // STEP II - Reprice the line items
                    if (result.numItems > 0) {
                        // show the modal panel
                        j$.APTTUS.showPricingWaitPanel();
                        // reprice line item
                        doRepriceLineItem(configId, result.numItems, 0);
                    
                    } else if (result.isPricePending) {
                        // compute total price
                        doComputeTotalPrice(configId);
                        
                    } else {
                        // hide modal panel
                        j$.APTTUS.hidePricingWaitPanel();
            
                    }
                    
                } else {
                    // throw exception
                    alert(event.message);
                    // hide modal panel
                    j$.APTTUS.hidePricingWaitPanel();
                   
                } 
                
            }, {buffer:false, escape:true});
        
        } catch(ex) {
            // hide modal panel
            j$.APTTUS.hidePricingWaitPanel();
            // display the error
            cp_erroralert(cp_cERROR_UNKNOWN, ex);
        
        } 
                
    }
    
    /**
     * Reprices the given line item
     */
    function doRepriceLineItem(configId, numItems, currIndex) {
        
        try {
            
            if (currIndex < numItems) {
            
                // STEP I - initialize the call
                Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doComputeBasePriceForNextItemColl, configId, function(result, event) {
                
                    try {
                        // check response status
                        if (event.status) {
                            // ok response, increment the index
                            currIndex++;
                            // check if done
                            if (currIndex < numItems) {
                                // more to go
                                doRepriceLineItem(configId, numItems, currIndex);
                                
                            } else {
                                // compute total price
                                doComputeTotalPrice(configId);
                            
                            }
                            
                        } else {
                            //throw exception
                            alert(event.message);
                            // hide modal panel
                            j$.APTTUS.hidePricingWaitPanel();
                            // reload the page
                            //doReload();
                        
                        }
                        
                    } catch(ex) {
                        // hide modal panel
                        j$.APTTUS.hidePricingWaitPanel();
                        // display the error
                        cp_erroralert(cp_cERROR_UNKNOWN, ex);
                        // reload the page
                        //doReload();
                          
                    } 
                    
                }, {buffer:false, escape:true});
              
             }
              
        } catch(ex) {
             // hide modal panel
            j$.APTTUS.hidePricingWaitPanel();
            // display the error
            cp_erroralert(cp_cERROR_UNKNOWN, ex);
            
        } 
        
    }
    
    /**
     * Reprices the given line item
     */
    function doRepriceLineItemColl(configId, lineNumber) {

        // STEP I - compute base price
        Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doComputeBasePriceForItemColl, configId, lineNumber, function(result, event) {
        
            try {
                 // check response status
                 if (event.status) {
                     // ok reponse, compute total price
                     doComputeTotalPrice(configId);
                     
                 } else {
                     //throw exception
                     alert(event.message);
                     
                 } 
                 
             } catch(ex) {
                // hide all modal panels
                j$.APTTUS.hidePricingWaitPanel();
                j$.APTTUS.hideLoadingWaitPanel();
                // display the error
                cp_erroralert(cp_cERROR_UNKNOWN, ex);
                // reload the page
                doReload();
                    
             } 
            
        }, {buffer:false, escape:true});
               
    }
    
    /**
     * Callback to update the total price
     */
    function doUpdateTotalPrice() {
        // get parameters
        // current configuration id
        var configId = j$.APTTUS.configurationId;
        // compute total price
        doComputeTotalPrice(configId);
        
    }
    
    /**
     * Callback to update the cart price
     */
    function doInvokeUpdatePriceForCart() {
        // get parameters
        // current configuration id
        var configId = j$.APTTUS.configurationId;
        // update price
        doUpdatePriceForCart(configId);
        
    }
    
    /**
	 * Updates the price for items in the given product configuration
	 * Only line items in pending status are updated.
 	 * Total price is always computed
	 * @param configId the product configuration id to update the price for
	 */
	function doUpdatePriceForCart(configId) {
		//console.log('doUpdatePriceForCart configId = ' + configId);
	    try {
	          
            Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doUpdatePriceForCart, configId, function(result, event) {
        	    try {
                    // check response status
                    if (event.status) {
                        // ok response, check if done
            			//if (result.IsPricePending.toLowerCase() == 'true') {
            			if (result.IsPricePending == true) {
                            // more to go
                            doUpdatePriceForCart(configId);
                            
                        } else {
                        	j$.APTTUS.pricingInProgress = false;
                            // reload the page
							doReload();
                        
                        }
                        
                    } else {
                        // throw exception
                        alert(event.message);
                        // reload the page
						doReload();
                    
                    }
                    j$.APTTUS.wrapSpan();
                    
                } catch(ex) {
                    // display the error
                    cp_erroralert(cp_cERROR_UNKNOWN, ex);
                    // reload the page
					doReload();
                      
                } 
                
            }, {buffer:false, escape:true, timeout:120000 });
	           
	    } catch(ex) {
	        // display the error
	        cp_erroralert(cp_cERROR_UNKNOWN, ex);
	        // reload the page
			doReload();
				            
	    } 
	    
	}
	
    /**
     * Computes the total price for the cart
     */
    function doComputeTotalPrice(configId) {
        
        // register to invoke the function after the page load
        var useMultiStepTotaling = "{!UseMultiStepTotaling}";
    
        try {
        
            // check if multi-step totaling should be used
            if (useMultiStepTotaling.toLowerCase() == 'true') {
                // use multi-step totaling
                doExecuteTotalPriceStepForCart(configId, cp_cTOTALING_STEP1);
        
            } else {
                // use single step totaling
                doExecuteTotalPriceStepForCart(configId, cp_cTOTALING_ALLSTEPS);
            
            }
          
        } catch(ex) {
            // hide all modal panels
            j$.APTTUS.hidePricingWaitPanel();
            j$.APTTUS.hideLoadingWaitPanel();
            // display the error
            cp_erroralert(cp_cERROR_UNKNOWN, ex);
            // reload the page
            doReload();

        } 
      
    }

    /**
     * Executes the totaling step for the cart
     */
    function doExecuteTotalPriceStepForCart(configId, stepName) {

        // STEP I - initialize the call
        Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doExecuteTotalPriceStepForCart, configId, stepName, function(result, event) {
         
            try {
                // check response status
                if (event.status) {
                    // ok response , check if done
                    if (cp_cTOTALING_STEP3 == stepName || 
                        cp_cTOTALING_ALLSTEPS == stepName) {
                        // we are done, reload the page
                        doReload();
                        
                    } else {
                        // get the next step
                        var nextStepName = ((cp_cTOTALING_STEP1 == stepName) ? cp_cTOTALING_STEP2 : cp_cTOTALING_STEP3);
                        // execute the next step
                        doExecuteTotalPriceStepForCart(configId, nextStepName);
                    
                    }
                } else {
                    // throw exception
                    alert(event.message);
                    // hide all modal panels
                    j$.APTTUS.hidePricingWaitPanel();
                    j$.APTTUS.hideLoadingWaitPanel();
                    // reload the page
                    doReload();
                    
                } 
            } catch(ex) {
                // hide all modal panels
                j$.APTTUS.hidePricingWaitPanel();
                j$.APTTUS.hideLoadingWaitPanel();
                // display the error
                cp_erroralert(cp_cERROR_UNKNOWN, ex);
                // reload the page
                doReload();
                   
            } 
            
        }, {buffer:false, escape:true});
               
    }

    /**
     * Clones the given line item
     */
    function doCopyLineItem(lineNumber) {
        
        try {
            
            // current configuration id
            var configId = j$.APTTUS.configurationId;
            // show the modal panel
            j$.APTTUS.showLoadingWaitPanel();
                
            // STEP I - initialize the call
            Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.doClonePrimaryItemColl, configId, lineNumber, function(result, event) {
            
                try {
                    // check response status
                    if (event.status) {
                        // ok response, compute total price
                        doRepriceLineItemColl(configId, event.result);
                        
                    } else {
                        // throw exception
                        alert(event.message);
                        // hide modal panel
                        j$.APTTUS.hideLoadingWaitPanel();
                        // reload the page
                        //doReload();
                    
                    }
                    
                } catch(ex) {
                    // hide modal panel
                    j$.APTTUS.hideLoadingWaitPanel();
                    // display the error
                    cp_erroralert(cp_cERROR_UNKNOWN, ex);
                    // reload the page
                    //doReload();
                      
                } 
                
            }, {buffer:false, escape:true});
              
        } catch(ex) {
             // hide modal panel
            j$.APTTUS.hideLoadingWaitPanel();
            // display the error
            cp_erroralert(cp_cERROR_UNKNOWN, ex);
            
        } 
        
    }
    
    /**
     * Get mouseover product information
     */
    function getProductDetail(productId) {
	    document.getElementById('ctxProductDescription').innerHTML = '';        
		Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.getProductDescription, productId, function(result, event){
			    if (event.status) {
			    	j$('.productDetailPanel .ui-dialog-title').html(result.Name);
			        if(result.Description != undefined){
			        	document.getElementById('ctxProductDescription').innerHTML = result.Description;
					} else {
						document.getElementById('ctxProductDescription').innerHTML = '';
					}
				} else {
			    	document.getElementById('ctxProductDescription').innerHTML = event.message;
				}
	       	}, {buffer:false, escape:true});
		
		showProductDetailPanel();
        
    }
    
    /**
     * Get info icon click line item information
     */
    function getLineItemDetail(lineItemId, nsPrefix) {
	    document.getElementById('ctxProductDescription').innerHTML = '';      
		Visualforce.remoting.Manager.invokeAction(j$.APTTUS.RemoteController.getLineItemDetail, lineItemId, function(result, event){
			    if (event.status) {
			    	j$('.productDetailPanel .ui-dialog-title').html(result[nsPrefix + 'ChargeType__c']);
			        if(result[nsPrefix + 'Description__c'] != undefined){
			        	document.getElementById('ctxProductDescription').innerHTML = result[nsPrefix + 'Description__c'];
					} else {
						document.getElementById('ctxProductDescription').innerHTML = j$.APTTUS.NoDescriptionProvidedLabel;
					}
				} else {
			    	document.getElementById('ctxProductDescription').innerHTML = event.message;
				}
	       	}, {buffer:false, escape:true});
		showProductDetailPanel();	       	
        
    }             

    /**
     * Callback when mouseover product information icon
     */
    function showProductDetailPanel() {
    	j$( "#productDetailPanel" ).dialog({
        	modal:true,
        	title:j$.APTTUS.LoadingPageLabel,
        	maxWidth:1000,
        	minWidth:500,
        	minHeight:110,
        	dialogClass:'productDetailPanel',
        	height:"auto",
        	open : function(){
	 			j$('.productDetailPanel .ui-widget-header').css({border:"none",background:"none",borderBottom:"1px solid #aaaaaa"});
	 			j$('.productDetailPanel .ui-widget-header').removeClass("ui-corner-all");
	 			
	 		}
        });
        
    }   
    
    /**
     * Show submit approval dialog
     */
    function showSubmitApprovalDialog() {
        
        // show the submit approval dialog
        j$.APTTUS.submitApprovalPanel = j$( "#submitApprovalPanel" ).dialog({
        	modal:true,
        	title:j$.APTTUS.ApprovalReasonInstruction,
        	maxWidth:800,
        	width:400,
        	minHeight:30,
        	dialogClass:'submitApprovalPanel',
        	height:"auto"
        });
        return false;
        
    }
    
    /**
     * Hide the submit approval dialog
     */
    function hideSubmitApprovalDialog(){
        // close the submit approval dialog
        if(typeof j$.APTTUS.submitApprovalPanel !== 'undefined') {
			j$.APTTUS.submitApprovalPanel.dialog("close");
		}
      
    }

    
    //hide message and call doHideMessage function to update the appliedActionInfo record HideMessage field
    function aptHideMessage(ele, actionInfoId){
        if(ele.parentNode != undefined){
            ele.parentNode.style.visibility = "hidden";
        }
        invokeDoHideMessage(actionInfoId);
    }