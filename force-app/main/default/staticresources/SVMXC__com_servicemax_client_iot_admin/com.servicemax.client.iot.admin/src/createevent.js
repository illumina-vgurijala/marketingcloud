/**
 *  Createevent.js.
 * @class com.servicemax.client.iot.admin.createevent
 * @author Madhusudhan HK
 *
 * @copyright 2017 ServiceMax, Inc.
 **/

(function() {
    var createevent = SVMX.Package("com.servicemax.client.iot.admin.createevent");
    createevent.init = function() {
        createevent.Class("CreateEvent", com.servicemax.client.lib.api.Object, {
            __config: null,
            __win: null,
            __applyButton: null,
            __searchTextField: null,
            __selectedCell: null,
            __parentContext: null,
            __recordIndex: null,
            __payload: null,
            __metadata: null,
            __constructor: function(config) {
                var me = this;
                me.__config = config;
                me.__metadata = config.metadata;
                me.__selectedCell = config.selectCell;
                me.__parentContext = config.parentContext;
                me.__recordIndex = config.recordIndex;
                me.__payload = config.payload;
                me.__win = me.__getUI();
                me.__win.show();
                me.__refresh();
            },
            __refresh: function() {
                var me = this,
                    objName, fld;
                if (!$.isEmptyObject(me.__payload)) {
                    objName = me.__payload.objName;
                    fld = me.__payload.fld;
                    me.showObjects.setValue(objName);
                    me.fieldGridStore.loadData(fld);
                    me.__describeSelectedObject(objName);
                    var refObjects = [];
                    for (var i = 0; i < fld.length; i++) {
                        if (fld[i].fldType === 'REFERENCE') {
                            refObjects.push(fld[i].refObj);
                        }
                    }
                    if (refObjects) me.fieldGrid.__describeReferenceObject(refObjects);
                } else {
                    me.showObjects.setValue("--None--");
                    me.__resetFieldGrid();
                }
            },
            __getUI: function() {
                var me = this;
                me.__applyButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton", {
                    text: $TR.APPLY,
                    id: 'applybutton',
                    docked: 'right',
                    disabled: true,
                    align: 'right',
                    cls: 'piq-setup-picklist-apply-button',
                    parentContext: me,
                    handler: function() {
                        this.parentContext.__apply();
                    }
                });
                var bottomBar = ['->', me.__applyButton];
                var objectsData = me.__getObjectListData();
                me.objectStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: ['objectName', 'objectLabel'],
                    data: objectsData
                });
                me.showObjects = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox', {
                    fieldLabel: $TR.SELECT_OBJECT + ' <span class="req" style="color:red">*</span>',
                    store: me.objectStore,
                    labelWidth: 150,
                    width: '60%',
                    displayField: 'objectLabel',
                    valueField: 'objectName',
                    queryMode: 'local',
                    editable: true,
                    disabled: false,
                    selectedObject: undefined,
                    listeners: {
                        select: {
                            fn: me.__onSelectObjects,
                            scope: me
                        },
                        afterrender: function(combo) {
                            var recordSelected = combo.getStore().getAt(0);
                            combo.setValue(recordSelected.get('objectLabel'));
                        }
                    }
                });
                me.fieldGridStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'fldLabel', type: 'string' },
                        { name: 'fldApi', type: 'string' },
                        { name: 'fldKey', type: 'string' },
                        { name: 'fldType', type: 'string' },
                        { name: 'refObj', type: 'string' },
                        { name: 'refFld', type: 'string' },
                        { name: 'refLabel', type: 'string' },
                        { name: 'isExternalId', type: 'boolean' }
                    ],
                    data: []
                });
                me.fieldStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'fldApi', type: 'string' }, { name: 'fldLabel', type: 'string' }, { name: 'fldType', type: 'string' }, { name: 'referenceTo', type: 'string' }, { name: 'isExternalId', type: 'boolean' }],
                    data: [],
                    sorters: [{
                        property: 'fldLabel',
                        direction: 'ASC'
                    }]
                });
                me.fieldGrid = SVMX.create('com.servicemax.client.iot.admin.FieldsGrid', {
                    cls: 'grid-panel-borderless panel-radiusless piq-setup-ta-grid iot-create-map-for-object-grid',
                    store: me.fieldGridStore,
                    fieldStore: me.fieldStore,
                    height: 350,
                    margin: '7 7 7 7',
                    width: 'calc(100% - 25px)',
                    autoScroll: true,
                    layout: 'fit',
                    selType: 'cellmodel',
                    parentContext: me,
                    editRowIndex: 0,
                    plugins: [
                        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
                            clicksToEdit: 2
                        })
                    ],
                    viewConfig: {},
                    listeners: {
                        celldblclick: function(cell, td, cellIndex, record, tr, rowIndex, e, eOpts) {},
                        cellclick: function(cell, td, cellIndex, record, tr, rowIndex, e, eOpts) {
                            cell.config.grid.editRowIndex = rowIndex;
                            var row = this.getView().getRow(rowIndex);
                            Ext.get(row).removeCls('piq-setup-new-attributes-row');
                        },
                        edit: function(editor, e, eOpts) {}
                    }
                });
                var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                    layout: { type: "vbox" },
                    height: 500,
                    width: 820,
                    items: [me.fieldGrid],
                    title: $TR.CREATE_EVENT,
                    cls: 'piq-setup-ta-picklist-window',
                    closable: true,
                    maximizable: false,
                    titleAlign: 'left',
                    layout: {
                        padding: 5
                    },
                    layout: 'fit',
                    modal: true,
                    dockedItems: [{
                            dock: 'top',
                            xtype: 'toolbar',
                            margin: '0',
                            items: me.showObjects
                        },
                        {
                            dock: 'bottom',
                            xtype: 'toolbar',
                            margin: '0',
                            items: bottomBar
                        }
                    ],
                    listeners: {
                        show: function(win) {
                            if (this.modal) {
                                var dom = Ext.dom.Query.select('.x-mask');
                                for (var i = 0; i < dom.length; i++) {
                                    Ext.get(dom[i]).setStyle('opacity', 1);
                                    var el = Ext.get(dom[i]);
                                    el.addCls('customWinMask');
                                }
                            }
                        },
                        close: function(win) {
                            if (this.modal) {
                                var dom = Ext.dom.Query.select('.x-mask');
                                for (var i = 0; i < dom.length; i++) {
                                    Ext.get(dom[i]).setStyle('opacity', 1);
                                    var el = Ext.get(dom[i]);
                                    el.removeCls('customWinMask');
                                }
                            }
                        }
                    }
                });
                return win;
            },
            __getObjectListData: function(){
                var me = this;
                var objectListData = [{ objectName: "--None--", objectLabel: $TR.NONE }];
                if(me.__metadata.eventObjects) objectListData.push.apply(objectListData,me.__metadata.eventObjects);
                return objectListData;
            },
            __apply: function() {
                var me = this;
                var shouldApply = me.__shouldAllowApply();
                if (!shouldApply.isValid) {
                    SVMX.getCurrentApplication().showQuickMessage('error', shouldApply.message);
                    me.__highlightRow(shouldApply.rowIndex);
                } else {
                    var objName = me.showObjects.getSelectedRecord().data.objectName;
                    var objLbl = me.showObjects.getSelectedRecord().data.objectLabel;
                    var fld = [];
                    var allFields = me.__getAllFieldDetails();
                    if (allFields) fld = allFields;
                    var payload = {
                        objName: objName,
                        fld: fld,
                        objLbl: objLbl
                    };
                    me.__parentContext.applyEvent(me.__selectedCell, me.__recordIndex, payload);
                    me.__win.close();
                }
            },
            __getAllFieldDetails: function() {
                var me = this;
                var allFields = [];
                var items = me.fieldGridStore.data.items;
                var l = items.length;
                for (var i = 0; i < l; i++) {
                    var data = items[i].data;
                    var fldObject = {
                        fldLabel: data.fldLabel,
                        fldKey: data.fldKey,
                        fldApi: data.fldApi,
                        fldType: data.fldType,
                        refLabel: data.refLabel,
                        isExternalId: data.isExternalId
                    }
                    if (data.fldType == 'REFERENCE') {
                        fldObject.refObj = data.refObj;
                        fldObject.refFld = data.refFld;
                    }
                    allFields.push(fldObject);
                }
                return allFields;
            },
            __shouldAllowApply: function() {
                var me = this;
                var returnObj = {
                    isValid: false,
                    message: '',
                    rowIndex: 0
                };
                var allKeys = me.__getAllKeys();
                var allFields = me.__getAllFields();
                var allLookUps = me.__getAllLookups();
                var duplicateFields = me.__validateDuplicateValues(allFields);
                var emptyKeyIndex = me.__checkEmptyValues(allKeys);
                var emptyFieldIndex = me.__checkEmptyValues(allFields.apis);
                var emptyLookups = me.__checkEmptyValues(allLookUps);
                var duplicateValues = [];
                if (allKeys.length == 0 && allFields.apis.length == 0) {
                    returnObj.message = $TR.EMPTY_FIELD;
                    returnObj.rowIndex = 0;
                } else if (emptyKeyIndex !== -1) {
                    returnObj.message = $TR.EMPTY_KEY;
                    returnObj.rowIndex = emptyKeyIndex;
                } else if (emptyFieldIndex !== -1) {
                    returnObj.message = $TR.EMPTY_FIELD;
                    returnObj.rowIndex = emptyFieldIndex;
                } else if (duplicateFields.isFound) {
                    duplicateValues = duplicateFields.duplicateValues.join();
                    returnObj.message = $TR.DUPLICATE_FIELD + ' : ' + duplicateValues;
                    returnObj.rowIndex = duplicateFields.rowIndex;
                } else if (emptyLookups !== -1) {
                    returnObj.message = $TR.EMPTY_LOOKUP_ID;
                    returnObj.rowIndex = emptyFieldIndex;
                } else {
                    returnObj.isValid = true;
                }
                return returnObj;
            },
            __validateDuplicateValues: function(allFlds) {
                var allValues = allFlds.apis;
                var allLabels = allFlds.labels;
                var duplicateValues = [];
                var caseInsensitiveValues = [];
                var isFound = false;
                var rowIndex = 0;
                for (var i = 0; i < allValues.length; i++) {
                    var value = allValues[i];
                    var num = allValues.reduce(function(count, label) {
                        if (label.toLowerCase() === value.toLowerCase())
                            count++;
                        return count;
                    }, 0);
                    if (num > 1) {
                        if (caseInsensitiveValues.indexOf(value.toLowerCase()) > -1) {
                            //In the array!
                        } else {
                            duplicateValues.push(allLabels[i]);
                            caseInsensitiveValues.push(value.toLowerCase());
                        }
                        isFound = true;
                        rowIndex = i;
                    }
                }
                var returnObject = {
                    duplicateValues: duplicateValues,
                    isFound: isFound,
                    rowIndex: rowIndex
                };
                return returnObject;
            },
            __highlightRow: function(rowIndex) {
                var me = this;
                var view = me.fieldGrid.getView();
                var row = view.getRow(rowIndex);
                Ext.get(row).scrollIntoView(view.getEl(), null, true);
                Ext.get(row).addCls('piq-setup-new-attributes-row');
            },
            __checkEmptyValues: function(allItems) {
                return $.inArray("", allItems);
            },
            __checkIfArrayValuesAreUnique: function(keyArray) {
                return keyArray.length === new Set(keyArray).size;
            },
            __getAllLookups: function() {
                var lookups = [];
                var me = this;
                var allItems = me.fieldGridStore.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    lookups.push(allItems[i].data.refLabel);
                }
                return lookups;
            },
            __getAllKeys: function() {
                var keys = [];
                var me = this;
                var allItems = me.fieldGridStore.data.items;
                for (var ikey = 0; ikey < allItems.length; ikey++) {
                    keys.push(allItems[ikey].data.fldKey);
                }
                return keys;
            },
            __getAllFields: function() {
                var fldApis = [];
                var fldLabels = [];
                var me = this;
                var allItems = me.fieldGridStore.data.items;
                for (var ikey = 0; ikey < allItems.length; ikey++) {
                    fldApis.push(allItems[ikey].data.fldApi);
                    fldLabels.push(allItems[ikey].data.fldLabel);
                }
                var flds = {
                    apis: fldApis,
                    labels: fldLabels
                };
                return flds;
            },
            __onSelectObjects: function(combo, record) {
                var me = this;
                me.__resetFieldGrid();
                if (combo.getSelectedRecord().get("objectName") == "--None--") {
                    me.fieldGrid.addFieldButton.setDisabled(true);
                    me.__applyButton.setDisabled(true);
                } else {
                    var selectedObjectName = combo.getSelectedRecord().get("objectName");
                    me.__describeSelectedObject(selectedObjectName);
                }
            },
            __describeSelectedObject: function(selectedObjectName) {
                var me = this;
                me.blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "IOT.DESCRIBE_OBJECT",
                    me, {
                        request: {
                            context: me,
                            requestData: {
                                allObjects: [{ objectAPIName: selectedObjectName }]
                            }
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            describeSelectedObjectComplete: function(data) {
                var me = this;
                me.fieldGrid.addFieldButton.setDisabled(false);
                me.__applyButton.setDisabled(false);
                me.__loadFieldStoreData(data);
            },
            __loadFieldStoreData: function(data) {
                var me = this;
                var __fieldStoreData = [];
                var describeObject = data.sforceObjectDescribes[0];
                var allFields = describeObject.fields;
                for (var i = 0; i < allFields.length; i++) {
                    var field = allFields[i];
                    __fieldStoreData.push({ fldApi: field.fieldAPIName, fldLabel: field.fieldLabel, fldType: field.type, referenceTo: field.referenceTo, isExternalId: field.isExternalId });
                }
                me.fieldStore.setData(__fieldStoreData);
                me.unblockUI();
            },
            __resetFieldGrid: function() {
                var me = this;
                me.fieldGridStore.clearData();
                me.fieldGridStore.removeAll();
                me.fieldGrid.view.refresh();
            },
            blockUI: function() {
                var opts = {
                    lines: 25, // The number of lines to draw
                    length: 25, // The length of each line
                    width: 5, // The line thickness
                    radius: 30, // The radius of the inner circle
                    corners: 1, // Corner roundness (0..1)
                    rotate: 0, // The rotation offset
                    direction: 1, // 1: clockwise, -1: counterclockwise
                    color: '#ffa384', // #rgb or #rrggbb or array of colors
                    speed: 3, // Rounds per second
                    trail: 60, // Afterglow percentage
                    shadow: false, // Whether to render a shadow
                    hwaccel: false, // Whether to use hardware acceleration
                    className: 'spinner', // The CSS class to assign to the spinner
                    zIndex: 2e9 // The z-index (defaults to 2000000000)
                };

                this.__spinner = new Spinner(opts).spin($("#" + this.__win.el.dom.id)[0]);
            },

            unblockUI: function() {
                this.__spinner.stop();
            }
        });
        //FieldsGrid   class start.
        Ext.define("com.servicemax.client.iot.admin.FieldsGrid", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
            fieldStore: null,
            __refObjDescribes: null,
            constructor: function(config) {
                var me = this;
                var config = config || {};
                me.__refObjDescribes = {};
                if (config.fieldStore) me.fieldStore = config.fieldStore || {};
                me.addFieldButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'piq-setup-add-button',
                    disabled: true,
                    id: 'addFieldRecordbutton',
                    handler: function() {
                        me.addFieldRecord({ name: '' });
                    }
                });
                config.dockedItems = [{
                    xtype: 'toolbar',
                    dock: 'top',
                    items: [{ xtype: 'tbfill' }, me.addFieldButton]
                }];
                config.columns = [{
                    menuDisabled: true,
                    sortable: false,
                    xtype: 'actioncolumn',
                    width: 50,
                    items: [{ iconCls: 'delet-icon', tooltip: $TR.DELETE }],
                    handler: function(grid, rowIndex, colIndex) {
                        var gridStore = grid.getStore();
                        var rec = gridStore.getAt(rowIndex);
                        gridStore.remove(rec);
                    },
                    renderer: function(value, metadata, record) {
                        config.columns[0].items[0].iconCls = 'delet-icon';
                    }
                }];
                config.columns.push(me.createComboBoxColumn({
                    text: $TR.FILED_NAME,
                    dataIndex: 'fldLabel',
                    flex: 1,
                    store: me.fieldStore,
                    renderer: function(value) {
                        return Ext.String.htmlEncode(value);
                    }
                }));
                config.columns.push(me.createComboBoxColumnForReference({
                    text: $TR.LOOKUP_FIELD_ID,
                    dataIndex: 'refLabel',
                    flex: 1,
                }));
                config.columns.push(me.createTextBoxColumn({ text: $TR.FIELD_KEY, dataIndex: 'fldKey', flex: 1, listeners: null }));
                me.callParent([config]);
            },
            __describeReferenceObject: function(objects) {
                var allObjects = [];
                for (var i = 0; i < objects.length; i++) {
                    allObjects.push({ objectAPIName: objects[i] });
                }
                var me = this;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "IOT.DESCRIBE_OBJECT", me, {
                    request: {
                        context: me,
                        requestData: {
                            allObjects: allObjects
                        },
                        isRefobj: true
                    }
                });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            describeReferenceObjectComplete: function(data) {
                this.__reloadObjectDescribes(data);
            },
            __reloadObjectDescribes: function(data) {
                var sforceObjectDescribes = data.sforceObjectDescribes;
                for (var i = 0; i < sforceObjectDescribes.length; i++) {
                    var objName = sforceObjectDescribes[i].objectAPIName;
                    var objLbl = sforceObjectDescribes[i].objectLabel;
                    var fields = [];
                    var flds = sforceObjectDescribes[i].fields;
                    for (var fldIndex = 0; fldIndex < flds.length; fldIndex++) {
                        var fld = flds[fldIndex];
                        if (fld.fieldAPIName === 'Name' || fld.fieldAPIName === 'Id' || fld.isExternalId == true) {
                            fields.push(fld);
                        }
                    }
                    var describeObject = {
                        objName: objName,
                        objLbl: objLbl,
                        flds: fields
                    }
                    this.__refObjDescribes[objName] = describeObject;
                }
            },
            addFieldRecord: function(records) {
                if (!records) return;
                var rowIndex = this.getStore().count();
                this.store.insert(this.getStore().count(), records);
                var view = this.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
            },
            __updateLookUpLabel: function(label) {
                var model = this.getSelectionModel();
                var fldRec = model.getSelection()[0];
                fldRec.set("refLabel", label);
            },
            createComboBoxColumn: function(fieldInfo) {
                var me = this;
                var fldCombo = SVMX.create('com.servicemax.client.iot.admin.celleditors.SVMXComboBoxCellEditor', {
                    displayField: 'fldLabel',
                    queryMode: 'local',
                    editable: false,
                    valueField: 'fldApi',
                    fieldName: fieldInfo.dataIndex,
                    store: fieldInfo.store,
                    parentContext: me,
                    rowIndex: -1,
                    listeners: {
                        select: function(combo, record, index) {
                            var me = this;
                            var gridRowIndex = me.parentContext.editRowIndex;
                            var comboData = record.data;
                            me.parentContext.store.data.items[gridRowIndex].data.fldType = comboData.fldType;
                            me.parentContext.store.data.items[gridRowIndex].data.fldApi = comboData.fldApi;
                            me.parentContext.store.data.items[gridRowIndex].data.refObj = comboData.referenceTo;
                            me.parentContext.store.data.items[gridRowIndex].data.isExternalId = comboData.isExternalId;
                            me.parentContext.store.data.items[gridRowIndex].data.refFld = '';

                            if (comboData.fldType === 'REFERENCE') {
                                if (!me.parentContext.__refObjDescribes[comboData.referenceTo]) {
                                    me.parentContext.__describeReferenceObject([comboData.referenceTo]);
                                }
                                me.parentContext.__updateLookUpLabel('');
                            } else {
                                me.parentContext.__updateLookUpLabel($TR.NA);
                            }
                        },
                        beforeedit: function(cellEditor, context, eOpts) {
                            console.log(context.rowIdx);
                            rowIndex = context.rowIdx;
                        }
                    }
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.menuDisabled = false;
                fieldInfo.sortable = true;
                fieldInfo.parentContext = me,
                    fieldInfo.getEditor = function(currentRecord) {
                        fldCombo.setRecord(currentRecord);
                        fldCombo.setValue(currentRecord.data.fldApi);
                        return fldCombo;
                    };
                return fieldInfo;
            },
            createComboBoxColumnForReference: function(fieldInfo) {
                var me = this;
                var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'fldApi', type: 'string' }, { name: 'fldLabel', type: 'string' }, { name: 'fldType', type: 'string' }],
                    data: [],
                    sorters: [{
                        property: 'fldLabel',
                        direction: 'ASC'
                    }]
                });
                var fldCombo = SVMX.create('com.servicemax.client.iot.admin.celleditors.SVMXComboBoxCellEditor', {
                    displayField: 'fldLabel',
                    queryMode: 'local',
                    editable: false,
                    valueField: 'fldApi',
                    fieldName: fieldInfo.dataIndex,
                    store: store,
                    parentContext: me,
                    rowIndex: -1,
                    listeners: {
                        select: function(combo, record, index) {
                            var me = this;
                            var gridRowIndex = me.parentContext.editRowIndex;
                            me.parentContext.store.data.items[gridRowIndex].data.refFld = combo.value;
                        },
                        beforeedit: function(cellEditor, context, eOpts) {

                        }
                    }
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.menuDisabled = false;
                fieldInfo.sortable = true;
                fieldInfo.parentContext = me,
                    fieldInfo.getEditor = function(currentRecord) {
                        var editor;
                        var data = currentRecord.data;
                        var type = data.fldType;
                        if (!type || type !== "REFERENCE") {
                            editor = null;
                        } else {
                            fldCombo.setRecord(currentRecord);
                            fldCombo.setValue(currentRecord.data.refFld);
                            var flds = this.parentContext.__refObjDescribes[data.refObj].flds;
                            var storeData = [];
                            for (var i = 0; i < flds.length; i++) {
                                var field = flds[i];
                                storeData.push({
                                    fldApi: field.fieldAPIName,
                                    fldLabel: field.fieldLabel
                                });
                            }
                            fldCombo.store.setData(storeData);
                            editor = fldCombo;
                        }
                        return editor;
                    };
                return fieldInfo;
            },
            createTextBoxColumn: function(fieldInfo) {
                var me = this;
                var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField', {
                    allowBlank: true,
                    editable: true,
                    maskRe: /[^ ]/
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return txtboxCol;
                };
                return fieldInfo;
            }

        });
        //FieldsGrid class end.
    }
})();