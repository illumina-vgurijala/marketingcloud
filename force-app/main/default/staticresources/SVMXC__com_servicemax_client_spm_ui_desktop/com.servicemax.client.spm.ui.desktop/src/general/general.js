
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