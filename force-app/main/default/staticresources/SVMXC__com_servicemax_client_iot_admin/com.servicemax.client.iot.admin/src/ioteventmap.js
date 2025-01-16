(function() {
    var ioteventmap = SVMX.Package("com.servicemax.client.iot.admin.ioteventmap");
    ioteventmap.init = function() {
        Ext.define("com.servicemax.client.iot.admin.ioteventmap", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            constructor: function(config) {
                var me = this;
                // Map to Apex.
                me.otherSettings = SVMX.create('com.servicemax.client.iot.admin.OtherSettings', {
                    metadata: metadata
                });
                // Map to Object.
                 me.maptoobject = SVMX.create('com.servicemax.client.iot.admin.Maptoobject', {
                    metadata: metadata
                });
               
                me.eventTabPanel = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTabPanel', {
                    tabPosition: 'top',
                    tabRotation: 0,
                    cls: 'iot-setup-tab-horizantal'
                    
                });
                me.eventTabPanel.add(me.otherSettings);
                me.eventTabPanel.add(me.maptoobject);
                me.eventTabPanel.setActiveTab("OS");
                config = config || {};
                config.items = [me.eventTabPanel];
                config.title = $TR.IOT_EVENTS;
                config.id = 'EM';
                me.callParent([config]);
            },
            getData: function() {
                var me = this;
                var otherSettingData = me.otherSettings.getData();
                var maptoobjectData = me.maptoobject.getData();
                var finalData = otherSettingData.data.concat(maptoobjectData.data);
                var finalDeletedEvents = otherSettingData.deletedEvents.concat(maptoobjectData.deletedEvents);
                var data = {
                    data: finalData,
                    deletedEvents: finalDeletedEvents
                };
                return data;
            },
            getMappingRecords: function() {
                var records = {};
                records = this.maptoobject.getMappingRecords();
                return records;
            },
            shouldSave: function() {
                var me = this;
                var returnObject = {};
                returnObject = me.maptoobject.shouldSave();
                if (returnObject.isValid) {
                    var otherSettingEvents = me.otherSettings.getAllEventName();
                    var maptoObjectEvents = me.maptoobject.getAllEventName();
                    var allEvents = [];
                    allEvents = otherSettingEvents.concat(maptoObjectEvents);
                    returnObject = me.__validateDuplicateValues(allEvents);
                }
                return returnObject;
            },
            __validateDuplicateValues: function(allValues) {
                var duplicateValues = [];
                var caseInsensitiveValues = [];
                var isFound = false;
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
                            duplicateValues.push(allValues[i]);
                            caseInsensitiveValues.push(value.toLowerCase());
                        }
                        isFound = true;
                    }
                }
                var returnObject = {
                    message: $TR.DUPLICATE_EVENT_NAMES + duplicateValues.join(),
                    isValid: !isFound
                };
                return returnObject;
            }
        });
    }
})();