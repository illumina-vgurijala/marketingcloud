// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\api.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        Ext.define("com.servicemax.client.spm.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",

            cls: 'spm-root-container',

            layout: 'fit',
            width: '100%', height: 650,

            constructor: function (config) {
                config = Ext.apply({
                    title: TS.T( 'TAG001', 'Service Performance Metrics Setup'),
                    titleAlign: 'center', collapsible: false,
                    header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            padding: '0', //width: 32, height: 32,
                            //iconCls : "svmx-spm-back-icon", scale: "large",
                            text : TS.T("TAG029", "Back To Setup Home"),
                            handler: function(e, el, owner, tool) {
                                //Added if condition for the story BAC-4797
                                if((typeof sforce != 'undefined') && (sforce != null)){
                                    sforce.one.navigateToURL("/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup");
                                }
                                else{
                                    window.location = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                                }
                            }
                        }]
                    },
                    items : [{
                        xtype: "svmx.tabpanel", itemId: 'spm-horizontal-tab-container',
                        defaults: { autoScroll: true, border: false, frame: false },
                        width: "100%", height: 460, activeTab: 0, border: false,
                        items : [{
                            xtype: "spm.general", padding:'5',
                            title: TS.T("TAG002", "Metrics"),
                            metaModel: config.deliveryEngine.getMetaModel(),
                            __parent: this,
                        },
	                    {
	                        xtype: "spm.config", padding:'5',
	                        title: TS.T( 'TAG086', 'Business Process Config'),
	                        metaModel: config.deliveryEngine.getMetaModel(),
	                        __parent: this,
	                    }],
                        tabBar: {
                            items: [
                                { xtype: 'tbfill' },
                                {
                                    iconCls : 'svmx-spm-help-icon ',
                                    cursor:'pointer',
                                    scale : 'small',
                                    cls: 'svmx-ent-help',
                                    tooltip: TS.T( 'TAG069', 'SPM Help'),
                                    href: TS.T( 'TAG070', 'http://userdocs.servicemax.com:8080/ServiceMaxHelp/Spring16/en_us/svmx_redirector.htm?uid=SPM|SPMConfiguration_Setup'),
                                    closable: false,
                                }
                            ],
                        }
                    }],

                }, config || {});

                this.callParent(arguments);
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\config\config.js

