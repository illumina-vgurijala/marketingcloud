(function () {

    var appImpl = SVMX.Package("com.servicemax.client.opt.ui.desktop.api.execution");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("OPT");
        
        //model data for job grid table 
        Ext.create('Ext.data.Store', {
            storeId:'jobsStoreExecution',
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
      //Dropdown for filter list
        Ext.create('Ext.data.ArrayStore',{
      	  	storeId: "dispatchProcessName", 
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
        
        
        Ext.define('com.servicemax.client.opt.ui.execution.execution', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.svmx.execution',
            layout: 'column',
            title:  TS.T("TAG080","Execution"),
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
                	text : TS.T("TAG095","Report Latest Run"),
                	cls:'spm-opt-button',
                	id: 'opt-report-latest-run-btn',
                	deliveryEngine : delEng,
                	handler: function(){
                		this.deliveryEngine.processLatestRunHandler();
                		Ext.getCmp('opt-report-latest-run-btn').disable();
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
                title:TS.T("TAG083","Report by Timeframe"),
                layout: 'anchor',
                minHeight: 551,
                defaultType: 'textfield',
                items: [
                      
					{
					    margin: '10 0 20 0',
					    width : 812,
					    padding: '10 10 10 10',
					    xtype: 'fieldset',
					    title:TS.T("TAG084","Select Filters"),
					    items: [
					    	{	
					    		layout: 'column',
								border : false,
						        items: [
								{
									columnWidth: .5,
									xtype: 'datefield',
							        anchor: '100%',
							        fieldLabel: TS.T("TAG089","Start Date"),
							        cls:'spm-opt-config-start-date',
							        margin: '0 30 0 0',
							        name: 'from_date',
							        format: 'Y-m-d',
							        maxValue: new Date(),
							        id: 'execution_from_date',
							        value: new Date()
							        
								},
								{
									columnWidth: .5,
									xtype: 'datefield',
							        anchor: '100%',
							        fieldLabel: TS.T("TAG090","End Date"),
							        cls:'spm-opt-config-end-date',
							        margin: '0 30 0 0',
							        id: 'execution_to_date',
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
									        labelWidth:150,
									        id: 'dispatch-process-name-execution',
									        deliveryEngine : delEng,
									        name: 'label', labelField:'label', 
						                    valueField:'name', displayField: 'label',  
						                    queryMode: 'local',
						                    editable: false,
									        getLoader: function(){
									        	this.deliveryEngine.loadDispatchProcessNamesHandler();   
									        },
									        store: Ext.data.StoreManager.lookup('dispatchProcessName')
									         //store: objstorelist
								        }
								       ]
						    }
						,{
					    	
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
					        	id: 'opt-find-run-btn',
					        	cls:'spm-opt-button',
					        	deliveryEngine : delEng,
					        	handler: function(){
				                  var execution_from_date =  Ext.getCmp('execution_from_date').getSubmitValue();
				                  var execution_to_date =  Ext.getCmp('execution_to_date').getSubmitValue();
				                  if(Ext.getCmp('dispatch-process-name-execution').displayTplData != undefined || Ext.getCmp('dispatch-process-name-execution').displayTplData != null){
				                  var dispatchProcessName = Ext.getCmp('dispatch-process-name-execution').displayTplData[0].label;
				                  }
				                  param = {
				                          "startDate": execution_from_date,
				                          "endDate": execution_to_date,
				                          "processName": dispatchProcessName,
				                          "isPurge":"fasle"
				                      };
				                  if ((Date.parse(execution_from_date) > Date.parse(execution_to_date))) {
				                	  Ext.MessageBox.alert('Status', TS.T("TAG097","Start Date should be earlier that End Date"));
	        							return false;		
	    						  }else if (execution_from_date == "" ) {
				                	  Ext.MessageBox.alert('Status', TS.T("TAG098","Select Start Date"));
	        							return false;		
	    						  }else if (execution_to_date == "") {
				                	  Ext.MessageBox.alert('Status', TS.T("TAG099","Select End Date"));
	        							return false;		
	    						  }
				                  this.deliveryEngine.getJobListForExecutionHandler(param);
				                  Ext.getCmp('opt-find-run-btn').disable();
				                }
					        }]
					    }
					]
					}
					,
					
					executionTable = Ext.create('Ext.grid.Panel', {
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
					    id: 'getexecutiondatagrid',
					    xtype:'checkboxgroup',
					    store: Ext.data.StoreManager.lookup('jobsStoreExecution'),
					    columns: [
					        { text: TS.T("TAG087","Job Id"),  dataIndex: 'jobId', width:110, sortable: false, menuDisabled:true },
					        { text: TS.T("TAG088","Dispatch Process Name"), dataIndex: 'processName', width:300, sortable: false, menuDisabled:true },
					        { text: TS.T("TAG089","Start Date"), dataIndex: 'startDate', width:200, sortable: false, menuDisabled:true},
					        { text: TS.T("TAG090","End Date"), dataIndex: 'endDate', width:200, sortable: false, menuDisabled:true}
					    ]
					}),
					executionTable.on('viewready', function(){
						executionTable.getSelectionModel().selectAll();	
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
		                	text : TS.T("TAG081","Report Selected Runs"),
		                	id: 'execution-selected-run-btn',
		                	cls:'spm-opt-button',
		                	deliveryEngine : delEng,
		                	handler : function(){
		                		   var grid = Ext.getCmp('getexecutiondatagrid');
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
				        	this.deliveryEngine.executionSelectedRunsHandler(param);
				        	Ext.getCmp('execution-selected-run-btn').disable();
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