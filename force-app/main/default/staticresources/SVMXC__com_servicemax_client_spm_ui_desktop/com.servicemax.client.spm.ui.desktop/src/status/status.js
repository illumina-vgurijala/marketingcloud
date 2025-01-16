
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