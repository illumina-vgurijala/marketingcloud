(function() {
    var othersettings = SVMX.Package("com.servicemax.client.iot.admin.othersettings");

    othersettings.init = function() {

        Ext.define("com.servicemax.client.iot.admin.eventsGrid", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXGrid",
            metadata: null,
            deletedIds: null,
            constructor: function(config) {
                var me = this;
                this.deletedIds = [];
                config.columns = [];
                config.columns.push(this.createTextBoxColumn({
                    text: $TR.EVENT_NAME,
                    dataIndex: 'eventName',
                    width: 400,
                    flex: 1
                }));

                config.columns.push(this.createTextBoxColumn({
                    text: $TR.CLASS_NAME,
                    dataIndex: 'className',
                    width: 400,
                    flex: 1
                }));

                config.columns.push({
                    menuDisabled: true,
                    sortable: true,
                    xtype: 'actioncolumn',
                    width: 50,
                    items: [{
                        iconCls: 'delet-icon',
                        tooltip: $TR.DELETE
                    }],
                    handler: function(grid, rowIndex, colIndex) {
                        var gridStore = grid.getStore();
                        var rec = gridStore.getAt(rowIndex);
                        var eventId = rec.data["eventId"];
                        if (eventId)
                            me.deletedIds.push(eventId)
                        gridStore.remove(rec);
                    },
                    renderer: function(value, metadata, record) {
                        config.columns[config.columns.length - 1].items[0].iconCls = 'delet-icon';
                    }
                });

                this.metadata = config.metadata;
                this.callParent([config]);
                this.loadData();
            },

            getDeletedEvents: function() {
                return this.deletedIds;
            },

            loadData: function() {
                var me = this;
                me.store.loadData(me.filterMapToObjectEvents());
                me.store.commitChanges();
            },
            filterMapToObjectEvents: function() {
                var events = this.metadata.events.filter(function(items) {
                    return items.className !== "COMM_IoTRestApiEngine";
                });
                return events;
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

        Ext.define("com.servicemax.client.iot.admin.OtherSettings", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            eventsGrid: null,
            constructor: function(config) {
                var me = this;
                this.refresh();

                var eventsStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: ['eventId', 'eventName', 'className'],
                    data: []

                });
                this.eventsGrid = SVMX.create('com.servicemax.client.iot.admin.eventsGrid', {
                    cls: 'grid-panel-borderless panel-radiusless iot-setup-ta-grid',
                    selType: 'cellmodel',
                    plugins: [
                        SVMX.create('com.servicemax.client.installigence.ui.components.SVMXCellEditorPlugin', {
                            clicksToEdit: 2
                        })
                    ],
                    viewConfig: {
                        markDirty: false
                    },
                    sortable: true,
                    store: eventsStore,
                    metadata: config.metadata
                });

                var userActionsPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXFormPanel', {
                    style: 'margin: 1px 0',
                    layout: 'fit',
                    cls: 'grid-panel-borderless',
                    defaults: {
                        anchor: '40%'
                    }
                });
                userActionsPanel.add(this.eventsGrid);

                var searchToolbar = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                    style: 'border-width: 0'
                });

                var addRecButton = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                    text: $TR.ADD,
                    cls: 'iot-setup-add-button',
                    handler: function() {
                        me.onAddRecords();
                    }
                });

                searchToolbar.add('->');
                searchToolbar.add(addRecButton);

                config = config || {};
                config.items = [];
                config.items.push(searchToolbar);
                config.items.push(userActionsPanel);
                config.title = $TR.MAP_TO_APEX;
                config.id = "OS";
                this.callParent([config]);
            },

            onAddRecords: function(grid) {
                this.eventsGrid.addItems({});
                this.eventsGrid.getView().refresh();
                var rowIndex = this.eventsGrid.store.data.items.length - 1;
                var view = this.eventsGrid.getView();
                Ext.get(view.getRow(rowIndex)).scrollIntoView(view.getEl(), null, true);
                view.select(rowIndex);
            },

            getData: function() {
                var data = this.eventsGrid.getStore();
                data = data.getModifiedRecords();
                var records = [];
                var iData = 0,
                    iDataLength = data.length;
                for (iData = 0; iData < iDataLength; iData++) {
                    delete data[iData].data["id"];
                    if (!$.isEmptyObject(data[iData].data)) {
                        records.push(data[iData].data);
                    }
                }
                return { data: records, deletedEvents: this.eventsGrid.getDeletedEvents() };
            },

            refresh: function() {
                var me = this;
                SVMX.getClient().bind("SAVE_SUCCESS", function(evt) {
                    me.eventsGrid.metadata = evt.data;
                    var sforceObjectDescribes = metadata.sforceObjectDescribes;

                    for (var iObjectCount = 0; iObjectCount < sforceObjectDescribes.length; iObjectCount++) {
                        me.eventsGrid.metadata[sforceObjectDescribes[iObjectCount].objectAPIName] = sforceObjectDescribes[iObjectCount];
                    }
                    me.eventsGrid.loadData();
                }, this);

            },
            getAllEventName: function() {
                var names = [];
                var me = this;
                var allItems = me.eventsGrid.getStore().data.items;
                for (var i = 0; i < allItems.length; i++) {
                    if(allItems[i].data.eventName)names.push(allItems[i].data.eventName);
                }
                return names;
            },
            createTextField: function(label) {
                return SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                    allowBlank: true,
                    editable: true,
                    margin: '5, 5',
                    labelAlign: 'right',
                    fieldLabel: label,
                    labelWidth: 200,
                    width: 550,
                    listeners: {
                        change: function(field, value) {

                        }
                    }
                });

            }
        });

    }

})();