(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.config");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");
        var orgNameSpace = SVMX.getClient().getApplicationParameter("org-name-space");
        
       
        Ext.define('com.servicemax.client.spm.ui.config.Config', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.spm.config',
            cls:'spm-edit-process-panel',

            layout: 'anchor', header: false, border: false,
			cls:'spm-config-tab',
			
			listeners:{
			afterrender: function () {
				 //this.callParent(arguments);
	                var me = this;
	                
	    	      //return an array of values that match on a certain key
	    			function getExpressionRuleValues(obj, key, keyId) {
	    			    var expressionRuleObj = [];
	    			    for (var i in obj) {
	    			        if (!obj.hasOwnProperty(i)) continue;
	    			        if (typeof obj[i] == 'object') {
	    			            expressionRuleObj = expressionRuleObj.concat(getExpressionRuleValues(obj[i], key, keyId));
	    			        } else if (i == key) {
	    			        	if(keyId != undefined ){
	    			        		var issueTrackerData = {
	 	 	            				   'exprId': obj[keyId],
	 	 	            				   'Values': obj[i]
	 	 	            		    };
			        			} else {
			        				var issueTrackerData = {
			 	            				   'Values': obj[i]
			 	            		    };
			        			}
	    			        	
	    			            expressionRuleObj.push(issueTrackerData);
	    			        }
	    			    }
	    			    return expressionRuleObj;
	    			} 
	                
	                
	              me.metaModel.loadBusinessProcessConfiguration( function(result){
	            	  	//defining global object to access result in different-2 component
	            	  	Ext.define('MyApp.util.Utilities', {
		            		    statics: {
		            		        myGlobal: result
		            		    }
	            	  	});
	            	  	var resultData = [];
	            	  	for(var k in result.sources) {
	            	  		var issueTrackerData = {
	            	  				'exprId': result.sources[k],
	            	  				'Values': k
	            	  		};
	            	  		resultData.push(issueTrackerData);
	            	   }
	            	   
	            	  	//on page load set source object  
		            	 
	            	  	var expressionDetailObj = result.expressionDetail ;
	            	  	var expressionRuleNameId = getExpressionRuleValues(expressionDetailObj,'expressionRuleName', 'expressionRuleId');
	            	   
	            	  	//updating issue Tracker  
	            	  	var selectedIssueTrackerStore = Ext.data.StoreManager.lookup('Issue_Tracker_Store');
	            	  	selectedIssueTrackerStore.setProxy({type:'memory',data:resultData});
	            	  	selectedIssueTrackerStore.load();
	            	
	            	 
	            	  	//updating Qualification Criteria
	            	  	var expressionRuleStore = Ext.data.StoreManager.lookup('Qualification_Criteria_Expression');
	            	  	expressionRuleStore.setProxy({type:'memory',data:expressionRuleNameId});
	            	  	expressionRuleStore.load();
	            });
			}
        },
			
			
			initComponent: function(){
				
                this.callParent(arguments);
                var me = this;
                function getExpressionRuleValues(obj, key, keyId) {
    			    var expressionRuleArr = [];
    			    for (var i in obj) {
    			        if (!obj.hasOwnProperty(i)) continue;
    			        if (typeof obj[i] == 'object') {
    			            expressionRuleArr = expressionRuleArr.concat(getExpressionRuleValues(obj[i], key, keyId));
    			        } else if (i == key) {
    			        	if(keyId != undefined ){
    			        		var issueTrackerData = {
 	 	            				   'exprId': obj[keyId],
 	 	            				   'Values': obj[i]
 	 	            		    };
		        			} else {
		        				var issueTrackerData = {
		 	            				   'Values': obj[i]
		 	            		    };
		        			}
    			        	
    			            expressionRuleArr.push(issueTrackerData);
    			        }
    			    }
    			    return expressionRuleArr;
    			}
                
                //store to load data in source object issue tracker
                var issueTrackerStore = SVMX.create('Ext.data.ArrayStore',{
	              	   storeId: 'Issue_Tracker_Store',
	              	   	autoLoad:false,
	                     fields: ['exprId', 'Values'],
	                     proxy: { type: 'memory' }
	                 });
               
               //store to load data in advance expression Qualification Criteria
                var frequecyStore = SVMX.create('Ext.data.ArrayStore',{
                	storeId: 'Qualification_Criteria_Expression',
              	   	autoLoad:false,
                     fields: ['exprId', 'Values'],
                     proxy: { type: 'memory' }
                });
                
                //wrapper for Qualification criteria
                var fieldSet = SVMX.create("Ext.form.FieldSet", {
                    layout: 'anchor', padding:'10'
                });

                me.add( fieldSet );
                
                //save configuration setting
                var saveButton = SVMX.create("Ext.form.FieldSet", {
                    xtype: 'toolbar', dock: 'top', border: 'none', id: 'save-business-process-btn',
                    layout: {
			    	    type: 'vbox'
			    	    ,align: 'right'
			    	},
                    items: [
                        { xtype: 'tbfill' }, 
                        {                                 
                            xtype: 'svmx.button',
                            tooltip : TS.T("TAG089", "Save Business Process Config"),
                            text: TS.T("TAG062", "Save"),
                            handler: function(){
                            	if(Ext.getCmp('source-obj-issue-tracker').valueModels.length){
                            		var sourceObject = Ext.getCmp('source-obj-issue-tracker').valueModels[0].data.exprId;	
                            	}
                            	if(Ext.getCmp('qualification_expression_id').valueModels.length){
                            		if(sourceObject != orgNameSpace+"__Service_Order__c") {
                            			var qualCritObject = Ext.getCmp('qualification_expression_id').valueModels[0].data.exprId;
                            		} else {
                            			var qualCritObject = "";
                            		}
                            	} else {
                            		var qualCritObject = "";
                            	}
                            	 
		                    	 // creating Json for save settings 
		                    	 var configurationParam = {
		                    			"source": sourceObject,
		                    			"selectedCriteria": qualCritObject
		                    	 };

		                    	 Ext.getCmp('save-business-process-btn').disable();
		                    	 
		                    	 me.metaModel.saveBusinessProcessConfiguration(configurationParam, function(result){
		                    	  Ext.getCmp('save-business-process-btn').enable();
		                    	  Ext.MessageBox.alert('Status', TS.T("","Business process configuration saved successfully"));
		                    	 });
		                    	 
		                    }
                        }
                    ]                        
                });
                
                fieldSet.add(saveButton);
                
                
                var issueTracker = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                	name: 'issueTracker', fieldLabel: TS.T("TAG087",'Top level Issue Tracker :'),id: 'source-obj-issue-tracker',
                    editable: false, flex: 1, anchor: '50%',valueField:'exprId', displayField: 'Values',
                    store: issueTrackerStore, labelAlign: 'top', padding:'10',
                    listeners: {
                        change: function (cb, exprId, eOpts) {
                        	
                        	var criteriaBlock = Ext.getCmp('qualification-criteria-section');
	                        if (exprId != orgNameSpace+"__Service_Order__c") {
	                        	me.metaModel.loadExpressions(exprId, function(result){
	                             criteriaBlock.show();
	                        	 MyApp.util.Utilities.myGlobal = result;
	                        	 var updatedSourceObj = MyApp.util.Utilities.myGlobal;
	                        	 var expressionRuleNameId = getExpressionRuleValues(updatedSourceObj.expressionDetail,'expressionRuleName', 'expressionRuleId');
	                        	 if(eOpts != undefined) {
		          	            	 //updating Qualification Criteria
		          	            	 var expressionRuleStore = Ext.data.StoreManager.lookup('Qualification_Criteria_Expression');
		          	            	 expressionRuleStore.setProxy({type:'memory',data:expressionRuleNameId});
		          	            	 expressionRuleStore.load();
	          	            	 }
	                        	});
	                        } else {
	                        	criteriaBlock.hide();
	                        }
                        	
                        }
                    },
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                fieldSet.add(issueTracker);
                
                
                var qualificationCriteria = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG088",'Qualification criteria'),
                    id:"qualification-criteria-section",
                    layout: 'anchor', padding:'10',margin:'10 0 10 10',
                });

                me.__qualificationCriteria = fieldSet.add( qualificationCriteria );
                
                var qualification = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                	name: 'qualificationExpression',id: 'qualification_expression_id', itemId: 'qualification-expression', queryMode: 'local',
                    editable: false, flex: 1,  anchor: '49.5%',  valueField:'exprId', displayField: 'Values', labelAlign: 'top', store: frequecyStore, padding:'10',
                    listeners: {
                        change: function(cb, exprId, eOpts){
                        	var responseObject = MyApp.util.Utilities.myGlobal;
                        	var list = responseObject.expressionDetail;
                        	if(list.length){
	                        	 for(i = 0, l = list.length; i < l; i++){
	                                 item = list[i];
	                                 if(item.expressionRuleList[0].expressionRuleId == exprId){
	                                	 //loading data into table
	                                     var grid = Ext.getCmp('expression_table_details');
	                                     grid.store.loadData(item.expressionRuleList[0].expressionList);
	                                     
	                                     //loading data into Advanced Expression
	                                     var advExp = Ext.getCmp('advanced_expression_text');
	                                     if(item.expressionRuleList[0].advancedExpression){
	                                    	 advExp.show();
	                                    	 advExp.setValue(item.expressionRuleList[0].advancedExpression);
	                                     } else {
	                                    	 advExp.hide();
	                                     }
	                                     
	                                 }
	                             }
                        	} else {
                        		//loading data into table
                                var grid = Ext.getCmp('expression_table_details');
                                grid.store.loadData("");
                                
                                //loading data into Advanced Expression
                                var advExp = Ext.getCmp('advanced_expression_text');
                                advExp.setValue("");
                                advExp.hide();
                                
                        	}
                        }
                    },
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                
                qualificationCriteria.add(qualification);
                
                var expressionTableData = Ext.create('Ext.data.Store', {
                    autoLoad:false,
                    fields: ['sequence', 'field', 'operator', 'value'],
                    proxy: { type: 'memory' }
                });
                
                var expressionTable = SVMX.create("Ext.form.FieldSet", {
                    xtype: 'toolbar',
                    dock: 'top', 
                    border: 'none',
                    items: [
                        {xtype: 'svmx.listcomposite', columnWidth: 1,
                        hidden: false,
                        id: 'expression_table_details',
                        columns: [
                            { text: TS.T("TAG032", "Sequence"),  dataIndex: 'sequence', flex: 1, menuDisabled: true, sortable: false, renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            }},
                            { text: TS.T("TAG033", "Field"),  dataIndex: 'field', flex: 2, menuDisabled: true, sortable: false, renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            }},
                            { text: TS.T("TAG034", "Operator"), dataIndex: 'operator', flex: 1, menuDisabled: true, sortable: false, renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            }},
                            { text: TS.T("TAG035", "Value"), dataIndex: 'value', flex: 1, menuDisabled: true, sortable: false, renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            }}
                        ],
                        store: expressionTableData
                        }
			    	]
                        
                });
                
                
                qualificationCriteria.add(expressionTable);
                
                
                var advancedExpression = SVMX.create("Ext.form.FieldSet", {
                	xtype: 'toolbar',dock: 'top', border: 'none', 
                    items: [
                    	{
                    		xtype: 'svmx.text', name: 'advExpression', width: "48.8%", flex: 1,id: 'advanced_expression_text',hidden: true,
                            fieldLabel: TS.T("TAG031", "Advanced Expression"),labelAlign: 'top', readOnly: true,labelAlign: 'top',
                    	}
                    ]
                });
                
                qualificationCriteria.add(advancedExpression);
                
                //on page load set source object  
                issueTrackerStore.on('load',function(store) {
                	var responseObject = MyApp.util.Utilities.myGlobal;
                	if(responseObject.businessProcessConfig){
                		if(responseObject.businessProcessConfig.source === undefined || responseObject.businessProcessConfig.source === null || responseObject.businessProcessConfig.source == "" ){
                			if(store.data.items.length) {
                			   Ext.getCmp('source-obj-issue-tracker').setValue(store.data.items[0].data.exprId);
                			}else { Ext.getCmp('source-obj-issue-tracker').setValue(''); }
                		} else {
                			Ext.getCmp('source-obj-issue-tracker').setValue(responseObject.businessProcessConfig.source);
                		}
                	} else {Ext.getCmp('source-obj-issue-tracker').setValue('');}
                });
                
                frequecyStore.on('load',function(store) {
                		var responseObject = MyApp.util.Utilities.myGlobal;
                		if(responseObject.businessProcessConfig){
                			if(responseObject.businessProcessConfig.selectedCriteria === undefined || responseObject.businessProcessConfig.selectedCriteria === null || responseObject.businessProcessConfig.selectedCriteria == "" ){
                    			if(store.data.items.length) {
                    				Ext.getCmp('qualification_expression_id').setValue(store.data.items[0].data.exprId);
                    			}else {Ext.getCmp('qualification_expression_id').setValue('');}
                    		} else {
                    			Ext.getCmp('qualification_expression_id').setValue(responseObject.businessProcessConfig.selectedCriteria);
                    		}
                		}
                		
                });
                
                
                
			}
			
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\general\general.js

