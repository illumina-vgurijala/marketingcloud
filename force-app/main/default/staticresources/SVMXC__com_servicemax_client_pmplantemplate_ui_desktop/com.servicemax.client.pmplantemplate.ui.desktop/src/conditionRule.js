
(function(){
    var impl = SVMX.Package("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("PMPLAN");

        Ext.define("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRule", {
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
                    storeId: 'Field_List_Store',
                    fields: ['fieldApiName', 'fieldLabel', 'dataType', 'category', 'attributeType'],
                    groupField: 'category',
                });
                this.__grid = SVMX.create("com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRuleGrid", {
                    __fieldStore: fieldListStore
                });
                this.add(this.__grid);
            }
        });

        Ext.define('com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.GroupComboBox', {
            extend: 'com.servicemax.client.ui.components.controls.impl.SVMXPicklist',
            groupField: 'group',
            listConfig: {
                cls: 'grouped-list',
                getInnerTpl: function(displayField) {
                    return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                }
            },
            initComponent: function() {
                var me = this;
                me.tpl = new Ext.XTemplate([
                    '{[this.currentGroup = null]}',
                    '<tpl for=".">',
                    '   <tpl if="this.shouldShowHeader('+me.groupField+')">',
                    '       <div class="group-header">{[this.showHeader(values.'+me.groupField+')]}</div>',
                    '   </tpl>',
                    '   <div class="svmx-boundlist-item">{'+me.displayField+'}</div>',
                    '</tpl>',
                    {  
                        shouldShowHeader: function(group){
                            return this.currentGroup != group;
                        },
                        showHeader: function(group){
                            this.currentGroup = group;
                            return group;
                        }
                    }
                ]);
                me.callParent(arguments);
            }
        });

        Ext.define('com.servicemax.client.pmplantemplate.ui.desktop.conditionRule.ConditionRuleGrid', {
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
                    id: 'fieldComboCmp',
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
                            "label":TS.T("TAG032", "Every"), 
                            "value":"EYI",
                            "type": "Date"
                        },
                        {
                            "label":TS.T("TAG033", "Every decrement"), 
                            "value":"EYD",
                            "type": "Number"
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
                    id: 'operatorComboCmp',
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
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                if(selectedFieldValue === 'Months' || selectedFieldValue === 'Weeks' || selectedFieldValue === 'Years'){
                                    combo.store.filter('type','Date');
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

                this.adjustmentTypeCombo = new Ext.form.field.ComboBox({
                    typeAhead: true,
                    triggerAction: 'all',
                    selectOnTab: true,
                    editable: false,
                    queryMode: 'local',
                    store: [
                        ['None',TS.T("COMM_TAG004", "--None--")],
                        ['Actual',TS.T("TAG038", "Actual")],
                        ['Fixed',TS.T("TAG039", "Fixed")]
                    ],
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                var initialAdjustmentUnitStore = Ext.create('Ext.data.Store', {
                    fields: ['label', 'value', 'type'],
                    data:{'items':[
                        {
                            "label":TS.T("TAG040", "Days"), 
                            "value":"Days",
                            "type": "Date"
                        },
                        {
                            "label":TS.T("TAG034", "Count"), 
                            "value":"Count",
                            "type": "Number"
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

                this.adjustmentUnitCombo = new Ext.form.field.ComboBox({
                    id: 'adjustmentUnitComboCmp',
                    displayField: 'label',
                    valueField: 'value',
                    queryMode: 'local',
                    typeAhead: true,
                    triggerAction: 'all',
                    selectOnTab: true,
                    editable: false,
                    store: initialAdjustmentUnitStore,
                    __parent: this,
                    listeners: {
                        expand : function(combo){
                            var selectedFieldValue = combo.__parent.__rowData.selectedField;
                            if(selectedFieldValue !== null && selectedFieldValue !== ''){
                                if(selectedFieldValue === 'Months' || selectedFieldValue === 'Weeks' || selectedFieldValue === 'Years'){
                                    combo.store.filter('type','Date');
                                }
                                else{
                                    combo.store.filter('type','Number');
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

                this.cellEditing = new Ext.grid.plugin.CellEditing({
                    clicksToEdit: 1,
                    __parent: this,
                    listeners: {
                        beforeedit: function(editor, e){
                            this.__parent.__rowData = e.record.data;
                            var adjustmentUnitComboCmp = Ext.getCmp('adjustmentUnitComboCmp');
                            adjustmentUnitComboCmp.store.clearFilter();

                            var operatorComboCmp = Ext.getCmp('operatorComboCmp');
                            operatorComboCmp.store.clearFilter();
                        },
                        edit: function(editor, e){
                            if(e.field === 'selectedAdjustmentType' && (e.value === 'None') && (e.value !== e.originalValue)){
                                e.record.set('minAdjustment','');
                                e.record.set('maxAdjustment','');
                                e.record.set('adjustmentVal','');
                                e.record.set('selectedAdjustedUnit','');
                            }

                            if(e.field === 'selectedAdjustmentType' && (e.value === 'Actual') && (e.value !== e.originalValue)){
                                e.record.set('adjustmentVal','');
                            }

                            if(e.field === 'selectedField'){
                                if((e.value === 'Weeks' || e.value === 'Months' || e.value === 'Years') && (e.originalValue !== '' && e.originalValue !== 'Weeks' && e.originalValue !== 'Months' && e.originalValue !== 'Years')){
                                    e.record.set('startAt','');
                                    e.record.set('stopAt','');
                                    e.record.set('threshold','');
                                    e.record.set('frequency','');
                                    e.record.set('selectedOperator','');
                                    e.record.set('selectedAdjustedUnit','');
                                }
                                else if((e.value !== 'Weeks' && e.value !== 'Months' && e.value !== 'Years') && (e.originalValue !== '' && (e.originalValue === 'Weeks' || e.originalValue === 'Months' || e.originalValue === 'Years'))){
                                    e.record.set('startAt','');
                                    e.record.set('stopAt','');
                                    e.record.set('frequency','');
                                    e.record.set('selectedOperator','');
                                    e.record.set('selectedAdjustedUnit','');
                                }
                            }

                            //Setting required field error message column 7 when operator is Every
                            if(e.record.data.selectedOperator == 'EYI' && (e.record.data.stopAt === '' || e.record.data.stopAt === null)){
                                var editedCell = e.row.childNodes[7]; //Stop At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG041", "This is a required field."));
                                }
                            }

                            //Setting required field error message column 5 when operator is Every decrement
                            if(e.record.data.selectedOperator == 'EYD' && (e.record.data.startAt === '' || e.record.data.startAt === null)){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG041", "This is a required field."));
                                }
                            }

                            //Setting required field error message column 11 when Adjustment type: Change from Actual to Fixed
                            if(e.record.data.selectedAdjustmentType === 'Fixed' && (e.record.data.adjustmentVal === '' || e.record.data.adjustmentVal === null)){
                                var editedCell = e.row.childNodes[11]; //Adjustment value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG041", "This is a required field."));
                                }
                            }
                            else if(e.record.data.selectedAdjustmentType !== 'Fixed'){ //removing error class
                                var editedCell = e.row.childNodes[11]; //Adjustment value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') !== -1){
                                    editedCell.firstChild.setAttribute('class', classAttr.replace('make-cell-dirty','').trim());
                                }
                            }

                            //Setting error message for column 7 when stopAt less than startAt and Unit is Weeks OR Months OR Years OR Count
                            if(e.record.data.selectedOperator == 'EYI' && (e.record.data.startAt !== '' && e.record.data.startAt !== null) && (e.record.data.stopAt !== '' && e.record.data.stopAt !== null)){
                                var stopAtLessThanstartAt = false;
                                if((e.record.data.selectedField === 'Months' || e.record.data.selectedField === 'Weeks' || e.record.data.selectedField === 'Years') && e.record.data.stopAt < e.record.data.startAt){
                                    stopAtLessThanstartAt = true;
                                }
                                else if((e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Years') && parseFloat(e.record.data.stopAt) < parseFloat(e.record.data.startAt)){
                                    stopAtLessThanstartAt = true;
                                }
                                if(stopAtLessThanstartAt){
                                    var editedCell = e.row.childNodes[7]; //Stop At column
                                    var classAttr = editedCell.firstChild.getAttribute('class');
                                    if(classAttr.indexOf('make-cell-dirty') === -1){
                                        editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                        editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG042", "Stop At cannot be less than Start At."));
                                    }
                                }
                            }

                            //Setting error message for column 5 when stopAt greater than startAt and Unit is Count
                            if((e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Years') && e.record.data.selectedOperator == 'EYD' && (e.record.data.startAt !== '' && e.record.data.startAt !== null) && (e.record.data.stopAt !== '' && e.record.data.stopAt !== null) && parseFloat(e.record.data.stopAt) > parseFloat(e.record.data.startAt)){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                if(classAttr.indexOf('make-cell-dirty') === -1){
                                    editedCell.firstChild.setAttribute('class',classAttr+' make-cell-dirty ');
                                    editedCell.firstChild.setAttribute('data-qtip', TS.T("TAG043", "Start At cannot be less than Stop At."));
                                }
                            }

                            //Removing error message when unit is Any value
                            if(e.record.data.selectedField !== null && e.record.data.selectedField !== ''){
                                var editedCell = e.row.childNodes[7]; //Stop At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                var qtipAtrr = editedCell.firstChild.getAttribute('data-qtip');
                                if(classAttr.indexOf('make-cell-dirty') === -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    editedCell.firstChild.removeAttribute('data-qtip');
                                }
                            }

                            //Removing error message when field is not date based
                            if(e.record.data.selectedField !== 'Weeks' && e.record.data.selectedField !== 'Months' && e.record.data.selectedField !== 'Years'){
                                var editedCell = e.row.childNodes[5]; //Start At column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                var qtipAtrr = editedCell.firstChild.getAttribute('data-qtip');
                                if(classAttr.indexOf('make-cell-dirty') === -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    editedCell.firstChild.removeAttribute('data-qtip');
                                }
                            }

                            //Removing error message when Adjustment Value column has value and AdjustmentType === 'Fixed'
                            if(e.record.data.selectedAdjustmentType === 'Fixed' && (e.record.data.adjustmentVal !== '' && e.record.data.adjustmentVal !== null)){
                                var editedCell = e.row.childNodes[11]; //Adjustment Value column
                                var classAttr = editedCell.firstChild.getAttribute('class');
                                var qtipAtrr = editedCell.firstChild.getAttribute('data-qtip');
                                if(classAttr.indexOf('make-cell-dirty') === -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    editedCell.firstChild.removeAttribute('data-qtip');
                                }
                            }

                            //Code to First column dirty state based on Column 5 and 7 and 11
                            var editedCellMakeDirty;
                            var editedClassAttr;
                            var makeFirstColDirty = false;
                            
                            var editedCellFifth = e.row.childNodes[5]; //Start At column
                            var classAttrFifth = editedCellFifth.firstChild.getAttribute('class');
                            if(classAttrFifth.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellFifth;
                                editedClassAttr = classAttrFifth;
                            }
                            
                            var editedCellSeventh = e.row.childNodes[7]; //Stop At column
                            var classAttrSeventh = editedCellSeventh.firstChild.getAttribute('class');
                            if(classAttrSeventh.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellSeventh;
                                editedClassAttr = classAttrSeventh;
                            }
                            
                            var editedCellEleventh = e.row.childNodes[11]; //Adjustment Value column
                            var classAttrEleventh = editedCellEleventh.firstChild.getAttribute('class');
                            if(classAttrEleventh.indexOf('make-cell-dirty') !== -1){
                                makeFirstColDirty = true;
                                editedCellMakeDirty = editedCellEleventh;
                                editedClassAttr = classAttrEleventh;
                            }
                            if(makeFirstColDirty){
                                e.record.set('isRowHasError',true);
                                editedCellMakeDirty.firstChild.setAttribute('class',editedClassAttr.replace('make-cell-dirty','').trim());
                                editedCellMakeDirty.firstChild.setAttribute('class',editedCellMakeDirty.firstChild.getAttribute('class')+' make-cell-dirty ');

                                var firstColumnCell = e.row.childNodes[0];
                                var firstClassAttr = firstColumnCell.firstChild.getAttribute('class');
                                if(firstClassAttr.indexOf('make-cell-dirty') === -1){
                                    firstColumnCell.firstChild.setAttribute('class',firstClassAttr+' make-cell-dirty ');
                                    firstColumnCell.firstChild.setAttribute('data-qtip', TS.T("TAG044", "This row has one or more issues. Please correct before proceeding"));
                                }
                            }
                            else{
                                e.record.set('isRowHasError',false);
                                var firstColumnCell = e.row.childNodes[0];
                                var firstClassAttr = firstColumnCell.firstChild.getAttribute('class');
                                var qtipAtrr = firstColumnCell.firstChild.getAttribute('data-qtip');
                                if(firstClassAttr.indexOf('make-cell-dirty') !== -1 && qtipAtrr !== null && qtipAtrr.length > 0){
                                    firstColumnCell.firstChild.removeAttribute('data-qtip');
                                    firstColumnCell.firstChild.setAttribute('class',firstClassAttr.replace('make-cell-dirty','').trim());
                                }
                            }
                        }
                    }
                });

                this.comboBoxRenderer = function(combo) {
                  return function(value) {
                    var idx = combo.store.find(combo.valueField, value);
                    var rec = combo.store.getAt(idx);
                    return ((rec === null || rec === undefined) ? '' : Ext.String.htmlEncode(rec.get(combo.displayField)));
                  };
                }
                
                Ext.apply(this, {
                    width: 600,
                    plugins: [this.cellEditing],
                    store: new Ext.data.Store({
                        storeId: 'Condition_Rule_Store',
                        fields: [
                            'isRowHasError',
                            'conditionRuleId',
                            'sequence', 
                            'selectedField',
                            'selectedOperator',
                            'frequency',
                            'startAt',
                            'threshold',
                            'stopAt',
                            'selectedAdjustmentType',
                            'minAdjustment',
                            'maxAdjustment',
                            'adjustmentVal',
                            'selectedAdjustedUnit'
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
                        width: 150,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.fieldCombo,
                        renderer: this.comboBoxRenderer(this.fieldCombo)
                    }, {
                        header: TS.T("TAG016", "Operator"),
                        dataIndex: 'selectedOperator',
                        width: 120,
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
                        header: TS.T("TAG017", "Frequency"),
                        dataIndex: 'frequency',
                        width: 100,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            if(fieldValue !== null && fieldValue !== ''){
                                if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years') {
                                    return Ext.create('Ext.grid.CellEditor', {
                                        field: Ext.create( 'Ext.form.field.Number', {
                                            minValue: 1,
                                            allowDecimals: false,
                                            nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                        })
                                    });
                                }
                                else{
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
                            }
                        }
                    }, {
                        header: TS.T("TAG019", "Start At"),
                        dataIndex: 'startAt',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: function(value, metaData, record, rowIdx, colIdx, store) {
                            if(value != null && value != '' && (record.data.selectedField === 'Weeks' || record.data.selectedField === 'Months' || record.data.selectedField === 'Years')){
                                var date = new Date(value);
                                var month = ("0" + (date.getMonth()+1)).slice(-2);
                                var day  = ("0" + date.getDate()).slice(-2);
                                return [month, day, date.getFullYear()].join("-");    
                            }
                            else{
                                return value;
                            }
                        },
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years') {
                                var dateField = Ext.create( 'Ext.form.field.Date', {
                                    format: 'm-d-Y',
                                    value: Ext.Date.dateFormat(record.data.startAt, 'm-d-Y'),
                                    invalidText: TS.T("COMM_TAG013", "Enter a valid date")
                                })
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: dateField
                                });
                            }
                            else{
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
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
                        }
                    }, {
                        header: TS.T("TAG020", "Threshold %"),
                        dataIndex: 'threshold',
                        width: 100,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var fieldValue = record.data.selectedField;
                            if(fieldValue !== 'Weeks' && fieldValue !== 'Months' && fieldValue !== 'Years'){
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
                                        allowDecimals: false,
                                        nanText: TS.T("COMM_TAG014", "Enter a valid number"),
                                    })
                                });
                            }
                        }
                    }, {
                        header: TS.T("TAG021", "Stop At"),
                        dataIndex: 'stopAt',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: function(value, metaData, record, rowIdx, colIdx, store) {
                            if(value != null && value != '' && (record.data.selectedField === 'Weeks' || record.data.selectedField === 'Months' || record.data.selectedField === 'Years')){
                                var date = new Date(value);
                                var month = ("0" + (date.getMonth()+1)).slice(-2);
                                var day  = ("0" + date.getDate()).slice(-2);
                                return [month, day, date.getFullYear()].join("-");    
                            }
                            else{
                                return value;
                            }
                        },
                        getEditor: function(record) {
                            var fieldValue = record.data.selectedField;
                            if(fieldValue === 'Weeks' || fieldValue === 'Months' || fieldValue === 'Years') {
                                var dateField = Ext.create( 'Ext.form.field.Date', {
                                    format: 'm-d-Y',
                                    value: Ext.Date.dateFormat(record.data.stopAt, 'm-d-Y'),
                                    invalidText: TS.T("COMM_TAG013", "Enter a valid date")
                                })
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: dateField
                                });
                            }
                            else{
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
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
                        }
                    }, {
                        header: TS.T("TAG022", "Adjustment Type"),
                        dataIndex: 'selectedAdjustmentType',
                        width: 110,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        editor: this.adjustmentTypeCombo,
                        renderer: this.comboBoxRenderer(this.adjustmentTypeCombo)
                    }, {
                        header: TS.T("TAG023", "Minimum Adjustment"),
                        dataIndex: 'minAdjustment',
                        width: 125,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType; 
                            if(adjustmentTypeValue !== null && adjustmentTypeValue !== '' && adjustmentTypeValue !== 'None'){
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
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
                        }
                    }, {
                        header: TS.T("TAG024", "Maximum Adjustment"),
                        dataIndex: 'maxAdjustment',
                        width: 130,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType; 
                            if(adjustmentTypeValue !== null && adjustmentTypeValue !== '' && adjustmentTypeValue !== 'None'){
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
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
                        }
                    }, {
                        header: TS.T("TAG025", "Adjustment Value"),
                        dataIndex: 'adjustmentVal',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType;
                            if (adjustmentTypeValue === 'Fixed') {
                                return Ext.create('Ext.grid.CellEditor', {
                                    field: Ext.create( 'Ext.form.field.Number', {
                                        minValue: 0,
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
                        }
                    }, {
                        header: TS.T("TAG026", "Adjustment Unit"),
                        dataIndex: 'selectedAdjustedUnit',
                        width: 120,
                        align: 'center',
                        sortable: false,
                        menuDisabled: true,
                        renderer: this.comboBoxRenderer(this.adjustmentUnitCombo),
                        __parent: this,
                        getEditor: function(record){
                            var adjustmentTypeValue = record.data.selectedAdjustmentType;
                            var selectedField = record.data.selectedField;
                            if(adjustmentTypeValue !== null && adjustmentTypeValue !== '' && adjustmentTypeValue !== 'None' && selectedField !== null && selectedField !== '' ){
                                return this.__parent.adjustmentUnitCombo;
                            }
                        }
                    }],
                    selModel: {
                        selType: 'cellmodel'
                    },
                    bbar: [{
                        text: '+ ' + TS.T("TAG028", "Add row"),
                        id: 'addRowButton',
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

                var addRowButtonCmp = Ext.getCmp('addRowButton');
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