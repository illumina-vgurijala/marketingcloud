(function () {

    var appImpl = SVMX.Package("com.servicemax.client.opt.ui.desktop.api.purge");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("OPT");
        
        //model data for job grid table 
        Ext.create('Ext.data.Store', {
            storeId:'jobsStorePurge',
            fields:['jobId', 'processName', 'startDate', 'endDate'],
            data:{},
            proxy: {
                type: 'memory',
                reader: {
                    type: 'json',
                    root: 'items'
                }
            }
        });
        
        //Dropdown for Dispatch Process Name
        Ext.create('Ext.data.ArrayStore',{
        	storeId: "dispatchProcessNamePurge", 
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
        
        
        Ext.define('com.servicemax.client.opt.ui.purge.purge', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.svmx.purge',
            layout: 'column',
            title: TS.T("TAG096","Purge"),
            __runOpts: null,
            
            constructor: function(config) {
                var delEng = config.engine;
                config = Ext.apply({
            items: [{
            	margin: '10 20 0 10',
                xtype: 'fieldset',
                columnWidth: 1,
                border : false,
                layout: {
            	    type: 'vbox'
            	    ,align: 'center' // or 'right'
            	},
                items: [{
                	xtype: 'button',
                	text : TS.T("TAG091","Purge Latest Run"),
                	cls:'spm-opt-button',
                	id:'opt-purge-latest-run-btn',
                	deliveryEngine : delEng,
                	handler: function(){
                		var parentContex = this;
                		Ext.MessageBox.confirm({
                        	title:TS.T("101", "Confirm"),
                			msg : TS.T("102", 'Are you sure ?' ),
                			buttons: Ext.MessageBox.YESNO,
                            buttonText:{
                                yes: TS.T("103", 'Yes' ), 
                                no: TS.T("104", 'No' ) 
                            },
                        	icon : Ext.MessageBox.QUESTION,
                        	fn :function(btn, text){
                        		if (btn == 'yes'){
                        			parentContex.deliveryEngine.purgeLatestRunHandler();
                        			Ext.getCmp('opt-purge-latest-run-btn').disable();
                                }
                        	}
                        });
                		
                		
                		
                	}
                	
                }]
            },
            {
            	margin: '10 0 8 0',
                xtype: 'fieldset',
                columnWidth: 1,
                border : false,
                layout: {
            	    type: 'vbox'
            	    ,align: 'center' // or 'right'
            	},
                items: [{
                	xtype: 'label',
                    text: '-' + TS.T("TAG082","Or") + '-'
                }]
            },
            {
                margin: '0 0 20 10',
                columnWidth: 1,
                xtype: 'fieldset',
                title:TS.T("TAG092","Purge by Timeframe"),
                layout: 'anchor',
                minHeight: 551,
                height: '100%',
                defaultType: 'textfield',
                items: [ 
                      
					{
						margin: '10 0 20 0',
					    padding: '10 10 10 10',
					    width: 812,
					    xtype: 'fieldset',
					    title: TS.T("TAG084","Select Filters"),
					    items: [{
								layout: 'column',
								border : false,
						        items: [
								{
									xtype: 'datefield',
									columnWidth: .5,
							        anchor: '100%',
							        fieldLabel: TS.T("TAG089","Start Date"),
							        cls:'spm-opt-config-start-date',
							        margin: '0 30 0 0',
							        name: 'from_date',
							        format: 'Y-m-d',
							        maxValue: new Date(),
							        id: 'purge_from_date',
							        value: new Date()
							        
								},
								{
									xtype: 'datefield',
								 	columnWidth: .5,
							        anchor: '100%',
							        fieldLabel: TS.T("TAG090","End Date"),
							        cls:'spm-opt-config-end-date',
							        margin: '0 30 0 0',
							        id: 'purge_to_date',
							        format: 'Y-m-d',
							        name: 'to_date',
							        value: new Date()
								}
								]
						    },
						    {	
						        layout: 'column',
								border : false,
							    items: [
									{   
										margin: '30 30 20 0',
							        	columnWidth: 1,
								    	xtype: 'combobox',
								        fieldLabel: TS.T("TAG085","Dispatch Process Name"), 
								        displayField: 'label', valueField: 'name',
								        cls:'spm-opt-dispatch-process',
								        id: 'dispatch-process-name-purge',
								        labelWidth:150,
								        editable: false,
								        deliveryEngine : delEng,
								        name: 'label', labelField:'label', 
					                    valueField:'name', displayField: 'label',  
					                    queryMode: 'local',
					                    store: Ext.data.StoreManager.lookup('dispatchProcessNamePurge')
								        
									}
								]
						    },
						{
					    	
					        xtype: 'fieldset',
					        columnWidth: 1,
					        border : false,
					        margin: '0 20 0 0',
					        layout: {
					    	    type: 'vbox'
					    	    ,align: 'right' // or 'right'
					    	},
					        items: [{
					        	xtype: 'svmx.button',
					        	text : TS.T("TAG086","Find Runs"),
					        	cls:'spm-opt-button',
					        	id:'opt-find-run-purge',
					        	deliveryEngine : delEng,
					        	handler: function(){
				                  var purge_from_date =  Ext.getCmp('purge_from_date').getSubmitValue();
				                  var purge_to_date =  Ext.getCmp('purge_to_date').getSubmitValue();
				                  if(Ext.getCmp('dispatch-process-name-purge').displayTplData[0] != undefined){
				                  var dispatchProcessName = Ext.getCmp('dispatch-process-name-purge').displayTplData[0].label;
				                  }
				                  param = {
				                          "startDate": purge_from_date,
				                          "endDate": purge_to_date,
				                          "processName": dispatchProcessName,
				                          "isPurge":"true"
				                      };
				                  if ((Date.parse(purge_from_date) > Date.parse(purge_to_date))) {
				                	  Ext.MessageBox.alert('Status', TS.T("TAG097","Start Date should be earlier that End Date"));
	        							return false;		
	    						  }else if (purge_from_date == "" ) {
				                	  Ext.MessageBox.alert('Status', TS.T("TAG098","Select Start Date"));
	        							return false;		
	    						  }else if (purge_to_date == "") {
				                	  Ext.MessageBox.alert('Status', TS.T("TAG099","Select End date"));
	        							return false;		
	    						  }
				                  this.deliveryEngine.getJobListForPurgeHandler(param);
				                  Ext.getCmp('opt-find-run-purge').disable();
				                 	
				                }
					        }]
					    }
						
					]
					}
					,
					
					purgeTable = Ext.create('Ext.grid.Panel', {
					    title: TS.T("TAG096","All Runs"),
					    selType:'checkboxmodel',
					    minHeight: 250,
					    height: 250,
					    width: 812,
					    selModel: {
					        checkOnly: false,
					        mode: "MULTI",
					        columnSelect: true,
					        checkboxSelect: true,
					        pruneRemoved: false
					    },
					    
					    //multiSelect: false,
					    id: 'getpurgedatagrid',
					    xtype:'checkboxgroup',
					    store: Ext.data.StoreManager.lookup('jobsStorePurge'),
					    columns: [
					        { text: TS.T("TAG087","Job Id"),  dataIndex: 'jobId', width:110, sortable: false, menuDisabled:true },
					        { text: TS.T("TAG088","Dispatch Process Name"), dataIndex: 'processName', width:300, sortable: false, menuDisabled:true },
					        { text: TS.T("TAG089","Start Date"), dataIndex: 'startDate', width:200, sortable: false, menuDisabled:true},
					        { text: TS.T("TAG090","End Date"), dataIndex: 'endDate', width:200, sortable: false, menuDisabled:true}
					    ]
					    
					}),
					purgeTable.on('viewready', function(){
						purgeTable.getSelectionModel().selectAll();	
					}),
					
					{
		            	margin: '10 20 0 10',
		                xtype: 'fieldset',
		                columnWidth: 1,
		                border : false,
		                
		                layout: {
		            	    type: 'vbox'
		            	    ,align: 'right' // or 'right'
		            	},
		                items: [{
		                	xtype: 'button',
		                	text : TS.T("TAG093","Purge Selected Runs"),
		                	cls:'spm-opt-button',
		                	id: 'purge-selected-run-btn',
		                	deliveryEngine : delEng,
		                	handler : function(){
		                		   var grid = Ext.getCmp('getpurgedatagrid');
				        	       var selection= grid.getSelectionModel();
				        	       var jobIdList = [];
				        	       for(i=0;i < grid.store.getCount();i++){
				        	          if(selection.isSelected(i)){
				        	        	  jobIdList.push(grid.store.getAt(i).data.jobId);
				        	          }
				        	       }
				        	var jobsIdList = jobIdList.toString() ;       
				        	param = {
					                  "jobsId": jobsIdList
					                 };
				        	if (jobIdList.length <= 0) {
			                	Ext.MessageBox.alert('Status', TS.T("TAG100","Select one or more job(s)"));
       							return false;		
   						  	}
				        	var parentContex = this;
				        	Ext.MessageBox.confirm({
                            	title:TS.T("101", "Confirm"),
                    			msg : TS.T("102", 'Are you sure ?' ),
                    			buttons: Ext.MessageBox.YESNO,
                                buttonText:{
                                    yes: TS.T("103", 'Yes' ), 
                                    no: TS.T("104", 'No' ) 
                                },
                            	icon : Ext.MessageBox.QUESTION,
                            	fn :function(btn, text){
                            		if (btn == 'yes'){
                            			parentContex.deliveryEngine.purgeSelectedRunsHandler(param);
                            			Ext.getCmp('purge-selected-run-btn').disable();
                                    }
                            	}
                            });
				        	
		                	}
		                }]
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