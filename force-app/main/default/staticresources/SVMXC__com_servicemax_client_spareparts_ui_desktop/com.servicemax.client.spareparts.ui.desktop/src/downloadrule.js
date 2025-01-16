(function () {
    var appImpl = SVMX.Package("com.servicemax.client.spareparts.ui.desktop.downloadrule");

    appImpl.init = function () {
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("SPAREPARTS");


        Ext.define("com.servicemax.client.spareparts.ui.desktop.downloadrule.DownloadrulePanel", {
            extend: 'Ext.form.FormPanel',
            id: 'downloadrule',
            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG024", "Download Criteria")
                },
                config || {});

                this.callParent([config]);
            },
            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                // Need to update Work Order Purpose List
                this.__downloadCriteriaGrid = SVMX.create("com.servicemax.client.spareparts.ui.desktop.downloadRule.CriteriaGrid", {
                });
                me.add(this.__downloadCriteriaGrid);
            },
            loadData: function(productStatusData, quantityData, griddata ){
                // Load Schedule Grid
                Ext.getCmp('addRowButton').setDisabled(false);   
                var productStatusStore = Ext.getStore('productStockStatus');
                productStatusStore.loadData(productStatusData);

                var quantityStore = Ext.getStore('quantityFields');
                quantityStore.loadData(quantityData);

                var downloadCriteria_store = Ext.getStore('downloadCriteria_store');
                if(griddata == null || griddata == ''){
                    griddata = []; 
                    /*var firstRow= {};
                    firstRow.includeserializedstock = false; 
                    firstRow.productstockstatus = '';
                    firstRow.quantityfield = '';
                    griddata.push(firstRow);*/
                }

                downloadCriteria_store.loadData(griddata);

                // Disbale Add Row button, when length of status picklist values == number of records
                if(productStatusData.length != griddata.length ){
                    Ext.getCmp('addRowButton').setDisabled(false);    
                }
            }
    
        });

        
        Ext.define('com.servicemax.client.spareparts.ui.desktop.downloadRule.CriteriaGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            viewConfig:{
                markDirty:false
            },
            initComponent: function() {

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                    listeners: {
                        beforeedit: function(editor, e){
                            //This should work only on 1st column
                            var stockStatusStore = Ext.getStore('productStockStatus');
                            stockStatusStore.clearFilter();
                            if(e.colIdx == 1){
                                // reset all product stock status to default value
                                stockStatusStore.data.items.forEach(function(obj, rowVal){
                                    obj.data.isUsed = false;
                                });

                                var rowIndx = e.rowIdx;
                                // Get the spare parts Grid Store
                                var gridCmp = Ext.getCmp('sparePartsGrid').getStore().data.items;
                                
                                gridCmp.forEach(function(obj, rowVal){
                                    if(rowVal != rowIndx){
                                        var index = stockStatusStore.findExact('Id', obj.data.productstockstatus);
                                        if(index != -1){
                                            // Update Store with value isUsed
                                            stockStatusStore.getAt(index).data.isUsed = true;  
                                        }
                                    }
                                })
                            }
                        },
                    }
                });

                var productStockStatusStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}, {name: 'isUsed'}],
                    id: 'productStockStatus',
                    proxy: {
                        type: "memory"
                    }
                });

                this.productStockCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    typeAhead: true,
                    editable: false,
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: productStockStatusStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                    listeners: {
                        expand : function(combo){
                            // Get Spare Parts Grid records 
                            combo.store.filter('isUsed',false);
                        }
                    }
                });

                var quantityFieldsStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    id: 'quantityFields',
                    proxy: {
                        type: "memory"
                    }
                });

                this.quantityFieldCombo = new Ext.form.field.ComboBox({
                    typeAhead: false,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    editable: false,  // Anchal, Fix for defect - BAC-2941. Making all picklist Select non-editable
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: quantityFieldsStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var serializedStore = SVMX.create('Ext.data.Store', {
                    fields: [{name: 'Id'}, {name: 'name'}],
                    id: 'serializedStore',
                    proxy: {
                        type: "memory"
                    },
                    data: [
                        {
                            Id : true,
                            name: TS.T("TAG025", "Yes")
                        },
                        {
                            Id : false,
                            name: TS.T("TAG026", "No")
                        }
                    ]
                });

                this.serializedCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    displayField: 'name',
                    valueField: 'Id',
                    queryMode: 'local',
                    typeAhead: false,
                    editable: false, // Anchal, Fix for defect - BAC-2941. Making all picklist Select non-editable
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: serializedStore,
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.picklistRenderer = function(combo) {
                    return function(value) {
                        var idx = combo.store.find(combo.valueField, value);
                        var rec = combo.store.getAt(idx);
                        return ((rec === null || rec === undefined) ? '' : Ext.String.htmlEncode(rec.get(combo.displayField)));
                    };
                }

                
                Ext.apply(this, {
                    width: '60%',
                    autoScroll: true,
                    margin: '5',
                    plugins: [this.cellEditing],
                    id:'sparePartsGrid', 
                    cls: 'spareparts-download-criteria',
                    store: new Ext.data.Store({
                        storeId: 'downloadCriteria_store',
                        fields: [
                            'productstockstatus', 
                            'quantityfield',
                            'includeserializedstock',
                        ],
                    }),
                    columns: [
                            {
                            xtype: 'actioncolumn',
                            width: 40,
                            height: 40,
                            align: 'center',
                            sortable: false,
                            menuDisabled: true,
                            items: [{
                                //icon: 'extjs/examples/shared/icons/fam/cog_edit.png',
                                tooltip: TS.T("TAG027", "Delete"),
                                scope: this,
                                //height: 40,
                                iconCls: 'spareparts-delete-row-icon',
                                cls: 'spareparts-delete-row-icon',
                                handler: this.onRemoveClick
                            }]
                        },
                        { flex: 1, text: TS.T("TAG028", 'Product Stock Status'), dataIndex: 'productstockstatus', align: 'left', resizable: true, readOnly: true, editor: this.productStockCombo, renderer: this.picklistRenderer(this.productStockCombo)}, 
                        { flex: 1, text: TS.T("TAG029", 'Quantity'),dataIndex: 'quantityfield', align: 'left', resizable: true, readOnly: true, editor: this.quantityFieldCombo, renderer: this.picklistRenderer(this.quantityFieldCombo)}, 
                        { flex: 1, text: TS.T("TAG030", 'Include Serialized Stocks'), dataIndex: 'includeserializedstock', align: 'left', resizable: true, readOnly: true, editor: this.serializedCombo, renderer: this.picklistRenderer(this.serializedCombo)}, 
                    ],
                    selModel: {
                        selType: 'cellmodel'
                    },
                    bbar: [{
                        text: '+ ' + TS.T("TAG031", "Add Row"),
                        id: 'addRowButton',
                        scope: this,
                        disabled: true,
                        handler: this.onAddClick,
                        cls: 'spareparts-blue-link'
                    }]
                });
                this.callParent();
                
            },
            onAddClick: function(button){
                var recCount = this.getStore().getCount();
                // Before Adding new row to the Grid, check previous mandatory field
                var gridCmp = Ext.getCmp('sparePartsGrid');

                var lastGridRecord = this.getStore().getAt(recCount -1);

                if(lastGridRecord != null && lastGridRecord != ''){
                    if(lastGridRecord.data.productstockstatus == ''){
                        var classAttr = gridCmp.getNode(recCount-1).childNodes[1].getAttribute('class');
                        gridCmp.getNode(recCount-1).childNodes[1].setAttribute('class', classAttr+ ' make-cell-dirty-lt');
                        gridCmp.getNode(recCount-1).childNodes[1].setAttribute('data-qtip', TS.T("TAG032", "This is a required field."));
                    }
                    else{
                        
                        // Before adding new record see, if record count is 1 less than Product Stock Status
                        var stockStatusStore = Ext.getStore('productStockStatus'); 
                        stockStatusStore.clearFilter();
                        var productStockStatusCount = stockStatusStore.getCount();
                        if(recCount < productStockStatusCount){
                            var rec = {
                                productstockstatus: '',
                                quantityfield : '',
                                includeserializedstock: false
                            };
                            this.getStore().insert(recCount, rec); 

                            // Now disable the Add button
                            if(recCount == productStockStatusCount-1){
                                button.setDisabled(true);
                            }
                        }
                    }
                }
                else{
                    var recBlank =   {
                                    productstockstatus: '',
                                    quantityfield : '',
                                    includeserializedstock: false
                                };
                    this.getStore().insert(recCount, recBlank);  
                }
            },
            onRemoveClick: function(grid, rowIndex, aa, bb){
                var store = this.getStore();
                store.removeAt(rowIndex);    
               
                // Enable button all time 
                Ext.getCmp('addRowButton').setDisabled(false);
            }
            
        });

    }
})();