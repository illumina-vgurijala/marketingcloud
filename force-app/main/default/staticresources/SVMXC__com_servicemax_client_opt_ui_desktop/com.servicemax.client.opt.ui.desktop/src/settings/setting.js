(function () {

    var appImpl = SVMX.Package("com.servicemax.client.opt.ui.desktop.api.setting");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("OPT");
       
        
      //Dropdown activity for productive hour
       var myStore = Ext.create('Ext.data.ArrayStore',{
        	storeId: "productiveHoursComputation", 
            fields: ['name','label'],
            autoLoad: true,
            data: {},
        	proxy: {
                type: 'memory',
                reader: {
                    type: 'json',
                    root: 'items'
                }
            }
        });
      
       
      //Dropdown activity for available hour
        Ext.create('Ext.data.ArrayStore',{
        	storeId: "availableHoursComputation",
            fields: ['name','label'],
            data: {},
        	proxy: {
                type: 'memory',
                reader: {
                    type: 'json',
                    root: 'items'
                }
            }
        });
       
        
        function findDiffInArr(arr1, arr2) {
		      differenceInArr = [];
		      coupledArr = arr1.concat(arr2);
		      for( i = 0; i <= coupledArr.length; i++ ) {
		        current = coupledArr[i];
		        if( coupledArr.indexOf(current) == coupledArr.lastIndexOf(current) ) {
		        	if(current !== undefined){
		        		differenceInArr.push(current);	
		        	}
		        }
		      }
		      return differenceInArr;
		}
		
		function checkObjAvailabilityInArr(arr, obj) {
		    var i = arr.length;
		    while (i--) {
		       if (arr[i] === obj) {
		           return true;
		       }
		    }
		    return false;
		}
        
        
        Ext.define('com.servicemax.client.opt.ui.settings.setting', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.svmx.setting',
            layout: 'column',
            id: 'opt-right-container',
            title: TS.T("TAG073","Settings"),
            __runOpts: null,
            constructor: function(config) {
            var delEng = config.engine;
            config = Ext.apply({
            items: [{
                margin: '0 0 0 10',
                columnWidth: .5,
                xtype: 'fieldset',
                title:TS.T("TAG074","Productive Hours Computation"),
                layout: 'anchor',
                defaultType: 'textfield',
                items: [{
                	xtype: 'combobox',
                	margin: '-8 0 1 0',
                	editable: false,
                	columnWidth: 1,
                	width:350,
                	padding: 10,
                	id: 'productive-hours-computation',
                    fieldLabel: TS.T("TAG078","Select one or more type(s) of activity for Productive Hour Computation"), 
                    labelAlign: 'top',
                    multiSelect: true,
			        name: 'label', labelField:'label', 
                    valueField:'name', displayField: 'label',  
                    queryMode: 'local',
                    deliveryEngine : delEng,
			        store: Ext.data.StoreManager.lookup('productiveHoursComputation'),
			        valueField: 'label',
			        listeners: {
			        	change: function(combo, eOpts, index){
			        		var availableHourCmp = Ext.getCmp('available-hours-computation');
			        		var availableHourValues = availableHourCmp.getValue();
			        		var currentClicked = findDiffInArr(eOpts, index);
			        		if(index !== undefined) {
			        			//checking click status select or de-select from drop-down 
				        			if(currentClicked != "Drive Time"){
				        			    //check if any of drop-down values not selected in available hour.
					        			if(availableHourValues.length != 0){
						        			var productiveHourValues = eOpts;
						        			copyOfproductiveHourValues = productiveHourValues.slice(0);
						        			
						        			/* merge productive hour drop-down values in available hour array.
						        			 * and Removing duplicate values from an array.
						        			 */
						        		  
						        			//removing "Drive Time" from Productive hour computation array
						        			for (var i =0; i < copyOfproductiveHourValues.length; i++){
					        					if (copyOfproductiveHourValues[i] === "Drive Time") {
					        						copyOfproductiveHourValues.splice(i,1);
					        					      break;
					        					   }
					        				}
						        		
							        		var unionOfAvailableAndProductive = availableHourValues.concat(copyOfproductiveHourValues);
							        		var availableHourWithProductiveSelection = unionOfAvailableAndProductive.filter(function (item, pos) {return unionOfAvailableAndProductive.indexOf(item) == pos});
							        		availableHourCmp.setValue(availableHourWithProductiveSelection);
						        		} else {
						        			for (var i =0; i < eOpts.length; i++){
					        					if (eOpts[i] === "Drive Time") {
					        						eOpts.splice(i,1);
					        					      break;
					        					   }
					        				}
						        			availableHourCmp.setValue(eOpts);
						        		}
				        			}
				        		
				        	} else {
				        		if(currentClicked != "Drive Time"){
					        		if(availableHourValues.length != 0){
					        			var productiveHourValues = eOpts;
						        		var unionOfAvailableAndProductive = availableHourValues.concat(productiveHourValues);
						        		var availableHourWithProductiveSelection = unionOfAvailableAndProductive.filter(function (item, pos) {return unionOfAvailableAndProductive.indexOf(item) == pos});
						        		availableHourCmp.setValue(availableHourWithProductiveSelection);
					        		} else {
					        			availableHourCmp.setValue(eOpts);
					        		}
				        		}
				        	  }
			        	 
			        	}
			        }
                }]
            },
            {
                fieldDefaults: {
                    labelAlign: 'left',
                    labelWidth: 90,
                    anchor: '100%',
                    msgTarget: 'side'
                },
                    margin: '0 10 0 10',
                    xtype: 'fieldset',
                    columnWidth: .5,
                    title:TS.T("TAG075","Available Hours Computation"),
                    layout: 'anchor',
                    defaultType: 'textfield',
                    items: [{
                    	xtype: 'combobox',
                    	editable: false,
                    	columnWidth: 1,
                    	width:350,
                    	padding: 10,
                    	margin: '-8 0 1 0',
                    	id: 'available-hours-computation',
                    	cls:'spm-opt-config-date',
                        fieldLabel: TS.T("TAG079","Select one or more type(s) of activity for Available Hour Computation"), 
                        labelAlign: 'top',
                        multiSelect: true,
    			        name: 'label', labelField:'label', 
                        valueField:'name', displayField: 'label',  
                        queryMode: 'local',
                        deliveryEngine : delEng,
    			        store: Ext.data.StoreManager.lookup('availableHoursComputation'),
    			        valueField: 'label',
    			        listeners: {
    			        	change: function(combo, eOpts, index){
    			        		var productiveHourCmp = Ext.getCmp('productive-hours-computation');
    			        		var availableHourCmp = Ext.getCmp('available-hours-computation');
    			        		var availableHourValues = availableHourCmp.getValue();
    			        		var productiveHourValues = productiveHourCmp.getValue();
    			        		
    			        	 var availableHourValues = eOpts;	
    			        	 if(index !== undefined) {
    			        		 //current clicked items from drop-down
    			        		 var currentClicked = findDiffInArr(eOpts, index);
    			        		 var checkStatusInAvailable = checkObjAvailabilityInArr(index, currentClicked[0]);
    			        		 if(checkStatusInAvailable){
    			        			     //check if current clicked item is already selected in productive hour then again set it in available hour
    			        				 var checkStatusInProductive = checkObjAvailabilityInArr(productiveHourValues, currentClicked[0]);
        			        			 if(checkStatusInProductive){
        			        				 availableHourValues.push(currentClicked[0]);
        						        	 var availableHourData = availableHourValues.filter(function (item, pos) {return availableHourValues.indexOf(item) == pos});
        						        	 availableHourCmp.setValue(availableHourValues);
        			        				 
        			        			 }
    			        		 }
    			        		 
    			        	 }
    			        	  
    			        	}
    			        }
                    }]
                },
                {
                    margin: '30 11 0 10',
                    padding: '20 0 20 20',
                    xtype: 'fieldset',
                    columnWidth: 1,
                    layout: 'anchor',
                    items: [
						{	
					    xtype: 'component',
					    cls: 'text-strong',
					    html: TS.T("TAG022","Send success notifications to this email address:"),
					    margin: '0 0 10 0',
					    anchor: '90%'
					    },
						{
					        xtype: 'textfield',
					        id: 'notification-email-opt',
					        name: 'email',
					        anchor: '60%',
					        vtype: 'email',
					        msgTarget: 'start',
					        allowBlank: false
					    }
                    ]
                },
                
                {  
                	margin: '30 0 0 10',
                    xtype: 'fieldset',
                    columnWidth: 1,
                    layout: 'anchor',
                    border : false,
                    align: 'right',
                    layout: {
                	    type: 'vbox'
                	    ,align: 'right'
                	},
                    items: [
                            { xtype: 'tbfill' }, 
                            {
		                    	xtype: 'svmx.button',
		                    	text : TS.T("TAG094","Save"),
		                    	cls:'spm-opt-button',
		                    	id:'opt-save-configuration-btn',
		                    	deliveryEngine : delEng,
		                    	handler: function(){
		                    	var selectedFromAvailable = [];
		                    	var availableHours = Ext.getCmp('available-hours-computation').displayTplData ;
		                    	for(var i=0; i<availableHours.length; i++){
		                    		selectedFromAvailable.push(availableHours[i].label);
		                        }
		                    	
		                    	var selectedFromProductive = [];
		                    	var productiveHours = Ext.getCmp('productive-hours-computation').displayTplData ;
		                    	for(var i=0; i<productiveHours.length; i++){
		                    		selectedFromProductive.push(productiveHours[i].label);
		                        }
		                    	var email = Ext.getCmp('notification-email-opt').getValue() ;
		                    	// creating Json for save configuration 
		                    	configurationParam = {
		   		                    	 "settings": {
		   		                    	   "emailId": email,
		   		                    	   "availableHours": selectedFromAvailable.toString(),
		   		                    	   "productiveHours": selectedFromProductive.toString()
		   		                    	 }
		                    	}
		                    	this.deliveryEngine.saveOptConfigurationHandler(configurationParam);
		                    	Ext.getCmp('opt-save-configuration-btn').disable()
		                    	}
                            }
                           ]
                }
            ]
            }, config || {});
            this.callParent([config])
            }

        });
        
        
        
        
        
    }
})();