/**
 * 
 */

(function(){
    
    var ibtreeImpl = SVMX.Package("com.servicemax.client.installigence.ibtree");

ibtreeImpl.init = function(){
    
    /**
     * EVENTS:
     * 01. node_selected
     * 02. records_selected
     * 03. node_loaded
     */
    Ext.define("com.servicemax.client.installigence.ibtree.IBTree", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.ibtree',
        __meta : null,
        __tree : null,
        __treeData : null,
        __treeDataById : null,
        __expandedById : null,
        __searchText : null,
        __optionsPanel : null,
        __filterExpressions : null,
        __transientFilters : null,
        __allNodeFilters : null,
        __appliedNodeFilters : null,
        __productIconIndex : null,
        __transientRecordIndex : null,
        __locationsVisible : true,
        __swappedVisible : true,
        __selectedNodeId : null,
        //Below variables are required for selecting single account tree data at a time.
        __accountsMenubarButton : null,
        __selectedAccountName : null,
        __currentAccountId : null, //current account selected
        __selectedAccountId : null, //initial account selected
        __isAccountChanged : null, //used to track if account changed.
        __isWorkOrderFilterChecked : null, //used to track work order filter check status.
        __selectedWorkOrderFilterData : null,
        __dragEnabled : null,
        __root : null,
        __selectFromRegisterExternal : null,
        __IBReferenceINFO : null, //Storing all reference field value for IB
        __isDataSyncTriggerd : null, //to check weather data sync is trigger is not.

        resizable : true,
        
        constructor: function(config) { 
            var me = this;
            this.__productIconIndex = {}; //assign an empty object for this ivar.
            this.__isDataSyncTriggerd = false; //default value.
            //Add account drop down here.
            var accountMenuButton =  this.__createAccountMenubarWithButton(); 
            this.__isAccountChanged = false;
            this.__isWorkOrderFilterChecked = true;
            this.__selectFromRegisterExternal = false;
            this.__dragEnabled = false;
            this.__registerExternalRequest();
            this.__setAccountIdOnLaunch();
            this.__registerForFilterActionCall();
            this.__getAllTopLevelAccounts();
            this.__clearAllFiltersForIbSearch();
			this.__getIBReference();
            var store = Ext.create('Ext.data.TreeStore', {
                
            });

            // meta model
            this.__meta = config.meta;
            this.__root = config.root;
            this.__meta.bind("MODEL.UPDATE", function(evt){
                this.__refreshFilterOptions();
            }, this);

            // options panel
            /*var cbLocations = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox",{ 
                boxLabel : $TR.SHOW_LOCATIONS,
                checked : this.__locationsVisible,
                margin: '0 0 0 5',
                handler : function(){
                    me.__locationsVisible = this.value;
                    if(this.value){
                        me.showNodes('loc');
                    }else{
                        me.hideNodes('loc');
                    }
                }
            });
            var cbSwappedProducts = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox",{ 
                boxLabel : $TR.SHOW_SWAPPED_PRODUCTS,
                checked : this.__swappedVisible,
                margin: '0 0 0 5',
                handler : function(){
                    me.__swappedVisible = this.value;
                    if(this.value){
                        me.showNodes('swap');
                    }else{
                        me.hideNodes('swap');
                    }
                }
            });*/

            var filterOptions = this.__getFilterOptions();
            var optionPanelItems = filterOptions;/*.concat([
                cbLocations,
                cbSwappedProducts
            ]);*/
            this.__optionsPanel = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXPanel", {
                layout : {type : "vbox"}, cls: 'svmx-options-panel',
                items : optionPanelItems,
                header : false, collapsed : true, width : "100%", margin: '2 3 0 3'
            });
            
            // tree
            this.__expandedById = {};
            this.__tree = SVMX.create("com.servicemax.client.installigence.ui.components.Tree", {
                cls: 'grid-panel-borderless svmx-tree-panel', margin: '5 0 0 0', width: '100%', 
                store: store, rootVisible: false, flex : 1,
                viewConfig: {
                    plugins: {
                        ptype : 'treeviewdragdrop',
                        enableDrag : true,
                        enableDrop : true,
                        appendOnly : true,
						containerScroll : true
                    },
                    listeners : {
                        nodedragover : function(targetNode, position, dragData, e, eOpts){
                            return me.__canDropOn(dragData, targetNode);
                        },
                        beforedrop : function(node, data, overModel, dropPosition, dropHandlers, eOpts){
                             me.__dragEnabled = true;
                            return me.__handleDropOn(data, overModel, dropHandlers);
                        },
                        drop : function(){
                            
                        }
                    }
                },
                
                listeners : {
                    select : function(that, record, index, eOpts){
                        if(me.__selectedNodeId !== record.data.id){
                            me.__selectedNodeId = record.data.id;
                            me.fireEvent("node_selected", me.__treeDataById[record.data.id]);
                        }
                    },
                    checkchange : function(node, checked, eOpts){
                        // one more records may have been selected via checkbox. fire a different event
                        me.__fireRecordsSelected();
                    },
                    afteritemexpand : function(node, index, item, eOpts) {
                        var treeNode = me.__treeDataById[node.id];
                        if(treeNode){
                            treeNode.expanded = true;
                            // Ensure parents are expanded internally (even if filtered)
                            var parent = me.__treeDataById[treeNode.parentId];
                            while(parent){
                                parent.expanded = true;
                                var parent = me.__treeDataById[parent.parentId];
                            }
                            me.__expandedById[node.id] = true;
                        }
                        if(node.data.nodeType == "IB" && me.__dragEnabled === false) { 
                            setTimeout(function(){
                                me.__showMore({node : node});
                            },1);
                        }
                    },
                    afteritemcollapse : function(node, index, item, eOpts) {
                        var treeNode = me.__treeDataById[node.id];
                        if(treeNode){
                            treeNode.expanded = false;
                            me.__expandedById[node.id] = false;
                        }
                    }
                }
            });
            
            // search
            this.__searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                cls: 'toolbar-search-textfield', width: '90%', emptyText : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'), enableKeyEvents : true,
                listeners : {
                    keyup : function(that, e, opts) {
                        me.__tree.search(that.getValue());
                    }
                }
            });
            
            // Filter button with menu option.
            var filterMenu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain:true,
                    width: 250,
                    collapsible: false, floatable: false, split: false,
                    autoScroll:true

                });
            var filterButton = 
                            {   xtype : 'button', 
                                text : $TR.__getValueFromTag($TR.PRODIQ001_TAG124,'Filter'),
                                cls : 'ibtree-filter-btn',
                                menuAlign : 'tr-br',
                                menu :filterMenu,
                                region : 'west',
                                // width: 100, 
                                width : '35%',
                                // margin:  '-30 0 0 200',
                                textAlign : 'right',
                                layout : {
                                      align: 'right'
                                },

                                handler : function(){
                                                me.toggleOptions();
                                }
                          };

            this.__transientFilters = [];

            this.__setupNodeFilters();

            this.__bindSyncEvents();

            var toptoolbar = Ext.create('com.servicemax.client.installigence.ui.components.SVMXToolbar', {
                id: 'ttool',
                cls: 'ibtree-toolbar',
                style:'border-bottom: 1px solid #d7d7d7 !important;',
                width: '100%',
                items: [
                          accountMenuButton,  filterButton      
                ]        

            });
            
            config = Ext.apply({
                layout : {type : "vbox"},
                dockedItems : [
                    {dock: 'top', xtype: 'toolbar', cls: 'grid-panel-borderless svmx-ibtree-toolbar', style:'background-color: #fff', margin: '0',
                    /*items:[ this.__searchText,
                            { xtype: 'button', iconCls: 'filter-icon', handler : function(){
                                me.toggleOptions();
                            }}
                    ]*/}
                ],
                items:[toptoolbar,this.__optionsPanel,this.__tree]
            }, config || {});
            this.callParent([config]);
        },

        __bindSyncEvents : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();

            syncService.bind("SYNC.STATUS", function(evt){
                var type = evt.data.type;
                if(type === "complete"){
                    var syncType = evt.data.syncType;
                    // Clear the account-menu items after initial sync.
                    if(syncType==="initial" && !SVMX.getCurrentApplication().isAppEmbedded()){
                         this.__selectedAccountId=null;
                         this.__currentAccountId=null;
                         this.__accountsMenubarButton.setText(' ');
                         this.__accountsMenubarButton.menu.items.removeAll();
                    }
                   
                    //Get top level IB's accounts only if synch completes for standalone app.
                    if (!this.__currentAccountId && !SVMX.getCurrentApplication().isAppEmbedded()) {
                        this.__getAllTopLevelAccounts();
                    }
                    
                    //if the sync type is purge then clear transiant filters. Defect - 016736
                    if(syncType === "purge" || syncType === "reset"){
                        this.deleteTransientFilters();
                        this.toggleOptions();
                    }
                    if(syncType === "incremental" || syncType === "purge" || syncType === "insert_local_records"){
                        this.__isDataSyncTriggerd = true;
                        this.refreshContent();
                    }
                }else if(type === "recordstatus"){
                    var recordId = evt.data.recordId;
                    var isTransient = !evt.data.valid;
                    this.setTreeNodeTransient(recordId, isTransient);
                    // Maintain the transient record index
                    var index = this.__transientRecordIndex.indexOf(recordId);
                    if(isTransient){
                        if(index === -1){
                            this.__transientRecordIndex.push(recordId);
                        }
                    }else{
                        if(index !== -1){
                            this.__transientRecordIndex.splice(index, 1);
                        }
                    }
                }
            }, this);
        },
        
        __registerExternalRequest : function(){
            SVMX.getClient().bind("EXTERNAL_MESSAGE", function(evt){
                var data = SVMX.toObject(evt.data);

                if (data.action === "SYNC" ) { //initiate initial sync once MFL app completes its sync.
                    if(data.operation === 'INITIAL' && !SVMX.getCurrentApplication().isAppEmbedded()) {
                        this.__root.handleFindAndGet({syncType : "initial"});
                    }
                    return;
                }

                if (data.recordIds === undefined) {
                    return;
                }
                var nodeId = data.recordIds[0];
                /*
                    if search is opened then trying to invoke wo from MFL. it was not getting refreshed. 
                    So close the search screen and invoke IB from MFL
                    Here cardIndex referes to IB Search screen.
                */
                if (this.__root.currentView.cardIndex === 3 && data.focused === undefined && !SVMX.getCurrentApplication().isAppEmbedded()) {
                    this.__root.handleNavigateBack();
                }

                if (data.accountId) {

                         /*
                        NOTE:
                            Apply below changes only for stand alone PIQ.
                            1. Clear app work order filters before invoking.
                            2. Clear transients data since we are clearing WO filters.
                            3. Clear appliedNodFilter data sincw we are clearing WO filters
                        
                        */

                        if (!SVMX.getCurrentApplication().isAppEmbedded() && data.focused === undefined ) {

                            var optionItems = this.__optionsPanel.items.items;
                            for(var i = 0; i < optionItems.length; i++){
                                var checkbox = optionItems[i];
                                if(checkbox.isTransientFilter === true) {
                                    this.__optionsPanel.remove(optionItems[i]);
                                } 
                                checkbox.setValue(false);
                            }
                            if (this.__transientFilters) {
                                for (var i = 0; i < this.__transientFilters.length; i++) {
                                    this.__transientFilters.splice(i,1);
                                }
                            }

                            var filterKeys = Object.keys(this.__appliedNodeFilters);
                            for(var i = 0; i < filterKeys.length; i++){
                                delete this.__appliedNodeFilters[filterKeys[i]];
                            }

                        }

                        if (data.focused === undefined) {
                            this.__searchForSelectedIBInLocalDatabase(data);
                        }

                        this.__selectedNodeId = null; // reset the value before invoking.
                        if(data.object === SVMX.getCustomObjectName("Installed_Product") || data.object === SVMX.getCustomObjectName("Site") ){
                            this.__isIBorLocationRecordSelected = true;
                        }else {
                            this.__isIBorLocationRecordSelected = false;
                        }
                        this.__selectFromRegisterExternal = true;
                        this.__selectedAccountId = data.accountId;
                        this.__currentAccountId = data.accountId;
                        this.__setSelectedAccountIdForIBSearch();
                        var menu = this.__accountsMenubarButton.menu;
                        var l = menu.items.items.length;
                        for (var i = 0; i < l; i++) {
                                var menuItem = menu.items.items[i];
                                if (menuItem.Id === this.__currentAccountId) {
                                        this.__accountsMenubarButton.setText(menuItem.text);
                                        this.__selectedAccountName = menuItem.text;
                                        break;
                                }
                         }
                         this.__isAccountChanged = false;
                         this.refreshContent();
                } 
                else {
                    SVMX.getCurrentApplication().getAppFocus();
                    this.__showErorrMessageForSelectedAccount();
                }
                
            }, this);           
        },

        __setAccountIdOnLaunch:function() {
            // Handle pending external messages
            var pendingMessage = SVMX.getCurrentApplication().getPendingMessage();
            if(pendingMessage !== null){
                pendingMessage = SVMX.toObject(pendingMessage);
                if (pendingMessage.accountId) {
                        this.__selectedAccountId = pendingMessage.accountId;
                        this.__currentAccountId = pendingMessage.accountId;
                        this.__setSelectedAccountIdForIBSearch();
                        this.__searchForSelectedIBInLocalDatabase(pendingMessage);
                } else {
                    if(SVMX.getCurrentApplication().isAppEmbedded()){
                        this.__showErorrMessageForSelectedAccount();
                    }
                    
                }
            } else {
                this.__isWorkOrderFilterChecked = false; // this flag is used to load first record, if there is no external data.
            }
        },

        __showErorrMessageForSelectedAccount : function()  { 
            SVMX.getCurrentApplication().showQuickMessage($TR.__getValueFromTag($TR.PRODIQ001_TAG056,'info'), $TR.__getValueFromTag($TR.PRODIQ001_TAG119,'The selected record does not have an account associated with it. Please contact your administrator to resolve this issue.'));
        },

        __setSelectedAccountIdForIBSearch : function() {
            var data = {};
            data.accountId = this.__currentAccountId;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "ACCOUNT_ID_MESSAGE", this, data);
            SVMX.getClient().triggerEvent(evt); 

        },

        __clearAllFiltersForIbSearch : function () {
            var me = this;
            SVMX.getClient().bind("CLEAR_FILTERS_MESSAGE", function(evt){
                // me.__uncheckFilters();
                var optionItems = me.__optionsPanel.items.items;
                for(var i = 0; i < optionItems.length; i++){
                    var checkbox = optionItems[i];
                    checkbox.setValue(false);
                }
            });
        },

        __registerForFilterActionCall : function(){
            
            SVMX.getClient().bind("FILTER_ACTION_CALL", function(evt){
                var data = SVMX.toObject(evt.data);
                this.toggleOptions();
            }, this);           
        },

        __searchForSelectedIBInLocalDatabase : function(data) {
            if(data.object === SVMX.getCustomObjectName("Service_Order") || data.object === SVMX.getCustomObjectName("Installed_Product")){
                data = SVMX.toObject(data);
                var selectedIBId =  data.recordIds[0];
                var accountId = data.accountId;
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.FIND_SELECTED_IB_IN_LOCAL_DB", this, {
                    request : {
                        context : this,
                        handler : this.onSearchBySelectedIBComplete,
                        params : {
                            accountId : accountId,
                            selectedIBId : selectedIBId
                        }
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            }

        },
        onSearchBySelectedIBComplete : function(result) {
            if (result === false) {
                SVMX.getCurrentApplication().showQuickMessage($TR.__getValueFromTag($TR.PRODIQ001_TAG056,'info'), $TR.__getValueFromTag($TR.PRODIQ001_TAG046,'Installed product or Location record(s) may not be available in the tree view because not all required data has been downloaded. Please download the associated Account or Installed Product record(s) and retry.'));
            }
        },
        
        __handleExternalMessage : function(data){
            if(data.object === SVMX.getCustomObjectName("Service_Order")){
                this.__selectFromExternal = true;
                this.__createTransientFilter(data);
            }else if(data.object === SVMX.getCustomObjectName("Installed_Product")){
                this.__selectFromExternal = true;
                this.__uncheckFilters();
                this.__selectTreeNodes(data);
            }else if(data.object === SVMX.getCustomObjectName("Site")){
                this.__selectFromExternal = true;
                this.__uncheckFilters();
            	this.__showLocationNode(data);
            } else {
                // Unrelated to IB tree
            }
        },

        __createTransientFilter : function(data){
            var me = this;
            var transFilter = SVMX.create("com.servicemax.client.installigence.ibtree.TransientFilter", {parent : this, data : data,meta : this.__meta});
            var exists = false;
            if(this.__transientFilters){
                for(var i = 0; i < this.__transientFilters.length; i++){
                    if(this.__transientFilters[i].getAlias() === transFilter.getAlias()){
                        // Already exists, let it reinitialize
                        exists = true;
                        transFilter = this.__transientFilters[i];
                        transFilter.setChecked();
                        break;
                    }
                }
                // Expand all the nodes
                this.__selectTreeNodes(data, function(){
                    if(!exists){
                        //Fixed: 027684 issue.
                        if (me.__transientFilters) {
                            var firstRecord = me.__transientFilters[0];
                            if (firstRecord === undefined) {
                                me.__transientFilters.push(transFilter);
                                transFilter.initialize(false);
                            } else {
                                for (var i = 0; i < me.__transientFilters.length; i++) {
                                    var workOrderName = me.__transientFilters[i].__data.sourceRecordName;
                                    var filterSourceRecordName = transFilter.__data.sourceRecordName;
                                    if (workOrderName !== filterSourceRecordName) {
                                        me.__transientFilters.push(transFilter);
                                        transFilter.initialize(false);
                                    } 
                                }
                            }
                        }
                    }else{
                        transFilter.setup();
                    }
                });
            }
        },

        enableAccountsMenuBarButton : function() {
            if (this.__accountsMenubarButton) {
                    this.__accountsMenubarButton.setDisabled(false);
            }
        },

        disableAccountsMenuBarButton : function() {

            if (this.__accountsMenubarButton) {
                    this.__accountsMenubarButton.setDisabled(true);
                    this.__accountsMenubarButton.setText(this.__selectedAccountName);
            }
        },
        enableOrDisableThePanels : function(flag) {
            if(window.parent.SVMX.getClient().getApplicationParameter("client-type").toLowerCase() !== "laptop")  {
                this.__optionsPanel.setDisabled(flag); 
                this.__tree.setDisabled(flag);
            }
        },

        __uncheckFilters : function(){
            var optionItems = this.getOptionsPanel().items.items;
            for(var i = 0; i < optionItems.length; i++){
                var checkbox = optionItems[i];
                checkbox.setValue(false);
            }
            this.__selectFromRegisterExternal = false;// reset the flag.

        },

        getTransientFilters : function(){
            var transFilter = [];
            if(this.__transientFilters){
                transFilter = this.__transientFilters;
            }
            return transFilter;
        },

        deleteTransientFilters : function(){
            var transientFilters = this.getTransientFilters();
            for(var i = 0; i < transientFilters.length; i++){
                transientFilters[i].hide();
            } 
            delete this.__transientFilters;
        },

        selectTreeNode : function(recordId, params, callback){
            this.__selectTreeNodes({recordIds : [recordId]}, callback, params);
        },
        
        __selectTreeNodes : function(data, callback, params){
            data = SVMX.toObject(data);
            this.__showSelectedIBRecord(data, callback, params);
        },
        
        __showLocationNode : function(data){
        	data = SVMX.toObject(data);
        	var root = SVMX.cloneObject(this.__treeData.root);
            var isRecordFound = this.__searchForLocation(root.children, root, data.recordIds[0]);
            if(isRecordFound === false && this.__selectFromExternal){
                SVMX.getCurrentApplication().showQuickMessage("info", $TR.__getValueFromTag($TR.PRODIQ001_TAG046,'Installed product or Location record(s) may not be available in the tree view because not all required data has been downloaded. Please download the associated Account or Installed Product record(s) and retry.'));
                delete this.__selectFromExternal;
            }
        },
        
        __searchForLocation : function(children, parentNode, recordId){
            var isRecordFound = false;
            if(!children) return isRecordFound;
            for(var i = 0; i < children.length; i++){
                var child = children[i];
                if(child.id === recordId){
                    var node = this.__tree.getStore().getNodeById(recordId);
                    if(node){
                        isRecordFound = true;
                        this.__tree.selectPath(node.getPath());
                        break;
                    }
                }else{
                    isRecordFound = this.__searchForLocation(child.children, parentNode, recordId);
                    if(isRecordFound === true) break;
                }
            }
            return isRecordFound;
        },
        
        __showSelectedIBRecord : function(data, callback, params) {
            var root = SVMX.cloneObject(this.__treeData.root);
            var loadSelectedIB = SVMX.create("com.servicemax.client.installigence.loadselectedib.LoadSelectedIB", {
                parent : this,
                selectedIB : data,
                root : root,
                callback : callback,
                params : params
            });
        },

        __createAccountMenubarWithButton:function() {
            //Add drop down for showing selected account.
            var me = this;
            var menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain :true,
                    width : 310,
                    maxHeight : 500,
                    cls :' ibtree-account-filter',
                    scrollable : true,
                    layout: 'vbox',
                    listeners : {

                                    hide : function(item,eOpts) {
                                        if (me.__menuItemSelected === false) {
                                                me.enableOrDisableThePanels(false); 
                                        }    
                                    }
                                }
                });               

            this.__accountsMenubarButton = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXButton",{ 
                    width : '65%',
                    // width : 300,
                    cls : 'border-botton', 
                     region : 'east',
                    disabled : false,
                    docked : 'left',
                    textAlign : 'left',
                    // margin: '8 3 0 3',
                    margin : '0 0 0 -5',
                    menuAlign : 'tl-bl',
                    layout : {
                      align : 'left'
                    },
                    menu : menu

                });
            return this.__accountsMenubarButton;
        },

        __getFilterOptions : function(){
            var me = this;
            if(!this.__filterExpressions){
                this.__filterExpressions = [];
            }

            var options = [];
            if(this.__meta.filters && this.__meta.filters.length){
                this.__filterState = this.__filterState || {};
                if(this.__meta.state && this.__meta.state.filters){
                    this.__filterState = this.__meta.state.filters;
                }
                for(i = 0; i < this.__meta.filters.length; i++){
                    var filter = this.__meta.filters[i];
                    var filterName = filter.name;
                    var cb = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
                        boxLabel : filterName,
                        filterExpression : filter.expression,
                        inputValue : i,
                        value : me.__filterState[filterName],
                        margin: '0 0 0 5',
                        handler : function(){
                            // Index checked state so that it can be restored
                            me.__filterState[this.boxLabel] = this.value;
                            me.__selectFilterExpressions();
                            // me.__setFilterState();
                        }
                    });
                    options.push(cb);
                }
                // Restore from saved state
                if(this.__meta.state && this.__meta.state.filters){
                    SVMX.doLater(function(){
                        me.__selectFilterExpressions();
                    });
                }
            }

            return options;
        },

        __setFilterState : function(){
            var newState = SVMX.cloneObject(this.__meta.state);
            newState.filters  = newState.filters || {};
            $.extend(newState.filters, this.__filterState);
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.SAVE_STATE", this, {
                request : {context : this, state: newState}
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance()
                .triggerEvent(evt);
        },

        __selectFilterExpressions : function(){
            this.__filterExpressions = [];
            var i, l = this.__optionsPanel.items.getCount();
            for(var i = 0; i < l; i++){
                var item = this.__optionsPanel.items.getAt(i);
                if(item.checked && item.filterExpression){
                    this.__filterExpressions.push(item.filterExpression);
                }
            }
            this.refreshContent({viaFilter : true});
        },

        __refreshFilterOptions : function(){
            var filterOptions = this.__getFilterOptions();
            var i, l = this.__optionsPanel.items.getCount();
            for(var i = 0; i < l; i++){
                var item = this.__optionsPanel.items.getAt(i);
                if(!item.filterExpression){
                    filterOptions.push(item);
                }
            }
            this.__optionsPanel.removeAll(false);
            for(var i = 0; i < filterOptions.length; i++){
                this.__optionsPanel.add(filterOptions[i]);
            }
        },
                
        getFilterExpressions : function(){
            return this.__filterExpressions;
        },

        __appendChildToParent : function(parent, child){
            parent.push({
                id : child.id,
                text : child.text,
                children : child.children,
                icon : child.icon,
                nodeType : child.nodeType,
                recordId : child.recordId
            });
        },

        __setupNodeFilters : function(){
            // setup internal node filters
            this.__allNodeFilters = {
                "loc": {
                    criteriaHandler : function(child){
                        return child.nodeType === "LOCATION"
                            || child.nodeType === "SUBLOCATION";
                    },
                    breakHandler : function(child){
                        return child.nodeType === "IB";
                    }
                },
                "swap": {
                    criteriaHandler : function(child){
                        return child.nodeType === "IB" && child.isSwapped;
                    }
                }
            };
            this.__appliedNodeFilters = {};
        },

        addNodeFilter : function(alias, criteriaHandler, breakHandler){
            this.__allNodeFilters[alias] = {
                criteriaHandler : criteriaHandler,
                breakHandler : breakHandler
            };
        },

        enableNodeFilter : function(alias){
            if(this.__allNodeFilters[alias]){
                this.__appliedNodeFilters[alias] = this.__allNodeFilters[alias];
            }
        },

        disableNodeFilter : function(alias){
            if(this.__appliedNodeFilters[alias]){
                delete this.__appliedNodeFilters[alias];
            }
        },

        hideNodes : function(alias, criteriaHandler, breakHandler){
            // Hide nodes based on criteria function, using alias to reference
            // Break handler is used ot prevent excessive recursion when
            // parent filters do not apply (i.e. locations)
            this.enableNodeFilter(alias);
            this.__applyNodeFilters(true);
        },

        showNodes : function(alias,doRemoveProperty){
            this.disableNodeFilter(alias);
            this.__applyNodeFilters(doRemoveProperty);
        },

        __applyNodeFilters : function(doRemoveProperty){
            var me = this;
            var treeData = this.__getTreeDataCloned();
            var root = treeData.root;

            //Defect fix - 24337 - Records are getting lost when user create location or IB while WO transient filter is "On"
            if(doRemoveProperty !== undefined && doRemoveProperty === true)
                me.__deleteUnWantedTreeDataProperties(root.children);
            var hasFilters = false;
            if(this.__appliedNodeFilters){
                var filterKeys = Object.keys(this.__appliedNodeFilters);
                for(var i = 0; i < filterKeys.length; i++){
                    if(this.__appliedNodeFilters[filterKeys[i]]){
                        hasFilters = true;
                        break;
                    }
                }
            }
            if(hasFilters){
                //disable the accounts menubar, if applied filters are true.
                this.disableAccountsMenuBarButton();
                filterNodes(root.children, root, true);
            } else {
                //enable the accounts menu bar.
                this.enableAccountsMenuBarButton();
            }

            if (this.__isIBorLocationRecordSelected == true) {
                this.__resetTreeStoreData(this.__treeData);
                this.enableAccountsMenuBarButton();
            } else {
                this.__resetTreeStoreData(treeData);
            }

            // this.__resetTreeStoreData(treeData);
            
            function criteriaHandler(node){
                for(var alias in me.__appliedNodeFilters){
                    if(!me.__appliedNodeFilters[alias]){
                        return true;
                    }
                    if(me.__appliedNodeFilters[alias].criteriaHandler(node)){
                        return true;
                    }
                }
            }
            function breakHandler(node){
                for(var alias in me.__appliedNodeFilters){
                    if(!me.__appliedNodeFilters[alias]){
                        continue;
                    }
                    if(me.__appliedNodeFilters[alias].breakHandler
                        && me.__appliedNodeFilters[alias].breakHandler(node)){
                        return true;
                    }
                }
            }
            function filterNodes(children, parentNode){
                if(!children) return;
                for(var i = 0; i < children.length; i++){
                    var child = children[i];
                    if(criteriaHandler(child)){
                        if(!parentNode.reset){
                            parentNode.reset = true;
                            parentNode.children = [];
                            // TODO: fix this hack, should be generic
                            if(!child.isSwapped || child.isSwapped === "false"){ // HACK
                                for(var j = 0; j < i; j++){
                                    parentNode.children.push(children[j]);
                                }
                            }
                        }
                        if(!child.isSwapped || child.isSwapped === "false"){ // HACK
                            filterNodes(child.children, parentNode);
                        }
                    }else{
                        if(child.nodeType !== "LOADING"){
                            if(parentNode.reset){
                                parentNode.children.push(child);
                            }
                            if(breakHandler(child)){
                                continue;
                            }
                            filterNodes(child.children, child);
                        }
                    }
                }
            }
        },

        __deleteUnWantedTreeDataProperties : function(children)
        {
            var me = this;
            for(var i = 0; i < children.length; i++){
                var child = children[i];
                var properties = ["allowDrag", "allowDrop", "checked", "cls", "depth", "expandable","href", "hrefTarget" ,"iconCls", "index", "isFirst" ,"isLast", "leaf" , "loaded" ,"loading", "qshowDelay", "qtip" ,"qtitle", "root" , "transient" ,"visible"];
                for(var j = 0; j < properties.length; j++){
                    delete child[properties[j]];
                }
                if(child.children){
                    me.__deleteUnWantedTreeDataProperties(child.children);
                }
                else{
                    return;
                }
            }
        },

        getTreeData : function(){
            return this.__treeData;
        },

        getTreeDataById : function(){
            return this.__treeDataById;
        },

        getTree : function() {
        	return this.__tree;
        },

        __getTreeDataCloned : function(){
            // Clone to prevent inconsistency after of modifying the tree
            return SVMX.cloneObject(this.__treeData);
        },

        __setTreeData : function(treeData, reloaded){
            if(reloaded){
                this.__setTreeDataReloaded(treeData);
            }
            // Clone to prevent inconsistency after of modifying the tree
            this.__treeData = SVMX.cloneObject(treeData);
            this.__treeDataById = {};
            this.__forEachChild(this.__treeData.root, function(child, parent){
                if(!child.id) return;
                // TODO: this check should not be necessary
                // But there exists a bug where a single parent can be referenced from children
                // in different parts of the tree, so we need to prevent that double reference
                // TODO: fix the tree issue and remove this check later
                if(!this.__treeDataById[child.id]){
                    this.__treeDataById[child.id] = child;
                    child.parentId = parent.id;
                }
                if(this.__expandedById[child.id]){
                    // If data was reloaded, then delay expandion of top level IBs
                    if(reloaded && child.nodeType === "IB"){
                        child.__expanded = true;
                    }else{
                        child.expanded = true;
                    }
                }
            });
            // Reset tree data
            this.__resetTreeStoreData(treeData);
            // Restore internal node filters
            if(!this.__locationsVisible){
                // Note: disabled until further notice
                //this.__appliedNodeFilters.loc = this.__allNodeFilters.loc;
            }
            if(!this.__swappedVisible){
                // Note: disabled until further notice
                //this.__appliedNodeFilters.swap = this.__allNodeFilters.swap;
            }
            if(this.__transientFilters){
                for(var i = 0; i < this.__transientFilters.length; i++){
                    if(this.__transientFilters[i].isChecked()){
                        var transAlias = this.__transientFilters[i].getAlias();
                        this.__appliedNodeFilters[transAlias]
                            = this.__allNodeFilters[transAlias];
                    }
                }
            }

            if (this.__isIBorLocationRecordSelected !== undefined && this.__isIBorLocationRecordSelected === true) {
                    this.__applyNodeFilters();
            }
        },

        __setTreeDataReloaded : function(treeData){
            var priorTreeDataById = this.__treeDataById;
            if(priorTreeDataById){
                var newTreeIBsById = {};
                this.__forEachChild(treeData.root, function(child, parent){
                    if(!child.id) return;
                    if(child.nodeType === "IB"){
                        if(priorTreeDataById[child.id]){
                            // TODO: good idea or bad idea?
                            /*if(this.__expandedById[child.id]){
                                var priorChildren = priorTreeDataById[child.id].children;
                                child.children = priorChildren;
                                child.expanded = true;
                            }*/
                        }else{
                            delete this.__expandedById[child.id];
                        }
                        newTreeIBsById[child.id] = child;
                    }
                });
                // Collapse children which are no longer visible
                this.__forEachChild(this.__treeData.root, function(child, parent){
                    if(child.nodeType === "IB" && child.id && !newTreeIBsById[child.id]){
                        delete this.__expandedById[child.id];
                    }
                });
            }
        },

        __setTreeDataTransients : function(){
            // Restore transient record state indicators
            if(this.__transientRecordIndex){
                for(var i = 0; i < this.__transientRecordIndex.length; i++){
                    var recordId = this.__transientRecordIndex[i];
                    this.setTreeNodeTransient(recordId, true);
                }
            }
        },

        __resetTreeStoreData : function(treeData){
            // this.__tree.getStore().removeAll();
            // this.__tree.getStore().setRootNode(treeData.root);

            var parent = this.__tree.getRootNode();
            if (parent !== null)
            {
                var delNode;
                    while (delNode = parent.childNodes[0])
                        parent.removeChild(delNode);

                this.__tree.saveState();    

            }

            this.__tree.getStore().removeAll();
            this.__tree.getStore().setRootNode(treeData.root);

        },

        __forEachChild : function(node, callback){
            // iterate through node children from top down
            if(!node.children) return;
            for(var i = 0; i < node.children.length; i++){
                callback.call(this, node.children[i], node);
                this.__forEachChild(node.children[i], callback);
            }
        },

        __detachChildFromParent : function(parent, child){
            for(var i = 0; i < parent.children.length; i++){
                if(parent.children[i].id === child.id){
                    parent.children.splice(i, 1);
                    return;
                }
            }
        },
        
        __canDropOn : function(nodes, parent){
            /******************************************
             * Rules: ALL CHANGES WITHIN SAME ACCOUNT
             * IB to different parent IB
             * IB to different location
             * IB to different to sub-location
             * Sublocation to different location
             * Sublocation to different sublocation
             * Child Location to different child location
             ******************************************/

            var dropNode = parent.data;
            var dropId = dropNode.recordId;
            var dropType = dropNode.nodeType;
            var accountId4Parent = this.__getAccountId4ChildNode(parent);

            var i, recs = nodes.records, l = recs.length, r, ret = true;
            for(i = 0; i < l; i++){
                r = recs[i];

                // if different account
                var accountId4Node = this.__getAccountId4ChildNode(r);
                if(accountId4Node != accountId4Parent){
                    return false;
                }

                var dragNode = r.data;
                var dragType = dragNode.nodeType;
                var dragParent = this.__treeDataById[dragNode.parentId];
                var dragParentType = dragParent.nodeType;

                // if it is the same parent
                if(r.parentNode.data.recordId == dropId){
                    return false;
                }

                if(dropType == "IB"){
                    if(dragType != "IB"){
                        ret = false;
                    }
                }else if(dropType == "SUBLOCATION"){
                    if(!(dragType == "IB" || dragType == "SUBLOCATION")){ 
                        ret = false;
                    }
                }else if(dropType == "LOCATION"){
                    if(!(dragType == "IB" || dragType == "SUBLOCATION" || dragType == "LOCATION")){ 
                        ret = false;
                    }
                    if(dragType == "LOCATION" && dragParentType === "ACCOUNT"){ 
                        ret = false;
                    }
                }else if(dropType == "ACCOUNT"){
                    ret = false;
                }else{
                    ret = false;
                }

                if(ret === false){
                    return false;
                }
            }
            return true;
        },

        __handleDropOn : function(nodes, parent, dropHandlers){
            dropHandlers.wait = true;
            var me = this;
            var parentData = parent.data;
            var parentType = parentData.nodeType;
            var parentId = parentData.recordId;
            var i, recs = nodes.records, l = recs.length, r, nodeType;
            var ur = {}; // ur = {Id, Site, SubLocation, Parent, Top_Level}
            var objectName = {};

            // used below to modify internal tree data
            var dropChildren = [];
            var dropParent = this.__treeDataById[parent.id];
            var dropParentNode = this.__tree.getStore().findNode("id", parent.id);

            // TODO: refactor this to work on treeData instead of store nodes
            for(i = 0; i < l; i++){
                r = recs[i]; nodeType = r.data.nodeType;
                ur.Id = r.data.recordId;
                dropChildren.push(this.__treeDataById[r.id]);
                // being dragged
                if(nodeType == "IB"){
                    objectName = SVMX.getCustomObjectName("Installed_Product");
                    // being dropped on
                    if(parentType == "IB"){
                        // get location, sublocation, and toplevel
                        var tmpParent = parent;
                        var topLevelId;
                        var locationId;
                        var sublocationId;
                        while(tmpParent != null){
                            if(tmpParent.data.nodeType == "IB"){
                                topLevelId = tmpParent.data.recordId;
                            }else if(tmpParent.data.nodeType == "SUBLOCATION" && !sublocationId){
                                sublocationId = tmpParent.data.recordId;
                            }else if(tmpParent.data.nodeType == "LOCATION" && !locationId){
                                locationId = tmpParent.data.recordId;
                            }
                            tmpParent = tmpParent.parentNode;
                        }

                        // update the parent
                        ur[SVMX.getCustomFieldName("Site")] = locationId;
                        ur[SVMX.getCustomFieldName("Parent")] = parentId;
                        ur[SVMX.getCustomFieldName("Top_Level")] = topLevelId;
                        ur[SVMX.getCustomFieldName("Sub_Location")] = sublocationId;
                    }else if(parentType == "SUBLOCATION"){
                        // This IB becomes top level 
                        var locationId = parent.parentNode.data.recordId;
                        ur[SVMX.getCustomFieldName("Site")] = locationId;
                        ur[SVMX.getCustomFieldName("Parent")] = "";
                        ur[SVMX.getCustomFieldName("Top_Level")] = "";
                        ur[SVMX.getCustomFieldName("Sub_Location")] = parentId;
                    }else if (parentType == "LOCATION"){
                        // This IB becomes toplevel
                        ur[SVMX.getCustomFieldName("Site")] = parentId;
                        ur[SVMX.getCustomFieldName("Parent")] = "";
                        ur[SVMX.getCustomFieldName("Top_Level")] = "";
                        ur[SVMX.getCustomFieldName("Sub_Location")] = "";
                    }else{
                        // should not happen
                        dropHandlers.wait = false;
                    }

                }else if(nodeType == "LOCATION"){
                    objectName = SVMX.getCustomObjectName("Site");
                    if(parentType == "LOCATION"){
                        parentId = parent.data.id;
                        // update the parent
                        ur[SVMX.getCustomFieldName("Parent")] = parentId;
                    }else{
                        dropHandlers.wait = false;
                    }
                }else if(nodeType == "SUBLOCATION"){
                    objectName = SVMX.getCustomObjectName("Sub_Location");
                    // TODO:
                    dropHandlers.wait = false;
                }else{
                    // should not happen
                    dropHandlers.wait = false;
                }
            }

            if(!dropHandlers.wait) return false;

            // process drop first to avoid double loading data from operation
            dropHandlers.processDrop();
            // update internal tree data
            var dropNodeSelectedId = false
            for(var i = 0; i < dropChildren.length; i++){
                var prevParent = this.__treeDataById[dropChildren[i].parentId];
                this.__detachChildFromParent(prevParent, dropChildren[i]);
                dropParent.children.push(dropChildren[i]);
                dropChildren[i].parentId = dropParent.id;
                dropChildren[i].prevParentId = prevParent.id;
                if(this.__selectedNodeId === dropChildren[i].id){
                    dropNodeSelectedId = dropChildren[i].id;
                }
            }

            // Cause the tree to reload parent

            //Commented below code to fix the issue : 035241 (dropParent is already loaded into tree. Hence reload is not required)
            // dropParent.loaded = false;

            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.UPDATE_IB_HIERARCHY", this, {
                    request : {
                        context : this,
                        params : {},
                        record : ur,
                        objectName : objectName,
                        handler : function(data){
                            // Reset the record view if a dropped node is selected
                            me.__dragEnabled = false; //reset drag flag.
                            if(dropNodeSelectedId){
                                me.fireEvent("node_selected", me.__treeDataById[dropNodeSelectedId]);
                            }
                        }
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __getAccountId4ChildNode : function(node){
            var ret = null;
            while(node != null){
                if(node.data.nodeType == "ACCOUNT"){
                    ret = node.data.recordId;
                    break;
                }
                node = node.parentNode;
            }
            return ret;
        },

        __fireRecordsSelected : function(){
            var selectedRecords = this.__tree.getChecked(), nodes = [];
            for(var i = 0; i < selectedRecords.length; i++){
                nodes.push(selectedRecords[i].data);
            }
            this.fireEvent("records_selected", nodes);
        },
        
        __showMore : function(p){
            var parentNode = this.__treeDataById[p.node.id];

            if(parentNode.allIBsLoaded){
                SVMX.getLoggingService().getLogger("All nodes loaded for " + parentNode.id);
                return;
            }
            
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.GET_MORE_IBS", this, {
                    request : { context : this, params : {
                        parentNode : parentNode,
                        iBReferenceInfo : this.__IBReferenceINFO,
                        thisNode : null // TODO: what was this for? if not needed remove it
                    },
                    lastIBIndex : parentNode.lastIBIndex,
                    parentIBId : parentNode.id
                }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            return this.__showMoreD = SVMX.Deferred();
        },
        
        onGetMoreIBsCompleted : function(data, params){
            var updatedLastIndex = 0, i, l = data.length, d;
            var parentNode = this.__tree.getStore().findNode("id", params.parentNode.id);

            var internalParentNode = this.__treeDataById[parentNode.id];
            
            // remove LOADING Node
            for(var i = 0; i < internalParentNode.children.length; i++){ 
                var child = internalParentNode.children[i];
                if(child.nodeType == "LOADING"){ 
                    internalParentNode.children.splice(i, 1);
                    break;
                }
            }
            
            var items = [];
            for(i = 0; i < l; i++){
                d = data[i];
                updatedLastIndex = d["RecordId"];
                var children = [];
                if (d.hasChild) {
                    children = [this.__getLoadingNodeObject()];
                }
                items.push({
                    id : d["Id"],
                    text : d["Name"],
                    children : children,
                    icon : this.__getIconFor(d, "IB"),
                    //checked : false,
                    nodeType : "IB",
                    recordId : d["Id"]
                });
            }

            if(!internalParentNode.children){
                internalParentNode.children = items;
            }else{
                for(var i = items.length-1; i >= 0; i--){
                    internalParentNode.children.unshift(items[i]);
                }
            }
            internalParentNode.lastIBIndex = updatedLastIndex;
            internalParentNode.expanded = true;
            internalParentNode.allIBsLoaded = true;

            // if node has no children, undo the expand state internally
            if(internalParentNode.children.length === 0){
                internalParentNode.expanded = false;
                this.__expandedById[parentNode.id] = false;
            }

            // Apply changes incrementally to data store
            parentNode.removeChild(parentNode.childNodes[0]);

            parentNode.collapse();
            for(var i = 0; i < items.length; i++){
                parentNode.appendChild(items[i]);
                this.__treeDataById[items[i].id] = items[i];
            }
            parentNode.expand();

            // Note: can't use setTreeData here because
            // it causes a locked focus on the expanded item
            //this.__setTreeData(this.__treeData);
            this.__setTreeDataTransients();
            this.fireEvent('node_loaded', data);

            if(this.__selectedNodeId){
                this.selectTreeNode(this.__selectedNodeId);
            }

            // parentNode.expand();

            this.__showMoreD.resolve();
        },
        
        __getIBChildNodes : function(parentId, childIBs){
            var children = [];
            if(childIBs && childIBs.length){
                var parentField = SVMX.getCustomFieldName("Parent");
                for(var i = 0; i < childIBs.length; i++){
                    var child = childIBs[i];
                    if(child[parentField] === parentId){
                        children.push({
                            id : child.Id,
                            text : child.Name,
                            children : this.__getIBChildNodes(child.Id, childIBs),
                            icon : this.__getIconFor(child, "IB"),
                            //checked : false,
                            nodeType : "IB",
                            recordId : child.Id
                        });
                    }
                }
            }
            if(!children.length){
                children.push(this.__getLoadingNodeObject());
            }
            return children;
        },

        __getLoadingNodeObject : function(){
            var loadingText = "Please wait";
            var ret = {
                text :  loadingText,
                icon : com.servicemax.client.installigence.impl.Module.instance.getResourceUrl("images/paging.gif"),
                nodeType : "LOADING"
            };
            
            return ret;
        },
        
        toggleOptions : function(){
            this.__optionsPanel.toggleCollapse();
            this.doLayout();
        },

        getOptionsPanel : function(){
            return this.__optionsPanel;
        },
        
        addToTree : function(children, parent, type){
            if(type == "IB"){
                this.__addIBsToTree(children, parent, type);
            }else if(type == "LOCATION"){
                this.__addLocationToTree(children, parent, type);
            }else if(type == "SUBLOCATION"){
                this.__addSubLocationToTree(children, parent, type);
            }
        },

        __addLocationToTree : function(children, parent, type){
            var records = [], r = {};

            r["Name"] = "New Location"; // default name
            if(parent.nodeType === "ACCOUNT"){
                r[SVMX.getCustomFieldName("Account")] = parent.id;
            }else if(parent.nodeType === "LOCATION"){
                r[SVMX.getCustomFieldName("Parent")] = parent.id;
                var accParent = parent;

                if (this.__currentAccountId) {
                    r[SVMX.getCustomFieldName("Account")] = this.__currentAccountId;
                } else {
                    while(accParent.nodeType !== "ACCOUNT"){
                        accParent = this.__treeDataById[accParent.parentId];
                    }
                    r[SVMX.getCustomFieldName("Account")] = accParent.id;
                }
            }
            records.push(r);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Site"));
        },

        __addSubLocationToTree : function(children, parent, type){
            var records = [], r = {};

            r["Name"] = "New Sub-Location"; // default name
            if(parent.nodeType === "LOCATION"){
                r[SVMX.getCustomFieldName("Location")] = parent.id;
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Account")] = accParent.id;
            }else if(parent.nodeType === "SUBLOCATION"){
                r[SVMX.getCustomFieldName("Parent")] = parent.id;
                var locParent = parent;
                while(locParent && locParent.nodeType !== "LOCATION"){
                    locParent = this.__treeDataById[locParent.parentId];
                }
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Location")] = locParent && locParent.id;
                if (this.__currentAccountId) {
                    r[SVMX.getCustomFieldName("Account")] = this.__currentAccountId;
                } else {
                    r[SVMX.getCustomFieldName("Account")] = accParent.id;
                }
            }
            records.push(r);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Sub_Location"));
        },

        /*__addIBsToTree_other : function(children, parent, type){
            var records = [], r = {};

            r["Name"] = "New Installed Product"; // default name
            if(parent.nodeType === "LOCATION"){
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Site")] = parent.id;
                r[SVMX.getCustomFieldName("Company")] = accParent.id;
            }else if(parent.nodeType === "SUBLOCATION"){
                r[SVMX.getCustomFieldName("Sub_Location")] = parent.id;
                var locParent = parent;
                while(locParent && locParent.nodeType !== "LOCATION"){
                    locParent = this.__treeDataById[locParent.parentId];
                }
                r[SVMX.getCustomFieldName("Site")] = locParent && locParent.id;
            }else if(parent.nodeType === "IB"){
                r[SVMX.getCustomFieldName("Parent")] = parent.id;
                var ibParent = parent;
                while(this.__treeDataById[ibParent.parentId].nodeType === "IB"){
                    ibParent = this.__treeDataById[ibParent.parentId];
                }
                var locParent = parent;
                while(locParent && locParent.nodeType !== "LOCATION"){
                    locParent = this.__treeDataById[locParent.parentId];
                }
                var sublocParent = parent;
                while(sublocParent && sublocParent.nodeType !== "SUBLOCATION"){
                    sublocParent = this.__treeDataById[sublocParent.parentId];
                }
                var accParent = parent;
                while(accParent.nodeType !== "ACCOUNT"){
                    accParent = this.__treeDataById[accParent.parentId];
                }
                r[SVMX.getCustomFieldName("Top_Level")] = ibParent.id;
                r[SVMX.getCustomFieldName("Site")] = locParent && locParent.id;
                r[SVMX.getCustomFieldName("Sub_Location")] = sublocParent && sublocParent.id;
                r[SVMX.getCustomFieldName("Company")] = accParent.id;
            }
            records.push(r);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Installed_Product"));
        },*/

        __addIBsToTree : function(children, parent, type){
            var pnode = this.__tree.getStore().findNode("id", parent.id);
            var records = this.__createNewIBRecordData(pnode, children);
            this.__addRecords(records, parent, type, SVMX.getCustomObjectName("Installed_Product"));
        },

        __addRecords : function(records, parent, type, objectName){
            SVMX.getCurrentApplication().blockUI();
            var pnode = this.__tree.getStore().findNode("id", parent.id);
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.CREATE_RECORDS", this, {
                    request : {
                        context : this,
                        handler : this.onCreateRecordsComplete,
                        objectName : objectName,
                        params : {
                            parentNode : pnode,
                            type : type
                        },
                        records : records
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        addClonedToTree : function(record, cloned, type, cascade){

            if (cloned.nodeType === "IB" && cloned.parentType === "ACCOUNT") {
                this.addClonedRecordToRootNode([record], {
                        type : type,
                        parentNode : null, //in this case there is no parent node. So we need to add to root node.
                        insertAfter : cloned,
                        hasChildren : cascade
                    });
            } else {
                    var parentNode = this.__tree.getStore().findNode("id", cloned.parentId);
                    this.onCreateRecordsComplete([record], {
                        type : type,
                        parentNode : parentNode,
                        insertAfter : cloned,
                        hasChildren : cascade
                    });
            }
        },

        deleteFromTree : function(node){
            SVMX.getCurrentApplication().blockUI();
            node = this.__tree.getStore().findNode("id", node.id);

            var objectName;
            switch(node.data.nodeType){
                case "ACCOUNT":
                    objectName = SVMX.getCustomObjectName("Account");
                    break;
                case "LOCATION":
                    objectName = SVMX.getCustomObjectName("Site");
                    break;
                case "SUBLOCATION":
                    objectName = SVMX.getCustomObjectName("Sub_Location");
                    break;
                case "IB":
                    objectName = SVMX.getCustomObjectName("Installed_Product");
                    break;
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.DELETE_RECORDS", this, {
                    request : {
                        context : this,
                        handler : this.onDeleteRecordsComplete,
                        objectName : objectName,
                        recordId : node.data.recordId,
                        params : {
                            node : node,
                            type : node.nodeType
                        }
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onDeleteRecordsComplete : function(success, params){
            SVMX.getCurrentApplication().unblockUI();
            if(!success){
                SVMX.getCurrentApplication().showQuickMessage("error", $TR.__getValueFromTag($TR.PRODIQ001_TAG045,'Unable to delete synced records.'));
                return;
            }
            var treeParent;
            if (params.node.data.parentId === "root" && params.node.data.nodeType === "IB") {
                 // update internal tree
                var treeNode = this.__treeDataById[params.node.id];
                treeParent = this.__tree.getRootNode();
                this.__detachChildFromParent(treeParent.data, treeNode);

            } else {
                // update internal tree
                var treeNode = this.__treeDataById[params.node.id];
                treeParent = this.__treeDataById[treeNode.parentId];
                this.__detachChildFromParent(treeParent, treeNode);
            }
            // remove from data store
            params.node.remove();

            //Once deletion complete, select its parent node.
            var parentId = treeParent.id;
            if (parentId) {
                this.__selectedNodeId = parentId;
                this.selectTreeNode(this.__selectedNodeId, params);
            } 
        },

        __createNewIBRecordData : function(pnode, children){
            var accountId = null;
            var locationId = null;
            var sublocationId = null;
            var topLevel = null;
            var records = [], r, i, l = children.length, c, tmpParent = pnode;
            
            var parentRecordId = null;
            if(pnode.data.nodeType === "IB"){
                parentRecordId = pnode.data.recordId;
            }
            while(tmpParent != null){   
                if(tmpParent.data.nodeType == "LOCATION" && !locationId){
                    locationId = tmpParent.data.recordId;
                }else if(tmpParent.data.nodeType == "SUBLOCATION" && !sublocationId){
                    sublocationId = tmpParent.data.recordId;
                }else if(tmpParent.data.nodeType == "ACCOUNT"){
                    accountId = tmpParent.data.recordId;
                }else if(tmpParent.data.nodeType == "IB"){
                    topLevel = tmpParent.data.recordId;
                }
                
                tmpParent = tmpParent.parentNode;
            }

            //set the accountId here.
            if (this.__currentAccountId) {
                accountId = this.__currentAccountId;
            }

            for(i = 0; i < l; i++){
                c = children[i];
                r = {};
                r["Name"] = c.Name;
                r[SVMX.getCustomFieldName("Company")] = accountId;
                r[SVMX.getCustomFieldName("Site")] = locationId;
                r[SVMX.getCustomFieldName("Sub_Location")] = sublocationId;
                r[SVMX.getCustomFieldName("Product")] = c.Id;
                r[SVMX.getCustomFieldName("Product_Name")] = c.Name;
                r[SVMX.getCustomFieldName("Parent")] = parentRecordId;
                r[SVMX.getCustomFieldName("Top_Level")] = topLevel;
                // TEMP: Hard coded mappings from product
                // TODO: Remove these after field mapping is available for add new IB action
                r['Category__c'] = c.CategoryId__c__id;     // Range
                r['DeviceType2__c'] = c.DeviceType2__c__id; // DeviceType
                r['Brand2__c'] = c.Brand2__c__id;           // Brand
				records.push(r);
            }
            
            return records;
        },
        
        onCreateRecordsComplete : function(data, params){

            SVMX.getCurrentApplication().unblockUI();

            var parentNode = this.__tree.getStore().findNode("id", params.parentNode.id);
            parentNode.expand(false);

            // if the parent node is not expanded, just return, the first-time expand code
            // will fetch the newly inserted records along with the other records
            var internalParentNode = this.__treeDataById[parentNode.id];
            if(internalParentNode.nodeType == "IB" && !internalParentNode.allIBsLoaded){
                this.__selectedNodeId = data[0].Id;
                return;
            }
            
            var childNodes = [];
            var i, l = data.length, d;
            for(i = 0; i < l; i++){
                d = data[i];
                var child = {
                    id : d.Id,
                    text : d.Name,
                    children : [],
                    icon : this.__getIconFor(d, params.type),
                    //checked : false,
                    nodeType : params.type,
                    recordId : d.Id
                };
                if(params.type === "IB"){
                    child.isSwapped = d[SVMX.getCustomFieldName("IsSwapped")];
                }
                if(params.hasChildren){
                    child.children = [this.__getLoadingNodeObject()];
                }
                childNodes.push(child);
                this.__treeDataById[child.id] = child;
            }
            if(params.insertAfter){
                var afterNode = this.__tree.getStore().findNode("id", params.insertAfter.id);
                for(var i = 0; i < internalParentNode.children.length; i++){
                    if(internalParentNode.children[i].id === params.insertAfter.id){
                        for(var j = 0; j < childNodes.length; j++){
                            internalParentNode.children.splice(i+j+1, 0, childNodes[j]);
                            parentNode.insertChild(i+1, childNodes[j]);
                            this.__tree.getStore().findNode("id", childNodes[j].id).loaded = false;
                        }
                        break;
                    }
                }
            }else{
                for(var i = 0; i < childNodes.length; i++){
                    internalParentNode.children.unshift(childNodes[i]);
                    parentNode.appendChild(childNodes[i]);
                    // parentNode.insertChild(0, childNodes[i]);
                    this.__tree.getStore().findNode("id", childNodes[i].id).loaded = false;
                }
            }

            // Cause parent to reload
            parentNode.loaded = false;
            
            this.__setTreeDataTransients();

            if(params.insertAfter){
                this.__tree.getStore().findNode("id", params.insertAfter.id).collapse(false);
            }
            this.__tree.getStore().findNode("id", childNodes[0].id).expand(false);
            this.selectTreeNode(childNodes[0].id);
        },

        addClonedRecordToRootNode : function(data, params) {

            SVMX.getCurrentApplication().unblockUI();
            if (!params.parentNode) {
                    var childNodes = [];
                    var i, l = data.length, d;
                    for(i = 0; i < l; i++){
                        d = data[i];
                        var child = {
                            id : d.Id,
                            text : d.Name,
                            children : [],
                            icon : this.__getIconFor(d, params.type),
                            //checked : false,
                            nodeType : params.type,
                            recordId : d.Id
                        };
                        if(params.type === "IB"){
                            child.isSwapped = d[SVMX.getCustomFieldName("IsSwapped")];
                        }
                        if(params.hasChildren){
                            child.children = [this.__getLoadingNodeObject()];
                        }
                        childNodes.push(child);
                        this.__treeDataById[child.id] = child;
                    }

                    if(params.insertAfter){
                        var afterNode = this.__tree.getStore().findNode("id", params.insertAfter.id);
                        var treeNode = this.__tree.getRootNode();
                        for(var i = 0; i < treeNode.data.children.length; i++){
                            if(treeNode.data.children[i].id === params.insertAfter.id){
                                for(var j = 0; j < childNodes.length; j++){
                                    this.__treeData.root.children.splice(i+j+1, 0, childNodes[j]);
                                    treeNode.insertChild(i+1, childNodes[j]);
                                    this.__tree.getStore().findNode("id", childNodes[j].id).loaded = false;
                                }
                                break;
                            }
                        }
                    } 
                    // Cause parent to reload
                    // parentNode.loaded = false;
                    
                    this.__setTreeDataTransients();

                    if(params.insertAfter){
                        this.__tree.getStore().findNode("id", params.insertAfter.id).collapse(false);
                    }
                    this.__tree.getStore().findNode("id", childNodes[0].id).expand(false);
                    this.selectTreeNode(childNodes[0].id);
            }

        },
        
        __getIconFor : function(record, type){
            switch(type){
                case "IB":
                    var ibId = record[SVMX.getCustomFieldName("Top_Level")]
                        || record.Id;
                    var ibIndex = this.__productIconIndex[ibId];
                    var productId = record[SVMX.getCustomFieldName("Product")];
                    if(ibIndex && ibIndex[productId]){
                        // TODO: use native client method to get download path
                        var iconName = ibIndex[productId];
                        var iconPath = "C:/ProgramData/ServiceMax/ProductIQ/Downloads/"+iconName;
                        return iconPath;
                    }
                    return "modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon1.png";
                default:
                    var defaultIcons = {
                        'LOCATION' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png',
                        'SUBLOCATION' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png',
                        'ACCOUNT' : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png'
                    };
                    return defaultIcons[type];
            }
        },

        refreshContent : function(p){

            if (!this.__currentAccountId) { // if there is no accountId, then just return it.
                return;
            }

            var bRefresh = true;
            if(p){
                if(p.type == "initialize"){
                    // nothing yet
                }else if(p.params && p.params.syncType && 
                    (p.params.syncType == "initial" || p.params.syncType == "reset" || p.params.syncType == "ib" || p.params.syncType === "insert_local_records")){
                    
                    // TODO: not sure tree should be refreshed when type is 'ib'
                    
                    // this may not be the right place
                    this.fireEvent("reset");
                }else{
                    bRefresh = false;
                }
                if(p.viaFilter !== undefined && p.viaFilter == true){
                    var me = this;
                    setTimeout(function(){
                        me.__refreshContentInternal(p);
                    }, 50);
                }
            }
            if(bRefresh){
                var me = this;
                setTimeout(function(){
                    me.__refreshContentInternal();
                }, 50);
            }
        },
        
        __refreshContentInternal : function(params){

            SVMX.getCurrentApplication().unblockUI();//first unblock UI, if its already exits.
            SVMX.getCurrentApplication().blockUI();

            if (this.__currentAccountId) {
                    if (params) {
                        params.accountId = this.__currentAccountId;
                    } else {
                        params = {accountId:this.__currentAccountId};
                    }
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_TOP_LEVEL_IBS", this, {request : 
                        { 
                            context : this, 
                            params : params,
                            iBReferenceInfo : this.__IBReferenceINFO
                        }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        /* Requesting for reference field info */
        __getIBReference: function(){
         		var me = this;
         		if(SVMX.getCurrentApplication().isAppEmbedded()) {
               		this.getIbLookupFieldInfoRelation("IB").execute().done(function(lookUpResult){
                		me.__IBReferenceINFO = me.getRelationshipNames(lookUpResult);
            		});
            	}else{
            		this.fetchMFLLabelDetail();
            	}
            	
        },
         /*  This method fetch custom name of the display column of the configuration */
        fetchMFLLabelDetail : function(){
             var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(), 
            me = this;
            syncService.getSObjectInfos([SVMX.getCustomObjectName("Installed_Product")])
            .done(function(info){
            	if(info && info.length>0){
            		for(var f_index = 0; f_index < info.length; f_index++){
						me.__IBReferenceINFO = {};
						var fieldsInfo = info[f_index];
						var i = 0,l = info[f_index].fields.length,fieldInfo = [];
						for(i = 0; i < l; i++){
							var fieldObject = info[f_index].fields[i];
							if(fieldObject.type.toUpperCase() == "REFERENCE")
								me.__IBReferenceINFO[fieldObject.name] = me.getObjectName(fieldObject);
						}
					}
            	}
            });
        },
        
        /* making reference model */
        getObjectName:function(fieldObject){
        	if(fieldObject){
        		var fieldInfo = {};
        		fieldInfo["relationName"] = fieldObject.relationshipName;
         		fieldInfo["referenceTo"] = fieldObject.referenceTo[0];
         		fieldInfo["fieldName"] = fieldObject.name;
        		return fieldInfo;
        	}
        	return fieldObject;
        },
         
        /* making reference info from DB, This is for iPad only */
         getIbLookupFieldInfoRelation : function(relationTable){
            var qo = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            qo.select("reference_To, relationship_name, api_name").from("SFObjectField");
            qo.where("object_api_name='"+SVMX.getCustomObjectName("Installed_Product")+"'");
            qo.where("type = 'reference'");
            return qo;
        },
        
        /* Making reference model */
        getRelationshipNames : function (lookUpResult){
            var relationshipName = {};
            for(var rIndex = 0; rIndex < lookUpResult.length; rIndex++){
                var config = lookUpResult[rIndex];
                relationshipName[config.fieldName] = config;
            }
            return relationshipName;
        },

        __getAllTopLevelAccounts:function(params) {
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.FETCH_TOPLEVEL_ACCOUNTS", this, {request : 
                        { 
                            context : this, params : params
                        }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        updateRecordName : function(id, name){
            var node = this.__treeDataById[id];
            if(node){
                this.__setTreeNodeName(node, name);
            }
        },
        
        updateRecordWithErrorStar : function(id, name){
        	var node = this.__treeDataById[id];
            if(node){
                this.__setTreeNodeError(node, name);
        	   //node.text = name+"*";
            }
        },
        
        __getLocationAndAccountDetails : function(treeData, listOfLocations, listOfSubLocations, listOfAccounts){
            var locIds = [];
            var sublocIds = [];
            var accIds = [];
            var i, l = listOfLocations.length;
            for(i = 0; i < l; i++){
                locIds.push(listOfLocations[i].id);
            }
            l = listOfSubLocations.length;
            for(i = 0; i < l; i++){
                sublocIds.push(listOfSubLocations[i].id);
            }
            l = listOfAccounts.length;
            for(i = 0; i < l; i++){
                accIds.push(listOfAccounts[i].id);
            }
            
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.GET_LOC_ACC_DETAILS", this, {
                    request : { 
                        context : this,
                        locIds : locIds,
                        sublocIds : sublocIds,
                        accIds : accIds,
                        params : {
                            treeData : treeData,
                            listOfLocations : listOfLocations,
                            listOfSubLocations : listOfSubLocations,
                            listOfAccounts : listOfAccounts
                        }
                    }
                }
            );
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },
        
        onGetLocationAndAccountDetailsCompleted : function(data, params){
            var treeData = params.treeData;
            var listOfAccounts = params.listOfAccounts || [];
            var listOfLocations = params.listOfLocations || [];
            var listOfSubLocations = params.listOfSubLocations || [];
            var accounts = data.accounts || [];
            var locations = data.locations || [];
            var sublocations = data.sublocations || [];
            
            // locations
            var id2nameMap = {}, i;
            for(i = 0; i < locations.length; i++){
                id2nameMap[locations[i].Id] = locations[i].Name;
            }
            
            for(i = 0; i < listOfLocations.length; i++){
                var n = listOfLocations[i].text;
                if(id2nameMap[listOfLocations[i].id]){
                    n = id2nameMap[ listOfLocations[i].id ];
                }
                listOfLocations[i].text = n;
            }
            // end locations

            // sublocations
            id2nameMap = {};
            for(i = 0; i < sublocations.length; i++){
                id2nameMap[sublocations[i].Id] = sublocations[i].Name;
            }
            
            for(i = 0; i < listOfSubLocations.length; i++){
                var n = listOfSubLocations[i].text;
                if(id2nameMap[listOfSubLocations[i].id]){
                    n = id2nameMap[ listOfSubLocations[i].id ];
                }
                listOfSubLocations[i].text = n;
            }
            // end sublocations
            
            // accounts
            id2nameMap = {};
            for(i = 0; i < accounts.length; i++){
                id2nameMap[accounts[i].Id] = accounts[i].Name;
            }
            
            for(i = 0; i < listOfAccounts.length; i++){
                var n = listOfAccounts[i].text;
                if(id2nameMap[listOfAccounts[i].id]){
                    n = id2nameMap[ listOfAccounts[i].id ];
                }
                listOfAccounts[i].text = n;
            }
            // end accounts

            this.onDataLoadComplete(treeData);
        },

       onDataLoadComplete : function(treeData, params){

            var me = this;
            // Finally set new tree data
            this.__setTreeData(treeData, true);
            this.__setTreeDataTransients();
            // Reload previously expanded IBs
            //this.__asyncExpandPriorIBs();

            SVMX.getCurrentApplication().unblockUI();

            // setTimeout(function(){
            //         if (me.__menuItemSelected) {
            //             me.enableOrDisableThePanels(false);
            //             me.__menuItemSelected = false;
            //         }
            // }, 800);

            //Case: action type is SYNC
            var pendingMessage = SVMX.getCurrentApplication().getPendingMessage();
            if(pendingMessage !== null){ //sync from MFL
                pendingMessage = SVMX.toObject(pendingMessage);
                if (pendingMessage.action === "SYNC" && (pendingMessage.operation === "INCREMENTAL" || pendingMessage.operation === "PURGE" || pendingMessage.operation === "INSERT_lOCAL_RECORDS")) {
                     // Re-select previous note when filtering
                    if(this.__selectedNodeId){
                        this.selectTreeNode(this.__selectedNodeId, params);
                    }
                    this.__isDataSyncTriggerd = false; //reset the value to false.
                    return;
                }
            } 
            if (this.__isDataSyncTriggerd === true) { // manual data sync check from PIQ.
                this.__isDataSyncTriggerd = false; //reset the value to false.
                if(this.__selectedNodeId){
                    this.selectTreeNode(this.__selectedNodeId, params);
                }
                return;
            }

            //Case: action type is VIEW 
            var flag = false;
            if (this.__isAccountChanged == false) {
                    // Handle pending external messages
                    if(pendingMessage !== null){
                        pendingMessage = SVMX.toObject(pendingMessage);
                        this.__handleExternalMessage(pendingMessage);               
                        if(pendingMessage.action === "VIEW"){
                            SVMX.getCurrentApplication().emptyPendingMessage();
                        } else {
                            flag = true;
                        }
                    } else {
                        flag = true;
                    }
            } else {
                    flag = true;
            }

            //Case : Selecting first node if no external data available.
            if (flag === true && this.__isWorkOrderFilterChecked == false) { // select first record the tree view data.
                this.__selectedNodeId = treeData.root.children[0].id;
            }


            //Case : Work order filter selection from different account.
            if (this.__isWorkOrderFilterChecked === true && this.__selectedWorkOrderFilterData) {
                this.__handleExternalMessage(this.__selectedWorkOrderFilterData);  
            }

            // Re-select previous note when filtering
            if(this.__selectedNodeId){
                this.selectTreeNode(this.__selectedNodeId, params);
            }
        },


        onGetTopLevelAccountsComplete : function(data) {
            var i,l = data.length,menuItem;
            var me = this;
            var menu = this.__accountsMenubarButton.menu;
            for(i = 0; i < l; i++){
                var record = data[i];
                menuItem = Ext.create('Ext.menu.Item', {
                                text : record.Name,
                                Id : record.Id,
                                margin: '6 0 12 10',
                                listeners : {
                                    click : function(item,e,eOpts) {
                                        me.__menuItemSelected = true;
                                        me.enableOrDisableThePanels(true);
                                        me.__loadSelectedAccountRecords(item);
                                    }
                                }
                                
                });
                menu.add(menuItem);
                if (this.__currentAccountId == record.Id) {
                        this.__accountsMenubarButton.setText(record.Name);
                        this.__selectedAccountName = record.Name;
                }
             }

             //check accountId and recordId here. If not exits then set first account treedata and
             //refresh the content.
             if (!this.__selectedAccountId && menu) {
                    var menuItem = menu.items.items[0];
                    this.__accountsMenubarButton.setText(menuItem.text);
                    this.__selectedAccountName = menuItem.Name;
                    this.__selectedAccountId = menuItem.Id;
                    this.__currentAccountId = menuItem.Id;
                    this.__setSelectedAccountIdForIBSearch();
                    this.refreshContent();//Now we have accountId. So refreshContent.
             }
        },

        __loadSelectedAccountRecords : function(menuItem) {

            var me = this;
            this.__selectFromRegisterExternal = false;
            this.__isWorkOrderFilterChecked = false;
            if (this.__currentAccountId !== menuItem.Id) {
                this.__currentAccountId = menuItem.Id;
                this.__accountsMenubarButton.setText(menuItem.text);
                if (this.__currentAccountId == this.__selectedAccountId) {
                    this.__isAccountChanged = false;
                } else {
                    this.__isAccountChanged = true;
                }
                this.__setSelectedAccountIdForIBSearch();
                this.refreshContent();
            } 

            setTimeout(function(){
                    me.enableOrDisableThePanels(false);
                    me.__menuItemSelected = false;

            }, 1500);
        },

        __asyncExpandPriorIBs : function(){
            var me = this;
            for(var id in this.__treeDataById){
                if(this.__treeDataById[id].__expanded){
                    this.__showMore({node : this.__tree.getStore().findNode("id", id)})
                    .done(function(){
                        // Continue recursively expanding top level nodes
                        //me.__asyncExpandPriorIBs();
                    });
                    this.__treeDataById[id].expanded = true;
                    delete this.__treeDataById[id].__expanded;
                    //break;
                }
            }
        },
        
        onGetTopLevelIBsComplete : function(data){

            this.__loadTreeData(data);
        },

        __loadTreeData : function(data){
            var me = this, params = data.params;
            var treeData = {
                root : {
                    expanded : true,
                    children : []
                }
            };
            data = data || [];

            if(data.templates){
                this.__indexProductIconsFromTemplates(data);
            }
            if(data.transients){
                this.__transientRecordIndex = data.transients;
            }

            // 1) Create all the nodes
            var accountsById = {};
            if(data.accounts){
                for(var i = 0; i < data.accounts.length; i++){
                    var record = data.accounts[i];
                    var accountNode = {
                        id : record.Id,
                        text : record.Name || ("(Acc) "+record.Id),
                        icon : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon5.png',
                        children : [],
                        nodeType : "ACCOUNT",
                        recordId : record.Id
                    };
                    accountsById[record.Id] = accountNode;
                }
            }
            var locationsById = {};
            if(data.locations){
                for(var i = 0; i < data.locations.length; i++){
                    var record = data.locations[i];
                    var parentId, parentType;
                    if(record[SVMX.getCustomFieldName("Parent")]){
                        parentId = record[SVMX.getCustomFieldName("Parent")];
                        parentType = "LOCATION";
                    }
                    else if(record[SVMX.getCustomFieldName("Account")]){
                        parentId = record[SVMX.getCustomFieldName("Account")];
                        parentType = "ACCOUNT";
                    }
                    var locationNode = {
                        id : record.Id,
                        text : record.Name || ("(Loc) "+record.Id),
                        icon : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon2.png',
                        children : [],
                        nodeType : "LOCATION",
                        recordId : record.Id,
                        parentId : parentId,
                        parentType : parentType
                    };
                    locationsById[record.Id] = locationNode;
                }
            }
            var sublocationsById = {};
            if(data.sublocations){
                for(var i = 0; i < data.sublocations.length; i++){
                    var record = data.sublocations[i];
                    var parentId, parentType;
                    if(record[SVMX.getCustomFieldName("Parent")]){
                        parentId = record[SVMX.getCustomFieldName("Parent")];
                        parentType = "SUBLOCATION";
                    }else if(record[SVMX.getCustomFieldName("Location")]){
                        parentId = record[SVMX.getCustomFieldName("Location")];
                        parentType = "LOCATION";
                    }
                    var sublocationNode = {
                        id : record.Id,
                        text : record.Name || ("(Sub) "+record.Id),
                        icon : 'modules/com.servicemax.client.installigence.ui.components/resources/extjsthemes/installigence/images/custom/dummy-icon4.png',
                        children : [],
                        nodeType : "SUBLOCATION",
                        recordId : record.Id,
                        parentId : parentId,
                        parentType : parentType
                    };
                    sublocationsById[record.Id] = sublocationNode;
                }
            }
            var ibsById = {};
            if(data.ibs){
                for(var i = 0; i < data.ibs.length; i++){
                    var record = data.ibs[i];
                    var parentId, parentType;
                    if(record[SVMX.getCustomFieldName("Parent")]){
                        parentId = record[SVMX.getCustomFieldName("Parent")];
                        parentType = "IB";
                    }else if(record[SVMX.getCustomFieldName("Sub_Location")]){
                        parentId = record[SVMX.getCustomFieldName("Sub_Location")];
                        parentType = "SUBLOCATION";
                    }else if(record[SVMX.getCustomFieldName("Site")]){
                        parentId = record[SVMX.getCustomFieldName("Site")];
                        parentType = "LOCATION";
                    }else if(record[SVMX.getCustomFieldName("Company")]){
                        parentId = record[SVMX.getCustomFieldName("Company")];
                        parentType = "ACCOUNT";
                    }else {
                        continue;
                    }
                    var children = [];

                    if (record.hasChild) {
                        children = [this.__getLoadingNodeObject()]
                    }
                    var ibNode = {
                        id : record.Id,
                        text : record.Name || ("(IB) "+record.Id),
                        icon : me.__getIconFor(record, "IB"),
                        children : children,
                        nodeType : "IB",
                        recordId : record.Id,
                        serialNo : record[SVMX.getCustomFieldName("Serial_Lot_Number")],
                        isSwapped : record[SVMX.getCustomFieldName("IsSwapped")],
                        parentId : parentId,
                        parentType : parentType
                    };
                    ibsById[record.Id] = ibNode;
                }
            }

            // 2) Assemble the hierarchy
            for(var key in locationsById){
                var node = locationsById[key];
                if(node.parentType === "LOCATION" && locationsById[node.parentId]){
                    locationsById[node.parentId].children.push(node);
                }else if(node.parentType === "ACCOUNT" && accountsById[node.parentId]){
                    if(accountsById[node.parentId]){
                        accountsById[node.parentId].children.push(node);
                    }
                }else{
                    warnParentInvalid(node);
                }
            }
            for(var key in sublocationsById){
                var node = sublocationsById[key];
                if(node.parentType === "LOCATION" && locationsById[node.parentId]){
                    locationsById[node.parentId].children.push(node);
                }else if(node.parentType === "SUBLOCATION" && sublocationsById[node.parentId]){
                    sublocationsById[node.parentId].children.push(node);
                }else{
                    warnParentInvalid(node);
                }
            }
            for(var key in ibsById){
                var node = ibsById[key];
                if(node.parentType === "ACCOUNT" && accountsById[node.parentId]){
                    accountsById[node.parentId].children.push(node);
                }else if(node.parentType === "LOCATION" && locationsById[node.parentId]){
                    locationsById[node.parentId].children.push(node);
                }else if(node.parentType === "SUBLOCATION" && sublocationsById[node.parentId]){
                    sublocationsById[node.parentId].children.push(node);
                }else if(node.parentType === "IB" && ibsById[node.parentId]){
                    ibsById[node.parentId].children.push(node);
                }else{
                    warnParentInvalid(node);
                }
            }

            if (this.__currentAccountId) { // filter tree data using selected accountId.
                    for(var key in accountsById){
                        var node = accountsById[key];
                        var childLocations = node.children;
                        if (childLocations) {
                            for (var i = 0; i < childLocations.length; i++) {
                                var childNode = childLocations[i];
                                treeData.root.children.push(childNode);
                            }
                        }
                    }
            } else {
                    for(var key in accountsById){
                        var node = accountsById[key];
                        treeData.root.children.push(node);
                }
            }




            this.onDataLoadComplete(treeData, params);

            function warnParentInvalid(node){
                console.warn('Tree structure invalid: Location '+node.id+' parent '+node.parentType+' '+node.parentId+' not found');
            }
        },

        __indexProductIconsFromTemplates : function(data){
            var index = this.__productIconIndex = {};
            for(var i = 0; i < data.ibs.length; i++){
                var ib = data.ibs[i];
                var tplId = ib[SVMX.getCustomFieldName("ProductIQTemplate")];
                if(tplId && data.templates[tplId]) {
                    indexIBProductIconsRecursive(
                        ib.Id, data.templates[tplId].template
                    );
                }
            }

            function indexIBProductIconsRecursive(ibId, template) {
                if(template.children){
                    var i, l = template.children.length;
                    for(i = 0; i < l; i++){
                        indexIBProductIconsRecursive(ibId, template.children[i]);
                    }
                }
                var product = template.product;
                if(product && product.productIcon){
                    index[ibId] = index[ibId] || {};
                    index[ibId][product.productId] = product.productIcon;
                }
            }
        },

        setTreeNodeTransient : function(id, isTransient){
            var me = this;
            var node = this.__treeDataById[id];
            if(!node) return;
            // Unref previous parent (set from handleDropOn...)
            if(node.transient && node.prevParentId){
                var prevParent = this.__treeDataById[node.prevParentId];
                if(prevParent){
                    unrefNode(prevParent);
                }
            }
            isTransient = (isTransient === undefined) ? true : isTransient;
            if(isTransient) {
                refNode(node);
            }else{
                unrefNode(node);
            }
            node.transient = isTransient;
            delete node.prevParentId;
            function refNode(node){
                node.transientRefs = node.transientRefs || [];
                if(node.transientRefs.indexOf(id) === -1){
                    node.transientRefs.push(id);
                }
                if(!node.origText){
                    node.origText = node.text;
                    node.text = node.text+"*";
                    me.__tree.getStore().findNode("id", node.id)
                        .updateInfo(true, {text: node.text});
                }
                var parent = me.__treeDataById[node.parentId];
                if(parent){
                    refNode(parent);
                }
            }
            function unrefNode(node){
                if(node.transientRefs){
                    var idx = node.transientRefs.indexOf(id);
                    if(idx !== -1){
                        node.transientRefs.splice(idx, 1);
                    }
                    if(!node.transientRefs.length && node.origText){
                        node.text = node.origText;
                        me.__tree.getStore().findNode("id", node.id)
                            .updateInfo(true, {text: node.text});
                        delete node.origText;
                    }
                }
                var parent = me.__treeDataById[node.parentId];
                if(parent){
                    unrefNode(parent);
                }
            }
            return;
            this.__setTreeData(this.__treeData);
        },

        __setTreeNodeName : function(node, name){
            if(!node.transientRefs || !node.transientRefs.length){
                node.text = name;
                delete node.origText;
            }else{
                node.origText = name;
                node.text = name+"*";
            }
            this.__tree.getStore().findNode("id", node.id)
                .updateInfo(true, {text: node.text});
        },

        __setTreeNodeError : function(node, name){
            node.origText = name;
            node.text = name+"*";
            this.__tree.getStore().findNode("id", node.id)
                .updateInfo(true, {text: node.text});
        }
    });

    /**
     * Transient filter functionality for IBtree
     * Used to manage and apply transient filters upon IBtree
     * Example: Filter IBs for WO-000000X, from external request
     */
    ibtreeImpl.Class("TransientFilter", com.servicemax.client.lib.api.Object, {
        __ibtree : null,
        __data : null,
        __alias : null,
        __checked : null,
        __checkbox : null,
        __meta : null,

        __constructor : function(params){
            this.__ibtree = params.parent;
            this.__data = params.data;
            this.__meta = params.meta;
            this.__alias = this.__data.sourceRecordName;
            this.__checked = true;
        },

         initialize : function(){
            var me = this;
            this.__checkbox = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", { 
                boxLabel : me.__alias,
                checked : true,
                margin: '0 0 0 5',
                isTransientFilter : true,
                handler : function(){
                    me.__checked = this.value;
                    var accountId = me.__data.accountId;
                    var ibId = me.__data.recordIds[0];
                    /* This is about open standalone */
                    me.__data.focused = true;

                 me.__ibtree.__isIBorLocationRecordSelected = false; //reset the flag.

                 if (me.__ibtree.__currentAccountId === accountId) {
                            if(this.value){
                                me.__ibtree.__selectedNodeId = ibId;
                                me.__ibtree.__isWorkOrderFilterChecked = true;
                                me.__uncheckOtherTransientFilters();
                                me.__ibtree.hideNodes(me.__alias);
                                me.__ibtree.__handleExternalMessage(me.__data);
                            }else{
                                if(!me.__ibtree.isUncheckingTransientFilters){
                                    me.__ibtree.__isWorkOrderFilterChecked = false;
                                    me.__ibtree.showNodes(me.__alias,true);
                                    me.__addTransientNodeFilter(true);
                                }
                            }
                            if(me.__ibtree.__selectedNodeId){
                                me.__ibtree.selectTreeNode(me.__ibtree.__selectedNodeId);
                            }
                    } else {

                            if (me.__ibtree.__selectFromRegisterExternal === false || me.__ibtree.__selectFromRegisterExternal === undefined) {
                                    me.__ibtree.__selectedNodeId = ibId;
                                    me.__ibtree.__isWorkOrderFilterChecked = true;
                                    me.__ibtree.__currentAccountId = accountId;
                                    var menu = me.__ibtree.__accountsMenubarButton.menu;
                                    var l = menu.items.items.length;

                                    for (var i = 0; i < l; i++) {
                                        var menuItem = menu.items.items[i];
                                        if (menuItem.Id === accountId) {
                                            me.__ibtree.__accountsMenubarButton.setText(menuItem.text);
                                            me.__ibtree.__selectedAccountName = menuItem.text;
                                            break;
                                        }
                                    }
                                    //updating accountID on filter selection
                                    me.__meta.accountId = accountId;
                                    me.__ibtree.__selectedWorkOrderFilterData = me.__data;
                                    me.__ibtree.refreshContent();
                         }
                    }
                }
               
            });
            this.__ibtree.getOptionsPanel().add(this.__checkbox);
            this.__ibtree.getOptionsPanel().expand();
            this.setup();
        },

        setup : function(){
            var me = this;
            this.__ibtree.__selectedNodeId = this.__data.recordIds[0];
            this.__addTransientNodeFilter();
            this.__uncheckOtherTransientFilters();
            this.__ibtree.hideNodes(this.__alias);
            this.__ibtree.selectTreeNode(this.__data.recordIds[0]);
            this.__selectFromRegisterExternal = false;
        },

        setChecked : function(){
            this.__checkbox.setValue(true);
        },

        isChecked : function(){
            return this.__checked; 
        },

        getAlias : function(){
            return this.__alias; 
        },

        hide : function(){
            this.__checkbox.setValue(false);
            this.__checkbox.hide();
        },

        __addTransientNodeFilter : function(reset){
            if (!this.__transientNodeFilter || reset) {
                this.__transientNodeFilter = this.__createTransientNodeFilter()
            }
            this.__ibtree.addNodeFilter(this.__alias,
                this.__transientNodeFilter
            );
        },

        __createTransientNodeFilter : function(){
            var me = this;
            // Find applicable parent locations, sublocations and account
            this.__parentAccounts = [];
            this.__parentIBs = [];
            this.__parentLocations = [];
            this.__parentSublocations = [];
            var treeDataById = this.__ibtree.getTreeDataById();
            for(var i = 0; i < this.__data.recordIds.length; i++){
                var recordId = this.__data.recordIds[i];
                var node = treeDataById[recordId];
                findNodeParents(node);
            }
            function findNodeParents(node){
                if(!node) return;
                var parent = treeDataById[node.parentId];
                if(!parent) return;
                if(parent.nodeType === "ACCOUNT"
                    && me.__parentAccounts.indexOf(parent.id) === -1){
                    me.__parentAccounts.push(parent.id);
                    parent.expanded = true;
                }
                if(parent.nodeType === "LOCATION"
                    && me.__parentLocations.indexOf(parent.id) === -1){
                    me.__parentLocations.push(parent.id);
                    parent.expanded = true;
                }
                if(parent.nodeType === "SUBLOCATION"
                    && me.__parentSublocations.indexOf(parent.id) === -1){
                    me.__parentSublocations.push(parent.id);
                    parent.expanded = true;
                }
                if(parent.nodeType === "IB"
                    && me.__parentIBs.indexOf(parent.id) === -1){
                    me.__parentIBs.push(parent.id);
                    parent.expanded = true;
                }
                findNodeParents(parent);
            }
            return function(child){
                // Filter out all records that do not match transient tree
                if(child.nodeType === "ACCOUNT"){
                    if(me.__parentAccounts.indexOf(child.id) === -1){
                        return true;
                    }
                }
                if(child.nodeType === "LOCATION"){
                    if(me.__parentLocations.indexOf(child.id) === -1){
                        return true;
                    }
                }
                if(child.nodeType === "SUBLOCATION"){
                    if(me.__parentSublocations.indexOf(child.id) === -1){
                        return true;
                    }
                }
                if(child.nodeType === "IB"){
                    if(me.__parentIBs.indexOf(child.id) === -1 && me.__data.recordIds.indexOf(child.id) === -1){
                        return true;
                    }
                }
                return false;
            };
        },

        __uncheckOtherTransientFilters : function(){
            var transFilters = this.__ibtree.getTransientFilters();
            for(var i = 0; i < transFilters.length; i++){
                this.__ibtree.disableNodeFilter(transFilters[i].getAlias());
            }
            var optionItems = this.__ibtree.getOptionsPanel().items.items;
            this.__ibtree.isUncheckingTransientFilters = true;
            for(var i = 0; i < optionItems.length; i++){
                var checkbox = optionItems[i];
                if(!checkbox.isTransientFilter) continue;
                if(checkbox.boxLabel === this.__alias) continue;
                checkbox.setValue(false);
            }
            delete this.__ibtree.isUncheckingTransientFilters;
        }

    }, {
        // Only for testing
        testTrigger : function(){
            var data = {
                action : 'VIEW',
                // Test serials under MAccount
                recordIds : [
                    'a0HF000000Nwd7XMAR', // INROW...
                    'a0HF000000Nv0qSMAR', // MInstalled 3
                    'a0HF000000NwcSfMAJ', // Coffee machine...
                    'a0HF000000NwkmQMAR', // ArchProd11
                    'a0HF000000NwkmZMAR'  // ArchProd10
                ],
                object : SVMX.getCustomObjectName("Installed_Product"), // ???
                sourceRecordName : "WO-100000TEST1"
            };
            if(window.previouslySet){
                data.sourceRecordName = "WO-100000TEST2";
            }
            window.previouslySet = true;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "EXTERNAL_MESSAGE", this, data);
            SVMX.getClient().triggerEvent(evt); 
        }
    });
    
};

})();

//end of file