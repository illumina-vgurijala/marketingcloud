// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.qbm.ui.desktop\src\api.js

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

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.qbm.ui.desktop\src\boxSelect.js
/**
 * BoxSelect for ExtJS 4.1, a combo box improved for multiple value querying, selection and management.
 *
 * A friendlier combo box for multiple selections that creates easily individually
 * removable labels for each selection, as seen on facebook and other sites. Querying
 * and type-ahead support are also improved for multiple selections.
 *
 * Options and usage mostly remain consistent with the standard
 * [ComboBox](http://docs.sencha.com/ext-js/4-1/#!/api/Ext.form.field.ComboBox) control.
 * Some default configuration options have changed, but most should still work properly
 * if overridden unless otherwise noted.
 *
 * Please note, this component does not support versions of ExtJS earlier than 4.1.
 *
 * Inspired by the [SuperBoxSelect component for ExtJS 3](http://technomedia.co.uk/SuperBoxSelect/examples3.html),
 * which in turn was inspired by the [BoxSelect component for ExtJS 2](http://efattal.fr/en/extjs/extuxboxselect/).
 *
 * Various contributions and suggestions made by many members of the ExtJS community which can be seen
 * in the [official user extension forum post](http://www.sencha.com/forum/showthread.php?134751-Ext.ux.form.field.BoxSelect).
 *
 * Many thanks go out to all of those who have contributed, this extension would not be
 * possible without your help.
 *
 * See [AUTHORS.txt](../AUTHORS.TXT) for a list of major contributors
 *
 * @author kvee_iv http://www.sencha.com/forum/member.php?29437-kveeiv
 * @version 2.0.3
 * @requires BoxSelect.css
 * @xtype boxselect
 *
 */
