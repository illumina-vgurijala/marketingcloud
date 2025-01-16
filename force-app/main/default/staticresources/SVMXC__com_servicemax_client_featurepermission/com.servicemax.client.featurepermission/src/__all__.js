// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.featurepermission\src\api.js
/**
 * ServiceMax 
 * @class com.servicemax.client.featurepermission.api
 */
(function() {
    var appImpl = SVMX.Package("com.servicemax.client.featurepermission.api");
    appImpl.init = function() {

        appImpl.Class("Application", com.servicemax.client.lib.api.AbstractApplication, {
            __constructor: function() {},

            beforeRun: function(options) {
                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();

                this.__eventBus = SVMX.create("com.servicemax.client.featurepermission.impl.EventBus", {});
                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                            },
                            context: this
                        });
                    },
                    context: this,
                    additionalParams: { eventBus: this.__eventBus }
                });
                options.handler.call(options.context);
            },

            getEventBus: function() {
                return this.__eventBus;
            },

            run: function() {
                this.getMetaData();
            },

            getMetaData: function() {
                this.blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "FEATUREPERMISSION.GET_META_DATA", this, {
                        request: {
                            context: this,
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },


            onGetMetaDataComplete: function(metaData) {
                var me = this;
                me.unblockUI();
                me.__processTranslations(metaData.translations);
                SVMX.create('com.servicemax.client.featurepermission.root.RootPanel', {
                    collapsible: false,
                    titleAlign: 'center',
                    frame: 'true',
                    metaData: metaData,
                    app: me
                });
            },
            __processTranslations: function(translationsArr) {
                var i, ilength = translationsArr.length;
                var translations = {};
                for (i = 0; i < ilength; i++) {
                    translations[translationsArr[i].Key] = Ext.String.htmlEncode(translationsArr[i].Text) ;
                }
                window.$TR = translations;
            },
            blockUI: function() {
                if (this.__spinner) {
                    this.__spinner.spin($("#" + SVMX.getDisplayRootId())[0]);
                } else {
                    var top = window.innerHeight / 2 - 100;
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
                        zIndex: 2e9, // The z-index (defaults to 2000000000)
                        top: top
                    };
                    this.__spinner = new Spinner(opts).spin($("#" + SVMX.getDisplayRootId())[0]);
                }
            },

            unblockUI: function() {
                this.__spinner.stop();
            },
        });
    }

})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.featurepermission\src\commands.js
(function() {
    var featurepermissioncommands = SVMX.Package("com.servicemax.client.featurepermission.commands");

    featurepermissioncommands.init = function() {
        featurepermissioncommands.Class("GetMetaData", com.servicemax.client.mvc.api.CommandWithResponder, {
            __cbContext: null,
            __constructor: function() { this.__base(); },

            executeAsync: function(request, responder) {
                this.__cbContext = request.context;
                this._executeOperationAsync(request, this, { operationId: "FEATUREPERMISSION.GET_META_DATA" });
            },

            result: function(data) {
                this.__cbContext.onGetMetaDataComplete(data);
            }

        }, {});

        featurepermissioncommands.Class("GetUserData", com.servicemax.client.mvc.api.CommandWithResponder, {
            __cbContext: null,
            __constructor: function() { this.__base(); },

            executeAsync: function(request, responder) {
                this.__cbContext = request.context;
                this._executeOperationAsync(request, this, { operationId: "FEATUREPERMISSION.GET_USER_DATA" });
            },

            result: function(data) {
                this.__cbContext.onGetUserDataComplete(data);
            }

        }, {});

        featurepermissioncommands.Class("SaveData", com.servicemax.client.mvc.api.CommandWithResponder, {
            __cbContext: null,
            __constructor: function() { this.__base(); },

            executeAsync: function(request, responder) {
                this.__cbContext = request.context;
                this._executeOperationAsync(request, this, { operationId: "FEATUREPERMISSION.SAVE_DATA" });
            },

            result: function(data) {
                this.__cbContext.saveDataComplete(data);
            }

        }, {});
    };
})()

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.featurepermission\src\impl.js
(function() {

    SVMX.OrgNamespace = SVMX.getClient().getApplicationParameter("org-name-space") || "SVMXDEV";
    SVMX.appType = SVMX.getClient().getApplicationParameter("app-type") || "external";
    var instImpl = SVMX.Package("com.servicemax.client.featurepermission.impl");
    instImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {
        __constructor: function() {
            this.__base();
            instImpl.Module.instance = this;
        },

        initialize: function() {},

        afterInitialize: function() {

        },
        beforeInitialize: function() {
            com.servicemax.client.featurepermission.api.init();
            com.servicemax.client.featurepermission.root.init();
            com.servicemax.client.featurepermission.commands.init();
            com.servicemax.client.featurepermission.operations.init();
        },

        createServiceRequest: function(params, operationObj) {
            var servDef = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.sal.service.factory");
            servDef.getInstanceAsync({
                handler: function(service) {
                    var options = params.options || {};
                    var p = {
                        type: options.type || "REST",
                        endPoint: options.endPoint || "",
                        nameSpace: SVMX.OrgNamespace
                    };
                    var sm = service.createServiceManager(p);
                    var sRequest = sm.createService();
                    params.handler.call(params.context, sRequest);
                },
                context: this
            });
        },

    }, {
        instance: null
    });

    instImpl.Class("EventBus", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor: function() { this.__base(); }
    }, {
        __instance: null,
        getInstance: function() {
            if (!instImpl.EventBus.__instance) {
                instImpl.EventBus.__instance = SVMX.create("com.servicemax.client.featurepermission.EventBus", {});
            }
            return instImpl.EventBus.__instance;
        }
    });
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.featurepermission\src\operations.js
(function() {
    var featurepermissionoperations = SVMX.Package("com.servicemax.client.featurepermission.operations");

    featurepermissionoperations.init = function() {
        var Module = com.servicemax.client.featurepermission.impl.Module;

        featurepermissionoperations.Class("GetMetaData", com.servicemax.client.mvc.api.Operation, {

            __constructor: function() {
                this.__base();
            },

            performAsync: function(request, responder) {
                featurepermissionObject.JsrGetMetadata('', function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});


        featurepermissionoperations.Class("GetUserData", com.servicemax.client.mvc.api.Operation, {

            __constructor: function() {
                this.__base();
            },

            performAsync: function(request, responder) {
                var requestString = {
                    profileId:request.profileId,
                    searchValue:request.searchValue
                }
                featurepermissionObject.JsrGetUserData(requestString, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});


        featurepermissionoperations.Class("SaveData", com.servicemax.client.mvc.api.Operation, {

            __constructor: function() {
                this.__base();
            },

            performAsync: function(request, responder) {
                featurepermissionObject.JsrSaveData(request.modifiedUsers, function(result, evt) {
                    responder.result(result);
                }, this);
            }
        }, {});
    };
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.featurepermission\src\root.js
(function() {
    var appImpl = SVMX.Package("com.servicemax.client.featurepermission.root");
    appImpl.init = function() {
        var uiComposites = com.servicemax.client.ui.components.composites.impl;
        Ext.define("com.servicemax.client.featurepermission.root.RootPanel", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            cls: 'svmx-feature-permission-root',
            __grid: null,
            __store: null,
            __metaData: null,
            __app: null,
            __modifiedUsers: null,
            __currentProfile: null,
            __newProfile: null,
            constructor: function(config) {
                var me = this;
                config = config || {};
                config.renderTo = SVMX.getDisplayRootId();
                config.autoScroll = true;
                me.__metaData = config.metaData;
                me.__app = config.app;
                me.__modifiedUsers = {};
                me.__newProfile = [];
                me.__currentProfile = [];
                config.items = me.__getItems();
                this.callParent([config]);
            },
            __getItems: function() {
                var me = this;
                var profilesData = [{ profileId: "--None--", profileName: $TR.NONE }];
                profilesData = profilesData.concat(me.__metaData.svmxProfiles);
                var profilesStore = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
                    fields: ['profileId', 'profileName'],
                    data: profilesData
                });
                me.__profilePicklist = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXPicklist", {
                    id: 'profileId',
                    name: 'profileName',
                    align: 'center',
                    fieldLabel: $TR.PROFILE,
                    labelWidth: 60,
                    labelField: 'profileName',
                    valueField: 'profileId',
                    displayField: 'profileName',
                    width: 300,
                    store: profilesStore,
                    parentContext: me,
                    listeners: {
                        select: function(combo, records, eOpts) {
                            me.__didProfileSelect(combo, records, eOpts);
                        },
                        afterrender: function(combo) {
                            var recordSelected = combo.getStore().getAt(0);
                            combo.setValue(recordSelected.get('profileId'));
                        }
                    },
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });
                var radioGroup = {
                    xtype: 'radiogroup',
                    id: 'groupradiocomp',
                    disabled: true,
                    margin: '0 0 0 25',
                    bind: {
                        value: '{}'
                    },
                    listeners: {
                        change: function(field, newValue, oldValue) {
                            me.__grid.getStore().clearFilter();
                            var filters = [new Ext.util.Filter({
                                filterFn: function(item) {
                                    if (newValue.users == 'userWithPermission') {
                                       me.__store.filterData = me.__store.allData.filter(function(item) {
                                            return (item.isChecklistEnabled === true || item.isSFMEnabled === true);
                                        });
                                        return (item.get('isChecklistEnabled') == true || item.get('isSFMEnabled') == true);
                                    } else if (newValue.users == 'alluser') {
                                        me.__store.filterData = me.__store.allData;
                                        return (item.get('isChecklistEnabled') == false) || (item.get('isChecklistEnabled') == true) || (item.get('isSFMEnabled') == true) || (item.get('isSFMEnabled') == false);
                                    }
                                }
                            })];
                            me.__grid.getStore().filter(filters);
                            me.__store.loadPage(1);
                            me.__updateSelectAllCheckboxes();
                        }
                    },
                    defaults: {
                        name: 'users'
                    },
                    items: [{
                            boxLabel: $TR.ALL_USER,
                            inputValue: 'alluser',
                            checked: true,
                            width: 100,
                        },
                        {
                            boxLabel: $TR.USER_WITH_PERMISSION,
                            inputValue: 'userWithPermission',
                            width: 150
                        }
                    ]
                };
                me.searchTextField = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                    cls: 'svmx-text-filter-icon',
                    width: 300,
                    id: 'searchtextfield',
                    emptyText: $TR.SEARCH_FOR_USERNAME_OR_EMAIL,
                    selectOnFocus: true,
                    disabled: true,
                    margin: '0 0 0 5'
                });
                me.searchButton = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: $TR.SEARCH,
                    tootip: $TR.SEARCH,
                    disabled: true,
                    cls: 'fp-btn-neutral',
                    style: {
                        marginLeft: '10px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function() {
                        if (Object.keys(me.__modifiedUsers).length) {
                            Ext.Msg.show({
                                title: $TR.ABANDON_CHANGES,
                                msg: $TR.ERROR_PROFILE_CHANGE,
                                width: 400,
                                closable: false,
                                cls: 'fp-confirmation-window',
                                buttons: Ext.Msg.YESNO,
                                buttonText: {
                                    yes: $TR.CANCEL,
                                    no: $TR.ABANDON
                                },
                                multiline: false,
                                fn: function(buttonValue, inputText, showConfig) {
                                    if (buttonValue == 'no') me.__doSearch();
                                }
                            });
                        } else {
                            me.__doSearch();
                        }
                    }
                });
                var navigationBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: '100%',
                    dock: "bottom",
                    border: false,
                    cls: 'svmx-feature-permission-main-nav',
                });
                var toolBar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    width: 'calc(100% - 20px)',
                    height: 50,
                    dock: "bottom",
                    border: false,
                    margin: 10
                });
                var backToSetupHomeButton = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: $TR.SETUP_HOME,
                    docked: 'left',
                    rigion: 'left',
                    align: 'left',
                    cls: 'svmx-feature-permission-back-btn',
                    handler: function() {
                        //me.__backToSetuphome();
                        //Added for the story BAC-4860
                        var urlString = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                        if((typeof sforce != 'undefined') && (sforce != null)){
                            urlString = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup";
                            sforce.one.navigateToURL(urlString);
                        }
                        else{
                            window.location = urlString;
                        }
                    }
                });
                var pageTitle = {
                    xtype: 'label',
                    forId: 'pagetitle',
                    text: $TR.FEATURE_PERMISSION,
                    margins: '0 0 0 0'
                };
                var helpIcon = {
                    iconCls: '',
                    cursor: 'pointer',
                    scale: 'small',
                    cls: 'svmx-feature-permission-help-btn',
                    tooltip: $TR.HELP,
                    href: $TR.HELP_URL,
                    style: {
                        marginRight: '25px',
                    }
                };
                navigationBar.add(backToSetupHomeButton);
                navigationBar.add(pageTitle);
                navigationBar.add('->');
                navigationBar.add(helpIcon);
                toolBar.add(me.__profilePicklist);
                toolBar.add(radioGroup);
                toolBar.add('->');
                toolBar.add(me.searchTextField);
                toolBar.add(me.searchButton);

                Ext.define('userModel', {
                    extend: 'Ext.data.Model',
                    fields: [
                        { name: 'userId', type: 'string' },
                        { name: 'name', type: 'string' },
                        { name: 'userName', type: 'string' },
                        { name: 'isChecklistEnabled', type: 'boolean' },
                        { name: 'isSFMEnabled', type: 'boolean' }
                    ]
                });
                var itemsPerPage = 100;
                me.__store = SVMX.create('Ext.data.Store', {
                    model: 'userModel',
                    data: [],
                    storeId: 'user_store',
                    autoLoad: false,
                    pageSize: itemsPerPage,
                    parentContext: me,
                    proxy: {
                        type: 'memory',
                        reader: { type: 'array', root: 'data', totalProperty: 'total' }
                    },
                    allData: [],
                    filterData: [],
                    listeners: {
                        beforeload: function(store, operation, eOpts) {
                            var shouldShowAll = Ext.getCmp("groupradiocomp").items.items[0].getValue();
                            store.clearFilter();
                            var data;
                            if (shouldShowAll) {
                                data = this.allData || [];
                            } else {
                                data = this.filterData || [];
                            }
                            var page = operation.start;
                            var limit = operation.limit;
                            var pagedData = data.slice(page, page + limit);
                            var pagedModelData = [];
                            for (var i = 0; i < pagedData.length; i++) {
                                var entObj = Ext.create('userModel', pagedData[i]);
                                pagedModelData.push(entObj);
                            }
                            store.proxy.data = {
                                data: pagedModelData,
                                total: data.length,
                            };
                        }
                    }
                });
                me.__grid = SVMX.create("com.servicemax.client.featurepermission.Grid", {
                    parentContext: me,
                    store: me.__store,
                    autoScroll: true,
                    margin: '5 10',
                    anchor: '100%',
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '2px',
                        marginBottom: '2px'
                    },
                    height: 570,
                    margin: '10',
                    autoScroll: true,
                    layout: 'fit',
                    selType: 'cellmodel',
                    flex: 9.5
                });
                var items = [navigationBar, toolBar, me.__grid];
                return items;
            },

            __doSearch: function() {
                var me = this;
                me.__modifiedUsers = {};
                me.__grid.getStore().clearFilter();
                Ext.getCmp("groupradiocomp").items.items[0].setValue(true);
                var searchValue = me.searchTextField.getValue();
                me.__getUserData(me.__currentProfile[0].data.profileId, searchValue);
            },

            __didProfileSelect: function(combo, records, eOpts) {
                var me = this;
                me.__newProfile = records;
                if (Object.keys(me.__modifiedUsers).length) {
                    Ext.Msg.show({
                        title: $TR.ABANDON_CHANGES,
                        msg: $TR.ERROR_PROFILE_CHANGE,
                        width: 400,
                        closable: false,
                        cls: 'fp-confirmation-window',
                        buttons: Ext.Msg.YESNO,
                        buttonText: {
                            yes: $TR.CANCEL,
                            no: $TR.ABANDON
                        },
                        multiline: false,
                        fn: function(buttonValue, inputText, showConfig) {
                            if (buttonValue == 'no') me.__didProfileChange(me.__newProfile);
                            if (buttonValue == 'yes') me.__profilePicklist.setValue(me.__currentProfile[0].data.profileId);
                        }
                    });
                } else {
                    me.__currentProfile = records;
                    me.__didProfileChange(records);
                }
            },

            __didProfileChange: function(records) {
                var me = this;
                me.searchTextField.setValue('');
                me.__modifiedUsers = {};
                me.__grid.getStore().clearFilter();
                Ext.getCmp("groupradiocomp").items.items[0].setValue(true);
                if (records[0].data.profileId == '--None--') {
                    Ext.getCmp("groupradiocomp").setDisabled(true);
                    me.searchButton.setDisabled(true);
                    me.__grid.saveButton.setDisabled(true);
                    Ext.getCmp("searchtextfield").setDisabled(true);
                    me.__grid.getStore().loadData([]);
                    document.getElementById('allchecklist').checked = false;
                    document.getElementById('allsfm').checked = false;
                    document.getElementById('allchecklist').disabled = true;
                    document.getElementById('allsfm').disabled = true;
                    me.__store.allData = [];
                    me.__store.filterData = [];
                    me.__store.loadPage(1);
                } else {
                    Ext.getCmp("groupradiocomp").setDisabled(false);
                    me.searchButton.setDisabled(false);
                    me.__grid.saveButton.setDisabled(false);
                    Ext.getCmp("searchtextfield").setDisabled(false);
                    me.__getUserData(records[0].data.profileId, '');
                }
            },

            __getUserData: function(profileId, searchValue) {
                var me = this;
                Ext.getCmp("groupradiocomp").items.items[0].setValue(true);
                me.__app.blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "FEATUREPERMISSION.GET_USER_DATA", this, {
                        request: {
                            context: me,
                            profileId: profileId,
                            searchValue: searchValue
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },

            onGetUserDataComplete: function(userData) {
                var me = this;
                me.__app.unblockUI();
                me.__store.allData = userData.svmxUser;
                me.__store.filterData = userData.svmxUser;
                me.__store.loadPage(1);
                me.__updateSelectAllCheckboxes();
                me.__updateActionItems();
            },
            __updateActionItems: function() {
                var me = this;
                var svmxUsers = me.__store.allData;
                if (svmxUsers.length == 0) {
                    Ext.getCmp("groupradiocomp").setDisabled(true);
                    me.__grid.saveButton.setDisabled(true);
                    document.getElementById('allchecklist').checked = false;
                    document.getElementById('allsfm').checked = false;
                } else {
                    Ext.getCmp("groupradiocomp").setDisabled(false);
                    me.__grid.saveButton.setDisabled(false);
                    document.getElementById('allchecklist').disabled = false;
                    document.getElementById('allsfm').disabled = false;
                }
            },
            __updateSelectAllCheckboxes: function() {
                var me = this;
                var shouldShowAll = Ext.getCmp("groupradiocomp").items.items[0].getValue();
                var svmxUsers = [];
                if (shouldShowAll) {
                    svmxUsers = me.__store.allData;
                } else {
                    svmxUsers = me.__store.filterData;
                }
                if (svmxUsers.length > 0) {
                    document.getElementById('allchecklist').checked = true;
                    document.getElementById('allsfm').checked = true;
                } else {
                    document.getElementById('allchecklist').checked = false;
                    document.getElementById('allsfm').checked = false;
                }

                for (var i = 0; i < svmxUsers.length; i++) {
                    if (!svmxUsers[i].isChecklistEnabled) {
                        document.getElementById('allchecklist').checked = false;
                        break;
                    }
                }
                for (var i = 0; i < svmxUsers.length; i++) {
                    if (!svmxUsers[i].isSFMEnabled) {
                        document.getElementById('allsfm').checked = false;
                        break;
                    }
                }
            },
            __backToSetuphome: function() {
                window.location = "/apex/" + SVMX.OrgNamespace + "__CONF_SetupHome";
            }

        });

        Ext.define("com.servicemax.client.featurepermission.Grid", {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            alias: 'widget.svmx.featurepermission.grid',
            __store: null,
            constructor: function(config) {
                var me = this;
                me.saveButton = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: $TR.SAVE,
                    tootip: $TR.SAVE,
                    disabled: true,
                    style: {
                        marginLeft: '10px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function() {
                        me.__saveData();
                    }
                });
                me.__store = config.store;
                config = Ext.apply({
                        store: me.__store,
                        emptyText: '<span>'+ $TR.NO_USER_FOUND +'</span>',
                        columns: [
                            { text: $TR.NAME, dataIndex: 'name', width: '30%',
                            renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                                } 
                            },
                            { text: $TR.USER_NAME, dataIndex: 'userName', width: '30%',
                            renderer: function(value) {
                                 return Ext.String.htmlEncode(value);
                                } 
                            },
                            {
                                xtype: 'checkColumnEditor',
                                headerCheckbox: true,
                                text: "<input type='checkbox' disabled id = 'allchecklist' class='grid-header-checkbox'>".concat($TR.CHECKLIST),
                                dataIndex: 'isChecklistEnabled',
                                width: '20%',
                                sortable: false,
                                listeners: {
                                    scope: me,
                                    checkchange: me.__onChecklistCheckChange,
                                    headerclick: me.__checklistHeaderclick
                                }
                            },
                            {
                                xtype: 'checkColumnEditor',
                                headerCheckbox: true,
                                text: "<input type='checkbox' disabled id = 'allsfm' class='grid-header-checkbox'>".concat($TR.SFM_DESIGNER),
                                dataIndex: 'isSFMEnabled',
                                width: '20%',
                                sortable: false,
                                listeners: {
                                    scope: me,
                                    checkchange: me.__onSFMCheckChange,
                                    headerclick: me.__sfmHeaderClick
                                }
                            }

                        ],
                        bbar: [{
                                xtype: 'pagingtoolbar',
                                store: me.__store,
                                dock: 'bottom',
                                cls: 'svmx-feature-permission-pagingtoolbar',
                                align: 'center',
                                displayInfo: false,
                                displayMsg: $TR.PAGE + '{0}' + $TR.OF + '{1}',
                                listeners: {
                                    afterrender: function() {
                                        this.child('#refresh').hide();
                                        document.querySelectorAll('.svmx-toolbar-text.svmx-box-item')[1].innerHTML = $TR.OF + ' ' + 0;
                                    },
                                    change: function(e, pageData, eOpts) {
                                        document.querySelectorAll('.svmx-toolbar-text.svmx-box-item')[1].innerHTML = $TR.OF + ' ' + pageData.pageCount;
                                    }
                                }
                            }, '->',
                            {
                                xtype: 'svmx.button',
                                itemId: "cancelbtn",
                                cls: 'fp-btn-neutral',
                                dock: 'bottom',
                                padding: '0',
                                text: $TR.CANCEL,
                                handler: function(e, el, owner, tool) {
                                    if (Object.keys(me.parentContext.__modifiedUsers).length) {
                                        Ext.Msg.show({
                                            title: $TR.ABANDON_CHANGES,
                                            msg: $TR.CANCEL_MESSAGE,
                                            width: 400,
                                            closable: false,
                                            cls: 'fp-confirmation-window',
                                            buttons: Ext.Msg.YESNO,
                                            buttonText: {
                                                yes: $TR.CANCEL,
                                                no: $TR.ABANDON
                                            },
                                            multiline: false,
                                            fn: function(buttonValue, inputText, showConfig) {
                                                if (buttonValue == 'no') me.parentContext.__backToSetuphome();
                                            }
                                        });
                                    } else {
                                        me.parentContext.__backToSetuphome();
                                    }
                                }
                            },
                            me.saveButton
                        ],
                        listeners: {}
                    },
                    config || {});
                me.callParent([config]);
            },

            __saveData: function() {
                var me = this;
                var modifiedUsers = me.__getModifiedUsers();
                me.parentContext.__app.blockUI();
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "FEATUREPERMISSION.SAVE_DATA", this, {
                        request: {
                            context: me,
                            modifiedUsers: modifiedUsers
                        }
                    });
                SVMX.getCurrentApplication().getEventBus().triggerEvent(evt);
            },
            __getModifiedUsers: function(){
                var me = this;
                var modifiedUsers = [];
                var modifiedUsersObject = me.parentContext.__modifiedUsers;
                for(var key in modifiedUsersObject) {
                    if(modifiedUsersObject.hasOwnProperty(key)) {
                        modifiedUsers.push(modifiedUsersObject[key]);
                    }
                }
                return  modifiedUsers;
            },
            saveDataComplete: function(response) {
                var me = this;
                var parentContext = me.parentContext;
                parentContext.__modifiedUsers = {};
                parentContext.__app.unblockUI();
                parentContext.__getUserData(parentContext.__currentProfile[0].data.profileId, parentContext.searchTextField.getValue());
                Ext.Msg.alert({
                    title : $TR.STATUS, 
                    msg : $TR.RECORD_SUCCESSFULLY_SAVED,
                    buttonText : { ok : $TR.OK }
                });
            },

            __onChecklistCheckChange: function(e, recordIndex, checked) {
                var me = this;
                var data = me.store.data.items[recordIndex].data;
                me.parentContext.__modifiedUsers[data.userId] = data;
                me.parentContext.__modifiedUsers[data.userId].isChecklistUpdated = true;
                var matchedObject = me.store.allData.find(function(object) {
                    if (object.userId == data.userId) return true;
                    return false;
                });
                if (typeof(matchedObject) === 'object') {
                    matchedObject.isChecklistEnabled = data.isChecklistEnabled;
                }

                me.parentContext.__updateSelectAllCheckboxes();
            },

            __checklistHeaderclick: function(ct, column, e, t, eOpts) {
                var me = this;
                if (me.parentContext.__profilePicklist.getSelectedData().profileId === '--None--') return;
                var shouldShowAll = Ext.getCmp("groupradiocomp").items.items[0].getValue();
                var data;
                if (shouldShowAll) {
                    data = me.store.allData || [];
                } else {
                    data = me.store.filterData || [];
                }
                var isAllSelected = !document.getElementById('allchecklist').checked;
                var store = me.store;
                var dataIndex = column.dataIndex;
                for (var i = 0; i < store.getCount(); i++) {
                    var record = store.getAt(i);
                    if (isAllSelected) {
                        record.set(dataIndex, true);
                    } else {
                        record.set(dataIndex, false);
                    }
                }
                for (var i = 0; i < data.length; i++) {
                    if (isAllSelected) {
                        data[i].isChecklistEnabled = true;
                    } else {
                        data[i].isChecklistEnabled = false;
                    }
                }
                if (isAllSelected) {
                    me.parentContext.__modifiedUsers = {};
                }
                me.parentContext.__modifiedUsers = data;
                for (var i = 0; i < me.parentContext.__modifiedUsers.length; i++) me.parentContext.__modifiedUsers[i].isChecklistUpdated = true;

                if (!isAllSelected) {
                    document.getElementById('allchecklist').checked = false;
                } else {
                    document.getElementById('allchecklist').checked = true;
                }
            },
            __onSFMCheckChange: function(e, recordIndex, checked) {
                var me = this;
                var data = me.store.data.items[recordIndex].data;
                me.parentContext.__modifiedUsers[data.userId] = data;
                me.parentContext.__modifiedUsers[data.userId].isSFMUpdated = true;
                var matchedObject = me.store.allData.find(function(object) {
                    if (object.userId == data.userId) return true;
                    return false;
                });
                if (typeof(matchedObject) === 'object') {
                    matchedObject.isSFMEnabled = data.isSFMEnabled;
                }
                me.parentContext.__updateSelectAllCheckboxes();
            },

            __sfmHeaderClick: function(ct, column, e, t, eOpts) {
                var me = this;
                if (me.parentContext.__profilePicklist.getSelectedData().profileId === '--None--') return;
                var shouldShowAll = Ext.getCmp("groupradiocomp").items.items[0].getValue();
                var data;
                if (shouldShowAll) {
                    data = me.store.allData || [];
                } else {
                    data = me.store.filterData || [];
                }
                var isAllSelected = !document.getElementById('allsfm').checked;
                var store = me.store;
                var dataIndex = column.dataIndex;
                for (var i = 0; i < store.getCount(); i++) {
                    var record = store.getAt(i);
                    if (isAllSelected) {
                        record.set(dataIndex, true);
                    } else {
                        record.set(dataIndex, false);
                    }
                }
                for (var i = 0; i < data.length; i++) {
                    if (isAllSelected) {
                        data[i].isSFMEnabled = true;
                    } else {
                        data[i].isSFMEnabled = false;
                    }
                }
                if (!isAllSelected) {
                    me.parentContext.__modifiedUsers = {};
                }
                me.parentContext.__modifiedUsers = data;
                for (var i = 0; i < me.parentContext.__modifiedUsers.length; i++) me.parentContext.__modifiedUsers[i].isSFMUpdated = true;
                if (!isAllSelected) {
                    document.getElementById('allsfm').checked = false;
                } else {
                    document.getElementById('allsfm').checked = true;
                }
            }
        });

        Ext.define('Ext.ux.CheckBoxColumnEditor', {
            extend: 'Ext.grid.column.Column',
            alias: 'widget.checkColumnEditor',

            /**
             * @cfg {Boolean} [stopSelection=true]
             * Prevent grid selection upon mousedown.
             */
            stopSelection: true,

            tdCls: Ext.baseCSSPrefix + 'grid-cell-checkcolumn',

            constructor: function() {
                this.addEvents(
                    /**
                     * @event beforecheckchange
                     * Fires when before checked state of a row changes.
                     * The change may be vetoed by returning `false` from a listener.
                     * @param {Ext.ux.CheckColumn} this CheckColumn
                     * @param {Number} rowIndex The row index
                     * @param {Boolean} checked True if the box is to be checked
                     */
                    'beforecheckchange',
                    /**
                     * @event checkchange
                     * Fires when the checked state of a row changes
                     * @param {Ext.ux.CheckColumn} this CheckColumn
                     * @param {Number} rowIndex The row index
                     * @param {Boolean} checked True if the box is now checked
                     */
                    'checkchange'
                );
                this.callParent(arguments);
            },

            /**
             * @private
             * Process and refire events routed from the GridView's processEvent method.
             */
            processEvent: function(type, view, cell, recordIndex, cellIndex, e, record, row) {
                var me = this,
                    key = type === 'keydown' && e.getKey(),
                    mousedown = type == 'mousedown';

                if (mousedown || (key == e.ENTER || key == e.SPACE)) {
                    var dataIndex = me.dataIndex,
                        checked = !record.get(dataIndex);

                    // Allow apps to hook beforecheckchange
                    if (me.fireEvent('beforecheckchange', me, recordIndex, checked) !== false) {
                        record.set(dataIndex, checked);
                        me.fireEvent('checkchange', me, recordIndex, checked);

                        // Mousedown on the now nonexistent cell causes the view to blur, so stop it continuing.
                        if (mousedown) {
                            e.stopEvent();
                        }

                        // Selection will not proceed after this because of the DOM update caused by the record modification
                        // Invoke the SelectionModel unless configured not to do so
                        if (!me.stopSelection) {
                            view.selModel.selectByPosition({
                                row: recordIndex,
                                column: cellIndex
                            });
                        }

                        // Prevent the view from propagating the event to the selection model - we have done that job.
                        return false;
                    } else {
                        // Prevent the view from propagating the event to the selection model if configured to do so.
                        return !me.stopSelection;
                    }
                } else {
                    return me.callParent(arguments);
                }
            },

            // Note: class names are not placed on the prototype bc renderer scope
            // is not in the header.
            renderer: function(value) {
                var cssPrefix = Ext.baseCSSPrefix,
                    cls = [cssPrefix + 'grid-checkheader'];

                if (value) {
                    cls.push(cssPrefix + 'grid-checkheader-checked');
                }
                return '<center><div class="' + cls.join(' ') + '">&#160;</div></center>';
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.featurepermission\src\util.js
(function(){

// Array.prototype.find is not supported in any version of IE hence adding Polyfill for same.
	
	if (!Array.prototype.find) {
  	Object.defineProperty(Array.prototype, 'find', {
    value: function(predicate) {
     // 1. Let O be ? ToObject(this value).
      if (this == null) {
        throw new TypeError('"this" is null or not defined');
      }

      var o = Object(this);

      // 2. Let len be ? ToLength(? Get(O, "length")).
      var len = o.length >>> 0;

      // 3. If IsCallable(predicate) is false, throw a TypeError exception.
      if (typeof predicate !== 'function') {
        throw new TypeError('predicate must be a function');
      }

      // 4. If thisArg was supplied, let T be thisArg; else let T be undefined.
      var thisArg = arguments[1];

      // 5. Let k be 0.
      var k = 0;

      // 6. Repeat, while k < len
      while (k < len) {
        // a. Let Pk be ! ToString(k).
        // b. Let kValue be ? Get(O, Pk).
        // c. Let testResult be ToBoolean(? Call(predicate, T, « kValue, k, O »)).
        // d. If testResult is true, return kValue.
        var kValue = o[k];
        if (predicate.call(thisArg, kValue, k, o)) {
          return kValue;
        }
        // e. Increase k by 1.
        k++;
      }

      // 7. Return undefined.
      return undefined;
    }
  });
}
})();