(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.general");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        var loadCustomLabel = function (processName) {
        	if(processName == "First Time Fix") {
        		return TS.T("TAG077", "First Time Fix");
        	} else if(processName == "Mean Time To Repair") {
        		return TS.T("TAG078", "Mean Time To Repair");
        	} else if(processName == "Contract Up Time") {
        		return TS.T("TAG079", "Contract Up Time");
        	} else if(processName == "Attach Rate") {
        		return TS.T("TAG080", "Attach Rate");
        	} else if(processName == "Mean Time To Complete") {
        		return TS.T("TAG081", "Mean Time To Complete");
        	} else if(processName == "Average Response Time") {
        		return TS.T("TAG082", "Average Response Time");
        	} else if(processName == "Utilization") {
        		return TS.T("TAG083", "Utilization");
        	} else if(processName == "Repeat Visit") {
        		return TS.T("TAG084", "Repeat Visit");
        	} else if(processName == "Account Summary") {
        		return TS.T("TAG085", "Account Summary");
        	} else {
        		return processName;
        	}
        };
        
        Ext.define('com.servicemax.client.spm.ui.general.General', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.spm.general',
            cls:'spm-edit-process-panel',

            layout: 'anchor', header: false, border: false,
			cls:'spm-genral-tab',
            initComponent: function(){
                this.callParent(arguments);

                var processList = this.metaModel.getProcessList() || [];
                var i, l = processList.length, reports = [];
                
                for(i = 0; i < l; i++){
                    var report = {
                        xtype: "svmx.tabpanel", anchor:'100% 100%', border: false,
                        title: loadCustomLabel(processList[i].processName),
                        activeTab: 0,
                        defaults: { autoScroll: true, frame: false, border: false, padding: '0 0 0 0' },
                        items:[{
                            xtype: "spm.report", 
                            tooltip: loadCustomLabel(processList[i].processName),
    						cls:'spm-report-general-'+i, title: TS.T("TAG005", "General"),
                            processId: processList[i].processId, tabPanelId: 'tabPanel_' + i, 
                            __parent: this, 
                            listeners: {
                                activate: SVMX.proxy(this, function( tabPanel, eOpts ){
                                    this.metaModel.getProcessConfig(tabPanel.processId, function(data){
                                        if(tabPanel.loadData){
                                            tabPanel.loadData(data);
                                        }
                                    });
                                })
                            }
                        },{
                            xtype: 'spm.schedule',
                            cls:'spm-report-config-schedule-tab',
                            __parent: this, metaModel: this.metaModel,
                            title: TS.T("TAG003", "Schedule & Notifications"),
                            processId: processList[i].processId,
                            tooltip: TS.T("TAG058", "Schedule & Notifications"),
                            listeners: {
                                activate: SVMX.proxy(this, function( tabPanel, eOpts ){                                    
                                    this.metaModel.getProcessConfig(tabPanel.processId, function(data){
                                        if(tabPanel.loadRecord){
                                            tabPanel.loadRecord({data: data.records[0]});
                                        }
                                    });
                                })
                            }
                        },{
                            xtype: 'spm.status',
                            cls:'spm-report-config-status-tab',
                            title: TS.T("TAG004", "Status"),
                            metaModel: this.metaModel,
                            processId: processList[i].processId,
                            tooltip: TS.T("TAG059", "Status"),
                            listeners: {
                                activate: function( tabPanel, eOpts ){
                                    if(tabPanel.onActivate){
                                        tabPanel.onActivate();
                                    }
                                }
                            }
                        }],
                        tabBar: {
                            items: [
                            { xtype: 'tbfill' },                             
                            {
                                xtype: 'component', margin:'5 5 5 5',
                                autoEl: { 
                                    tag: 'a', align: 'right', //style: 'padding:10px 0px 0px 310px;', 
                                    target: '_blank', style: 'text-decoration: underline !important;',
                                    href: '/../../'+processList[i].dashboardId, 
                                    html:(processList[i].dashboardId)?TS.T("TAG030", "Launch Dashboard"):''
                                }
                            }]
                        }
                    };
                    reports.push(report);
                }
                
                this.tabPanel = this.add({
                    xtype: "svmx.tabpanel", anchor:'100% 100%', border: false,
					cls:'spm-tabs-left',
                    tabPosition: "left", itemId: 'spm-general-tab-items-container',
                    defaults: { autoScroll: true, frame: false, border: false, padding: '0 0 0 0' },
                    items: reports, activeTab: 0
                });
                
            },
            
            saveProcessConfig: function(config, callback){
                var me = this;
                if(config.appliesTo || config.scheduleInfo ) {
                    me.metaModel.saveProcessConfig(config, function(result) {
                        Ext.Msg.alert( result.success?'Success':'Failed', result.message );
                        if(result.success){
                            var tab = me.tabPanel.getActiveTab().getActiveTab();
                            if(tab.loadData){
                                me.metaModel.getProcessConfig(config.processId, function(data){
                                    tab.loadData(data);
                                }, true);
                            }
                        } 
                    });
                } else {
                    Ext.Msg.alert( 'Failed', TS.T("TAG064", "Invalid description field value.") );
                }
            },

            deleteProcessConfig: function(config, callback){
                var me = this; 
                me.metaModel.deleteProcessConfig(config, function(result){
                    Ext.Msg.alert( result.success?'Success':'Failed', result.message );
                    if(result.success){
                        var tab = me.tabPanel.getActiveTab().getActiveTab();
                        if(tab.loadData){
                            me.metaModel.getProcessConfig(config.processId, function(data){
                                tab.loadData(data);
                            }, true);
                        }
                    }  
                });
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\general\reports\reports.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.reports");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        var isAccountSummary = true; //Variable to track if the current view is for Account-Summary Flow.

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.report', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.spm.report',
			cls:'spm-components-container',
            layout: { type: 'vbox', align: 'stretch' }, border: false,

            initComponent: function(){
                this.callParent(arguments); 
            },

            loadData: function(data, isNewRecord){
                /*if(!!isNewRecord){
                    this.destroyProcessListPanel();
                }*/
                
                isAccountSummary = (this.processId != 'AccountSummary') ? false : true;               

                this.destroyProcessListPanel();
                this.destroyEditProcessPanel();

                this.listPanel = this.add({ 
                    xtype: 'spm.report.processlistpanel', 
					cls:'spm-components-tab', processId: this.processId,
                    itemId: this.tabPanelId + '_processlistpanel', 
                    fields: data.fields, data: (data && data.records) ? data.records : [],
                    __parent: this, padding: '0 0 10 0'
                });
                
                //var record = this.listPanel.store.getAt(0);
                //if(record){
                //    this.editRecord(record);
                //}
            },

            editRecord: function(record){                
                isAccountSummary = (this.processId != 'AccountSummary') ? false : true;                
                this.destroyEditProcessPanel();

                var tabPanel = this.add({
                    flex:1, xtype: 'spm.report.editprocesspanel',
                    itemId: this.tabPanelId + '_editprocesspanel', border: false,
                    record: record, __parent: this
                }); 
            },

            getMetaModel: function(){
                return this.__parent.metaModel;
            },

            getFirstDefaultProcessConfig : function(processId){
                return this.getMetaModel().getFirstDefaultProcessConfig(processId);
            },

            /*refreshEditPanel: function(data){
                setTimeout(SVMX.proxy(this, function(){
                    data.isNewRecord = true;
                    this.editRecord(data);
                }), 1);
            },

            getDefaultProcessConfig: function(method){
                return this.getMetaModel().getDefaultProcessConfig(this.processId, method);
            },

            getProcessConfig: function(isNewRecord, callback, refresh){
                if(!isNewRecord){
                    this.getMetaModel().getProcessConfig(this.processId, callback, refresh);
                }else{
                    callback && callback(this.getFirstDefaultProcessConfig(this.processId));
                }
            },*/

            saveProcessConfig: function(config){
                config.processId = this.processId;
                // BAC-4107 - Security (XSS) - Text is not getting decoded, When loaded back in the UI. HtmlEncode has been taken care at grid where description has displied.
                //config.appliesTo = Ext.String.htmlEncode( config.appliesTo ); 
                this.__parent.saveProcessConfig(config);
            },

            deleteProcessConfig: function(config){
                config.processId = this.processId;
                this.__parent.deleteProcessConfig(config);
            },

            destroyProcessListPanel: function(){
                var panel = this.getComponent(this.tabPanelId + '_processlistpanel');
                if(panel) panel.destroy(); 
            },

            destroyEditProcessPanel: function(){
                var panel = this.getComponent(this.tabPanelId + '_editprocesspanel');
                if(panel) panel.destroy();
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.ProcessListPanel', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            alias:'widget.spm.report.processlistpanel',
			cls:'spm-process-list-panel',
            hidden: false, border: false, maxHeight : 172,

            constructor: function (config) {
                
                config = Ext.apply({
                    columns: [
                        //{ text: 'Name',  dataIndex: 'name', flex: 1 },
                        //{ text: "Name",  dataIndex: 'name', flex: 1.5/10 },
                        { dataIndex: 'cSequence', flex: 0.5/10, menuDisabled: true, sortable: false },                        
                        //{ text: TS.T("TAG008", "Calculation Method"),  dataIndex: 'method', flex: 2.4/10 },
                        { text: TS.T("TAG009", "Description"),  dataIndex: 'appliesTo', flex: 7/10, menuDisabled: true, sortable: false,
                            renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG010", "Last Modified On"), dataIndex: 'lastModifiedOn', flex: 2/10, menuDisabled: true, sortable: false },
                        { 
                            xtype: 'actioncolumn', align: 'center', 
                            flex: 0.4/10, sortable: false, menuDisabled: true,
                            items: [{
                                //icon:'some_icon.png',
                                tooltip : TS.T("TAG012", "Delete Calculation Method"), 
                                //xtype: 'svmx.button',
                                iconCls : "svmx-spm-delete-icon",
                                disabled: isAccountSummary,
                                handler : SVMX.proxy(this, function(grid, rowIndex, colIndex, item, e, record) {
                                    var me = this;
                                    Ext.MessageBox.confirm({
                                    	title:TS.T("TAG051", "Confirm"),
                            			msg : TS.T("TAG076", 'Are you sure ? Would you like to delete this Calculation Method ?' ),
                            			buttons: Ext.MessageBox.YESNO,
                                        buttonText:{
                                            yes: TS.T("TAG074", 'Yes' ), 
                                            no: TS.T("TAG075", 'No' ) 
                                        },
                                    	icon : Ext.MessageBox.QUESTION,
                                    	fn :function(btn, text){
                                    		if (btn == 'yes'){
                                                me.__parent.deleteProcessConfig({recordId: record.data.raw.recordId});
                                            }
                                    	}
                                    });   
                                })
                            }] 
                        }
                    ],
                    store: Ext.create('Ext.data.Store', {
                        storeId: config.itemId + '_store', proxy: { type: 'memory' },
                        fields: config.fields, data: config.data
                    }),
                    listeners: {
                        select: function( grid, record, index, eOpts ){
                            this.__parent.editRecord(record);
                        }
                    },
                    dockedItems: [{
                        xtype: 'toolbar',
                        dock: 'top',
                        //style: 'background-color: lightgray;',
                        items: [
                            { xtype: 'tbfill' }, 
                            
                            {                                 
                                tooltip : TS.T("TAG011", "Add Calculation Method"), 
                                xtype: 'svmx.button', //width: 28, height: 24,
                                text: TS.T("TAG071", "Add"),
                                cursor:'pointer',
                                disabled: isAccountSummary,
                                //iconCls : "svmx-spm-add-icon",scale   : "medium",
                                handler: SVMX.proxy(this, function(){
                                    var config = this.__parent.getFirstDefaultProcessConfig(this.processId);
                                    config = { data: config, isNewRecord: true};
                                    this.__parent.editRecord(config);
                                    this.__parent.listPanel.getSelectionModel().deselectAll();
                                })
                            }                            
                        ]                        
                    }]  
                }, config || {});
                this.callParent(arguments); 
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.EditProcessPanel', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXTabPanel',
            alias:'widget.spm.report.editprocesspanel',
            border: true, 
			cls:'spm-edit-process-panel',
            initComponent: function(){
                this.callParent(arguments);                
                this.tabBar.add([
                    { xtype: 'tbfill' }, 
                    {
                        xtype: 'svmx.button', margin: '2 2 0 0',
                        //iconCls : "svmx-spm-save-icon", 
                        tooltip : TS.T("TAG013", "Save Calculation Method"),
                        text: TS.T("TAG062", "Save"),
                        disabled: isAccountSummary,
                        //scale   : "medium", 
                        handler : SVMX.proxy(this, function(){
                            var tabPanel = this, result = {};
                            tabPanel.items.items.forEach(function(item){ 
                                if(item.getData){
                                    var data = item.getData(); 
                                    if(item.itemId == tabPanel.id + "spm_schedule"){
                                        result.scheduleInfo = data;
                                    }else{
                                        for(var key in data){
                                            result[key] = data[key];
                                        }
                                    }
                                }
                            });
                            tabPanel.__parent.saveProcessConfig(result);
                        })
                    },{
                        xtype: 'svmx.button', margin: '2 5 0 0',
                        tooltip : TS.T("TAG014", "Cancel"),
                        text : TS.T("TAG063", "Cancel"),
                        disabled: isAccountSummary,
                        //iconCls : "svmx-spm-cancel-icon", 
                        //margin: '0 0 0 2', 
                        //scale : "medium", 
                        handler : SVMX.proxy(this, function(){
                            var tabPanel = this;
                            /*tabPanel.__parent.destroyEditProcessPanel();
                            tabPanel.__parent.listPanel.getSelectionModel().deselectAll();*/
                            
                            Ext.MessageBox.confirm({
                            	title:TS.T("TAG051", "Confirm"),
                    			msg : TS.T("TAG052", 'Would you like to discard your changes ?' ),
                    			buttons: Ext.MessageBox.YESNO,
                                buttonText:{
                                    yes: TS.T("TAG074", 'Yes' ), 
                                    no: TS.T("TAG075", 'No' ) 
                                },
                            	icon : Ext.MessageBox.QUESTION,
                            	fn :function(btn, text){
	                                if (btn == 'yes'){
	                                    /*me.__parent.getProcessConfig(isNewRecord, function(config){
	                                        me.__parent.loadData(config, isNewRecord);
	                                    });*/
	                                    tabPanel.__parent.destroyEditProcessPanel();
	                                    tabPanel.__parent.listPanel.getSelectionModel().deselectAll();
	                                }
                            	}
                            });
                            
                        })
                    }
                ]);

                if(!this.record) return;

                var me = this;
                var isNewRecord = me.record.isNewRecord || false;
                var record = me.record.data || {};

                var components = [];
                var fieldSetGeneral = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG065", 'Metric Information'),
                    layout: 'column', padding:'10',
                    defaults: { padding: '10px', labelAlign: 'top' }
                });
                components.push(fieldSetGeneral);
                
                var keyArray = ['isActive', 'sourceObjectLabel', 'targetObjectLabel', 'appliesTo'];
                if(record.method === 'SPMMTBF: Standard'){
                    keyArray = ['isActive', 'sourceObjectLabel', 'targetObjectLabel', 'entryTypeForMTBF', 'appliesTo'];
                }
                if (record.entryTypeForMTBF === '' || record.entryTypeForMTBF === null  || isNewRecord) {
                    record.entryTypeForMTBF = 'Multiple_MTBF';
                }
                SVMX.array.forEach(keyArray, function(key){
                    if(!(key in record)) return;
                    switch(key){
                        case 'name': 
                            fieldSetGeneral.add({ fieldLabel: 'Name', name: key, readOnly: true });
                            break;
                        case 'isActive':
                            fieldSetGeneral.add({ xtype: 'checkbox', boxLabel: TS.T("TAG050", "Active"), readOnly: isAccountSummary,
                                name: key, value:record[key], columnWidth: 1.0, labelAlign: 'top'
                            });
                            break;
                        case 'method_values': 
                            fieldSetGeneral.add({
                                xtype: 'svmx.picklist', name: 'method', fieldLabel: TS.T("TAG008", "Calculation Method"), 
                                displayField: 'name', valueField: 'name', value: record.method, hidden: true,
                                columnWidth: 1.0, labelAlign: 'top',
                                store: Ext.create('Ext.data.Store', {
                                    storeId: me.id+'_'+key+'_store', 
                                    fields: ['name'], data: record[key], 
                                    proxy: { type: 'memory' }
                                }),
                                listeners: {
                                    change: function(cmp, nv){
                                        /*if(isNewRecord){
                                            var config = me.__parent.getDefaultProcessConfig(nv);
                                            me.__parent.refreshEditPanel({ data: config });
                                        }*/
                                    }
                                },
                                listConfig: {
                                    getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                }
                            });
                            break;
                        case 'entryTypeForMTBF':
                            fieldSetGeneral.add({
                                xtype: 'svmx.picklist', name: 'entryTypeForMTBF', fieldLabel: TS.T("TAG090", "Define how many entries must be maintained per Installed Product in this metric"), 
                                displayField: 'label', valueField: 'name', value: record.entryTypeForMTBF,
                                columnWidth: 1.0, labelAlign: 'top', editable: false, readOnly: !isNewRecord,
                                store: Ext.create('Ext.data.Store', {
                                    storeId: 'entryTypeForMTBFStore', 
                                    fields: ['label', 'name'],
                                    data : [
                                        {"name": "Single_MTBF", "label": TS.T("TAG091", "Single MTBF")},
                                        {"name": "Multiple_MTBF", "label": TS.T("TAG092", "Multiple MTBF")},
                                    ], 
                                    proxy: { type: 'memory' }
                                }),
                                listConfig: {
                                    getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                }
                            });
                            break;
                        case 'appliesTo': 
                            fieldSetGeneral.add({ xtype: 'svmx.textarea', labelAlign: 'top', columnWidth: 1.0, readOnly: isAccountSummary, fieldLabel: TS.T("TAG009", "Description"), name: key });
                            break;
                        case 'dashboardId': 
                            if(record[key]){
                                fieldSetGeneral.add({
                                    xtype: 'component', 
                                    autoEl: { 
                                        tag: 'a', align: 'right', //style: 'padding:10px 0px 0px 310px;', 
                                        target: '_blank', style: 'text-decoration: underline !important;',
                                        href: '/../../'+record[key], html: TS.T("TAG030", "Launch Dashboard")
                                    }
                                }); 
                            }
                            break;
                        case 'sourceObjectLabel': 
                            fieldSetGeneral.add({ xtype: 'textfield', columnWidth: 1.0, readOnly: true,
                                fieldLabel: TS.T("TAG060", "Object(s) from which this metric is derived"), 
                                name: key, value: record[key], labelAlign: 'top'
                            });
                            break;
                        case 'targetObjectLabel': 
                            fieldSetGeneral.add({ xtype: 'textfield', columnWidth: 1.0, readOnly: true,
                                fieldLabel: TS.T("TAG061", "Object(s) where metrics are collected"), 
                                name: key, value: record[key], labelAlign: 'top'
                            });
                            break;
                    }
                }, me);

                if(components.length){
                    me.add({ 
                        xtype: 'form',cls:'spm-report-config-general', title: TS.T("TAG055", "Metric Definition"), items: components, height: '100%',
                        header: false, bodyPadding: 5, layout: 'column', defaultType: 'textfield',
                        tooltip: TS.T("TAG055", "Metric Definition"), border: false, labelAlign: 'top', padding: 10,
                        defaults: { padding: '10px', columnWidth: 1.0, labelAlign: 'top' }, autoScroll: true,
                        getData: function(){
                            return this.getForm().getValues();
                        } 
                    });
                }

                components = [];

                var fieldSetAdditionalCriterias = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG068", 'Please define inputs to be used in metric calculation' ),
                    layout: 'column', padding:'10', columnWidth: 1
                });
                var selectedMatrixTab = this.__parent ;
                var hasAdditionalCriteria = false;
                for(var key in record) {
                	
                    if(key.match('_fields')) {
                        if( record[key].isCriteria == true ) {
                            hasAdditionalCriteria = true;
                            fieldSetAdditionalCriterias.add({
                                xtype: 'combobox', name: record[key].name, editable: false, columnWidth: 0.5,id: 'selectbox_Id'+selectedMatrixTab.processId+record[key].componentId,
                                fieldLabel: record[key].name, displayField: 'label', valueField: 'name',
                                labelAlign: 'top', padding: 10, multiSelect: record[key].multiSelect,
                                listeners: {
                                    change: function(cb, exprId, eOpts){
                                    	if(selectedMatrixTab.processId === "FirstTimeFix"){
	                                    	if(exprId === 'WorkDetail'){
	                                    		if(Ext.getCmp('selectbox_IdFirstTimeFixPeriod') != undefined && Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder') != undefined){
		                                    		Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder').hide();
		                                            Ext.getCmp('selectbox_IdFirstTimeFixPeriod').show();
		                                         if(Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id') != undefined && Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id') != undefined ){
		                                            	Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id').up().hide();
		                                          	    Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id').up().show();
		                                            }
	                                    		}
	                                        }
	                                    	if(exprId === 'WorkOrder'){
	                                        	if(Ext.getCmp('selectbox_IdFirstTimeFixPeriod') != undefined && Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder') != undefined){
	                                        		Ext.getCmp('selectbox_IdFirstTimeFixPeriod').hide();
	                                          	    Ext.getCmp('selectbox_IdFirstTimeFixhasPrimaryWorkOrder').show();
	                                          	    if(Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id') != undefined && Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id') != undefined ){
	                                          	    	Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedfieldset_id').up().show();
	                                          	    	Ext.getCmp('tabPanel_0_editprocesspanel_expression_CriteriaForFirstTimeFixedUsingWorkDetailfieldset_id').up().hide();
	                                          	    }
	                                        	}
	                                        }
                                    	}
                                    }
                                },
                                listConfig: {
                                   getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                }, 
                                store: Ext.create('Ext.data.Store', {
                                    storeId: me.itemId + '_'+record[key].name+'_store', 
                                    fields: ['name','label','displayType'], data: record[key].values, 
                                    proxy: { type: 'memory' },
                                })
                            });
                        }
                    } 
                }

                if( hasAdditionalCriteria ) {
                    components.push( fieldSetAdditionalCriterias );    
                }

                var fieldSet = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG066", 'Please define the object mapping for this metric'),
                    layout: 'column', padding:'10', 
                });                
                components.push(fieldSet);

                for(var key in record) {
                    if(key.match('_fields')) {
                        if( record[key].isCriteria == false ) {
                            fieldSet.add({
                                xtype: 'combobox', name: record[key].name, editable: false, columnWidth: 0.5,
                                fieldLabel: record[key].name, displayField: 'label', valueField: 'name',
                                labelAlign: 'top', padding: 10, multiSelect: record[key].multiSelect,
                                listConfig: {
                                   getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                                },                                   
                                store: Ext.create('Ext.data.Store', {
                                    storeId: me.itemId + '_'+record[key].name+'_store', 
                                    fields: ['name','label','displayType'], data: record[key].values, 
                                    proxy: { type: 'memory' }
                                })
                            });
                        }  
                    } 
                }

                for(var key in record){
                    if(key.match('_mappings')){
                        fieldSet.add({
                            xtype: 'combobox', name: record[key].name, editable: false, columnWidth: 0.5,
                            fieldLabel: record[key].name, displayField: 'name', valueField: 'mapId',
                            labelAlign: 'top', padding: 10,
                            listConfig: {
                                   getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                    }
                            },  
                            store: Ext.create('Ext.data.Store', {
                                storeId: me.itemId + '_'+record[key].name+'_store', 
                                fields: ['name','mapId'], data: record[key].values, 
                                proxy: { type: 'memory' }
                            })
                        });   
                    } 
                }     
                
                if(components.length && !isAccountSummary) {
                    me.add({ 
                        xtype: 'form', cls:'spm-report-config-settings', title: TS.T("TAG006", "Settings"), items: components, 
                        header: false, bodyPadding: 5, layout: 'column', defaultType: 'textfield',
                        tooltip: TS.T("TAG056", "Settings"), padding: 10,
                        defaults: { padding: '10px', columnWidth: 1.0, labelAlign: 'top' }, autoScroll: true,
                        getData: function(){
                            return this.getForm().getValues();
                        } 
                    });
                }

                components = [];
                Ext.each(record.expressions || [], function(item){
                    components.push({
                        xtype: 'spm.report.exprpanel', columnWidth: 1,
                        itemId: me.itemId + '_expression_' + item.type, 
                        title: item.label, rules: item.rules, value: item.value
                    });
                }, me);

                if(components.length){
                    me.add({ 
                        xtype: 'form', cls:'spm-report-config-criteria', title: TS.T("TAG007", "Criteria(s)"), items: components, autoScroll: true,
                        header: false, bodyPadding: 5, layout: 'column', defaultType: 'textfield',
                        tooltip: TS.T("TAG057", "Criteria(s)"),
                        defaults: { padding: '10px', columnWidth: 0.5, labelAlign: 'top' },
                        getData: function(){
                            var record = this.getForm().getRecord();
                            if(!isNewRecord) record = record.getData();
                            else record = record.data;

                            var expressions = {};
                            Ext.each(record.expressions, function(item){
                                var cmp = this.getComponent(me.itemId + '_expression_' + item.type);
                                var val = cmp.getSelectedExpression();
                                if(val) expressions[item.type] = val;
                            }, this);

                            var params = this.getForm().getValues();
                            var retValue = {

                                expressions: expressions, 
                                raw: record.raw
                            };

                            if( params ) {
                                for( var key in params ) {
                                    if( key != 'advExp') {
                                        retValue[key] = params[key];
                                    }
                                }    
                            }

                            return retValue;
                        }
                    });
                }

     //            me.add([{
     //                xtype: 'spm.schedule',
					// cls:'spm-report-config-schedule-tab',
     //                itemId: this.id + "spm_schedule",
     //                metaModel: this.__parent.getMetaModel(),
     //                processId: this.__parent.processId,
     //                tooltip: TS.T("TAG058", "Schedule & Notifications"),
     //            },{
     //                xtype: 'spm.status',
					// cls:'spm-report-config-status-tab',
     //                metaModel: this.__parent.getMetaModel(),
     //                processId: this.__parent.processId,
     //                tooltip: TS.T("TAG059", "Status"),
     //                listeners: {
     //                    activate: function( tabPanel, eOpts ){
     //                        if(tabPanel.onActivate){
     //                            tabPanel.onActivate();
     //                        }
     //                    }
     //                }
     //            }])

                me.setActiveTab(0);
                me.loadData(me.record);
            },

            loadData: function(record){
                SVMX.array.forEach( this.items.items, function(item){
                    if(item.loadRecord){
                        item.loadRecord(record || this.record);
                    }
                }, this);
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.ExpressionPanel', {
            extend: 'Ext.form.FieldSet',
            alias:'widget.spm.report.exprpanel',
			cls:'spm-report-expression-panel',
			id: '',
            layout: 'column', border: false, margin: '10',
            labelStyle: 'font-weight:bold;padding:0',
            defaults: { padding: '5', columnWidth: 0.5, labelAlign: 'top' },

            initComponent: function () {
                this.callParent(arguments);

                var me = this;
                this.add([{
                    xtype: 'svmx.picklist', itemId: me.itemId + '_expression', id:me.itemId + 'fieldset_id',
                    displayField: 'name', valueField: 'exprId', editable: false,
                    store: Ext.create('Ext.data.Store', {
                        storeId: me.itemId + '_expression_store', 
                        fields: ['exprId', 'name', 'expressions', 'advExp'],
                        data : me.rules, proxy: { type: 'memory' }
                    }),
                    listeners: {
                        change: function(cb, exprId){
                            var list = cb.store.data.items, item;
                            for(i = 0, l = list.length; i < l; i++){
                                item = list[i];
                                if(item.data.exprId == exprId || item.data.name == exprId){

                                    var grid = me.getComponent(me.itemId + '_expression_details');
                                    grid.store.loadData(item.data.expressions);
                                    grid.show();  

                                    var advExp = me.getComponent(me.itemId + '_advExp');
                                    if(item.data.advExp){
                                      advExp.setValue(item.data.advExp);  
                                      advExp.show();  
                                    } 
                                    else advExp.hide();

                                    break;
                                }
                            }
                        }
                    },
                    listConfig: {
                                getInnerTpl: function(displayField) {
                                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                                }
                    }
                },{
                    xtype: 'svmx.listcomposite', columnWidth: 1,
                    itemId: me.itemId + '_expression_details', hidden: false,
                    columns: [
                        { text: TS.T("TAG032", "Sequence"),  dataIndex: 'sequence', flex: 1, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG033", "Field"),  dataIndex: 'field', flex: 2, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG034", "Operator"), dataIndex: 'operator', flex: 1, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: TS.T("TAG035", "Value"), dataIndex: 'value', flex: 1, menuDisabled: true, sortable: false,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } }
                    ],
                    store: Ext.create('Ext.data.Store', {
                        storeId: me.itemId + '_expression_grid_store',
                        fields: ['sequence', 'field', 'operator', 'value'],
                        proxy: { type: 'memory' }
                    })
                },{
                    xtype: 'svmx.text', name: 'advExp', itemId: me.itemId + '_advExp', hidden: true,
                    fieldLabel: TS.T("TAG031", "Advanced Expression"), readOnly: true,columnWidth: 1
                }]);

                this.items.get(this.itemId + '_expression').setValue(this.value);
            },

            getSelectedExpression: function(){
                return this.items.get(this.itemId + '_expression').getValue();
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\impl.js

(function(){

	var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},
		
		beforeInitialize: function() {
			com.servicemax.client.spm.ui.desktop.api.general.init();
			com.servicemax.client.spm.ui.desktop.api.reports.init();
			com.servicemax.client.spm.ui.desktop.api.schedule.init();
			com.servicemax.client.spm.ui.desktop.api.status.init();
			com.servicemax.client.spm.ui.desktop.api.config.init();
        },

        initialize: function() {
        	com.servicemax.client.spm.ui.desktop.api.init();
        }

	}, {
		instance : null
	});

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\schedule\schedule.js
(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.schedule");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        Ext.define('com.servicemax.client.spm.ui.desktop.api.schedule.Schedule', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXSection',
            alias:'widget.spm.schedule',

           title: TS.T("TAG003", "Schedule & Notifications"), layout: 'fit', border: false, autoScroll: true, 

            constructor: function (config) {
                config = Ext.apply({
                    dockedItems: [{
                        xtype: 'toolbar',
                        dock: 'top',                        
                        items: [
                            { xtype: 'tbfill' }, 
                            {                                 
                                tooltip : 'Save', 
                                xtype: 'svmx.button', //width: 28, height: 24,
                                text: 'Save',
                                //iconCls : "svmx-spm-add-icon",scale   : "medium",
                                handler: SVMX.proxy(this, function(){    
                                    this.__parent.saveProcessConfig({
                                        processId: this.processId,
                                        scheduleInfo: this.getData()
                                    });                            
                                })
                            }
                        ]                        
                    }]
                    /*buttons: [{
                        text: 'Apply',
                        handler: SVMX.proxy(this, function() {
                            var data = this.topPanel.down('form').getForm().getValues();
                            var selections = this.topPanel.down('grid').getSelectionModel().getSelection();

                            data.selections = [];                            
                            selections.forEach(function(item){
                                data.selections.push(item.data.processId);
                            });
                            data.raw = this.raw;
                            this.__parent.saveScheduleConfig(data);
                        })
                    }]*/
                }, config || {});
                this.callParent(arguments);
            },

            initComponent: function (config) {
                this.callParent(arguments);
                this.topPanel = this.add({
                    title: 'SPM Report Schedule', header: false,
                    anchor: '100%', autoScroll: true, border: false
                });
            },

            loadRecord: function(record){
                this.scheduleId = record.data ? record.data.details.scheduleId: null;
                this.editRecord(record);
            },

            /*onActivate: function() {
                if(this.topPanel) this.topPanel.destroy();
                this.topPanel = this.add({
                    //title: 'SPM Report Schedule',
                    anchor: '100%', autoScroll: true
                });
                
                this.metaModel.getScheduleList( SVMX.proxy(this, function(data) {
                    if(data){
                        var toolbar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                            dock: "top"
                        });
                        
                        var searchtext = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                            cls: 'svmx-text-filter-icon',
                            emptyText: 'Search for SPM Report', width: "40%", height: 30, 
                            style: { 
                                marginLeft: '20px', 
                                marginRight: '2px', 
                                marginTop: '0px', 
                                marginBottom: '0px'
                            },

                            listeners: {
                                change: SVMX.proxy(this, function(f, e) {
                                    this.topPanel.listPanel.store.clearFilter();
                                    this.topPanel.listPanel.store.filter('processName',  new RegExp( Ext.escapeRe( searchtext.getValue() ), 'i') );                                    
                                })
                            }
                        });
                        toolbar.addItemsLeft(searchtext);
                        this.topPanel.addDocked(toolbar);

                        this.raw = data.raw;
                        this.topPanel.listPanel = this.topPanel.add({ 
                            xtype: 'spm.report.schedulelistpanel', 
                            itemId: this.itemId + '_schedulelistpanel', border: true,
                            fields: data.fields, __parent: this
                        });
                        this.topPanel.listPanel.store.loadData( (data && data.records) ? data.records : [] );
                    }
                }));
            },*/

            getData: function() {
                var data  = this.topPanel.down('form').getForm().getValues();
                data.scheduleId = this.scheduleId;
                return data;
            },

            loadData: function(record) {
            },

            editRecord: function(record){
                if(this.topPanel.editPanel){
                  this.topPanel.editPanel.destroy();  
                } 
                this.topPanel.editPanel = this.topPanel.add({ 
                    xtype: 'spm.schedule.scheduleform', 
                    itemId: 'scheduleform', anchor: '100%',
                    metaModel: this.metaModel,
                    processId: this.processId
                });

                if(record.data) {
                    var form = this.topPanel.editPanel.getForm();
                    form.setValues(record.data.details);
                    if(record.data.details.weekOn){
                        form.findField('weekOn').setValue(record.data.details.weekOn);
                    }
                    if(record.data.details.dayToRun){
                        form.findField('dayToRun').setValue(record.data.details.dayToRun);
                    }
                }
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.reports.ScheduleListPanel', {
            extend: 'Ext.grid.Panel',
            alias:'widget.spm.report.schedulelistpanel',

            constructor: function (config) {
                var me = this;

                config = Ext.apply({
                    autoScroll: false,
                    columns: [
                        { text: 'SPM Report Name',  dataIndex: 'processName', flex: 1,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: 'Period',  dataIndex: 'period', flex: 1,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } },
                        { text: 'Last Modified', dataIndex: 'lastModified', flex: 1,renderer: function(value) {
                            return Ext.String.htmlEncode(value);
                            } }
                    ],
                    store: {
                        storeId: config.itemId + '_store',
                        fields: config.fields, proxy: { type: 'memory' }
                    },
                    /*selModel: SVMX.create('Ext.selection.CheckboxModel', { 
                        mode: 'SIMPLE'
                    }),*/
                    listeners: {
                        select: function( grid, record, index, eOpts ){
                            //me.__parent.editRecord(record);
                        }
                    }
                }, config || {});
                this.callParent(arguments); 
            }
        });

        Ext.define('com.servicemax.client.spm.ui.desktop.api.schedule.ScheduleForm', {
            extend: 'Ext.form.Panel',
            alias:'widget.spm.schedule.scheduleform',

            layout: 'anchor', padding:10, border: false, autoScroll: true,bodyPadding: 5,
            defaults: { labelAlign: 'top', anchor: '100%', padding:'10px' }, buttonAlign: 'left',

            constructor: function(config){
                config = Ext.apply({
                    
                }, config || {});
                this.callParent(arguments); 
            },

            initComponent: function(){
                this.callParent(arguments);

                var me = this;
                me.TS = { T: function(tagId, val){ return val; } };

                var onStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'weekOn'], 
                    data: [
                        ['Monday', TS.T("TAG036", 'Monday')], 
                        ['Tuesday', TS.T("TAG037",'Tuesday')], 
                        ['Wednesday', TS.T("TAG038",'Wednesday')], 
                        ['Thursday', TS.T("TAG039",'Thursday')], 
                        ['Friday', TS.T("TAG040",'Friday')], 
                        ['Saturday', TS.T("TAG041",'Saturday')], 
                        ['Sunday', TS.T("TAG042",'Sunday')]
                    ]
                });

                var atStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'timeAt'],
                    data: [
                        [1, '12:00 '+ TS.T("TAG072", 'am')], [2, '1:00 '+ TS.T("TAG072", 'am')], [3, '2:00 '+ TS.T("TAG072", 'am')], [4, '3:00 '+ TS.T("TAG072", 'am')], 
                        [5, '4:00 '+ TS.T("TAG072", 'am')], [6, '5:00 '+ TS.T("TAG072", 'am')], [7, '6:00 '+ TS.T("TAG072", 'am')], 
                        [8, '7:00 '+ TS.T("TAG072", 'am')], [9, '8:00 '+ TS.T("TAG072", 'am')], [10, '9:00 '+ TS.T("TAG072", 'am')], [11, '10:00 '+ TS.T("TAG072", 'am')], [12, '11:00 '+ TS.T("TAG072", 'am')], [13, '12:00 '+ TS.T("TAG073", 'pm')], [14, '1:00 '+ TS.T("TAG073", 'pm')], 
                        [15, '2:00 '+ TS.T("TAG073", 'pm')], [16, '3:00 '+ TS.T("TAG073", 'pm')], [17, '4:00 '+ TS.T("TAG073", 'pm')], [18, '5:00 '+ TS.T("TAG073", 'pm')], [19, '6:00 '+ TS.T("TAG073", 'pm')], [20, '7:00 '+ TS.T("TAG073", 'pm')], [21, '8:00 '+ TS.T("TAG073", 'pm')], 
                        [22, '9:00 '+ TS.T("TAG073", 'pm')], [23, '10:00 '+ TS.T("TAG073", 'pm')], [24, '11:00 '+ TS.T("TAG073", 'pm')]
                    ]
                });

                var frequecyStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'period'],
                    data: [
                        ['Daily', TS.T("TAG043", 'Daily')], 
                        ['Weekly', TS.T("TAG044",'Weekly')],
                        ['Monthly', TS.T("TAG045",'Monthly')]
                    ]
                });

                var dayStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'day'],
                    data: [
                        [1, '1'], [2, '2'], [3, '3'], [4, '4'], [5, '5'], 
                        [6, '6'], [7, '7'], [8, '8'], [9, '9'], [10, '10'], 
                        [11, '11'], [12, '12'], [13, '13'], [14, '14'], [15, '15'], 
                        [16, '16'], [17, '17'], [18, '18'], [19, '19'], [20, '20'], 
                        [21, '21'], [22, '22'], [23, '23'], [24, '24'], [25, '25'],
                        [26, '26'], [27, '27'], [28, '28'], [29, '29'], [30, '30'], [31, '31']
                    ]
                });

                var timezoneStore = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'name'],
                    proxy: { type: "memory" },
                    data: me.metaModel.getTimezoneList()
                });

                var fieldSet = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG053",'Choose the times and days to run metric generation engine'),
                    layout: 'anchor', padding:'10'
                });

                me.add( fieldSet );

                var timezone = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'timezone', name: 'timezone', fieldLabel: TS.T("TAG018",'Time Zone'),
                    labelField:'label', valueField:'Id', displayField: 'name', margins: '0 5 0 0',
                    queryMode: 'local', editable: false, anchor: '50%', flex: 1,
                    store: timezoneStore, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var container = fieldSet.add({
                    xtype: 'fieldcontainer', layout: {type: 'hbox', align: 'spaced'},                          
                    anchor: '100%', fieldDefaults: {labelAlign: 'top'},
                });

                fieldSet.add(container);

                container.add( timezone );

                container.add({
                    xtype:'tbspacer',
                    flex:1
                }); 

                container.add({

                    xtype:'label', anchor: '50%', align: 'right', style: "text-decoration: underline !important;",
                    html:'<a href="#" align: "right" style: "text-decoration: underline !important;">' + TS.T("TAG049", 'Run Now') + '</a>', 
                    listeners: {
                        afterRender:function() { 
                            this.el.on('click',function() { 
                                me.metaModel.executeBatch(me.processId, function(result){
                                    if(result){
                                        Ext.Msg.alert( result.success?'Success':'Failed', result.message );
                                    }
                                });
                            });
                        }
                    }
                });
                /*
                container.add({
                        xtype: 'svmx.button', text: TS.T("TAG049", 'Run Now'), align: 'right',
                        anchor: '50%', tooltip: TS.T("TAG015", 'Execute report now'),
                        handler: function(){
                            var me = this.up('form');
                            me.metaModel.executeBatch(me.processId, function(result){
                                if(result){
                                    Ext.Msg.alert( result.success?'Success':'Failed', result.message );
                                }
                            });
                        }
                    });*/

                var period = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'period', name: 'period', fieldLabel: TS.T("TAG017",'Period'),
                    labelField:'period', valueField:'Id', displayField: 'period', defaultValue: 'Daily', value: 'Daily',
                    queryMode: 'local', editable: false, store: frequecyStore, flex: 1, anchor: '30%', labelAlign: 'top', padding:'10',
                    listeners: {              
                        change: function( field, newValue, oldValue ) {
                            switch( newValue ) {
                                case TS.T("TAG043",'Daily'): {
                                    me.__on.reset();
                                    me.__on.setValue( ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'] );
                                    me.__on.hide();
                                    me.__dayToRun.hide();
                                    break;
                                }
                                case TS.T("TAG044",'Weekly'): {
                                    me.__dayToRun.hide();
                                    me.__on.reset();
                                    me.__on.setValue( [TS.T("TAG036",'Monday')] );
                                    me.__on.show();                                  
                                    break;
                                }
                                case TS.T("TAG045",'Monthly') : {

                                    me.__on.reset();
                                    me.__on.hide();
                                    me.__dayToRun.show();
                                }
                            }
                        }
                    },
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                fieldSet.add(period);

                var weekOn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'weekOn', name: 'weekOn', fieldLabel: TS.T("TAG020",'Create Schedule on'),
                    labelField:'label', valueField:'Id', displayField: 'weekOn',
                    queryMode: 'local', editable: false, multiSelect: true, anchor: '30%', flex: 1, 
                    store: onStore, value: 'Monday', hidden: true, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                me.__on = fieldSet.add(weekOn);

                var dayToRun = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'dayToRun', name: 'dayToRun', fieldLabel: TS.T("TAG021",'Day'),
                    labelField:'label', valueField:'Id', displayField: 'day', 
                    queryMode: 'local', editable: false, multiSelect: false, anchor: '30%', flex: 1, 
                    store: dayStore, value: 1, hidden: true, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                me.__dayToRun = fieldSet.add(dayToRun);

                var timeAt = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    itemId: 'timeAt', name: 'timeAt', fieldLabel: TS.T("TAG019",'At'),
                    labelField:'label', valueField:'timeAt', displayField: 'timeAt',
                    queryMode: 'local', editable: false, anchor: '30%', margins: '0 0 0 5', flex: 1,
                    store: atStore, labelAlign: 'top', padding:'10',
                    listConfig: {
                    getInnerTpl: function(displayField) {
                        return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                fieldSet.add(timeAt);

                /*me.add({
                    xtype: 'checkboxfield', 
                    boxLabel  : 'Enable Email Notification',
                    name      : 'enableEmailNotification',
                    listeners: {
                        change: function(ele, val){
                            if(val) email.show(); 
                            else email.hide();
                        }
                    }
                });*/

                var fieldSetNotification = SVMX.create("Ext.form.FieldSet", {
                    title: TS.T("TAG054",'Specify recipients of notifications and alerts'),
                    layout: 'anchor', padding:'10'
                });

                me.add( fieldSetNotification );

                var emailOnSuccess = fieldSetNotification.add({
                    xtype: 'textfield', fieldLabel : TS.T("TAG022",'Email on Job Execution'), name : 'emailOnSuccess',
                    anchor: '50%', labelAlign: 'top', padding:'10', margins: '0 0 0 5'
                });
            }
        }); 
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.spm.ui.desktop\src\status\status.js

