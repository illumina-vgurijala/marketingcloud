(function() {
    var maptoobject = SVMX.Package("com.servicemax.client.iot.admin.maptoobject");
    maptoobject.init = function() {
        Ext.define("com.servicemax.client.iot.admin.Maptoobject", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            metadata: null,
            constructor: function(config) {
                var me = this;
                me.refresh();
                me.metadata = config.metadata,
                    config.items = [];
                me.eventStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: [{ name: 'eventName', type: 'string' }, { name: 'eventDescription', type: 'string' }, { name: 'objectName', type: 'string' }, { name: 'sfdc', type: 'string' }, { name: 'eventId', type: 'string' }, { name: 'payload', type: 'string' }],
                    data: []
                });
                me.eventGrid = SVMX.create('com.servicemax.client.iot.admin.EventGrid', {
                    cls: 'grid-panel-borderless panel-radiusless iot-setup-ta-grid iot-create-map-for-object-grid',
                    store: me.eventStore,
                    autoScroll: true,
                    parentContext: me,
                    selType: 'cellmodel',
                    plugins: [
                        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
                            clicksToEdit: 2
                        })
                    ],
                    viewConfig: {
                        markDirty: false,
                        getRowClass: function(record, index) {
                            return 'iot-maptoobject-object-cell';
                        }
                    },
                    listeners: {
                        cellclick: function(cell, td, cellIndex, record, tr, rowIndex, e, eOpts) {
                            if (cell.config.grid.columns[cellIndex].dataIndex === "objectName") {
                                var payloadString = cell.config.grid.getStore().data.items[rowIndex].data.payload,
                                    payload = null;
                                if (payloadString !== "") payload = JSON.parse(payloadString);
                                var createEventObject = SVMX.create("com.servicemax.client.iot.admin.createevent.CreateEvent", { recordIndex: rowIndex, selectCell: cell, parentContext: cell.config.grid.parentContext, metadata: cell.config.grid.parentContext.metadata, payload: payload });
                            }
                        },
                        edit: function(editor, e, eOpts) {}
                    }
                });
                var searchToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                    style: 'border-width: 0'
                });
                var addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'iot-setup-add-button',
                    handler: function() {
                        me.__onAddRecords();
                    }
                });
                searchToolbar.add('->');
                searchToolbar.add(addRecButton);
                var formPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel', {
                    style: 'margin: 1px 0',
                    layout: 'fit',
                    cls: 'grid-panel-borderless',
                    defaults: {
                        anchor: '40%'
                    }
                });
                formPanel.add(me.eventGrid);
                config.items.push(searchToolbar);
                config.items.push(formPanel);
                config.title = $TR.MAP_TO_OBJECT;
                config.id = 'MO';
                me.callParent([config]);
                me.__loadAllEventTemplates();
            },
            shouldSave: function() {
                var me = this;
                var returnObject = {
                    isValid: true,
                    message: ''
                };
                var maps = me.__getAllMappings();
                var names = me.getAllEventName();
                var emptyRowIndex;
                if (Boolean($.inArray("", maps) + 1)) {
                    returnObject.isValid = false;
                    returnObject.message = $TR.SELECT_FIELD_MAP;
                    emptyRowIndex = $.inArray("", maps);
                } else if (Boolean($.inArray("", names) + 1)) {
                    returnObject.isValid = false;
                    returnObject.message = $TR.EMPTY_EVENT_NAME;
                    emptyRowIndex = $.inArray("", names);
                }
                if(!returnObject.isValid) me.__highlightRow(emptyRowIndex);
                return returnObject;
            },
            getAllEventName: function() {
                var names = [];
                var me = this;
                var allItems = me.eventStore.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    names.push(allItems[i].data.eventName);
                }
                return names;
            },
            __getAllMappings: function() {
                var maps = [];
                var me = this;
                var allItems = me.eventStore.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    maps.push(allItems[i].data.payload);
                }
                return maps;
            },
            getMappingRecords: function() {
                var grid = this.eventGrid;
                var data = grid.getStore();
                data = data.getModifiedRecords();
                var records = [];
                var iData = 0,
                    iDataLength = data.length;
                for (iData = 0; iData < iDataLength; iData++) {
                    delete data[iData].data["id"];
                    records.push(data[iData].data);
                }
                return { data: records, deletedEventMapIds: grid.deletedEventMapIds };
            },
            getData: function() {
                var grid = this.eventGrid;
                var data = grid.getStore();
                data = data.getModifiedRecords();
                var records = [];
                var iData = 0,
                    iDataLength = data.length;
                for (iData = 0; iData < iDataLength; iData++) {
                    delete data[iData].data["id"];
                    var eventData = data[iData].data;
                    var record = {
                        eventName: eventData.eventName,
                        className: "COMM_IoTRestApiEngine"
                    }
                    if (eventData.eventId !== "") record.eventId = eventData.eventId;
                    records.push(record);
                }
                return { data: records, deletedEvents: grid.deletedEventIds };
            },
            __onAddRecords: function(records) {
                var me = this;
                me.eventGrid.addItems({ 'objectName': $TR.SELECT });
                me.eventGrid.getView().refresh();
                var rowIndex = me.eventGrid.store.data.items.length - 1;
                var view = me.eventGrid.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
                view.select(rowIndex);
            },
            __loadAllEventTemplates: function() {
                var me = this;
                SVMX.getCurrentApplication().blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "IOT.GET_ALL_EVENT_TEMPLATES", me, { request: { context: me } });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            loadAllEventTemplatesComplete: function(data) {
                var me = this;
                var l = data.length;
                var eventData = [];
                for (var iEvt = 0; iEvt < l; iEvt++) {
                    var iData = data[iEvt];
                    var jsonObject = JSON.parse(iData[SVMX.OrgNamespace + '__SM_JSON_Payload__c']);
                    var objName = jsonObject.objLbl;
                    var eventRowData = {
                        eventName: iData[SVMX.OrgNamespace + '__SM_Event_Name__c'],
                        eventDescription: iData[SVMX.OrgNamespace + '__SM_Description__c'],
                        sfdc: iData['Id'],
                        objectName: objName,
                        payload: iData[SVMX.OrgNamespace + '__SM_JSON_Payload__c']
                    };
                    var eventItems = me.__getEventItems(me.metadata.events, eventRowData.eventName);
                    if (eventItems) {
                        var eventId = eventItems.eventId;
                        eventRowData.eventId = eventId;
                    }
                    eventData.push(eventRowData);
                }
                me.eventStore.loadData(eventData);
                SVMX.getCurrentApplication().unblockUI();
            },
            __getEventItems: function(allEvents, eventName) {
                var event = null;
                for (var iEvent = 0; iEvent < allEvents.length; iEvent++) {
                    if (allEvents[iEvent].eventName === eventName) {
                        event = allEvents[iEvent];
                        break;
                    }
                }
                return event;
            },
            applyEvent: function(cell, recordIndex, payload) {
                var me = this;
                var stringPayload = JSON.stringify(payload);
                me.eventGrid.store.data.items[recordIndex].data.objectName = payload.objLbl;
                me.eventGrid.store.data.items[recordIndex].data.payload = stringPayload;
                me.eventGrid.getView().refresh();
            },
            refresh: function() {
                var me = this;
                SVMX.getClient().bind("SAVE_SUCCESS", function(evt) {
                    me.metadata = evt.data;
                    me.__loadAllEventTemplates();
                }, me);

            },
            __highlightRow: function(rowIndex) {
                var me = this;
                var view = me.eventGrid.getView();
                var row = view.getRow(rowIndex);
                Ext.get(row).scrollIntoView(view.getEl(), null, true);
                Ext.get(row).addCls('piq-setup-new-attributes-row');
            },
        });
        // event grid class start.
        Ext.define("com.servicemax.client.iot.admin.EventGrid", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
            deletedEventMapIds: null,
            deletedEventIds: null,
            constructor: function(config) {
                var me = this;
                me.deletedEventMapIds = [];
                me.deletedEventIds = [];
                var config = config || {};
                me.addFieldButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'piq-setup-add-button',
                    disabled: false,
                    id: 'addFieldRecordbutton',
                    handler: function() {
                        me.addFieldRecord({ name: '' });
                    }
                });
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
                        var data = rec.data;
                        if (data.sfdc && data.eventId) {
                            me.deletedEventMapIds.push(data.sfdc);
                            me.deletedEventIds.push(data.eventId);
                        }
                    },
                    renderer: function(value, metadata, record) {
                        config.columns[0].items[0].iconCls = 'delet-icon';
                    }
                }];
                config.columns.push(me.createTextBoxColumn({
                    text: $TR.EVENT_NAME,
                    dataIndex: 'eventName',
                    flex: 1,
                    parentContext: me,
                    maskRe: /[^ ]/,
                    listeners: {
                        blur: function(field) {
                            setTimeout(function() {
                                var allEventsName = field.parentContext.__getAllEventsName();
                                var newEventName = field.value;
                                var numOfEvent = allEventsName.reduce(function(count, label) {
                                    if (label.toLowerCase() === newEventName.toLowerCase())
                                        count++;
                                    return count;
                                }, 0);
                                if (numOfEvent > 1) {
                                    SVMX.getCurrentApplication().showQuickMessage('error', 'Event name already exists');
                                }
                            }, 200);
                        }
                    }
                }));
                config.columns.push(this.createTextBoxColumn({ text: $TR.EVENT_DESCRIPTION, dataIndex: 'eventDescription', flex: 1, listeners: null }));
                config.columns.push(this.createObjectColumn({ text: $TR.OBJECT, dataIndex: 'objectName', flex: 1, listeners: null, tdCls: 'x-change-cell' }));
                me.callParent([config]);
            },
            __getAllEventsName: function() {
                var eventsName = [];
                var me = this;
                var allItems = me.store.data.items;
                for (var i = 0; i < allItems.length; i++) {
                    eventsName.push(allItems[i].data.eventName);
                }
                return eventsName;
            },
            addFieldRecord: function(records) {
                if (!records) return;
                var rowIndex = this.getStore().count();
                this.store.insert(this.getStore().count(), records);
                var view = this.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
            },
            createTextBoxColumn: function(fieldInfo) {
                var me = this;
                var txtboxCol = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField', {
                    allowBlank: true,
                    editable: true,
                    listeners: fieldInfo.listeners,
                    parentContext: fieldInfo.parentContext,
                    maskRe: fieldInfo.maskRe
                });
                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return txtboxCol;
                };
                return fieldInfo;
            },
            createObjectColumn: function(fieldInfo) {
                var me = this;
                var fieldInfo = fieldInfo || {};
                fieldInfo.sortable = true;
                fieldInfo.editable = true;
                fieldInfo.getEditor = function(currentRecord) {
                    return null;
                };
                return fieldInfo;
            }
        });
        // event grid class end.   
    }
})();