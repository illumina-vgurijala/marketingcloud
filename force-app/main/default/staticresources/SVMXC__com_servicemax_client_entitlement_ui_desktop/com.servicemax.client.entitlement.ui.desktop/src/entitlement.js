(function () {

    var appImpl = SVMX.Package("com.servicemax.client.entitlement.ui.desktop.api.entitlement");

    appImpl.init = function () {

		var ENTITLEMENT = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("ENTITLEMENT");

        Ext.define("com.servicemax.client.entitlement.ui.desktop.api.EntitlementPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            width:'100%' , height: '100%',border: false,
            id:'workDetailPannel',

            constructor: function(config) {                
                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);

                var me = this;
                /* <----------- Start of Work Order/ Work Detail Entitlement Info ---------> */
                Ext.define('DetailLines',{
                    extend: 'Ext.data.Model',
                    fields:[                    
                        {name: "selectEntitlementName"}, {name: "productName"}, {name: "recordName"}, {name: "installedBaseName"}, {name: 'description'}, {name: "selectedEntitlementInfo", type: 'object'}, {name: "updatedEntitlementInfo", type: 'object'}, {name: "recordID"}, {name: 'entitlementPerformed'},{name: "listEntitlementInfo", type: 'object'}
                    ]
                });

                var entitlementSelectionWindow = this.__entitlementSelectionWindow = SVMX.create('Ext.window.Window', {
                    id: 'entitlementSelectionWindow',
                    layout: 'anchor', border: false,
                    title: ENTITLEMENT.T('TAG072', 'Select Warranty/Contract'), header: { 
                        titleAlign: 'center',
                    }, closable:true,
                    hidden: true, 
                    closeAction: 'hide', 
                    width: '60%',
                    __parentWin: me, 
                    resizable: false, 
                    overflowY: 'auto', 
                    cls: 'entitlement-root-container',
                    listeners:{
                        beforehide: function(thisWindow, eOpts ){
                            var allTabPannels = Ext.getCmp('selectionWindowTab');
                            // Set focus on tab 0- Entitlement Selection
                            allTabPannels.items.items[0].setVisible(true);

                            // Reset Entitlement History Tab
                            Ext.getCmp('entHisPanel').loadEntHis([]);

                            //Remove All tabs except Entitlement Selection & Entitlement History
                            allTabPannels.items.each(function(item,j){
                                if(j != 0 && j != 1){
                                    allTabPannels.remove(item);
                                }
                            });
                        },
                        hide: function(thisWindow, eOpts){
                            thisWindow.hide();
                            Ext.getCmp('selectEntBtn').setDisabled(true);
                            thisWindow.__parentWin.enable();
                        }
                    }
                });

                me.add(entitlementSelectionWindow);

                var entitlementWindowActions = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    border: false, 
                    style : 'margin-top: 20px', 
                }); 

                var tabFill3 = SVMX.create("Ext.Toolbar.Fill",{ });
                entitlementWindowActions.add(tabFill3);

                var saveEntitlementWindowBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG021", 'Select'), //Icon Class for lookup button,
                    id: 'selectEntBtn',
                    disabled: true,
                    scale: 'medium',
                    height: 30, 
                    handler: function(button, e) {
                        var selectedPSEntitlement = {};
                        var selectionPSWindow = Ext.getCmp('entitlementSelection');
                        selectedPSEntitlement.recordID = selectionPSWindow.__parentData.recordID;
                        selectedPSEntitlement.entitlementInfo  = selectionPSWindow.__selectedEntitlement;
                        selectionPSWindow.__parentData.selectedPSEntitlement  = selectedPSEntitlement;
                        selectionPSWindow.__selectedEntitlement = null;
                        // Enable Save to Database
                        var saveEnttoDatabase = Ext.getCmp('saveEnttoDatabase');
                        saveEnttoDatabase.setDisabled(false);
                        button.setDisabled(true);
                        entitlementSelectionWindow.hide();
                        entitlementSelectionWindow.__parentWin.enable();

                        var selectedWorkDetail = entitlementSelectionWindow.__workdetailSelected ;
                        selectedWorkDetail.set('updatedEntitlementInfo', selectionPSWindow.__parentData.selectedPSEntitlement.entitlementInfo);
                        selectedWorkDetail.store.fireEvent('refresh');
                    }
                });

                /*var cancelEntitlementWindowBtn = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXButton', {
                    text: ENTITLEMENT.T("TAG063", 'Cancel'), //Icon Class for lookup button,
                    scale: 'medium',
                    height: 30, 
                    handler: function(button,e) {
                        entitlementSelectionWindow.hide();
                        Ext.getCmp('selectEntBtn').setDisabled(true);
                        entitlementSelectionWindow.__parentWin.enable();
                    }
                });

                entitlementWindowActions.add(cancelEntitlementWindowBtn);*/
                entitlementWindowActions.add(saveEntitlementWindowBtn);
                

                var itemsPerPage = 20;
                me.workDetailstore =  SVMX.create('Ext.data.Store', {
                    model: 'DetailLines',
                    data: [],
                    storeId: 'entitlement_store',
                    autoLoad: false, 
                    pageSize: itemsPerPage,
                    proxy: {
                        type: 'memory',
                        reader: {type: 'array', root : 'data', totalProperty : 'total'}
                    },
                    allData:[],
                    listeners : {
                        beforeload : function(store, operation, eOpts){

                            var data=this.allData||[];
                            
                            var page = operation.start;
                            var limit = operation.limit;  

                            var pagedData=data.slice(page,page+limit);

                            var pagedModelData=[];
                            for(var i=0;i<pagedData.length;i++)
                            {
                                var entObj=Ext.create('DetailLines',pagedData[i]);
                                pagedModelData.push(entObj);
                            }

                            store.proxy.data ={ 
                                data: pagedModelData,
                                total : data.length,
                            };
                        }
                    }
                });

                // cls: 'borderless', 
                var workDetailGrid = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXListComposite',{               
                    autoScroll: true, maxHeight:450, margin: '5 10', anchor: '100%',
                    store: me.workDetailstore,
                    border: false,
                    emptyText: ENTITLEMENT.T("TAG077", 'No valid Products Serviced lines to display'),
                    viewConfig: { 
                        deferEmptyText: false,
                    },
                    columns : [  
                        { xtype: 'rownumberer', text: ENTITLEMENT.T("TAG080", 'No.') , align: 'left', flex:1/5},                   
                        { flex: 1, text: ENTITLEMENT.T("TAG045", 'Warranties/Service Contracts'), dataIndex: 'selectEntitlementName', align: 'left', resizable: true, readOnly: true, 
                            renderer: function(value, md, record, row, col, store) {
                                var displayVal = '';
                                if(record.data.updatedEntitlementInfo != '' && record.data.updatedEntitlementInfo != undefined){
                                    displayVal = record.data.updatedEntitlementInfo.recordName != undefined ? record.data.updatedEntitlementInfo.recordName: ENTITLEMENT.T('TAG068', 'Not Covered'); 
                                    md.tdCls = 'svmx-ent-uncommitedChanges';
                                }
                                else{
                                    if((record.data.selectedEntitlementInfo != null && record.data.selectedEntitlementInfo != undefined) && record.data.entitlementPerformed) {
                                        if(record.data.selectedEntitlementInfo.warrantyOrScon == 'notcovered'){
                                            md.tdCls= 'svmx-ent-notCovered';  
                                            displayVal = ENTITLEMENT.T('TAG068', 'Not Covered');
                                        }
                                        else{
                                            displayVal = record.data.selectedEntitlementInfo.recordName != null?  record.data.selectedEntitlementInfo.recordName : record.data.selectedEntitlementInfo.warrantyTermName;
                                        }
                                    }
                                    else{
                                        md.tdCls= 'svmx-ent-emptytext';
                                        md.style = 'font-style: italic !important'; 
                                        displayVal = ENTITLEMENT.T("TAG081", 'Select for Contract/Warranty options');
                                    }  
                                }
                                return Ext.String.htmlEncode(displayVal);
                            }
                        },   
                        { flex: 1, text: ENTITLEMENT.T("TAG073", 'Product'), dataIndex: 'productName', align: 'left', resizable : false, readOnly: true, sortable: true, 
                            renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T("TAG074", 'Installed Product'), dataIndex: 'installedBaseName', align: 'left', resizable : false, readOnly: true, sortable: true,
                        renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        },
                        { flex: 1, text: ENTITLEMENT.T("TAG075", 'Description') , dataIndex: 'description', align: 'left', resizable: false, readOnly: true, sortable: false,
                        renderer: function(value, md, record, row, col, store) {
                                 return Ext.String.htmlEncode(value);
                            }
                        }
                        
                    ],
                    dockedItems: [{
                        xtype: 'pagingtoolbar',
                        store: me.workDetailstore,   // same store GridPanel is using
                        dock: 'bottom',
                        displayInfo: false,
                        layout: {pack: 'center'},
                        beforePageText : ENTITLEMENT.T("TAG079", 'Page'),
                        listeners: {
                            afterrender : function() {
                                this.child('#refresh').hide();
                            }
                        }
                    }],
                    listeners: {
                        cellclick: function( grid, td, cellIndex, record, tr, rowIndex, e ) {                                
                            entitlementSelectionWindow.add(me.__parent.showEntitlementSelectionPanel(entitlementSelectionWindow, record));
                            entitlementSelectionWindow.add(entitlementWindowActions); 
                            entitlementSelectionWindow.show(); 
                            entitlementSelectionWindow.__parentWin.disable();
                        }
                    }
                });
                me.add(workDetailGrid);  
            },
            loadData: function(data) {
                this.workDetailstore.allData=data;
                this.workDetailstore.loadPage(1);
            },
        });
    }
})();


