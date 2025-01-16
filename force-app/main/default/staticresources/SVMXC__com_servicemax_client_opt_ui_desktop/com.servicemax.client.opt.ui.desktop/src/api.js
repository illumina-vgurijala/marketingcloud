
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