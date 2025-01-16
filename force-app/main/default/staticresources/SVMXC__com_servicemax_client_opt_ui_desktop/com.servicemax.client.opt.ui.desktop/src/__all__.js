// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.opt.ui.desktop\src\api.js

(function(){

    var appImpl = SVMX.Package("com.servicemax.client.opt.ui.desktop.api");

    appImpl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("OPT");
        
        Ext.define("com.servicemax.client.opt.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            cls: 'apft-root-container opt-root-container',
            layout: 'fit',
            width: "100%",
            height: 720,
            __parent: this,
            __resultsViewPanel: null,
            __runOpts: null,
            constructor: function(config) {
            	var eng = config.deliveryEngine;
                config = Ext.apply({
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            padding: '0',
                            text : TS.T("TAG029", "Back To Setup Home"),           
                            handler: function(e, el, owner, tool) {
                                var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                                window.location.href = urlString;
                            }
                        }]
                    },
                    
                    items : [{
                    	margin: '20 0 0 0',
                        layout:'column',
                        columnWidth: .25,
                        cls: 'opt-container-box',
    					items: [{
    					    items: [{
    		                    xtype: "svmx.tabpanel", anchor:'100% 100%', border: false,
    							cls:'opt-tabs-left',
    		                    tabPosition: "left", itemId: 'opt-general-tab-items-container',
    		                    defaults: { autoScroll: true, frame: false, border: false, padding: '0 0 0 0' },
    		                    activeTab: 0,
    		                    items : [{
    	                        	xtype: "svmx.tabpanel",border: false,
    	                            title: TS.T("TAG072", "Technician Utilization"), activeTab: 0,
    	                            defaults: { autoScroll: true, frame: false, border: false, padding: '0 0 0 0' }
    	                        }
    	                        ]
    				    	}]
    					},{
    					    columnWidth: .75,
    					    items: [{
                            xtype: "svmx.tabpanel", itemId: 'opt-horizontal-tab-container',
                            defaults: { autoScroll: true, border: false, frame: false},
                            width: 875, activeTab: 0, border: false,minHeight: 850,
                            items : [{
                            	xtype: "svmx.setting",
                            	margin: '20 0 0 0',
                            	border: false,
                            	__parent: this,
                            	engine : eng
                            },
                            {
                                xtype: "svmx.execution",
                                id : "getreportdata",
                            	margin: '20 0 0 0',
                            	border: false,
                            	 __parent: this,
                            	 engine : eng
                            }
                            ,{
                            	xtype: "svmx.purge",
                            	margin: '20 0 0 0',
                            	border: false,
                            	 __parent: this,
                            	 engine : eng
                            }
                            
                            ],
                            tabBar: {
                                items: [
                                    { xtype: 'tbfill' },
                                    {
                                        iconCls : 'svmx-spm-help-icon ',
                                        cursor:'pointer',
                                        scale : 'small',
                                        cls: 'svmx-ent-help-opt',
                                        tooltip: TS.T( 'TAG069', 'OPT Help'),
                                        href: TS.T( 'TAG070', 'http://userdocs.servicemax.com:8080/ServiceMaxHelp/Spring16/en_us/svmx_redirector.htm?uid=SPM|SPMConfiguration_Setup'),
                                        closable: false
                           	         }
                                ]
                            }
                        }
                        
                        ]
    					}
                      ]
                   }],
               
                    collapsible: false,
                    title: SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar") ? "" : TS.T("TAG071", "Scheduled Service Performance Metrics"),
                    titleAlign: "center",
                    layout: {
                        type: "border"
                    }
                }, config || {});
                this.callParent([config]);
                
                
            },
            //click handler for Report Latest Run 
            reportLatestRuns: function(data){
                Ext.MessageBox.alert('Status', data);
                Ext.getCmp('opt-report-latest-run-btn').enable();
           
            },
            //click handler for Purge Latest Run 
            purgeLatestRun: function(data){
            	var gridtable =  Ext.getCmp('getpurgedatagrid') ;	
                Ext.MessageBox.alert('Status', data);
                Ext.getCmp('opt-purge-latest-run-btn').enable();
            },
            //click handler for Find Run in Purge
            getJobListForPurge: function(result){
            	if(result.data != null){
            		var gridtable =  Ext.getCmp('getpurgedatagrid') ;
                	var mystore = 	gridtable.getStore();
            		mystore.loadData(result.data);
            	} else {
            		Ext.MessageBox.alert('Status', result.message);
            	}
            	Ext.getCmp('opt-find-run-purge').enable();
            	purgeTable.getSelectionModel().selectAll();
            },
            //click handler for Find Run in Execution
            getJobListForExecution: function(result){
            	if(result.data != null){
                	var gridtable =  Ext.getCmp('getexecutiondatagrid') ;
                	var mystore = 	gridtable.getStore();
            		mystore.loadData(result.data);
            	} else {
            		Ext.MessageBox.alert('Status', result.message);
            	}
            	Ext.getCmp('opt-find-run-btn').enable();
            	executionTable.getSelectionModel().selectAll();
            },
            //click handler for Purge selected Run
            purgeSelectedRuns: function(data){
            	Ext.MessageBox.alert('Status', data);
            	Ext.getCmp('purge-selected-run-btn').enable();
            },
            
            //click handler for Report selected Run
            executionSelectedRuns: function(data){
            	Ext.MessageBox.alert('Status', data);
            	Ext.getCmp('execution-selected-run-btn').enable();
            },
            //load configuration call on page load
            loadDispatchProcessNames: function(data){
            	
            	//extracting data only for dispatchProcessNames from load configuration JSON
            	var dispatchProcessNames = [];
                for(var i=0; i<data.processList.length; i++){
                	dispatchProcessNames.push({label: data.processList[i], name:'None' });
                }
            	
            	var gridtable =  Ext.getCmp('dispatch-process-name-execution') ;
            	var mystore = 	gridtable.getStore();
            	mystore.loadData(dispatchProcessNames);
            	gridtable.setValue(dispatchProcessNames[0].label);
            	
            	//updating UI for dispatch process name dropdown
            	var gridtable =  Ext.getCmp('dispatch-process-name-purge') ;
            	var mystore = 	gridtable.getStore();
            	mystore.loadData(dispatchProcessNames);
            	gridtable.setValue(dispatchProcessNames[0].label);
            	
            	//updating UI for Productive Hours Computation dropdown
            	var productiveHours = [];
            	for(var i=0; i<data.productiveHoursList.length; i++){
            		productiveHours.push({label: data.productiveHoursList[i], name:i });
                }
            	var gridtable =  Ext.getCmp('productive-hours-computation') ;
            	var mystore = 	gridtable.getStore();
            	mystore.loadData(productiveHours);
				if (data.data != null || data.data != undefined) {
					if (data.data.settings.productiveHours != "") {
						var productiveHourArr = data.data.settings.productiveHours.split(",");
						gridtable.setValue(productiveHourArr);
					}
				}

				//updating UI for Available Hours Computation dropdown
				var avaliableHours = [];
            	for(var i=0; i<data.availableHoursList.length; i++){
            		avaliableHours.push({label: data.availableHoursList[i], name:i });
                }
            	var gridtable =  Ext.getCmp('available-hours-computation') ;
            	var mystore = 	gridtable.getStore();
            	mystore.loadData(avaliableHours);
				if (data.data != null || data.data != undefined) {
					if (data.data.settings.availableHours != "") {
						var availableHourArr = data.data.settings.availableHours.split(",");
						gridtable.setValue(availableHourArr);
					}
				}

				//updating UI for Email

				var notificationEmail = Ext.getCmp('notification-email-opt');
            	if(data.data != null || data.data != undefined){
            		notificationEmail.setValue(data.data.settings.emailId);
            	}
            },
            //click handler for save configuration
            saveOptConfiguration: function(data){
            	Ext.MessageBox.alert('Status', data.message);
            	Ext.getCmp('opt-save-configuration-btn').enable();
            }
            
        })
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.opt.ui.desktop\src\execution\execution.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.opt.ui.desktop\src\impl.js

(function(){

	var appImpl = SVMX.Package("com.servicemax.client.opt.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize: function() {
			com.servicemax.client.opt.ui.desktop.api.setting.init();
			com.servicemax.client.opt.ui.desktop.api.execution.init();
			com.servicemax.client.opt.ui.desktop.api.purge.init();
        },

        initialize: function() {
        },

        afterInitialize: function() {
        	com.servicemax.client.opt.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.opt.ui.desktop\src\purge\purge.js
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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.opt.ui.desktop\src\settings\setting.js
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

