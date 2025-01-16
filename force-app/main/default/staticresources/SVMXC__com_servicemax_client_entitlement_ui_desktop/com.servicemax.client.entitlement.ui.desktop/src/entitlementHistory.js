(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api.entitlementHistory");

    appImpl.init = function () {
        var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");


        Ext.define("com.servicemax.client.entitlement.ui.desktop.api.EntitlementHistoryPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            autoScroll: true, cls: 'entitlement-root-container',
            id: 'entHisPanel',
            constructor: function(config) {                
                this.callParent([config]);
            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                me.entHisStore =  SVMX.create('Ext.data.Store', {
                    fields:[                    
                        {name: "warrantyOrSconName"}, {name: "warrantyOrSconId"}, {name: "startDate"}, {name: "endDate"},{name: "slaTermName"} ,{name: "slaTermID"} ,{name: "dateOfEntitlement"} ,{name: "coveredBy"},{name: "recordId"} ,{name: "recordName"},
                    ],
                    data: [],
                    storeId: 'entitlementHis_store',
                });

                var entHisGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{
                    autoScroll: true, margin: '5 10', anchor: '100%',
                    store: me.entHisStore,
                    emptyText: ENTITLEMENT.T("TAG095", 'No Entitlement History Available') ,
                    border: false,
                    id:'entHistoryGrid',
                    height : 330,
                    viewConfig: { 
                        deferEmptyText: false, 
                    },
                    columns : [ 
                        { flex: 1, text: ENTITLEMENT.T("TAG017", 'Entitlement History')  , dataIndex: 'recordName', resizable: true, readOnly: true, sortable: true,
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.recordName != null){
                                    return '<a class="entHistoryRecord" href="#">'+ record.data.recordName+ '</a>';
                                }
                                else{
                                    return " "; 
                                }
                            }
                        },  
                        { flex: 1, text: ENTITLEMENT.T("TAG045", 'Warranties/Service Contracts'), dataIndex: 'warrantyOrSconName', resizable: true, readOnly: true, sortable: true,
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.warrantyOrSconName != null){
                                    return '<a class="sconWarrantyRecord" href="#">'+ Ext.String.htmlEncode(record.data.warrantyOrSconName)+ '</a>';
                                }
                                else{
                                    return " "; 
                                }
                            }
                        },   
                        { flex: 1, text: ENTITLEMENT.T('TAG055', 'SLA Terms') , dataIndex: 'slaTermName', align: 'center', resizable : false, readOnly: true,sortable: true, 
                            renderer: function(value, md, record, row, col, store) {
                                if(record.data.slaTermName != null){
                                    return '<a class="slaRecord" href="#">'+ Ext.String.htmlEncode(record.data.slaTermName)+ '</a>';
                                }
                                else{
                                    return " "; 
                                }
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG052', 'Start Date') , dataIndex: 'startDate', align: 'center', resizable : false, readOnly: true, sortable: true,
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG053', 'End Date') , dataIndex: 'endDate', align: 'center', resizable : false,readOnly: true,sortable: true,
                        },
                        { flex: 1, text: ENTITLEMENT.T('TAG096', 'Date of Entitlement')  , dataIndex: 'dateOfEntitlement', align: 'center', resizable : false,readOnly: true, hidden: true, sortable: true
                        },
                    ],
                    listeners: {
                        cellclick: function(grid, td, cellIndex, record, tr, rowIndex, e) {

                            var rowRecord = grid.store.getAt(rowIndex);
                            e.preventDefault();

                            if (e.getTarget('a.entHistoryRecord')) {
                                me.__parent.findDuplicateTab(Ext.getCmp('selectionWindowTab'), Ext.getCmp('entitlementSelection'), record.data.recordName, record.data.recordId);
                            }

                            if (e.getTarget('a.sconWarrantyRecord')){
                                me.__parent.findDuplicateTab(Ext.getCmp('selectionWindowTab'), Ext.getCmp('entitlementSelection'), record.data.warrantyOrSconName, record.data.warrantyOrSconId);
                            }

                            if (e.getTarget('a.slaRecord')){
                                me.__parent.findDuplicateTab(Ext.getCmp('selectionWindowTab'), Ext.getCmp('entitlementSelection'), record.data.slaTermName, record.data.slaTermID);
                            }
                        },
                    }
                    
                });
                me.add(entHisGrid); 

                var entHisToolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    border: false
                });
            },
            callEntHisWebservice: function(){
                var me = this;
                var entHisConfig ={};
                entHisConfig.headerId = me.__parentRecordID;
                var entitlementHistoryList = me.__engine.getEntitlementHistory(entHisConfig, function (result){
                    if(result.headerRecord.entitlementHistoryMap != null){
                        me.loadEntHis(result.headerRecord.entitlementHistoryMap[entHisConfig.headerId]); 
                    }
                }); 
            },
            loadEntHis : function(data){
                if(this.__parent.__parent.__showDetailView){
                    var serviceContractGridTable = Ext.getCmp('entHistoryGrid');
                    serviceContractGridTable.down('[dataIndex=slaTermName]').hide();
                }
                this.entHisStore.loadData(data);
            }
        });
    }
})();