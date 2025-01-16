
(function(){

    var appImpl = SVMX.Package("com.servicemax.client.qbm.ui.desktop.api");

    appImpl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("CQL");

        Ext.define("com.servicemax.client.qbm.ui.desktop.api.RootContainer", {
            extend: "com.servicemax.client.ui.components.composites.impl.SVMXSection",
            alias: 'widget.qbm.rootcontainer',
            layout: "border",
            cls: "qbm-root-container",
            __resultsViewPanel: null,
            __runOpts: null,
            height: "100%",
            __parent: this,
            constructor: function(config) {
                var urlLocation = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                var urlParams = window.location.search.substring(1);
                var backButtonTitle = TS.T("TAG002", "Back To Setup Home");
                if (urlParams && urlParams.indexOf("isStandAloneChecklist") !=-1) {
                    urlLocation = "/apex/"+SVMX.OrgNamespace+"__CONF_FeatureSetup";
                    backButtonTitle = TS.T("COMM008", "Back To Feature Setup");
                }
                //Added else if condition for the story BAC-4797
                else if((typeof sforce != 'undefined') && (sforce != null)){
                    urlLocation = "/lightning/n/"+SVMX.OrgNamespace+"__ServiceMax_Setup";
                }
                config = Ext.apply({

                   header: {
                        items: [{
                            xtype: 'svmx.button', itemId  : "BackButton",
                            padding: '0',
                            text : backButtonTitle,           
                            handler: function(e, el, owner, tool) {
                                //Added if condition for the story BAC-4797
                                if((typeof sforce != 'undefined') && (sforce != null)){
                                    sforce.one.navigateToURL(urlLocation);
                                }
                                else{
                                    window.location = urlLocation;
                                }
                            }
                        }]
                    },

                    collapsible: false,

                    // TODO: Translation Required
                    title: SVMX.getClient().getApplicationParameter("svmx-sfm-hide-title-bar") ? "" : TS.T("TAG003", "Checklist Question Library"),
                    titleAlign: "center",

                    layout: {
                        type: "border"
                    }
                }, config || {});
                this.callParent([config]);
            },

            run: function(options) {
                var me = this;
                this.__runOpts = options;

                // A panel to hold everything if in the future the view gets more complex
                this.__mainPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXContainer", {
                    region: "center",
                    width: "100%",

                    layout: {
                        type: "vbox",
                        align: "stretch"
                    }
                });
                this.add(this.__mainPanel);

                this.__libraryPanel = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXContainer", {
                    region: "center",
                    width: "100%",
                    flex: 1, hidden: true,

                    layout: {
                        type: "vbox",
                        align: "stretch"
                    }
                });
                this.__mainPanel.add(this.__libraryPanel);

                this.__editPanel = SVMX.create("com.servicemax.client.qbm.ui.desktop.EditPanel", {
                    region: "center",
                    width: "100%",
                    flex: 1, hidden: true,
                    __parent: this
                });
                this.__mainPanel.add(this.__editPanel);

                // set up the search toolbar
                var toolbar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    dock: "top",
                    flex: 0.5
                });

                // search text field
                var searchtext = SVMX.create('com.servicemax.client.ui.components.controls.impl.SVMXText', {
                    cls: 'svmx-text-filter-icon',
                    width: 300,
                    //emptyText: TS.T("TAG0003"),
                    emptyText: TS.T("TAG004", "Search for Questions"),
                    selectOnFocus: false,
                    style: {
                        marginLeft: '20px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    listeners: {
                        change: function(f, e) {
                            var keyword = searchtext.getValue();
                            me.__resultsViewPanel.__questionListStore.clearFilter();
                            //me.__resultsViewPanel.__questionListStore.filter('question', keyword);
                            me.__resultsViewPanel.__questionListStore.filter('question',  new RegExp(Ext.escapeRe(keyword),'i'));
                        }
                    }
                });
                toolbar.addItemsLeft(searchtext);


                /*
                // Back to setup home button
                var backToSetupHomeBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TODO", "Back To Setup Home"),
                    tootip: TS.T("TODO", "Back To Setup Home"),
                    style: {
                        marginLeft: '10px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function() {
                        window.location = "/apex/"+SVMX.OrgNamespace+"__CONF_SetupHome";
                    }
                });
                toolbar.addItemsLeft(backToSetupHomeBtn);

                */

                // Add button
                var addBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG005", "Add"),
                    tootip: TS.T("TODO", "Create a Question"),
                    style: {
                        marginLeft: '2px',//Try css file
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function() {
                        me.showEditPanel(false);
                    }
                });
                toolbar.addItemsRight(addBtn);

                // Delete button
                var deleteBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG006", "Delete"),
                    tootip: TS.T("TODO", "Delete a Question"),
                    disabled: true,
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function () {
                        var selection = me.__resultsViewPanel.getSelectedItems();
                        if(selection.length === 1){
                            Ext.Msg.confirm(TS.T("TAG007","Confirm Delete"), TS.T("TAG008","The question will be deleted. This action cannot be undone"), function(answer) {
                                if (answer === "yes") {
                                    me.blockApplication();
                                    me.deliveryEngine.deleteQuestion(selection[0]);
                                }
                            }, this);
                        }
                    }
                });
                toolbar.addItemsRight(deleteBtn);

                // Previous button
                var previousBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG009", "PREVIOUS"),
                    tootip: TS.T("TODO", "Get Previous List of Question"),
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function () {
                        me.blockApplication();
                        me.deliveryEngine.previousQuestionList();
                    }
                });
                toolbar.addItemsRight(previousBtn);

                // Next button
                var nextBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG010", "NEXT"),
                    tootip: TS.T("TODO", "Get Next List of Question"),
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function () {
                        me.blockApplication();
                        me.deliveryEngine.nextQuestionList();
                    }
                });
                toolbar.addItemsRight(nextBtn);

                this.__libraryPanel.add(toolbar);
                this.__toolbar = toolbar;
                this.__deleteButton = deleteBtn;

                // results view
                this.__resultsViewPanel = SVMX.create("com.servicemax.client.qbm.ui.desktop.Grid", {
                    metaModel: this.metaModel,
                    __parent: this,
                    deliveryEngine: this.deliveryEngine,
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '2px',
                        marginBottom: '2px'
                    },
                    flex: 9.5
                });
                this.__libraryPanel.add( this.__resultsViewPanel );
                // end results view

                this.resize();
                this.showLibraryPanel();
            },

            showLibraryPanel: function(){
                this.__editPanel.hide();
                this.__libraryPanel.show();
            },

            showEditPanel: function(isEditMode, question){
                this.__libraryPanel.hide();
                this.__editPanel.show();
                this.__editPanel.setActiveQuestion(isEditMode, question);
            },

            setAndSaveQuestionData: function(){
                var ques = this.__editPanel.formPanel.getData();
                var isValuesBlank = false;
                var isRespSetNameBlank = false;
                //ques['questionText'] = Ext.String.htmlEncode( ques['questionText'] );
                var question = ques['questionText'] && ques['questionText'].trim();
                if(ques['answers'] != undefined){
                    var answerslst = SVMX.typeOf(ques['answers']) === "string"? [ques['answers']] : ques['answers'];
                    var l = answerslst.length;
                    for(var i =0; i < l; i++){
                        var answerValue = Ext.String.htmlEncode( answerslst[i].trim() );
                        if(!(answerValue != '' && answerValue.length > 0))
                            isValuesBlank = true;
                    }
                }

                var responseTypeArray = ['Checkbox','Radio Button','Picklist','Multi-select Picklist'];
                var responseIndex = responseTypeArray.indexOf(ques['response_Type']);
                if(responseIndex != -1 && ques['newResponseSetName'] != undefined && ques['newResponseSetName'].trim() == '')
                    isRespSetNameBlank = true;

                if(question != '' && question.length > 0 && !isValuesBlank && !isRespSetNameBlank){
                    this.blockApplication();
                    this.deliveryEngine.saveQuestion(ques);
                }
                else{
                    Ext.Msg.alert(TS.T("TAG011","Failure"), TS.T("TAG012","Please fill all the Required fields"));
                }

            },

            showMessage: function(msg){
                var sta = Ext.Msg.alert(TS.T("TAG013","Success"), Ext.String.htmlEncode(msg), function(btn, text){
                    if (btn == 'ok'){
                        this.showLibraryPanel();
                    }
                }, this);
            },

            onFailure: function(msg, msgType){
                this.unblockApplication();
                if(msgType === 'DUPLICATE_RESPONSE_SET'){
                    var sta = Ext.Msg.alert(TS.T("TAG011","Failure"), Ext.String.htmlEncode(msg), function(btn, text){

                    }, this);
                }
                else{
                    var sta = Ext.Msg.alert(TS.T("TAG011","Failure"), Ext.String.htmlEncode(msg), function(btn, text){
                        if (btn == 'ok'){
                            this.showLibraryPanel();
                        }
                    }, this);
                }
            },

            onDeleteFailure: function(msg, lstProcessName){
                msg = Ext.String.htmlEncode(msg);
                var i, l = lstProcessName && lstProcessName.length;
                msg = msg + '<ol>';
                for(i = 0; i < l; i++){
                    msg = msg + '<li>' + Ext.String.htmlEncode(lstProcessName[i]) + '</li>';
                    if(i === 3)
                        break;
                }
                msg = msg + '</ol>';
                if(i === 3 && l > i+1){
                    msg = msg + '<br>'+TS.T("TAG015","and") +' '+ (l-(i+1)) +' '+ TS.T("TAG016","more");
                }
                this.unblockApplication();
                var sta = Ext.Msg.alert(TS.T("TAG014","Unable To Delete"), msg);
            },
			onSaveFailure: function(msg, lstProcessName){
                msg = Ext.String.htmlEncode(msg);
                var i, l = lstProcessName && lstProcessName.length;
                msg = msg + '<ol>';
                for(i = 0; i < l; i++){
                    msg = msg + '<li>' + Ext.String.htmlEncode(lstProcessName[i]) + '</li>';
                    if(i === 3)
                        break;
                }
                msg = msg + '</ol>';
                if(i === 3 && l > i+1){
                    msg = msg + '<br>'+TS.T("TAG015","and") +' '+ (l-(i+1)) +' '+ TS.T("TAG016","more");
                }
                this.unblockApplication();
                var sta = Ext.Msg.alert(TS.T("TAG047","Unable To Save"), msg);
            },

            resize: function(size) {
                if (!this.getEl()) return SVMX.timer.job(this.id + ".resize", 10, this, "resize");
                if (!size) size = this.getEl().getViewSize();

                // -4 because of internal padding
                if (size.width) size.width = size.width - 4;
                if (size.height) size.height = size.height - 6;

                if (size.width) this.setWidth(size.width);
                if (size.height) this.setHeight(size.height);
            },

            blockApplication: function(params) {
                var p = params || {
                    request: {
                        state: "block",
                        deliveryEngine: this.getDeliveryEngine()
                    },
                    responder: {}
                };
                var currentApp = this.getDeliveryEngine().getEventBus();
                //TODO: Change for QBM, let the world know they cannot update the QBM
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "QBM.CHANGE_APP_STATE", this, p);
                currentApp.triggerEvent(evt);
            },

            unblockApplication: function(params) {
                var p = params || {
                    request: {
                        state: "unblock",
                        deliveryEngine: this.getDeliveryEngine()
                    },
                    responder: {}
                };
                var currentApp = this.getDeliveryEngine().getEventBus();
                //TODO: Change for QBM,  let the world know QBM is ready to take events/data
                var evt = SVMX.create("com.servicemax.client.lib.api.Event", "QBM.CHANGE_APP_STATE", this, p);
                currentApp.triggerEvent(evt);
            },

            getDeliveryEngine: function() {
                return this.deliveryEngine;
            }
        });

        Ext.define("com.servicemax.client.qbm.ui.desktop.EditPanel", {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXContainer',
            alias: 'widget.svmx.qbm.editpanel',

            constructor: function(config) {
                config = Ext.apply({
                    layout: {
                        type: "vbox",
                        align: "stretch"
                    }
                }, config || {});
                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                var editToolbar = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXToolbar", {
                    dock: "top",
                    flex: 0.5
                });

                // Cancel button
                var cancelBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG017", "Cancel"),
                    tootip: TS.T("TODO", "Back to Question listing page"),
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function() {
                        me.__parent.showLibraryPanel();
                    }
                });
                editToolbar.addItemsLeft(cancelBtn);

                // Save button
                var saveBtn = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    text: TS.T("TAG018", "Save"),
                    tootip: TS.T("TODO", "Save a Question"),
                    style: {
                        marginLeft: '2px',
                        marginRight: '2px',
                        marginTop: '0px',
                        marginBottom: '0px'
                    },
                    handler: function() {
                        me.__parent.setAndSaveQuestionData();
                    }
                });
                editToolbar.addItemsRight(saveBtn);
                this.add(editToolbar);

                this.formPanel = SVMX.create("com.servicemax.client.qbm.ui.desktop.editQuestion.EditQuestionPanel", {
                    titleAlign: 'center', width: '90%', __parent: this, flex: 9.5
                });
                this.add(this.formPanel);
            },

            setActiveQuestion: function(isEditMode, question){
                if(!isEditMode){
                    this.formPanel.setTitle(TS.T("TAG019","Add Question"));
                    this.formPanel.radioButton.hide();
                    this.formPanel.__newResponseSetName.hide();
                }else{
                    this.formPanel.radioButton.show();
                    this.formPanel.setTitle(TS.T("TAG020","Edit Question"));
                }
                this.formPanel.loadQuestionDataInEditMode(isEditMode, question || {});
            }
        });

        Ext.define("com.servicemax.client.qbm.ui.desktop.Grid", {
            extend: 'com.servicemax.client.ui.components.composites.impl.SVMXListComposite',
            alias: 'widget.svmx.qbm.grid',

            constructor: function(config) {
                var me = this;
                var selectionModel = SVMX.create('Ext.selection.CheckboxModel', {
                    showHeaderCheckbox : false,
                    mode: "SINGLE",

                    //this is included OR overrided to fix the defect 029308
                    setLastFocused: function(record, supressFocus) {
                        var me = this,
                            recordBeforeLast = record;
                        me.lastFocused = record;

                        // Only call the changed method if in fact the selected record *has* changed.
                        if (record !== recordBeforeLast) {
                            me.onLastFocusChanged(recordBeforeLast, record, supressFocus);
                        }
                    },
                    //this is included OR overrided to fix the defect 029308
                    onRowMouseDown: function(b, a, h, d, i) {
                        // b.el.focus();
                        var g = this,
                            c = i.getTarget("." + Ext.baseCSSPrefix + "grid-row-checker"),
                            j;

                        if (!g.allowRightMouseSelection(i)) {
                            return
                        }
                        if (g.checkOnly && !c) {
                            return
                        }
                        if (c) {
                            j = g.getSelectionMode();
                            if (j !== "SINGLE") {
                                g.setSelectionMode("SIMPLE")
                            }
                            g.doSelect(a, true);
                            g.setSelectionMode(j)
                        } else {
                            g.doSelect(a, true)
                        }
                    },
                    listeners: {
                        selectionchange: function( selModel, selections ) {
                            me.__parent.__deleteButton.setDisabled(selections.length == 0);
                        }
                    }
                });

                var questionListStore = this.__questionListStore = Ext.create('Ext.data.Store', {
                    storeId:  "questionListStore",
                    fields: [{name: 'id'}, {name: 'question'}, {name: 'dataType'}, {name: 'lastModifiedDate', type: 'date'}],
                    data: []
                });

                config = Ext.apply({
                    //title: 'Question Library',
                    //titleAlign: "center",
                    store: questionListStore,
                    selModel: selectionModel,
                    columns:[
                         {text: TS.T("TAG021","Question"), dataIndex: 'question', width: '50%'},
                         {text: TS.T("TAG022","Type"), dataIndex: 'dataType', width: '25%'},
                         {text: TS.T("TAG023","Edited"), xtype:'datecolumn', format:'m-d-Y', dataIndex: 'lastModifiedDate', width: '25%'}
                         //{text: "Edited", xtype:'datecolumn', format:'F j, Y', dataIndex: 'lastModifiedDate', width: '25%'}
                    ],
                    listeners: {
                        celldblclick: SVMX.proxy(this, function( grid, rowIndex, columnIndex, e ) {
                            this.__parent.blockApplication();
                            this.deliveryEngine.editQuestion(this.getSelectionModel().getLastSelected());
                        })
                    }
                }, config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);
                this.loadData();
            },

            loadData: function(){
                this.__questionListStore.loadData(this.__parent.metaModel.getQuestionInfo());
            },

            getSelectedItems: function(){
                var templates = [],
                    selection = this.selModel.getSelection();

                if(selection.length > 0) {
                    for(var i=0; i< selection.length; i++) {
                        templates.push(selection[i].data.id);
                    }
                }
                return templates;
            }
        });
    }
})();