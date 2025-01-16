/**
 * @class com.servicemax.client.installigence
 * @author Amar Joshi
 * @since       : 1.0
 * @copyright 2015 ServiceMax, Inc.
 */

(function(){
    
    var ibSwapImpl = SVMX.Package("com.servicemax.client.installigence.ibswap");

    ibSwapImpl.init = function(){

        Ext.define("com.servicemax.client.installigence.ibswap.IBSwap", {
            extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
            alias: 'widget.installigence.ibswap',
            __sourceComponent : null,
            __parentComponent : null,
            __meta : null,
            __ibtree : null,
            __record : null,
            __ibSwapIBTree : null,
            __ibSwapTreeData : null,
            __treeDataById : null,
            __expandedById : null,
           __productIconIndex : {},
           __selectedNode : null,
           __treeStore : {},
           __newSerialNoById : {},
           __ibRecord : null,
           __requiredFields : null,
           __fields : null,
           __recordName : null,
           __dataValidationRules : null,
           __ibRecordById : null,
           __win : null,

            constructor: function(config) { 
                var me = this;
                this.__sourceComponent = config.source;
                this.__parentComponent = config.parent;
                this.__meta = this.__parentComponent.__meta
                this.__ibtree = this.__parentComponent.__contentarea.__ibtree;
                this.__record = this.__parentComponent.__contentarea.__record;
                this.__treeDataById = SVMX.cloneObject(this.__ibtree.__treeDataById);
                this.__treeStore = {};
                this.__ibRecord = this.__record.__views[0];
                this.__requiredFields = this.__ibRecord.__pl.__requiredFields;
                this.__fields = this.__ibRecord.__pl.fields;
                this.__recordName = this.__ibRecord.__pl.__recordName;
                this.__dataValidationRules = this.__ibRecord.__pl.__dataValidationRules;
                this.__ibRecordById = {};
                
            },

            __openProductLookup : function(){
                var parentNode;// = this._context[0];
                var displayFields = this.__meta.productDisplayFields || [];
                var searchFields = this.__meta.productSearchFields || [];
                var productSearch = SVMX.create("com.servicemax.client.installigence.objectsearch.ObjectSearch", {
                    objectName : "Product2",
                    columns : displayFields.length ? displayFields : [{name: 'Name'}],
                    searchColumns : searchFields.length ? searchFields : [{name: 'Name'}],
                    multiSelect : false,
                    sourceComponent : this.__sourceComponent,
                    mvcEvent : "FIND_PRODUCTS",
                    fromIBSwap : true
                });
                var me = this;
                productSearch.find().done(function(results){
                    //To do :
                    // Update the Product Id in treeData Store.
                });
            },

            getFilterExpressions : function(){
                return this.__ibtree.getFilterExpressions();
            },

            getChildIBs : function(parentIB){
                this.__selectedNode = this.__treeDataById[parentIB];
                SVMX.getCurrentApplication().blockUI();
                var objectName = SVMX.getCustomObjectName("Installed_Product");
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_ALL_CHILD_IBS", this, {request : { context : this, targetId : parentIB, objectName : objectName, handler : this.__onChildIBCompleate}});
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            },


            __onChildIBCompleate : function(data){
               var me = this;
               // 1) Create all the nodes
               var ibsById = {};
               this.__ibRecordById = {};
                if(data){
                    for(var i = 0; i < data.length; i++){
                        var record = data[i];
                        this.__ibRecordById[record.Id] = record;
                        var parentId, parentType;
                        if(record[SVMX.getCustomFieldName("Parent")]){
                            parentId = record[SVMX.getCustomFieldName("Parent")];
                            parentType = "IB";
                        }else {
                            continue;
                        }
                        var ibNode = {
                            id : record.Id,
                            text : record.Name || ("(IB) "+record.Id),
                            icon : me.__getIconFor(record, "IB"),
                            children : [],
                            nodeType : "IB",
                            recordId : record.Id,
                            serialNo : record[SVMX.getCustomFieldName("Serial_Lot_Number")],
                            isSwapped : record[SVMX.getCustomFieldName("IsSwapped")],
                            parentId : parentId,
                            parentType : parentType,
                            expanded : true,
                            collapsible : true
                        };
                        ibsById[record.Id] = ibNode;
                    }
                }

               // 2) Assemble the hierarchy
                var ibsByIdToBeRemoved = {};
                for(var key in ibsById){
                    var node = ibsById[key];
                    if(node.parentType === "IB" && ibsById[node.parentId]){
                        ibsById[node.parentId].children.push(node);
                        ibsByIdToBeRemoved[node.id] = node;
                    }else{
                        warnParentInvalid(node);
                    }
                }
                for(var key in ibsByIdToBeRemoved){
                    delete ibsById[key];
                }
                var topNode = this.__selectedNode;
                topNode.collapsible = true;
                topNode.expanded = true;
                topNode.children = [];
                for(var key in ibsById){
                    var node = ibsById[key];
                    topNode.children.push(node);
                }
                var root = {}; 
                root.children = [], root.expanded = true, root.collapsible = true;
                root.children.push(topNode);
                var treeDate = {root : root};
                
                me.__getUI(treeDate);
                
                function warnParentInvalid(node){
                    console.warn('Tree structure invalid: Location '+node.id+' parent '+node.parentType+' '+node.parentId+' not found');
                }
            },

            __getUI : function(treeData){
                SVMX.getCurrentApplication().unblockUI();
                this.__ibSwapTreeData = treeData;
                var me = this;
                var treeStore = Ext.create('Ext.data.TreeStore', { root : treeData.root });
                this.__treeStore = treeStore;
                this.__expandedById = {};
                var cellEditing = Ext.create('Ext.grid.plugin.CellEditing', { clicksToEdit: 1 });

                this.__ibSwapIBTree =  SVMX.create("com.servicemax.client.installigence.ui.components.Tree", {
                    
                    cls: 'grid-panel-borderless svmx-tree-panel', margin: '5 0 0 0', width: '100%', store: this.__treeStore, flex : 1,
                    useArrows: true, rootVisible: false, multiSelect: false, collapsed: false,
                    plugins:[cellEditing], 
                    selModel: {
                        selType: 'checkboxmodel',
                        mode: 'SIMPLE'
                    },   
                    columns: [
                        {
                            xtype: 'treecolumn',
                            text: $TR.__getValueFromTag($TR.PRODIQ001_TAG066,'Product'),
                            dataIndex: 'text',
                            width : '25%'
                        },
                        {
                            text: $TR.__getValueFromTag($TR.PRODIQ001_TAG105,'Serial/Lot Number'),
                            dataIndex: 'serialNo',
                            width : '25%',
                            editor: {
                                xtype : "textfield"
                            }    
                        },
                        {
                            renderer: function(value, md, record, row, col, store) {
                                return '<a class="change-link" href="#">Change</a>';
                            }
                        },
                        
                    ],
                    listeners : {
                        select : function(that, record, index, eOpts){
                             Ext.defer(function() {
                                    cellEditing.startEdit(index, 2);
                                }, 100, this);
                        },
                        checkchange : function(node, checked, eOpts){
                            
                        },
                        afteritemexpand : function(node, index, item, eOpts) {
                        },
                        afteritemcollapse : function(node, index, item, eOpts) {
                                           
                        },
                        cellclick: function(grid, row, col, e) {
                            if (col === 3) {
                                me.__openProductLookup();
                            }
                        }
                    }
                });
                
                this.__win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                    layout : {type : "vbox"}, height : "100%", width : "100%",
                    title : $TR.__getValueFromTag($TR.PRODIQ001_TAG102,'Component Replacement'),
                    maximizable : true,
                    items : [this.__ibSwapIBTree],
                    modal : true,
                    buttons : [
                        {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel'), handler : function(){
                                this.__win.close();
                        }},
                        {text : $TR.__getValueFromTag($TR.PRODIQ001_TAG104,'Update'), handler : function(){
                            SVMX.getCurrentApplication().blockUI();
                           me.__performIBSwap();
                        }},
                    ]
                });
                this.__win.show();
            },

            __performIBSwap : function(){
                var d = SVMX.Deferred(), me =  this;
                this.__newSerialNoById = {};
                var seletedIBsForSwap = [];
                var IBs = [];
                var selectedRows = this.__ibSwapIBTree.getSelectionModel().getSelection();
                if(selectedRows !== undefined || selectedRows.length > 0){
                    for(var i = 0; i < selectedRows.length; i++){
                        var node = selectedRows[i].data;
                        if(node.serialNo === undefined || node.serialNo === null || node.serialNo === ""){
                            IBs.push(node.text);
                        }
                        else{
                            this.__newSerialNoById[node.recordId] = node.serialNo;
                            seletedIBsForSwap.push(node.recordId)
                        }
                    }
                    if(IBs.length > 0){
                        SVMX.getCurrentApplication().showQuickMessage("error", "Please enter serial no for: "+IBs.toString());
                    }
                    else{
                        // First Swap(clone) selected records 
                         var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                        "INSTALLIGENCE.CLONE_MULTIPLE_RECORDS", this, {
                            request : {
                                context : this,
                                recordIds : seletedIBsForSwap,
                                objectName : SVMX.getCustomObjectName("Installed_Product")
                                
                            }
                        });
                        com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
                    }    
                }
                
            },

            onCloneComplete : function(){
                var records = [];
                for(var key in this.__newSerialNoById){
                    var record = this.__ibRecordById[key];
                    var serialNo = SVMX.getCustomFieldName("Serial_Lot_Number");
                    for(var field in record){
                        if(field === serialNo){
                            record[field] = this.__newSerialNoById[key];
                        }
                    }
                    records.push(record);
                }
                //Update Exsisting Records
                var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.SAVE_MULTIPLE_RECORDS", this, {
                        request : { context : this, requiredFields : this.__requiredFields, objectName: SVMX.getCustomObjectName("Installed_Product"), meta : this.__fields, records : records, recordName : this.__recordName, root : this.__record, handler : this.onSaveComplete, dataValidationRules : this.__dataValidationRules}
                });
                com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
            },

            onSaveComplete : function(){
                SVMX.getCurrentApplication().unblockUI();
                this.__win.close();
                this.__ibtree.refreshContent();
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

        });    
    }
})();

// end of file