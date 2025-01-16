
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleCriteriaBased", {
            extend: 'Ext.form.FormPanel',

            constructor: function(config) {
                config = Ext.apply({
                    title: TS.T("TAG027", "Condition Rules")
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);

                var fieldListStore = Ext.create('Ext.data.Store', {
                    storeId: 'Field_List_Store_CB',
                    fields: ['fieldApiName', 'fieldLabel', 'dataType', 'category', 'attributeType'],
                    groupField: 'category',
                });
                this.__grid = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleGrid", {
                    __fieldStore: fieldListStore
                });
                this.add(this.__grid);
            }
        });

        Ext.define('com.servicemax.client.pmplantemplate.ui.desktop.conditionRuleCriteriaBased.ConditionRuleGrid', {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            xtype: 'cell-editing',
            frame: true,
            __fieldStore: null,
            __rowData: null,
            viewConfig:{
                markDirty:false
            },
            
            initComponent: function() {
                this.fieldCombo = new SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.GroupComboBox",{
                    id: 'fieldComboCmp_CB',
                    typeAhead: true,
                    queryMode: 'local',
                    triggerAction: 'all',
                    selectOnTab: true,
                    store: this.__fieldStore,
                    displayField: 'fieldLabel',
                    valueField: 'fieldApiName',
                    groupField: 'category',
                    editable: false
                });

                var initialOperatorStore = Ext.create('Ext.data.Store', {
                    fields: ['label', 'value', 'type'],
                    data:{'items':[
                        {
                            "label":TS.T("COMM_TAG010", "Equals"), 
                            "value":"eq",
                            "type": "TEXT_PICKLIST"
                        },
                        {
                            "label":TS.T("COMM_TAG011", "Greater Than"), 
                            "value":"gt",
                            "type": ""
                        },
                        {
                            "label":TS.T("COMM_TAG012", "Less Than"), 
                            "value":"lt",
                            "type": ""
                        }
                    ]},
                    proxy: {
                        type: 'memory',
                        reader: {
                            type: 'json',
                            root: 'items'
                        }
                    }
                });
                this.operatorCombo = new Ext.form.field.ComboBox({
                    id: 'operatorComboCmp_CB',
                    typeAhead: true,
                    triggerAction: 'all',
                    queryMode: 'local',
                    selectOnTab: true,
                    displayField: 'label',
                    store: initialOperatorStore,
                    valueField: 'value',
                    editable: false,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            var Fstore = Ext.getStore('Field_List_Store_CB');
                            var recFromStore = Fstore.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                            var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                if(dataTypeForSelectedField === 'TEXT' || dataTypeForSelectedField === 'PICKLIST'){
                                    combo.store.filter('type','TEXT_PICKLIST');
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

                var TA_PA_Store = Ext.create('Ext.data.Store', {
                    storeId: 'TA_PA_Store',
                    fields: ['fieldApiName', 'label', 'value']
                });
                this.TA_PA_Combo = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'TA_PA_ComboCmp',
                    store: TA_PA_Store,
                    queryMode: 'local',
                    displayField: 'label',
                    valueField: 'value',
                    editable: false,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                combo.store.filter('fieldApiName',selectedFieldValue);
                            }
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                    __parent: this,
                    listeners: {
                        beforeedit: function(editor, e){
                            this.__parent.__rowData = e.record.data;
                            var operatorComboCmp = Ext.getCmp('operatorComboCmp_CB');
                            operatorComboCmp.store.clearFilter();

                            var TA_PA_ComboCmp = Ext.getCmp('TA_PA_ComboCmp');
                            TA_PA_ComboCmp.store.clearFilter();
                        },
                        edit: function(editor, e){
                            if(e.field === 'selectedField'){
                                var selectedFieldValue = e.value;
                                var originalSelectedFieldValue = e.originalValue;
                                var dataTypeForOriginalSelectedField = '';
                                var dataTypeForSelectedField = '';
                                var Fstore = Ext.getStore('Field_List_Store_CB');
                                var recFromStore = Fstore.findRecord('fieldApiName',selectedFieldValue, 0, false, true, true);
                                var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                                if(originalSelectedFieldValue !== '' && originalSelectedFieldValue !== null){
                                    recFromStore = Fstore.findRecord('fieldApiName',originalSelectedFieldValue, 0, false, true, true);
                                    dataTypeForOriginalSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                                }

                                if((dataTypeForSelectedField === 'TEXT' || dataTypeForSelectedField === 'PICKLIST') && (dataTypeForOriginalSelectedField !== '' && (dataTypeForOriginalSelectedField === 'NUMBER' || dataTypeForOriginalSelectedField === 'DATE'))) {
                                    e.record.set('selectedOperator','');
                                }
                                else if((dataTypeForSelectedField === 'NUMBER' || dataTypeForSelectedField === 'DATE') && (dataTypeForOriginalSelectedField !== '' && (dataTypeForOriginalSelectedField === 'TEXT' || dataTypeForOriginalSelectedField === 'PICKLIST'))){
                                    e.record.set('selectedOperator','');
                                }

                                if(dataTypeForOriginalSelectedField !== '' && (dataTypeForSelectedField !== dataTypeForOriginalSelectedField)){
                                    e.record.set('value','');
                                }
                                else if(dataTypeForSelectedField === 'PICKLIST' && dataTypeForOriginalSelectedField !== '' && (dataTypeForSelectedField === dataTypeForOriginalSelectedField) && (selectedFieldValue !== originalSelectedFieldValue)){
                                    e.record.set('value','');
                                }
                            }
                        }
                    }
                });

                this.comboBoxRenderer = function(combo) {
                  return function(value) {
                    var idx = combo.store.find(combo.valueField, value);
                    var rec = combo.store.getAt(idx);
                    return ((rec === null || rec === undefined) ? '' : rec.get(combo.displayField) );
                  };
                }
                
                Ext.apply(this, {
                    width: 600,
                    plugins: [this.cellEditing],
                    store: new Ext.data.Store({
                        storeId: 'Condition_Rule_Store_CB',
                        fields: [
                            'isRowHasError',
                            'conditionRuleId',
                            'sequence', 
                            'selectedField',
                            'selectedOperator',
                            'value'
                        ]
                    }),
                    columns: [{
                        xtype: 'actioncolumn',
                        width: 40,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        items: [{
                            iconCls: 'pmplantemplate-delete-row-icon',
                            tooltip: TS.T("TAG029", "Delete"),
                            scope: this,
                            handler: this.onRemoveClick
                        }]
                    }, {
                        header: TS.T("TAG014", "Sequence"),
                        dataIndex: 'sequence',
                        width: 80,
                        sortable: false,
                        menuDisabled: true,
                        align: 'center'
                    }, {
                        header: TS.T("TAG015", "Attribute"),
                        dataIndex: 'selectedField',
                        width: 300,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.fieldCombo,
                        renderer: this.comboBoxRenderer(this.fieldCombo)
                    }, {
                        header: TS.T("TAG016", "Operator"),
                        dataIndex: 'selectedOperator',
                        width: 250,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: this.comboBoxRenderer(this.operatorCombo),
                        __parent: this,
                        getEditor: function(record){
                            var selectedField = record.data.selectedField;
                            if(selectedField !== null && selectedField !== ''){
                                return this.__parent.operatorCombo;
                            }
                        }
                    }, {
                        header: TS.T("TAG063", "Value"),
                        dataIndex: 'value',
                        width: 470,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        __parent: this,
                        renderer: function(value, metaData, record, rowIdx, colIdx, store) {
                            if(value != null && value != ''){
                                var fieldValue = record.data.selectedField;
                                var Fstore = Ext.getStore('Field_List_Store_CB');
                                var recFromStore = Fstore.findRecord('fieldApiName',fieldValue, 0, false, true, true);
                                var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                                if(dataTypeForSelectedField === 'DATE'){
                                    var date = new Date(value);
                                    var month = ("0" + (date.getMonth()+1)).slice(-2);
                                    var day  = ("0" + date.getDate()).slice(-2);
                                    return [month, day, date.getFullYear()].join("-"); 
                                }
                                else{
                                    //return value;
                                    return Ext.String.htmlEncode(value);
                                }
                            }
                            else{
                                return value;
                            }
                        },
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            var Fstore = Ext.getStore('Field_List_Store_CB');
                            var recFromStore = Fstore.findRecord('fieldApiName',fieldValue, 0, false, true, true);
                            var dataTypeForSelectedField = recFromStore && recFromStore.getData().dataType.toUpperCase();
                            if(dataTypeForSelectedField !== null && dataTypeForSelectedField !== ''){
                                if(dataTypeForSelectedField === 'DATE'){
                                    var dateField = Ext.create( 'Ext.form.field.Date', {
                                        format: 'm-d-Y',
                                        value: Ext.Date.dateFormat(record.data.value, 'm-d-Y'),
                                        invalidText: TS.T("COMM_TAG013", "Enter a valid date")
                                    })
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: dateField
                                    });
                                }
                                else if(dataTypeForSelectedField === 'TEXT'){
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Text', {
                                        })
                                    });
                                }
                                else if(dataTypeForSelectedField === 'NUMBER'){
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Number', {
                                            minValue: 0.1,
                                            enableKeyEvents: true,
                                            nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                            listeners: {
                                                keypress: function(field, e) {
                                                    var v = field.getValue();
                                                    if (!Ext.isEmpty(v)) {
                                                        if (/\.\d{2,}/.test(v)) {
                                                            e.stopEvent();
                                                        }
                                                    }
                                                }
                                            }
                                        })
                                    });
                                }
                                else if(dataTypeForSelectedField === 'PICKLIST'){
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: this.__parent.TA_PA_Combo
                                    });
                                }
                            }
                        }
                    }],
                    selModel: {
                        selType: 'cellmodel'
                    },
                    bbar: [{
                        text: '+ ' + TS.T("TAG028", "Add row"),
                        id: 'addRowButton_CB',
                        scope: this,
                        handler: this.onAddClick,
                        cls: 'pmplantemplate-blue-link'
                    }]
                });
                
                this.callParent();
            },
            
            onAddClick: function(button){
                var recCount = this.getStore().getCount();
                var rec = {
                    sequence: recCount+1,
                    isRowHasError : false
                };
                if(recCount < 5){
                    //inserting row in the grid
                    this.getStore().insert(recCount, rec);
                    if(recCount == 4){
                        button.setDisabled(true);
                    }
                }
                Ext.getCmp('buildSampleSchedule').setDisabled(false);
            },
            
            onRemoveClick: function(grid, rowIndex, aa, bb){
                var store = this.getStore();
                store.removeAt(rowIndex);
                var recCount = store.getCount();
                for(var i = rowIndex; i<recCount; i++){
                    var rec = store.getAt(i);
                    rec.set('sequence', i+1);
                }

                var addRowButtonCmp = Ext.getCmp('addRowButton_CB');
                if(recCount < 5 && addRowButtonCmp.isDisabled()){    
                    addRowButtonCmp.setDisabled(false);
                }

                if(recCount === 0){
                    Ext.getCmp('buildSampleSchedule').setDisabled(true);
                }
            }
        })
    }
})();