(function(){
    var impl = SVMX.Package("com.servicemax.client.qbm.ui.desktop.boxselect");

    impl.init = function(){ 
        Ext.define('com.servicemax.client.qbm.ui.desktop.boxselect.BoxSelect', {
            extend:'Ext.form.field.ComboBox',
            alias: ['widget.comboboxselect', 'widget.boxselect'],
            requires: ['Ext.selection.Model', 'Ext.data.Store'],

            //
            // Begin configuration options related to the underlying store
            //
            
            /**
             * @cfg {String} valueParam
             * The name of the parameter used to load unknown records into the store. If left unspecified, {@link #valueField}
             * will be used.
             */

            //
            // End of configuration options related to the underlying store
            //



            //
            // Begin configuration options related to selected values
            //

            /**
             * @cfg {Boolean}
             * If set to `true`, allows the combo field to hold more than one value at a time, and allows selecting multiple
             * items from the dropdown list. The combo's text field will show all selected values using the template
             * defined by {@link #labelTpl}.
             *

             */
            multiSelect: true,

            /**
             * @cfg {String/Ext.XTemplate} labelTpl
             * The [XTemplate](http://docs.sencha.com/ext-js/4-1/#!/api/Ext.XTemplate) to use for the inner
             * markup of the labelled items. Defaults to the configured {@link #displayField}
             */

            /**
        	 * @cfg
             * @inheritdoc
             *
             * When {@link #forceSelection} is `false`, new records can be created by the user as they
             * are typed. These records are **not** added to the combo's store. This creation
             * is triggered by typing the configured 'delimiter', and can be further configured using the
             * {@link #createNewOnEnter} and {@link #createNewOnBlur} configuration options.
             *
             * This functionality is primarily useful with BoxSelect components for things
             * such as an email address.
             */
            forceSelection: true,

            /**
        	 * @cfg {Boolean}
             * Has no effect if {@link #forceSelection} is `true`.
             *
        	 * With {@link #createNewOnEnter} set to `true`, the creation described in
             * {@link #forceSelection} will also be triggered by the 'enter' key.
        	 */
            createNewOnEnter: false,

            /**
        	 * @cfg {Boolean}
             * Has no effect if {@link #forceSelection} is `true`.
             *
             * With {@link #createNewOnBlur} set to `true`, the creation described in
             * {@link #forceSelection} will also be triggered when the field loses focus.
             *
             * Please note that this behavior is also affected by the configuration options
             * {@link #autoSelect} and {@link #selectOnTab}. If those are true and an existing
             * item would have been selected as a result, the partial text the user has entered will
        	 * be discarded and the existing item will be added to the selection.
        	 */
            createNewOnBlur: false,

            /**
             * @cfg {Boolean}
             * Has no effect if {@link #multiSelect} is `false`.
             *
             * Controls the formatting of the form submit value of the field as returned by {@link #getSubmitValue}
             *
             * - `true` for the field value to submit as a json encoded array in a single GET/POST variable
             * - `false` for the field to submit as an array of GET/POST variables
             */
            encodeSubmitValue: false,

            //
            // End of configuration options related to selected values
            //



            //
            // Configuration options related to pick list behavior
            //

            /**
             * @cfg {Boolean}
             * `true` to activate the trigger when clicking in empty space in the field. Note that the
             * subsequent behavior of this is controlled by the field's {@link #triggerAction}.
             * This behavior is similar to that of a basic ComboBox with {@link #editable} `false`.
             */
            triggerOnClick: true,

            /**
        	 * @cfg {Boolean}
             * - `true` to have each selected value fill to the width of the form field
             * - `false to have each selected value size to its displayed contents
        	 */
            stacked: false,

            /**
        	 * @cfg {Boolean}
             * Has no effect if {@link #multiSelect} is `false`
             *
             * `true` to keep the pick list expanded after each selection from the pick list
             * `false` to automatically collapse the pick list after a selection is made
        	 */
            pinList: true,

            /**
             * @cfg {Boolean}
             * True to hide the currently selected values from the drop down list. These items are hidden via
             * css to maintain simplicity in store and filter management.
             *
             * - `true` to hide currently selected values from the drop down pick list
             * - `false` to keep the item in the pick list as a selected item
             */
            filterPickList: false,

            //
            // End of configuration options related to pick list behavior
            //



            //
            // Configuration options related to text field behavior
            //

            /**
             * @cfg
             * @inheritdoc
             */
            selectOnFocus: true,

            /**
             * @cfg {Boolean}
             *
             * `true` if this field should automatically grow and shrink vertically to its content.
             * Note that this overrides the natural trigger grow functionality, which is used to size
             * the field horizontally.
             */
            grow: true,

            /**
             * @cfg {Number/Boolean}
             * Has no effect if {@link #grow} is `false`
             *
             * The minimum height to allow when {@link #grow} is `true`, or `false` to allow for
             * natural vertical growth based on the current selected values. See also {@link #growMax}.
             */
            growMin: false,

            /**
             * @cfg {Number/Boolean}
             * Has no effect if {@link #grow} is `false`
             *
             * The maximum height to allow when {@link #grow} is `true`, or `false` to allow for
             * natural vertical growth based on the current selected values. See also {@link #growMin}.
             */
            growMax: false,

            /**
             * @cfg growAppend
             * @hide
             * Currently unsupported by BoxSelect since this is used for horizontal growth and
             * BoxSelect only supports vertical growth.
             */
            /**
             * @cfg growToLongestValue
             * @hide
             * Currently unsupported by BoxSelect since this is used for horizontal growth and
             * BoxSelect only supports vertical growth.
             */

            //
            // End of configuration options related to text field behavior
            //


            //
            // Event signatures
            //

            /**
             * @event autosize
             * Fires when the **{@link #autoSize}** function is triggered and the field is resized according to the
             * {@link #grow}/{@link #growMin}/{@link #growMax} configs as a result. This event provides a hook for the
             * developer to apply additional logic at runtime to resize the field if needed.
             * @param {Ext.ux.form.field.BoxSelect} this This BoxSelect field
             * @param {Number} height The new field height
             */

            //
            // End of event signatures
            //



            //
            // Configuration options that will break things if messed with
            //

            /**
             * @private
             */
            fieldSubTpl: [
                '<div id="{cmpId}-listWrapper" class="x-boxselect {fieldCls} {typeCls}">',
                '<ul id="{cmpId}-itemList" class="x-boxselect-list">',
                '<li id="{cmpId}-inputElCt" class="x-boxselect-input">',
                '<div id="{cmpId}-emptyEl" class="{emptyCls}">{emptyText}</div>',
                '<input id="{cmpId}-inputEl" type="{type}" ',
                '<tpl if="name">name="{name}" </tpl>',
                '<tpl if="value"> value="{[Ext.util.Format.htmlEncode(values.value)]}"</tpl>',
                '<tpl if="size">size="{size}" </tpl>',
                '<tpl if="tabIdx">tabIndex="{tabIdx}" </tpl>',
                '<tpl if="disabled"> disabled="disabled"</tpl>',
                'class="x-boxselect-input-field {inputElCls}" autocomplete="off">',
                '</li>',
                '</ul>',
                '</div>',
                {
                    compiled: true,
                    disableFormats: true
                }
            ],

            /**
             * @private
             */
            childEls: [ 'listWrapper', 'itemList', 'inputEl', 'inputElCt', 'emptyEl' ],

            /**
             * @private
             */
            componentLayout: 'boxselectfield',

            /**
             * @private
             */
            emptyInputCls: 'x-boxselect-emptyinput',

            /**
             * @inheritdoc
             *
             * Initialize additional settings and enable simultaneous typeAhead and multiSelect support
             * @protected
        	 */
            initComponent: function() {
                var me = this,
                typeAhead = me.typeAhead;

                if (typeAhead && !me.editable) {
                    Ext.Error.raise('If typeAhead is enabled the combo must be editable: true -- please change one of those settings.');
                }

                Ext.apply(me, {
                    typeAhead: false
                });

                me.callParent();

                me.typeAhead = typeAhead;

                me.selectionModel = new Ext.selection.Model({
                    store: me.valueStore,
                    mode: 'MULTI',
                    lastFocused: null,
                    onSelectChange: function(record, isSelected, suppressEvent, commitFn) {
                        commitFn();
                    }
                });

                if (!Ext.isEmpty(me.delimiter) && me.multiSelect) {
                    me.delimiterRegexp = new RegExp(String(me.delimiter).replace(/[$%()*+.?\[\\\]{|}]/g, "\\$&"));
                }
            },

            /**
        	 * Register events for management controls of labelled items
             * @protected
        	 */
            initEvents: function() {
                var me = this;

                me.callParent(arguments);

                if (!me.enableKeyEvents) {
                    me.mon(me.inputEl, 'keydown', me.onKeyDown, me);
                }
                me.mon(me.inputEl, 'paste', me.onPaste, me);
                me.mon(me.listWrapper, 'click', me.onItemListClick, me);

                // I would prefer to use relayEvents here to forward these events on, but I want
                // to pass the field instead of exposing the underlying selection model
                me.mon(me.selectionModel, {
                    'selectionchange': function(selModel, selectedRecs) {
                        me.applyMultiselectItemMarkup();
                        me.fireEvent('valueselectionchange', me, selectedRecs);
                    },
                    'focuschange': function(selectionModel, oldFocused, newFocused) {
                        me.fireEvent('valuefocuschange', me, oldFocused, newFocused);
                    },
                    scope: me
                });
            },

            /**
             * @inheritdoc
             *
        	 * Create a store for the records of our current value based on the main store's model
             * @protected
        	 */
            onBindStore: function(store, initial) {
                var me = this;

                if (store) {
                    me.valueStore = new Ext.data.Store({
                        model: store.model,
                        proxy: {
                            type: 'memory'
                        }
                    });
                    me.mon(me.valueStore, 'datachanged', me.applyMultiselectItemMarkup, me);
                    if (me.selectionModel) {
                        me.selectionModel.bindStore(me.valueStore);
                    }
                }
            },

            /**
             * @inheritdoc
             *
             * Remove the selected value store and associated listeners
             * @protected
             */
            onUnbindStore: function(store) {
                var me = this,
                valueStore = me.valueStore;

                if (valueStore) {
                    if (me.selectionModel) {
                        me.selectionModel.setLastFocused(null);
                        me.selectionModel.deselectAll();
                        me.selectionModel.bindStore(null);
                    }
                    me.mun(valueStore, 'datachanged', me.applyMultiselectItemMarkup, me);
                    valueStore.destroy();
                    me.valueStore = null;
                }

                me.callParent(arguments);
            },

            /**
             * @inheritdoc
             *
        	 * Add refresh tracking to the picker for selection management
             * @protected
        	 */
            createPicker: function() {
                var me = this,
                picker = me.callParent(arguments);

                me.mon(picker, {
                    'beforerefresh': me.onBeforeListRefresh,
                    scope: me
                });

                if (me.filterPickList) {
                    picker.addCls('x-boxselect-hideselections');
                }

                return picker;
            },

            /**
             * @inheritdoc
             *
        	 * Clean up selected values management controls
             * @protected
        	 */
            onDestroy: function() {
                var me = this;

                Ext.destroyMembers(me, 'valueStore', 'selectionModel');

                me.callParent(arguments);
            },

            /**
             * Add empty text support to initial render.
             * @protected
             */
            getSubTplData: function() {
                var me = this,
                    data = me.callParent(),
                    isEmpty = me.emptyText && data.value.length < 1;

                data.value = '';
                if (isEmpty) {
                    data.emptyText = me.emptyText;
                    data.emptyCls = me.emptyCls;
                    data.inputElCls = me.emptyInputCls;
                } else {
                    data.emptyText = '';
                    data.emptyCls = me.emptyInputCls;
                    data.inputElCls = '';
                }

                return data;
            },

            /**
             * @inheritdoc
             *
        	 * Overridden to avoid use of placeholder, as our main input field is often empty
             * @protected
        	 */
            afterRender: function() {
                var me = this;

                if (Ext.supports.Placeholder && me.inputEl && me.emptyText) {
                    delete me.inputEl.dom.placeholder;
                }

                me.bodyEl.applyStyles('vertical-align:top');

                if (me.grow) {
                    if (Ext.isNumber(me.growMin) && (me.growMin > 0)) {
                        me.listWrapper.applyStyles('min-height:'+me.growMin+'px');
                    }
                    if (Ext.isNumber(me.growMax) && (me.growMax > 0)) {
                        me.listWrapper.applyStyles('max-height:'+me.growMax+'px');
                    }
                }

                if (me.stacked === true) {
                    me.itemList.addCls('x-boxselect-stacked');
                }

                if (!me.multiSelect) {
                    me.itemList.addCls('x-boxselect-singleselect');
                }

                me.applyMultiselectItemMarkup();

                me.callParent(arguments);
            },

            /**
        	 * Overridden to search entire unfiltered store since already selected values
             * can span across multiple store page loads and other filtering. Overlaps
             * some with {@link #isFilteredRecord}, but findRecord is used by the base component
             * for various logic so this logic is applied here as well.
             * @protected
        	 */
            findRecord: function(field, value) {
                var ds = this.store,
                matches;

                if (!ds) {
                    return false;
                }

                matches = ds.queryBy(function(rec, id) {
                    return rec.isEqual(rec.get(field), value);
                });

                return (matches.getCount() > 0) ? matches.first() : false;
            },

            /**
        	 * Overridden to map previously selected records to the "new" versions of the records
        	 * based on value field, if they are part of the new store load
             * @protected
        	 */
            onLoad: function() {
                var me = this,
                valueField = me.valueField,
                valueStore = me.valueStore,
                changed = false;

                if (valueStore) {
                    if (!Ext.isEmpty(me.value) && (valueStore.getCount() == 0)) {
                        me.setValue(me.value, false, true);
                    }

                    valueStore.suspendEvents();
                    valueStore.each(function(rec) {
                        var r = me.findRecord(valueField, rec.get(valueField)),
                        i = r ? valueStore.indexOf(rec) : -1;
                        if (i >= 0) {
                            valueStore.removeAt(i);
                            valueStore.insert(i, r);
                            changed = true;
                        }
                    });
                    valueStore.resumeEvents();
                    if (changed) {
                        valueStore.fireEvent('datachanged', valueStore);
                    }
                }

                me.callParent(arguments);
            },

            /**
        	 * Used to determine if a record is filtered out of the current store's data set,
             * for determining if a currently selected value should be retained.
             *
             * Slightly complicated logic. A record is considered filtered and should be retained if:
             *
             * - It is not in the combo store and the store has no filter or it is in the filtered data set
             *   (Happens when our selected value is just part of a different load, page or query)
             * - It is not in the combo store and forceSelection is false and it is in the value store
             *   (Happens when our selected value was created manually)
             *
        	 * @private
        	 */
            isFilteredRecord: function(record) {
                var me = this,
                store = me.store,
                valueField = me.valueField,
                storeRecord,
                filtered = false;

                storeRecord = store.findExact(valueField, record.get(valueField));

                filtered = ((storeRecord === -1) && (!store.snapshot || (me.findRecord(valueField, record.get(valueField)) !== false)));

                filtered = filtered || (!filtered && (storeRecord === -1) && (me.forceSelection !== true) &&
                    (me.valueStore.findExact(valueField, record.get(valueField)) >= 0));

                return filtered;
            },

            /**
             * @inheritdoc
             *
        	 * Overridden to allow for continued querying with multiSelect selections already made
             * @protected
        	 */
            doRawQuery: function() {
                var me = this,
                rawValue = me.inputEl.dom.value;

                if (me.multiSelect) {
                    rawValue = rawValue.split(me.delimiter).pop();
                }
                if(rawValue.length>0){
                    this.doQuery(rawValue, false, true);
                }
                this.focus();
                this.selectText(rawValue.length,rawValue.length);
            },

            /**
        	 * When the picker is refreshing, we should ignore selection changes. Otherwise
        	 * the value of our field will be changing just because our view of the choices is.
             * @protected
        	 */
            onBeforeListRefresh: function() {
                this.ignoreSelection++;
            },

            /**
        	 * When the picker is refreshing, we should ignore selection changes. Otherwise
        	 * the value of our field will be changing just because our view of the choices is.
             * @protected
        	 */
            onListRefresh: function() {
                this.callParent(arguments);
                if (this.ignoreSelection > 0) {
                    --this.ignoreSelection;
                }
            },

            /**
        	 * Overridden to preserve current labelled items when list is filtered/paged/loaded
        	 * and does not include our current value. See {@link #isFilteredRecord}
             * @private
        	 */
            onListSelectionChange: function(list, selectedRecords) {
                var me = this,
                valueStore = me.valueStore,
                mergedRecords = [],
                i;

                // Only react to selection if it is not called from setValue, and if our list is
                // expanded (ignores changes to the selection model triggered elsewhere)
                if ((me.ignoreSelection <= 0) && me.isExpanded) {
                    // Pull forward records that were already selected or are now filtered out of the store
                    valueStore.each(function(rec) {
                        if (Ext.Array.contains(selectedRecords, rec) || me.isFilteredRecord(rec)) {
                            mergedRecords.push(rec);
                        }
                    });
                    mergedRecords = Ext.Array.merge(mergedRecords, selectedRecords);

                    i = Ext.Array.intersect(mergedRecords, valueStore.getRange()).length;
                    if ((i != mergedRecords.length) || (i != me.valueStore.getCount())) {
                        me.setValue(mergedRecords, false);
                        if (!me.multiSelect || !me.pinList) {
                            Ext.defer(me.collapse, 1, me);
                        }
                        if (valueStore.getCount() > 0) {
                            me.fireEvent('select', me, valueStore.getRange());
                        }
                    }
                    me.inputEl.focus();
                    if (!me.pinList) {
                        me.inputEl.dom.value = '';
                    }
                    if (me.selectOnFocus) {
                        me.inputEl.dom.select();
                    }
                }
            },

            /**
             * Overridden to use valueStore instead of valueModels, for inclusion of
             * filtered records. See {@link #isFilteredRecord}
             * @private
             */
            syncSelection: function() {
                var me = this,
                picker = me.picker,
                valueField = me.valueField,
                pickStore, selection, selModel;

                if (picker) {
                    pickStore = picker.store;

                    // From the value, find the Models that are in the store's current data
                    selection = [];
                    if (me.valueStore) {
                        me.valueStore.each(function(rec) {
                            var i = pickStore.findExact(valueField, rec.get(valueField));
                            if (i >= 0) {
                                selection.push(pickStore.getAt(i));
                            }
                        });
                    }

                    // Update the selection to match
                    me.ignoreSelection++;
                    selModel = picker.getSelectionModel();
                    selModel.deselectAll();
                    if (selection.length > 0) {
                        selModel.select(selection);
                    }
                    if (me.ignoreSelection > 0) {
                        --me.ignoreSelection;
                    }
                }
            },

            /**
        	 * Overridden to align to itemList size instead of inputEl
             */
            doAlign: function(){
                var me = this,
                    picker = me.picker,
                    aboveSfx = '-above',
                    isAbove;

                me.picker.alignTo(me.listWrapper, me.pickerAlign, me.pickerOffset);
                // add the {openCls}-above class if the picker was aligned above
                // the field due to hitting the bottom of the viewport
                isAbove = picker.el.getY() < me.inputEl.getY();
                me.bodyEl[isAbove ? 'addCls' : 'removeCls'](me.openCls + aboveSfx);
                picker[isAbove ? 'addCls' : 'removeCls'](picker.baseCls + aboveSfx);
            },

            /**
             * Overridden to preserve scroll position of pick list when list is realigned
             */
            alignPicker: function() {
                var me = this,
                    picker = me.picker,
                    pickerScrollPos = picker.getTargetEl().dom.scrollTop;

                me.callParent(arguments);

                if (me.isExpanded) {
                    if (me.matchFieldWidth) {
                        // Auto the height (it will be constrained by min and max width) unless there are no records to display.
                        picker.setWidth(me.listWrapper.getWidth());
                    }

                    picker.getTargetEl().dom.scrollTop = pickerScrollPos;
                }
            },

            /**
        	 * Get the current cursor position in the input field, for key-based navigation
        	 * @private
        	 */
            getCursorPosition: function() {
                var cursorPos;
                if (Ext.isIE) {
                    cursorPos = document.selection.createRange();
                    cursorPos.collapse(true);
                    cursorPos.moveStart("character", -this.inputEl.dom.value.length);
                    cursorPos = cursorPos.text.length;
                } else {
                    cursorPos = this.inputEl.dom.selectionStart;
                }
                return cursorPos;
            },

            /**
        	 * Check to see if the input field has selected text, for key-based navigation
        	 * @private
        	 */
            hasSelectedText: function() {
                var sel, range;
                if (Ext.isIE) {
                    sel = document.selection;
                    range = sel.createRange();
                    return (range.parentElement() == this.inputEl.dom);
                } else {
                    return this.inputEl.dom.selectionStart != this.inputEl.dom.selectionEnd;
                }
            },

            /**
        	 * Handles keyDown processing of key-based selection of labelled items.
             * Supported keyboard controls:
             *
             * - If pick list is expanded
             *
             *     - `CTRL-A` will select all the items in the pick list
             *
             * - If the cursor is at the beginning of the input field and there are values present
             *
             *     - `CTRL-A` will highlight all the currently selected values
             *     - `BACKSPACE` and `DELETE` will remove any currently highlighted selected values
             *     - `RIGHT` and `LEFT` will move the current highlight in the appropriate direction
             *     - `SHIFT-RIGHT` and `SHIFT-LEFT` will add to the current highlight in the appropriate direction
             *
             * @protected
        	 */
            onKeyDown: function(e, t) {
                var me = this,
                key = e.getKey(),
                rawValue = Ext.String.htmlEncode(me.inputEl.dom.value),
                valueStore = me.valueStore,
                selModel = me.selectionModel,
                stopEvent = false;

                if (me.readOnly || me.disabled || !me.editable) {
                    return;
                }

                if (me.isExpanded && (key == e.A && e.ctrlKey)) {
                    // CTRL-A when picker is expanded - add all items in current picker store page to current value
                    me.select(me.getStore().getRange());
                    selModel.setLastFocused(null);
                    selModel.deselectAll();
                    me.collapse();
                    me.inputEl.focus();
                    stopEvent = true;
                } else if ((valueStore.getCount() > 0) &&
                        ((rawValue == '') || ((me.getCursorPosition() === 0) && !me.hasSelectedText()))) {
                    // Keyboard navigation of current values
                    var lastSelectionIndex = (selModel.getCount() > 0) ? valueStore.indexOf(selModel.getLastSelected() || selModel.getLastFocused()) : -1;

                    if ((key == e.BACKSPACE) || (key == e.DELETE)) {
                        if (lastSelectionIndex > -1) {
                            if (selModel.getCount() > 1) {
                                lastSelectionIndex = -1;
                            }
                            me.valueStore.remove(selModel.getSelection());
                        } else {
                            me.valueStore.remove(me.valueStore.last());
                        }
                        selModel.clearSelections();
                        me.setValue(me.valueStore.getRange());
                        if (lastSelectionIndex > 0) {
                            selModel.select(lastSelectionIndex - 1);
                        }
                        stopEvent = true;
                    } else if ((key == e.RIGHT) || (key == e.LEFT)) {
                        if ((lastSelectionIndex == -1) && (key == e.LEFT)) {
                            selModel.select(valueStore.last());
                            stopEvent = true;
                        } else if (lastSelectionIndex > -1) {
                            if (key == e.RIGHT) {
                                if (lastSelectionIndex < (valueStore.getCount() - 1)) {
                                    selModel.select(lastSelectionIndex + 1, e.shiftKey);
                                    stopEvent = true;
                                } else if (!e.shiftKey) {
                                    selModel.setLastFocused(null);
                                    selModel.deselectAll();
                                    stopEvent = true;
                                }
                            } else if ((key == e.LEFT) && (lastSelectionIndex > 0)) {
                                selModel.select(lastSelectionIndex - 1, e.shiftKey);
                                stopEvent = true;
                            }
                        }
                    } else if (key == e.A && e.ctrlKey) {
                        selModel.selectAll();
                        stopEvent = e.A;
                    }
                    me.inputEl.focus();
                }

                if (stopEvent) {
                    me.preventKeyUpEvent = stopEvent;
                    e.stopEvent();
                    return;
                }

                // Prevent key up processing for enter if it is being handled by the picker
                if (me.isExpanded && (key == e.ENTER) && me.picker.highlightedItem) {
                    me.preventKeyUpEvent = true;
                }

                if (me.enableKeyEvents) {
                    me.callParent(arguments);
                }

                if (!e.isSpecialKey() && !e.hasModifier()) {
                    me.selectionModel.setLastFocused(null);
                    me.selectionModel.deselectAll();
                    me.inputEl.focus();
                }
            },

            /**
        	 * Handles auto-selection and creation of labelled items based on this field's
             * delimiter, as well as the keyUp processing of key-based selection of labelled items.
             * @protected
        	 */
            onKeyUp: function(e, t) {
                var me = this,
                rawValue = Ext.String.htmlEncode(me.inputEl.dom.value);

                if (me.preventKeyUpEvent) {
                    e.stopEvent();
                    if ((me.preventKeyUpEvent === true) || (e.getKey() === me.preventKeyUpEvent)) {
                        delete me.preventKeyUpEvent;
                    }
                    return;
                }

                if (me.multiSelect && (me.delimiterRegexp && me.delimiterRegexp.test(rawValue)) ||
                        ((me.createNewOnEnter === true) && e.getKey() == e.ENTER)) {
                    rawValue = Ext.Array.clean(rawValue.split(me.delimiterRegexp));
                    me.inputEl.dom.value = '';
                    me.setValue(me.valueStore.getRange().concat(rawValue));
                    me.inputEl.focus();
                }

                me.callParent([e,t]);
            },

            /**
             * Handles auto-selection of labelled items based on this field's delimiter when pasting
             * a list of values in to the field (e.g., for email addresses)
             * @protected
             */
            onPaste: function(e, t) {
                var me = this,
                    rawValue = me.inputEl.dom.value,
                    clipboard = (e && e.browserEvent && e.browserEvent.clipboardData) ? e.browserEvent.clipboardData : false;

                if (me.multiSelect && (me.delimiterRegexp && me.delimiterRegexp.test(rawValue))) {
                    if (clipboard && clipboard.getData) {
                        if (/text\/plain/.test(clipboard.types)) {
                            rawValue = clipboard.getData('text/plain');
                        } else if (/text\/html/.test(clipboard.types)) {
                            rawValue = clipboard.getData('text/html');
                        }
                    }

                    rawValue = Ext.Array.clean(rawValue.split(me.delimiterRegexp));
                    me.inputEl.dom.value = '';
                    me.setValue(me.valueStore.getRange().concat(rawValue));
                    me.inputEl.focus();
                }
            },

            /**
             * Overridden to handle key navigation of pick list when list is filtered. Because we
             * want to avoid complexity that could be introduced by modifying the store's contents,
             * (e.g., always having to search back through and remove values when they might
             * be re-sent by the server, adding the values back in their previous position when
             * they are removed from the current selection, etc.), we handle this filtering
             * via a simple css rule. However, for the moment since those DOM nodes still exist
             * in the list we have to hijack the highlighting methods for the picker's BoundListKeyNav
             * to appropriately skip over these hidden nodes. This is a less than ideal solution,
             * but it centralizes all of the complexity of this problem in to this one method.
             * @protected
             */
            onExpand: function() {
                var me = this,
                    keyNav = me.listKeyNav;

                me.callParent(arguments);

                if (keyNav || !me.filterPickList) {
                    return;
                }
                keyNav = me.listKeyNav;
                keyNav.highlightAt = function(index) {
                    var boundList = this.boundList,
                        item = boundList.all.item(index),
                        len = boundList.all.getCount(),
                        direction;

                    if (item && item.hasCls('x-boundlist-selected')) {
                        if ((index == 0) || !boundList.highlightedItem || (boundList.indexOf(boundList.highlightedItem) < index)) {
                            direction = 1;
                        } else {
                            direction = -1;
                        }
                        do {
                            index = index + direction;
                            item = boundList.all.item(index);
                        } while ((index > 0) && (index < len) && item.hasCls('x-boundlist-selected'));

                        if (item.hasCls('x-boundlist-selected')) {
                            return;
                        }
                    }

                    if (item) {
                        item = item.dom;
                        boundList.highlightItem(item);
                        boundList.getTargetEl().scrollChildIntoView(item, false);
                    }
                };
            },

            /**
        	 * Overridden to get and set the DOM value directly for type-ahead suggestion (bypassing get/setRawValue)
             * @protected
        	 */
            onTypeAhead: function() {
                var me = this,
                displayField = me.displayField,
                inputElDom = me.inputEl.dom,
                valueStore = me.valueStore,
                boundList = me.getPicker(),
                record, newValue, len, selStart;

                if (me.filterPickList) {
                    var fn = this.createFilterFn(displayField, inputElDom.value);
                    record = me.store.findBy(function(rec) {
                        return ((valueStore.indexOfId(rec.getId()) === -1) && fn(rec));
                    });
                    record = (record === -1) ? false : me.store.getAt(record);
                } else {
                    record = me.store.findRecord(displayField, inputElDom.value);
                }

                if (record) {
                    newValue = record.get(displayField);
                    len = newValue.length;
                    selStart = inputElDom.value.length;
                    boundList.highlightItem(boundList.getNode(record));
                    if (selStart !== 0 && selStart !== len) {
                        inputElDom.value = newValue;
                        me.selectText(selStart, newValue.length);
                    }
                }
            },

            /**
        	 * Delegation control for selecting and removing labelled items or triggering list collapse/expansion
             * @protected
        	 */
            onItemListClick: function(evt, el, o) {
                var me = this,
                itemEl = evt.getTarget('.x-boxselect-item'),
                closeEl = itemEl ? evt.getTarget('.x-boxselect-item-close') : false;

                if (me.readOnly || me.disabled) {
                    return;
                }

                evt.stopPropagation();

                if (itemEl) {
                    if (closeEl) {
                        me.removeByListItemNode(itemEl);
                        if (me.valueStore.getCount() > 0) {
                            me.fireEvent('select', me, me.valueStore.getRange());
                        }
                    } else {
                        me.toggleSelectionByListItemNode(itemEl, evt.shiftKey);
                    }
                    me.inputEl.focus();
                } else {
                    if (me.selectionModel.getCount() > 0) {
                        me.selectionModel.setLastFocused(null);
                        me.selectionModel.deselectAll();
                    }
                    if (me.triggerOnClick) {
                        me.onTriggerClick();
                    }
                }
            },

            /**
        	 * Build the markup for the labelled items. Template must be built on demand due to ComboBox initComponent
        	 * lifecycle for the creation of on-demand stores (to account for automatic valueField/displayField setting)
             * @private
        	 */
            getMultiSelectItemMarkup: function() {
                var me = this;

                if (!me.multiSelectItemTpl) {
                    if (!me.labelTpl) {
                        me.labelTpl = Ext.create('Ext.XTemplate',
                            '{[values.' + me.displayField + ']}'
                        );
                    } else if (Ext.isString(me.labelTpl) || Ext.isArray(me.labelTpl)) {
                        me.labelTpl = Ext.create('Ext.XTemplate', me.labelTpl);
                    }

                    me.multiSelectItemTpl = [
                    '<tpl for=".">',
                    '<li class="x-boxselect-item ',
                    '<tpl if="this.isSelected(values.'+ me.valueField + ')">',
                    ' selected',
                    '</tpl>',
                    '" qtip="{[typeof values === "string" ? values : values.' + me.displayField + ']}">' ,
                    '<div class="x-boxselect-item-text">{[typeof values === "string" ? values : this.getItemLabel(values)]}</div>',
                    '<div class="x-tab-close-btn x-boxselect-item-close"></div>',
                    '</li>' ,
                    '</tpl>',
                    {
                        compile: true,
                        disableFormats: true,
                        isSelected: function(value) {
                            var i = me.valueStore.findExact(me.valueField, value);
                            if (i >= 0) {
                                return me.selectionModel.isSelected(me.valueStore.getAt(i));
                            }
                            return false;
                        },
                        getItemLabel: function(values) {
                            return me.getTpl('labelTpl').apply(values);
                        }
                    }
                    ];
                }

                return this.getTpl('multiSelectItemTpl').apply(Ext.Array.pluck(this.valueStore.getRange(), 'data'));
            },

            /**
        	 * Update the labelled items rendering
             * @private
        	 */
            applyMultiselectItemMarkup: function() {
                var me = this,
                itemList = me.itemList,
                item;

                if (itemList) {
                    while ((item = me.inputElCt.prev()) != null) {
                        item.remove();
                    }
                    me.inputElCt.insertHtml('beforeBegin', me.getMultiSelectItemMarkup());
                }

                Ext.Function.defer(function() {
                    if (me.picker && me.isExpanded) {
                        me.alignPicker();
                    }
                    if (me.hasFocus && me.inputElCt && me.listWrapper) {
                        me.inputElCt.scrollIntoView(me.listWrapper);
                    }
                }, 15);
            },

            /**
        	 * Returns the record from valueStore for the labelled item node
        	 */
            getRecordByListItemNode: function(itemEl) {
                var me = this,
                itemIdx = 0,
                searchEl = me.itemList.dom.firstChild;

                while (searchEl && searchEl.nextSibling) {
                    if (searchEl == itemEl) {
                        break;
                    }
                    itemIdx++;
                    searchEl = searchEl.nextSibling;
                }
                itemIdx = (searchEl == itemEl) ? itemIdx : false;

                if (itemIdx === false) {
                    return false;
                }

                return me.valueStore.getAt(itemIdx);
            },

            /**
        	 * Toggle of labelled item selection by node reference
        	 */
            toggleSelectionByListItemNode: function(itemEl, keepExisting) {
                var me = this,
                rec = me.getRecordByListItemNode(itemEl),
                selModel = me.selectionModel;

                if (rec) {
                    if (selModel.isSelected(rec)) {
                        if (selModel.isFocused(rec)) {
                            selModel.setLastFocused(null);
                        }
                        selModel.deselect(rec);
                    } else {
                        selModel.select(rec, keepExisting);
                    }
                }
            },

            /**
        	 * Removal of labelled item by node reference
        	 */
            removeByListItemNode: function(itemEl) {
                var me = this,
                rec = me.getRecordByListItemNode(itemEl);

                if (rec) {
                    me.valueStore.remove(rec);
                    me.setValue(me.valueStore.getRange());
                }
            },

            /**
             * @inheritdoc
        	 * Intercept calls to getRawValue to pretend there is no inputEl for rawValue handling,
        	 * so that we can use inputEl for user input of just the current value.
        	 */
            getRawValue: function() {
                var me = this,
                inputEl = me.inputEl,
                result;
                me.inputEl = false;
                result = me.callParent(arguments);
                me.inputEl = inputEl;
                return Ext.String.htmlDecode(result);
            },

            /**
             * @inheritdoc
        	 * Intercept calls to setRawValue to pretend there is no inputEl for rawValue handling,
        	 * so that we can use inputEl for user input of just the current value.
        	 */
            setRawValue: function(value) {
                value = Ext.String.htmlEncode(value);
                var me = this,
                inputEl = me.inputEl,
                result;

                me.inputEl = false;
                result = me.callParent([value]);
                me.inputEl = inputEl;

                return result;
            },

            /**
        	 * Adds a value or values to the current value of the field
        	 * @param {Mixed} value The value or values to add to the current value, see {@link #setValue}
        	 */
            addValue: function(value) {
                value = Ext.String.htmlEncode(value);
                var me = this;
                if (value) {
                    me.setValue(Ext.Array.merge(me.value, Ext.Array.from(value)));
                }
            },

            /**
        	 * Removes a value or values from the current value of the field
        	 * @param {Mixed} value The value or values to remove from the current value, see {@link #setValue}
        	 */
            removeValue: function(value) {
                value = Ext.String.htmlDecode(value);
                var me = this;

                if (value) {
                    me.setValue(Ext.Array.difference(me.value, Ext.Array.from(value)));
                }
            },

            /**
             * Sets the specified value(s) into the field. The following value formats are recognised:
             *
             * - Single Values
             *
             *     - A string associated to this field's configured {@link #valueField}
             *     - A record containing at least this field's configured {@link #valueField} and {@link #displayField}
             *
             * - Multiple Values
             *
             *     - If {@link #multiSelect} is `true`, a string containing multiple strings as
             *       specified in the Single Values section above, concatenated in to one string
             *       with each entry separated by this field's configured {@link #delimiter}
             *     - An array of strings as specified in the Single Values section above
             *     - An array of records as specified in the Single Values section above
             *
             * In any of the string formats above, the following occurs if an associated record cannot be found:
             *
             * 1. If {@link #forceSelection} is `false`, a new record of the {@link #store}'s configured model type
             *    will be created using the given value as the {@link #displayField} and {@link #valueField}.
             *    This record will be added to the current value, but it will **not** be added to the store.
             * 2. If {@link #forceSelection} is `true` and {@link #queryMode} is `remote`, the list of unknown
             *    values will be submitted as a call to the {@link #store}'s load as a parameter named by
             *    the {@link #valueParam} with values separated by the configured {@link #delimiter}.
             *    ** This process will cause setValue to asynchronously process. ** This will only be attempted
             *    once. Any unknown values that the server does not return records for will be removed.
             * 3. Otherwise, unknown values will be removed.
             *
             * @param {Mixed} value The value(s) to be set, see method documentation for details
             * @return {Ext.form.field.Field/Boolean} this, or `false` if asynchronously querying for unknown values
        	 */
            setValue: function(value, doSelect, skipLoad) {
                var me = this,
                valueStore = me.valueStore,
                valueField = me.valueField,
                record, len, i, valueRecord, h,
                unknownValues = [];

                if (Ext.isEmpty(value)) {
                    value = null;
                }
                if (Ext.isString(value) && me.multiSelect) {
                    value = value.split(me.delimiter);
                }
                value = Ext.Array.from(value, true);

                for (i = 0, len = value.length; i < len; i++) {
                    record = value[i];
                    if (!record || !record.isModel) {
                        valueRecord = valueStore.findExact(valueField, record);
                        if (valueRecord >= 0) {
                            value[i] = valueStore.getAt(valueRecord);
                        } else {
                            valueRecord = me.findRecord(valueField, record);
                            if (!valueRecord) {
                                if (me.forceSelection) {
                                    unknownValues.push(record);
                                } else {
                                    valueRecord = {};
                                    valueRecord[me.valueField] = record;
                                    valueRecord[me.displayField] = record;
                                    valueRecord = new me.valueStore.model(valueRecord);
                                }
                            }
                            if (valueRecord) {
                                value[i] = valueRecord;
                            }
                        }
                    }
                }

                if ((skipLoad !== true) && (unknownValues.length > 0) && (me.queryMode === 'remote')) {
                    var params = {};
                    params[me.valueParam || me.valueField] = unknownValues.join(me.delimiter);
                    me.store.load({
                        params: params,
                        callback: function() {
                            if (me.itemList) {
                                me.itemList.unmask();
                            }
                            me.setValue(value, doSelect, true);
                            me.autoSize();
                            me.lastQuery = false;
                        }
                    });
                    return false;
                }

                // For single-select boxes, use the last good (formal record) value if possible
                if (!me.multiSelect && (value.length > 0)) {
                    for (i = value.length - 1; i >= 0; i--) {
                        if (value[i].isModel) {
                            value = value[i];
                            break;
                        }
                    }
                    if (Ext.isArray(value)) {
                        value = value[value.length - 1];
                    }
                }

                return me.callParent([value, doSelect]);
            },

            /**
             * Returns the records for the field's current value
             * @return {Array} The records for the field's current value
             */
            getValueRecords: function() {
                return this.valueStore.getRange();
            },

            /**
             * @inheritdoc
             * Overridden to optionally allow for submitting the field as a json encoded array.
             */
            getSubmitData: function() {
                var me = this,
                val = me.callParent(arguments);

                if (me.multiSelect && me.encodeSubmitValue && val && val[me.name]) {
                    val[me.name] = Ext.encode(val[me.name]);
                }

                return val;
            },

            /**
        	 * Overridden to clear the input field if we are auto-setting a value as we blur.
             * @protected
        	 */
            mimicBlur: function() {
                var me = this;

                if (me.selectOnTab && me.picker && me.picker.highlightedItem) {
                    me.inputEl.dom.value = '';
                }

                me.callParent(arguments);
            },

            /**
        	 * Overridden to handle partial-input selections more directly
        	 */
            assertValue: function() {
                var me = this,
                rawValue = me.inputEl.dom.value,
                rec = !Ext.isEmpty(rawValue) ? me.findRecordByDisplay(rawValue) : false,
                value = false;

                if (!rec && !me.forceSelection && me.createNewOnBlur && !Ext.isEmpty(rawValue)) {
                    value = rawValue;
                } else if (rec) {
                    value = rec;
                }

                if (value) {
                    me.addValue(value);
                }

                me.inputEl.dom.value = '';

                me.collapse();
            },

            /**
             * Update the valueStore from the new value and fire change events for UI to respond to
             */
            checkChange: function() {
                var me = this,
                valueStore = me.valueStore,
                models = valueStore.getRange(),
                
                value = me.value;
                var tempValue = [];
                SVMX.array.forEach(me.valueModels,function(key){
                    key.data.name = key.data.name.replace(/^\s+|\s+$/g,'');
                });  
         

                var arr = {};
				for ( var i = 0 ; i < me.valueModels.length ; i++ ){
						if(me.valueModels[i].data['name'] != "" && !(arr[me.valueModels[i].data['name'].toUpperCase()])){
							arr[me.valueModels[i].data['name'].toUpperCase()] = me.valueModels[i];
						}
				}
				me.valueModels = new Array();
				
				for ( var key in arr ){
					me.valueModels.push(arr[key]);
				}

                if ((Ext.encode(value) !== Ext.encode(me.lastValue)) || (Ext.isArray(value) && (models.length != value.length))) {
                    valueStore.suspendEvents();
                    valueStore.removeAll();
                    me.value = value;
                    if (Ext.isArray(me.valueModels)) {
                        valueStore.add(me.valueModels);
                    }
                    valueStore.resumeEvents();
                    valueStore.fireEvent('datachanged', valueStore);
                }

                me.callParent(arguments);
            },
            
            
            /**
        	 * Expand record values for evaluating change and fire change events for UI to respond to
        	 *
            checkChange: function() {
                if (!this.suspendCheckChange && !this.isDestroyed) {
                    var me = this,
                    valueStore = me.valueStore,
                    lastValue = me.lastValue || '',
                    valueField = me.valueField,
                    newValue = Ext.Array.map(Ext.Array.from(me.value), function(val) {
                        if (val.isModel) {
                            return val.get(valueField);
                        }
                        return val;
                    }, this).join(this.delimiter),
                    isEqual = me.isEqual(newValue, lastValue);

                    //if (!isEqual){//newValue.length))) {
                        valueStore.suspendEvents();
                        valueStore.removeAll();
                        if (Ext.isArray(me.valueModels)) {
                            valueStore.add(me.valueModels);
                        }
                        valueStore.resumeEvents();
                        valueStore.fireEvent('datachanged', valueStore);

                        if (!isEqual) {
                            me.lastValue = newValue;
                            me.fireEvent('change', me, newValue, lastValue);
                            me.onChange(newValue, lastValue);
                        }
                    //}
                }
            }, */

            /**
             * Overridden to be more accepting of varied value types
             */
            isEqual: function(v1, v2) {
                var fromArray = Ext.Array.from,
                    valueField = this.valueField,
                    i, len, t1, t2;

                v1 = fromArray(v1);
                v2 = fromArray(v2);
                len = v1.length;

                if (len !== v2.length) {
                    return false;
                }

                for(i = 0; i < len; i++) {
                    t1 = v1[i].isModel ? v1[i].get(valueField) : v1[i];
                    t2 = v2[i].isModel ? v2[i].get(valueField) : v2[i];
                    if (t1 !== t2) {
                        return false;
                    }
                }

                return true;
            },

            /**
        	 * Overridden to use value (selection) instead of raw value and to avoid the use of placeholder
        	 */
            applyEmptyText : function() {
                var me = this,
                emptyText = me.emptyText,
                inputEl, isEmpty;

                if (me.rendered && emptyText) {
                    isEmpty = Ext.isEmpty(me.value) && !me.hasFocus;
                    inputEl = me.inputEl;
                    if (isEmpty) {
                        inputEl.dom.value = '';
                        me.emptyEl.update(emptyText);
                        me.emptyEl.addCls(me.emptyCls);
                        me.emptyEl.removeCls(me.emptyInputCls);
                        me.listWrapper.addCls(me.emptyCls);
                        me.inputEl.addCls(me.emptyInputCls);
                    } else {
                        me.emptyEl.addCls(me.emptyInputCls);
                        me.emptyEl.removeCls(me.emptyCls);
                        me.listWrapper.removeCls(me.emptyCls);
                        me.inputEl.removeCls(me.emptyInputCls);
                    }
                    me.autoSize();
                }
            },

            /**
        	 * Overridden to use inputEl instead of raw value and to avoid the use of placeholder
        	 */
            preFocus : function(){
                var me = this,
                inputEl = me.inputEl,
                emptyText = me.emptyText,
                isEmpty = (inputEl.dom.value == '');

                me.emptyEl.addCls(me.emptyInputCls);
                me.emptyEl.removeCls(me.emptyCls);
                me.listWrapper.removeCls(me.emptyCls);
                me.inputEl.removeCls(me.emptyInputCls);

                if (me.selectOnFocus || isEmpty) {
                    inputEl.dom.select();
                }
            },

            /**
        	 * Intercept calls to onFocus to add focusCls, because the base field
             * classes assume this should be applied to inputEl
        	 */
            onFocus: function() {
                var me = this,
                focusCls = me.focusCls,
                itemList = me.itemList;

                if (focusCls && itemList) {
                    itemList.addCls(focusCls);
                }

                me.callParent(arguments);
            },

            /**
        	 * Intercept calls to onBlur to remove focusCls, because the base field
             * classes assume this should be applied to inputEl
        	 */
            onBlur: function() {
                var me = this,
                focusCls = me.focusCls,
                itemList = me.itemList;

                if (focusCls && itemList) {
                    itemList.removeCls(focusCls);
                }

                me.callParent(arguments);
            },

            /**
        	 * Intercept calls to renderActiveError to add invalidCls, because the base
             * field classes assume this should be applied to inputEl
        	 */
            renderActiveError: function() {
                var me = this,
                invalidCls = me.invalidCls,
                itemList = me.itemList,
                hasError = me.hasActiveError();

                if (invalidCls && itemList) {
                    itemList[hasError ? 'addCls' : 'removeCls'](me.invalidCls + '-field');
                }

                me.callParent(arguments);
            },

            /**
             * Initiate auto-sizing for height based on {@link #grow}, if applicable.
             */
            autoSize: function() {
                var me = this,
                height;

                if (me.grow && me.rendered) {
                    me.autoSizing = true;
                    me.updateLayout();
                }

                return me;
            },

            /**
             * Track height change to fire {@link #event-autosize} event, when applicable.
             */
            afterComponentLayout: function() {
                var me = this,
                    width;

                if (me.autoSizing) {
                    height = me.getHeight();
                    if (height !== me.lastInputHeight) {
                        if (me.isExpanded) {
                            me.alignPicker();
                        }
                        me.fireEvent('autosize', me, height);
                        me.lastInputHeight = height;
                        delete me.autoSizing;
                    }
                }
            }
        });

        /**
         * Ensures the input element takes up the maximum amount of remaining list width,
         * or the entirety of the list width if too little space remains. In this case,
         * the list height will be automatically increased to accomodate the new line. This
         * growth will not occur if {@link Ext.ux.form.field.BoxSelect#multiSelect} or
         * {@link Ext.ux.form.field.BoxSelect#grow} is false.
         */
        Ext.define('Ext.ux.layout.component.field.BoxSelectField', {
            /* Begin Definitions */
            alias: ['layout.boxselectfield'],
            extend: 'Ext.layout.component.field.Trigger',

            /* End Definitions */

            type: 'boxselectfield',

            /*For proper calculations we need our field to be sized.*/
            waitForOuterWidthInDom:true,

            beginLayout: function(ownerContext) {
                var me = this,
                    owner = me.owner;

                me.callParent(arguments);

                ownerContext.inputElCtContext = ownerContext.getEl('inputElCt');
                owner.inputElCt.setStyle('width','');

                me.skipInputGrowth = !owner.grow || !owner.multiSelect;
            },

            beginLayoutFixed: function(ownerContext, width, suffix) {
                var me = this,
                    owner = ownerContext.target;

                owner.triggerEl.setStyle('height', '24px');

                me.callParent(arguments);

                if (ownerContext.heightModel.fixed && ownerContext.lastBox) {
                    owner.listWrapper.setStyle('height', ownerContext.lastBox.height+'px');
                    owner.itemList.setStyle('height', '100%');
                }
                /*No inputElCt calculations here!*/
            },

            /*Calculate and cache value of input container.*/
            publishInnerWidth:function(ownerContext) {
                var me = this,
                    owner = me.owner,
                    width = owner.itemList.getWidth(true) - 10,
                    lastEntry = owner.inputElCt.prev(null, true);

                if (lastEntry && !owner.stacked) {
                    lastEntry = Ext.fly(lastEntry);
                    width = width - lastEntry.getOffsetsTo(lastEntry.up(''))[0] - lastEntry.getWidth();
                }

                if (!me.skipInputGrowth && (width < 35)) {
                    width = width - 10;
                } else if (width < 1) {
                    width = 1;
                }
                ownerContext.inputElCtContext.setWidth(width);
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.qbm.ui.desktop\src\editQuestion.js
(function(){
    var impl = SVMX.Package("com.servicemax.client.qbm.ui.desktop.editQuestion");

    impl.init = function(){
        var TS = SVMX.getClient().getServiceRegistry().getServiceInstance("com.servicemax.client.translation").getDictionary("CQL");
        
        Ext.define("com.servicemax.client.qbm.ui.desktop.editQuestion.EditQuestionPanel", {
            extend: 'Ext.form.FormPanel',

            __actionType: null,
 
           constructor: function(config) {

                config = Ext.apply({
                    layout: 'anchor', defaultType: 'textfield', bodyPadding: 25, autoScroll: true, border: false,
                    defaults: {anchor: '100%'}, fieldDefaults: {labelAlign: 'top', labelWidth: 100},
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function() {
                this.callParent(arguments);
                var me = this;

                // Define the model for a State
                Ext.define('State', {
                    extend: 'Ext.data.Model',
                    fields: [
                        {type: 'string', name: 'name'},
                    ]
                });

                var tagsStore = Ext.create('Ext.data.Store', {
                    model: 'State',
                    //data: tags,
                    data : [],
                    proxy: {
                        type: 'memory'
                    }
                });

                this.__tagstore = tagsStore;

                // Basic BoxSelect using the data store
                var basicBoxselect = Ext.create('com.servicemax.client.qbm.ui.desktop.boxselect.BoxSelect', {
                    fieldLabel: TS.T("TAG024","Tags"),
                    displayField: 'name',
                    name:'TagField',
                    id:'tagsList',
                    anchor: '50%',
                    multiSelect : true,
                    forceSelection:false,
                    hideTrigger:true,
                    editable:true,
                    store: tagsStore,
                    queryMode: 'local',
                    createNewOnEnter: true,
                    createNewOnBlur: true,
                    filterPickList: true,
                    triggerOnClick: false,
                    pinList: false,
                    delimiter : ',',
                });

                me.add({
                    fieldLabel: TS.T("TAG025","Question Text"), name: 'questionText',
                    id: SVMX.OrgNamespace+'__Question__c',
                    anchor: '50%', allowBlank: false, padding: '0 0 15',
                    //Added as part of defect BAC-3578 fix. Created custom label for this error message
                    blankText: TS.T("TAG054","This field is required")
                });

                me.add({
                    fieldLabel: 'Question ID', name: 'questionId',
                    id: SVMX.OrgNamespace+'__QuestionID__c',
                    anchor: '50%', padding: '0 0 15', hidden: 'true'
                });

                //Added for the story BAC-2300
                me.add({
                    fieldLabel : TS.T("TAG051","Default Answer"), name: 'defaultResponseText',
                    id: 'defaultResponseText',
                    anchor: '50%', padding: '0 0 15', xtype : 'textfield', maxLength : 255, enforceMaxLength: true
                });

                //Added for the story BAC-2300
                me.add({
                    fieldLabel : TS.T("TAG051","Default Answer"), name: 'defaultResponseNumber',
                    id: 'defaultResponseNumber',
                    anchor: '50%', padding: '0 0 15', xtype : 'numberfield', hidden: 'true',
                    enforceMaxLength: true, maxLength: 14 //Added for fixing defect 
                });

                //Added for the story BAC-2303
                var valueFunctionStore = SVMX.create('Ext.data.Store',{
                    fields: ['value', 'label'],
                    data:{'items':[{
                            "label":TS.T("COMM002","Value"), 
                            "value":"Value"
                        },{
                            "label":TS.T("COMM001","Function"), 
                            "value":"Function",
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

                //Added for the story BAC-2303
                var valueFunctionComboCmp = {
                    xtype: 'combobox', 
                    padding: '0 0 15', 
                    id: 'valueFunctionCombo',
                    name: 'valueFunctionCombo', fieldLabel: TS.T("TAG051","Default Answer"),
                    labelField:'label', valueField:'value', displayField: 'label', defaultValue: 'Value', value: 'Value',
                    queryMode: 'local', editable: false, 
                    anchor: '50%',
                    store: valueFunctionStore,
                    hidden: true,
                    listeners: {              
                        change: function(field, newValue, oldValue) {
                            var dateCmp = Ext.getCmp('defaultResponseDate');
                            var literalCmp = Ext.getCmp('literalCombo');
                            if(newValue === 'Value'){
                                literalCmp.hide();
                                dateCmp.reset();
                                dateCmp.show();
                            }
                            else if(newValue === 'Function'){
                                dateCmp.hide();
                                literalCmp.reset();
                                literalCmp.show();
                            }
                        }, 
                        afterrender: function(combo) { 
                            combo.setValue(this.defaultValue);
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                };

                //Added for the story BAC-2303
                var defaultResponseDateCmp = {
                    xtype : 'datefield',
                    name: 'defaultResponseDate',
                    id: 'defaultResponseDate',
                    anchor: '50%', 
                    padding: '0 0 15',
                    editable: false,
                    hidden: true,
                };

                //Added for the story BAC-2303
                var literalStore = Ext.create('Ext.data.Store',{
                    fields: ['value', 'label', 'type'],
                    data:{'items':[{
                            "label": TS.T("COMM004","Today"), 
                            "value": "Today",
                            "type": "DateAns"
                        },{
                            "label": TS.T("COMM005","Tomorrow"), 
                            "value": "Tomorrow",
                            "type": "DateAns"
                        },{
                            "label": TS.T("COMM006","Yesterday"), 
                            "value": "Yesterday",
                            "type": "DateAns"
                        },{
                            "label": TS.T("COMM007","Now"), 
                            "value": "Now",
                            "type": "DateTimeAns"
                        }
                    ]},
                    proxy: {
                        type: 'memory',
                        reader: {
                            type: 'json',
                            root: 'items'
                        }
                    },
                    sorters: [{
                        property: 'label',
                        direction: 'ASC'
                    }]
                });

                //Added for the story BAC-2303
                var literalCombo = {
                    xtype: 'combobox', 
                    padding: '0 0 15', 
                    id: 'literalCombo',
                    name: 'literalCombo',
                    labelField:'label', 
                    valueField:'value', 
                    displayField: 'label',
                    queryMode: 'local', 
                    editable: false, 
                    anchor: '50%',
                    store: literalStore,
                    hidden: true,
                    emptyText: TS.T("COMM003","Select"),
                    listeners: {              
                        expand : function(combo){
                            var answerTypeValue = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                            if(answerTypeValue !== null && answerTypeValue !== '' && answerTypeValue === 'Date'){
                                combo.store.filter('type','DateAns');
                            }
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                };

                me.add(valueFunctionComboCmp);
                me.add(defaultResponseDateCmp);
                me.add(literalCombo);

                me.add({
                    fieldLabel: TS.T("TAG044","Help URL"), name: 'helpURL',
                    id: SVMX.OrgNamespace+'__Help_URL__c',
                    anchor: '50%', padding: '0 0 15'
                });

                var responseType = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'response_Type'],
                    data: [
                        ['Text', TS.T("TAG026","Text")],
                        ['Checkbox', TS.T("TAG027","Checkbox")],
                        ['Radio Button', TS.T("TAG028","Radio Button")],
                        ['Picklist', TS.T("TAG029","Picklist")],
                        ['Multi-select Picklist', TS.T("TAG030","Multi-select Picklist")],
                        ['Number', TS.T("TAG031","Number")],
                        ['DateTime', TS.T("TAG032","DateTime")],
                        ['Date', TS.T("TAG033","Date")],
                        ['Attachment', TS.T("TAG048","Attachment")]//Added for the story BAC-2322
                    ],
                    //This is addded for sorting response type values during implementation of BAC-2322
                    sorters: [{
                        property: 'response_Type',
                        direction: 'ASC'
                    }]
                });

                this.__responseTypeDropDown = me.add({
                    xtype: 'combobox', padding: '0 0 15', 
                    id: SVMX.OrgNamespace+'__Response_Type__c',
                    name: 'response_Type', fieldLabel: TS.T("TAG034","Answer Type"),
                    labelField:'label', valueField:'Id', displayField: 'response_Type', defaultValue: 'Text', value: 'Text',
                    queryMode: 'local', editable: false, anchor: '50%',
                    store: responseType,
                    listeners: {              
                        change: function( field, newValue, oldValue ) {
                            //Clear filter literal combo - //Added for the story BAC-2322
                            var literalComboCmp = Ext.getCmp('literalCombo');
                            if(literalComboCmp != null){
                                literalComboCmp.store.clearFilter();
                            }

                            if(newValue === 'Checkbox' || newValue === 'Picklist' || newValue === 'Multi-select Picklist' || newValue === 'Radio Button'){
                                me.showHideResponseSetDropDown(true);
                                me.showResponseOptions(true);
                                me.showHideNewResponseSetName(true);
                            }else{
                                me.showHideResponseSetDropDown(false);
                                me.showResponseOptions(false);
                                me.showHideNewResponseSetName(false);
                            }

                            //Added for the story BAC-2322
                            if(newValue === 'Attachment'){
                                me.showHideOpdocDescriptionFields(true);
                            }
                            else{
                                me.showHideOpdocDescriptionFields(false);
                            }

                            //------Start-----Added for the story BAC-2300
                            me.hideAllDefaultAnsCmp();
                            if(newValue === 'Text' || newValue === 'Number' || newValue === 'Date' || newValue === 'DateTime'){
                                switch(newValue){
                                    case 'Text':
                                        me.resetAndShowCmp('defaultResponseText');
                                        break;
                                    case 'Number':
                                        me.resetAndShowCmp('defaultResponseNumber');
                                        break;
                                    case 'Date':
                                    case 'DateTime':
                                        me.resetAndShowCmp('valueFunctionCombo');
                                        me.resetAndShowCmp('defaultResponseDate');
                                        break;
                                }
                            }
                            //------End-----Added for the story BAC-2300

                            //-------Start------Added for the defect BAC-3361 fix
                            if(newValue === 'Attachment'){
                                Ext.getCmp('clearDefault').hide();
                            }
                            else{
                                Ext.getCmp('clearDefault').show();
                            }
                            //-------End------Added for the defect BAC-3361 fix
                        },  
                        afterrender: function(combo) { 
                            combo.setValue( this.defaultValue );
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    },
                });

                //Added for the story BAC-2322
                me.add({
                    xtype: 'checkbox', 
                    boxLabel: TS.T("TAG049","Include in Output Document"),
                    name: 'includeInOpDoc',
                    id: SVMX.OrgNamespace+'__SM_Show_In_Smart_Doc__c',
                    anchor: '50%',
                    padding: '0 0 15',
                    hidden: true
                });

                //Added for the story BAC-2322
                me.add({
                    xtype: 'checkbox', 
                    boxLabel: TS.T("TAG050","Description required"),
                    name: 'descriptionRequired',
                    id: SVMX.OrgNamespace+'__SM_Description_Required__c',
                    anchor: '50%',
                    padding: '0 0 15',
                    hidden: true
                });

                var responseSet = SVMX.create('Ext.data.ArrayStore',{
                    fields: ['Id', 'responseSetName', 'responseSetValues'],
                    data: []
                });

                this.__responseSetStore = responseSet;

                this.__responseSetDropDown = me.add({
                    xtype: 'combobox', padding: '0 0 15', 
                    hidden: 'true',
                    id: SVMX.OrgNamespace+'__Response_Set__c',
                    name: 'responseSetName', fieldLabel: TS.T("TAG035","Response Set"),
                    labelField:'label', valueField:'Id', displayField: 'responseSetName', defaultValue: 'CreateNew', value: 'CreateNew',
                    queryMode: 'local', editable: false, anchor: '50%',
                    store: responseSet,
                    listeners: {              
                        change: function( field, newValue, oldValue ) {
                            if(newValue === 'CreateNew'){
                                me.showHideNewResponseSetName(true);
                                me.__activeRecord.responseOptions = [""];
                                me.showResponseOptions(true);
                            }else{
                                var responseValues = [""];
                                var store = me.__responseSetDropDown.store;
                                var Items = store.data.items || [];
                                for(var i = 0; i < Items.length; i++){
                                    var tempData = Items[i].data;
                                    if(tempData.Id === newValue){
                                        me.__newResponseSetName.setValue(tempData.responseSetName);//Setting value in response set text box
                                        responseValues = tempData.responseSetValues && tempData.responseSetValues.split(";");
                                        if(responseValues && responseValues.length>0)
                                            responseValues.splice(responseValues.length-1, 1);
                                        break;
                                    }
                                }
                                me.__activeRecord.responseOptions = responseValues;
                                me.showResponseOptions(true);
                                //me.showHideNewResponseSetName(false);
                            }
                        },  
                        afterrender: function(combo) {
                        }
                    },
                    //This is added for the security fix
                    listConfig: {
                        getInnerTpl: function(displayField) {
                            return '{[Ext.String.htmlEncode(values.' + displayField + ')]}';
                        }
                    }
                });

                this.__newResponseSetName = me.add({
                    fieldLabel: TS.T("TAG036","Response Set Name"), name: 'newResponseSetName',
                    id: 'Name',
                    anchor: '50%', allowBlank: false, padding: '0 0 15',
                    //Added as part of defect BAC-3578 fix. Created custom label for this error message
                    blankText: TS.T("TAG054","This field is required")
                });
                
                me.add(basicBoxselect);

                //-------Start---------Added for the story BAC-2303
                var clearDefault = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXButton", {
                    id:'clearDefault',
                    text: TS.T("TAG052", "Clear Default"),
                    __parent: this, //Added for the story BAC-2301
                    //This is commented for fixing defect BAC-3578 as it is not needed
                    //anchor: '11%', //Changed for defect BAC-3361 fix
                    style: {
                        marginLeft: '0px',
                        marginRight: '0px',
                        marginTop: '10px',
                        marginBottom: '5px'
                    },
                    handler: function() {
                        //Here condition is added to fix defect BAC-3365
                        var answerTypeValue = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                        switch(answerTypeValue){
                            case 'Text':
                                Ext.getCmp('defaultResponseText').reset();
                                break;
                            case 'Number':
                                Ext.getCmp('defaultResponseNumber').reset();
                                break;
                            case 'Date':
                            case 'DateTime':
                                Ext.getCmp('valueFunctionCombo').reset();
                                Ext.getCmp('defaultResponseDate').reset();
                                Ext.getCmp('literalCombo').reset();
                                break;

                            //-------Start---------Added for the story BAC-2301
                            case 'Radio Button':
                            case 'Picklist':
                                var answerPanelItems = this.__parent.__responseOptionsPanel.__fields, l = answerPanelItems.length;
                                for(var i=0; i<l; i++){
                                    var radioButtonId = answerPanelItems[i].radioField.getId();
                                    if(radioButtonId != null){
                                        var radioCmp = Ext.getCmp(radioButtonId);
                                        //Here condition is added for fixing BAC-3399 defect
                                        if(radioCmp){
                                            radioCmp.setValue(false);
                                        }
                                    }
                                }
                            //-------End---------Added for the story BAC-2301

                            //------Start-----Added for the story BAC-2302
                            case 'Multi-select Picklist':
                            case 'Checkbox':
                                var answerPanelItems = this.__parent.__responseOptionsPanel.__fields, l = answerPanelItems.length;
                                for(var i=0; i<l; i++){
                                    var checkboxFieldId = answerPanelItems[i].checkboxField.getId();
                                    if(checkboxFieldId != null){
                                        var checkboxCmp = Ext.getCmp(checkboxFieldId);
                                        //Here condition is added for fixing BAC-3399 defect
                                        if(checkboxCmp){
                                            checkboxCmp.setValue(false);
                                        }
                                    }
                                }
                            //------End-----Added for the story BAC-2302
                        }
                    }
                });
                //me.add(clearDefault); This is commented for fixing defect BAC-3578
                //----Start------//Below code is added for fixing defect BAC-3578 by adding panel in page and
                //inside the panel added the button for auto width
                var clearDefaultButtonPanel = Ext.create("Ext.form.Panel",{
                    layout: 'vbox', border: false, anchor: '50%'
                });
                clearDefaultButtonPanel.add(clearDefault);
                me.add(clearDefaultButtonPanel);
                //------End--------//

                //-------End---------Added for the story BAC-2303
                
                this.radioButton = me.add({
                    xtype: 'radiogroup',
                    id: 'operationTypeCmp', //Added for the story BAC-2301
                    columns: 1,
                    vertical: true,
                    items: [{ 
                        boxLabel: TS.T("TAG037","Update library (all checklists using this question will be updated)"), 
                        name: 'Operationtype', inputValue: 'SAVE', checked: true
                    },{ 
                        boxLabel: TS.T("TAG038","Save as a new question in the library"), 
                        name: 'Operationtype', inputValue: 'SAVEAS'
                    }],
                    listeners: {
                        change: function( rgroup, newValue, oldValue, eOpts ){
                            me.__actionType = newValue.Operationtype;
                        }
                    }
                });
                
                this.showResponseOptions();
            },

            //Added for the story BAC-2300
            hideAllDefaultAnsCmp: function(){
                Ext.getCmp('defaultResponseText').hide();
                Ext.getCmp('defaultResponseNumber').hide();
                Ext.getCmp('valueFunctionCombo').hide();
                Ext.getCmp('defaultResponseDate').hide();
                Ext.getCmp('literalCombo').hide();
            },

            //Added for the story BAC-2300
            resetAndShowCmp: function(cmpId){
                var cmp = Ext.getCmp(cmpId);
                cmp.reset();
                cmp.show();
            },

            //Added for the story BAC-2322
            showHideOpdocDescriptionFields: function(isShow){
                var showInOpdocCmp = Ext.getCmp(SVMX.OrgNamespace+'__SM_Show_In_Smart_Doc__c');
                var descriptionRequiredCmp = Ext.getCmp(SVMX.OrgNamespace+'__SM_Description_Required__c');
                if(isShow){
                    showInOpdocCmp.setValue(true);
                    descriptionRequiredCmp.setValue(true);
                    showInOpdocCmp.show();
                    descriptionRequiredCmp.show();
                }
                else{
                    showInOpdocCmp.setValue(false);
                    descriptionRequiredCmp.setValue(false);
                    showInOpdocCmp.hide();
                    descriptionRequiredCmp.hide();
                }
            },

            showHideResponseSetDropDown: function(isShow){
                if(isShow){
                    this.__responseSetDropDown.reset();
                    this.__responseSetDropDown.show();
                }
                else
                    this.__responseSetDropDown.hide();
            },

            showHideNewResponseSetName: function(isShow){
                if(isShow){
                    this.__newResponseSetName.reset();
                    this.__newResponseSetName.show();
                }
                else
                    this.__newResponseSetName.hide();
            },

            showResponseOptions: function(isShow){
                if(this.__responseOptionsPanel) this.__responseOptionsPanel.destroy();
                if(!isShow) return;

                this.__responseOptionsPanel = SVMX.create('com.servicemax.client.qbm.ui.desktop.editQuestion.ResponseOptionsPanel', {
                    data: (this.__activeRecord && this.__activeRecord.responseOptions) || null,
                    defaultValueForRadio: (this.__activeRecord && this.__activeRecord.defaultValueForRadio) || null, //Added for the story BAC-2301
                    defaultValueForCheckbox: (this.__activeRecord && this.__activeRecord.defaultValueForCheckbox) || null //Added for the story BAC-2302
                });

                //Changed to fix defect BAC-3578 for setting correct position
                //var ind = (!this.radioButton.hidden && this.items.length-2) || this.items.length-2; 
                var ind = (!this.radioButton.hidden && this.items.length-3) || this.items.length-3;
                this.add(ind, this.__responseOptionsPanel);
            },

            loadQuestionDataInEditMode: function(isEditMode, record){
                //this.resetData();
                this.resetComponentData(); //Added for the story BAC-2301
                
                //Added for the story BAC-2322
                if(record && record[SVMX.OrgNamespace+'__Response_Type__c'] && record[SVMX.OrgNamespace+'__Response_Type__c'] === 'Attachment'){
                    this.showHideOpdocDescriptionFields(true);
                }
                else{
                    this.showHideOpdocDescriptionFields(false);
                }

                this.showHideNewResponseSetName(false);
                if(!isEditMode){
                    this.showResponseOptions(false);
                    this.showHideResponseSetDropDown(false);
                }

                //-------Start---------Added for the story BAC-2303
                this.hideAllDefaultAnsCmp();
                this.resetAndShowCmp('defaultResponseText');
                var answerType = record && record[SVMX.OrgNamespace+'__Response_Type__c'] && record[SVMX.OrgNamespace+'__Response_Type__c'];
                if(answerType === 'Date' || answerType === 'DateTime'){
                    this.resetAndShowCmp('valueFunctionCombo');
                    if(record['valueFunctionCombo'] && record['valueFunctionCombo'] === 'Value'){
                        this.resetAndShowCmp('defaultResponseDate');
                    }
                    else if(record['valueFunctionCombo'] && record['valueFunctionCombo'] === 'Function'){
                        this.resetAndShowCmp('literalCombo');
                    }
                }
                //-------End---------Added for the story BAC-2303

                //-------Start------Added for the defect BAC-3361 fix
                if(answerType === 'Attachment'){
                    Ext.getCmp('clearDefault').hide();
                }
                else{
                    Ext.getCmp('clearDefault').show();   
                }
                //-------End------Added for the defect BAC-3361 fix

                this.__activeRecord = record;
                this.getForm().setValues(record);

                //Added for fixing issue (After opening picklist question then open text question in edit mode it shows the answers panel which should not come in text question)
                if(record && record[SVMX.OrgNamespace+'__Response_Type__c'] && record[SVMX.OrgNamespace+'__Response_Type__c'] === 'Text'){
                    this.showResponseOptions(false);
                }

                if(isEditMode) this.__actionType = "SAVE";
                else this.__actionType = "SAVEAS";
            },

            //Added for the story BAC-2301 for reseting all the component value before loading new data
            resetComponentData: function(){
                Ext.getCmp(SVMX.OrgNamespace+'__Question__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__QuestionID__c').reset();
                Ext.getCmp('defaultResponseText').reset();
                Ext.getCmp('defaultResponseNumber').reset();
                Ext.getCmp('valueFunctionCombo').reset();
                Ext.getCmp('defaultResponseDate').reset();
                Ext.getCmp('literalCombo').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__Help_URL__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__SM_Show_In_Smart_Doc__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__SM_Description_Required__c').reset();
                Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').reset();
                Ext.getCmp('tagsList').reset();
                Ext.getCmp('operationTypeCmp').reset();
            },

            getData: function(){
                var data = this.getForm().getFieldValues();
                data.Operationtype = this.__actionType;

                if(this.__actionType === "SAVE"){
                    data.Id = this.__activeRecord.Id;
                }

                return data;
            },

            resetData: function() {
                this.getForm().reset();
            },

            getActionType:  function(){
                return this.__actionType;
            }
        });

        Ext.define("com.servicemax.client.qbm.ui.desktop.editQuestion.ResponseOptionsPanel", { 
            extend: 'Ext.form.FieldSet',
 
           constructor: function(config) {

                config = Ext.apply({
                    title: TS.T("TAG039","Answer Values"), 
                    layout: 'vbox', border: true, anchor: '50%'
                },
                config || {});

                this.callParent([config]);
            },

            initComponent: function(){
                this.callParent(arguments);
                var me = this;

                this.__addButton = me.add({
                    xtype: 'button', text: '+'+TS.T("TAG040","Add Answer"), anchor: '10%', margins: '8 8',
                    disabled: true,
                    listeners: {
                        click: function(){
                            me.addOption();
                            me.__addButton.setDisabled(true);
                            me.__disableDeleteButton();
                        }
                    }
                });

                this.__fields = [];

                var localDefaultValueForRadio = this.defaultValueForRadio; //Added for the story BAC-2301
                var localDefaultValueForCheckbox = this.defaultValueForCheckbox; //Added for the story BAC-2302
                var data = this.data || [""],
                    i, l = data.length, 
                    item;

                for(i=0; i<l; i++){
                    item = data[i];
                    //me.addOption(item);
                    me.addOption(item, localDefaultValueForRadio, localDefaultValueForCheckbox); //Added for the story BAC-2301
                }

                this.__disableDeleteButton();
            },

            //addOption: function(item){
            addOption: function(item, localDefaultValueForRadio, localDefaultValueForCheckbox){    //Added for the story BAC-2301
                var me = this;
                item = item || "";

                //-----Start-------Added for the story BAC-2301
                var checkStatusForRadio = false;
                if(item === localDefaultValueForRadio){
                    checkStatusForRadio = true;
                }
                var answerType = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                //-----End-------Added for the story BAC-2301

                //------Start-----Added for the story BAC-2302
                var checkStatusForCheckbox = false;
                if(localDefaultValueForCheckbox != null && localDefaultValueForCheckbox.length > 0){
                    var len = localDefaultValueForCheckbox.length;
                    for(var i=0; i<len; i++){
                        if(item === localDefaultValueForCheckbox[i]){
                            checkStatusForCheckbox = true;
                            break;
                        }
                    }
                }
                //------End-----Added for the story BAC-2302

                var mainPanel = this.add(this.items.length-1, {
                    layout: 'hbox', width: '100%', border: false, flex: 1, padding: '8 8'
                });

                var fld = mainPanel.add({
                    xtype: 'textfield', name: 'answers', flex:0.9, allowBlank: false, padding: '0 5',
                    //Added as part of defect BAC-3578 fix. Created custom label for this error message
                    blankText: TS.T("TAG054","This field is required"),
                    value: item,
                    listeners:{ 
                        change: function(){
                            var answerType = Ext.getCmp(SVMX.OrgNamespace+'__Response_Type__c').getValue();
                            if(answerType === 'Radio Button' || answerType === 'Picklist'){
                                me.__setValueOfRadio(); //Added for the story BAC-2301
                            }
                            me.__addButton.setDisabled(!me.__isValid());
                        }
                    }
                });

                //------Start-----Added for the story BAC-2302
                var checkboxFieldForDefaultAns = Ext.create('Ext.form.field.Checkbox',{
                    name: 'defaultAnsForCheckbox', boxLabel: TS.T("TAG053","Default"), 
                    //flex:0.2, //Commented for the defect BAC-3420 fix
                    value: item, 
                    checked: checkStatusForCheckbox
                });
                if(answerType === 'Checkbox' || answerType === 'Multi-select Picklist'){
                    mainPanel.add(checkboxFieldForDefaultAns);
                }
                //------End-----Added for the story BAC-2302

                //--------Start-------Added for the story BAC-2301
                var radioFieldForDefaultAns = Ext.create('Ext.form.field.Radio',{
                    xtype: 'radiofield', name: 'defaultAnsForRadio', boxLabel: TS.T("TAG053","Default"), 
                    //flex:0.2, //Commented for the defect BAC-3420 fix
                    inputValue: item, 
                    checked: checkStatusForRadio,
                    listeners:{ 
                        change: function(cmpRadio, newValue, oldValue, eOpts){
                            me.__setValueOfRadio();
                        }
                    }
                });
                if(answerType === 'Radio Button' || answerType === 'Picklist'){
                    mainPanel.add(radioFieldForDefaultAns);
                }
                //--------End-------Added for the story BAC-2301

                var btn = mainPanel.add({
                    xtype: 'button', name: 'del', text: 'X', flex:0.1,
                    margin: '0 0 0 5', //Added for the defect BAC-3420 fix
                    listeners:{ 
                        click: function(){
                            mainPanel.destroy();   
                            me.__disableDeleteButton(true);
                        }
                    }
                });

                //this.__fields.push({fld: fld, btn: btn});
                this.__fields.push({fld: fld, btn: btn, radioField: radioFieldForDefaultAns, checkboxField: checkboxFieldForDefaultAns}); //Modified for the story BAC-2301
            },

            //Added for the story BAC-2301
            __setValueOfRadio: function(){
                var items = this.__fields, l = items.length;
                for(var i =0; i<l; i++){
                    items[i].radioField.inputValue = items[i].fld.getValue();
                }
            },

            __isValid: function(){
                var items = this.__fields,
                    i, l = items.length,
                    item;

                for(i = 0; i < l; i++){
                    item = items[i];
                    if(item && !item.fld.isDestroyed && !item.fld.getValue()){
                        return false;
                    }
                }
                return true;
            },

            __disableDeleteButton: function(){
                var items = this.__fields,
                    i, l = items.length,
                    item, btn, count = 0;

                for(i = 0; i < l; i++){
                    item = items[i];
                    if(item && !item.btn.isDestroyed){
                        item.btn.setDisabled(false);
                        if(!count) btn = item.btn;
                        count++;
                    }
                }

                if(count === 1 && btn) btn.setDisabled(true);
                this.__addButton.setDisabled(!this.__isValid());
            }
        });
    }
})();

// Code: C:\var\lib\jenkins\workspace\ReleaseOps\SVMX_UIFW_SUM20\src\modules\com.servicemax.client.qbm.ui.desktop\src\impl.js

(function(){

	var appImpl = SVMX.Package("com.servicemax.client.qbm.ui.desktop.impl");

	appImpl.Class("Module", com.servicemax.client.lib.api.ModuleActivator, {

		__constructor : function(){
			this.__base();
		},

		beforeInitialize: function() {

        },

        initialize: function() {
        },

        afterInitialize: function() {
        	com.servicemax.client.qbm.ui.desktop.api.init();
            com.servicemax.client.qbm.ui.desktop.editQuestion.init();
            com.servicemax.client.qbm.ui.desktop.boxselect.init();
        }

	}, {
		instance : null
	});

})();

