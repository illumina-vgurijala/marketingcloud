
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