(function () {

    var appImpl = SVMX.Package("com.servicemax.client.spm.ui.desktop.api.status");

    appImpl.init = function () {

        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPM");

        Ext.define('com.servicemax.client.spm.ui.status.Status', {
            extend: 'Ext.panel.Panel',
            alias:'widget.spm.status',
            
            title: TS.T("TAG004", "Status"), layout: 'fit',
			cls:'spm-report-config-status',

            initComponent: function() {
                this.callParent(arguments);

                /*var toolbar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    dock: "top"
                });
                
                var searchtext = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                    cls: 'svmx-text-filter-icon',
                    emptyText: 'Search for SPM Report', width: "40%", height: 30, 
                    style: { 
                        marginLeft: '20px', 
                        marginRight: '2px', 
                        marginTop: '0px', 
                        marginBottom: '0px'
                    },

                    listeners: {

                        change: function(f, e) {
                            jobsTable.store.clearFilter();
                            jobsTable.store.filter('reportName',  new RegExp( Ext.escapeRe( searchtext.getValue() ), 'i') );                                    
                        }
                    }
                });
                toolbar.addItemsLeft(searchtext);
                this.addDocked(toolbar);
                */

                var jobsTable = this.add({
                    itemId: this.itemId + '_grid', anchor: '100%', autoScroll: true,
                    xtype: 'gridpanel', title: 'SPM Schedule Jobs',disableSelection: true, header: false,
                    columns: [
                        { text: TS.T("TAG023", "Job"),  dataIndex: 'recordId', flex: 1,
                            renderer: function(val, cmp, rec){
                                return '<a target="_blank" href="{/../../'+val+'">'+rec.get('jobName')+'</a>' 
                            }
                        },
                        //{ text: TS.T("TAG024", "SPM Report"), dataIndex: 'processId', flex: 1, 
                        //    renderer: function(val, cmp, rec) {
                        //        return rec.get('reportName');
                        //    }
                        //},
                        { text: TS.T("TAG025", "Start Time"), dataIndex: 'startTime', flex: 1 },
                        { text: TS.T("TAG026", "End Time"), dataIndex: 'endTime', flex: 1 },
                        { text: TS.T("TAG027", "Job Status"), dataIndex: 'status', align: 'center',
                            renderer : function(value, meta) {
                            if(value.toUpperCase() == 'SUCCESS') {
                                meta.style = "background-color:lightgreen;align:center";
                                value = TS.T("TAG047", "SUCCESS");
                            } else {
                                meta.style = "background-color:#F75D59;";
                                value = TS.T("TAG048", "FAILED")
                            }
                            return value;
                        }
                    },
                        { text: TS.T("TAG028", "Attachment"), dataIndex: 'attachment', flex: 1, 
                            renderer: function(val){
                                //Added if condition for the story BAC-4521
                                //Changed condition for fixing issue BAC-4532 - Contenversion Object keyprefix starts with 068 which represents Salesforce File record
                                if(val && val.startsWith('068')){
                                    return '<a target="_blank" href="{/../../sfc/servlet.shepherd/version/download/'+val+'">'+TS.T("TAG046", "View")+'</a>' 
                                }
                                else{
                                    return '<a target="_blank" href="{/../../servlet/servlet.FileDownload?file='+val+'">'+TS.T("TAG046", "View")+'</a>' 
                                }
                            }
                        }
                    ],
                    store: Ext.create('Ext.data.Store', {
                        storeId: this.itemId + '_store',
                        fields: ['recordId', 'jobName', 'processId', 'reportName', 'startTime', 'endTime', 'status', 'attachment'], 
                        proxy: { type: 'memory' }
                    }),
                }); 
            },

            /*onActivate: function(){
                this.deliveryEngine.getSPMJobs(SVMX.proxy(this, function(data){
                    this.items.get(this.itemId + '_grid').store.loadData(data);
                }));
            },*/

            onActivate: function(){
                this.metaModel.getSPMJobs(this.processId, SVMX.proxy(this, function(data){
                    this.items.get(this.itemId + '_grid').store.loadData(data);
                }));
            }
        });
    }
})();

