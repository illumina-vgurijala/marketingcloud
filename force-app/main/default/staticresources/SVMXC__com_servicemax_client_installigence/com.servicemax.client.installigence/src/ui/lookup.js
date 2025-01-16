(function(){
    var lookupImpl = SVMX.Package("com.servicemax.client.installigence.lookup");

lookupImpl.init = function(){

    Ext.define("com.servicemax.client.installigence.lookup.TextField", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXTextField",
        alias: 'widget.inst.referencefield',

        constructor: function(config) {
            this.callParent([config]);
        }
    });

    Ext.define("com.servicemax.client.installigence.lookup.Container", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXFieldContainer", // temporary
        alias: 'widget.inst.fieldcontainer',
        __text : null, __btn : null, __lookup : null,

        constructor: function(config) {
            var me = this;
            config = Ext.apply({
                layout : { type : "hbox"},
                items : [],
                defaults: {
                    hideLabel: true
                }
             }, config || {});

            this.__lookup = SVMX.create("com.servicemax.client.installigence.lookup.Lookup", config);
            this.__text = this.__lookup.getLookupText();
            this.__btn = this.__lookup.getLookupBtn();

            this.callParent([config]);


        },

        setValue : function(value){
           this.__lookup.setValue(value);
        },

        getValue : function(){
            return this.__lookup.getValue();
        },

        makeReadOnly : function(){
            this.__lookup.readOnly();
        },

        getLookupText : function(){
            return this.__lookup.getLookupText();
        },

        getLookupBtn : function(){
            return this.__lookup.getLookupBtn();
        },

        onAdded : function( container, pos, instanced ){
            this.callParent([ container, pos, instanced ]);

            var me = this;
            container.on("resize", function(){
                me.readjustItemsWidth(container.getWidth() - 40);
            }, this);

            container.on("all_fields_added", function(){
                me.readjustItemsWidth(container.getWidth() - 40);
            }, this);
        },

        readjustItemsWidth : function(width){

            var scrollbarWidth = 38;
                if(!SVMX.getCurrentApplication().isAppEmbedded()) {
                    var scrollbarWidth = 73;
                }

            //var labelWidth = this.labelEl.getWidth();
            var availableWidth = width - scrollbarWidth - this.__btn.getWidth(); // 25 scrollbar
            this.__text.setWidth(availableWidth);

        }
    });

    lookupImpl.Class("Lookup", com.servicemax.client.lib.api.Object, {
        __config : null, __lookupBtn : null, __lookupText : null, __inited : false, __objectInfo : null,
        __store : null, __grid : null, __win : null, __value : null, __displayValue : null, __objectName : null,
        __displayFields : null, __searchFields : null, __fields : null, __searchFields : null,__fieldsMap : null,
        __isConnected : true, __selectedRecord : null, __fieldLabel: null,
        __constructor : function(config){
            this.__config = config || [];
            this.__config.items = [];
            this.__config.layout = 'hbox';
            this.__config.cls = 'svmx-lookup-field';
            this.__config.margin = '05, 30';
            this.__config.labelAlign ='top';
            this.__fieldLabel = config.fieldLabel;
            this.__parent = config.parent;
            this.__inited = false;
            this.__objectName = this.__config.objectName;
            this.__value = "";
            this.__displayValue = "";
            this.__lookupField();
            this.__fields = this.__getFields(this.__config.columns);
            this.__searchFields = this.__getSearchFields(this.__config.searchColumns);
            this.__parentNodeId = this.__parent.__node.id;
            this.__selectedRecord = {};
        },

        __getFields : function(fields){
            var colFields = ["Id", "Name"];
            for(var key in fields){
                if(fields[key].name && fields[key].name.toLowerCase() == "id") continue;
                if(fields[key].name && fields[key].name.toLowerCase() == "name") continue;
                colFields.push(fields[key].name);
            }

            return colFields;
        },

        __getSearchFields : function(fields){
            var colFields = [];
            for(var key in fields){
                colFields.push(fields[key].name);
            }

            return colFields;
        },

        __showWindow : function(){
            if(this.__inited == false){ this.__init();}
            else{ this.__showUI(); }
        },

        __find1 : function(params){
            SVMX.getCurrentApplication().blockUI();
            this.__parentNodeId = this.__parent.__node.id;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_LOOKUPCONFIG", this,
                    {request : {
                        context: this,
                        keyword : params.text,
                        handler : params.handler,
                        doQueryMFL : params.doQueryMFL,
                        doQueryOnline :params.onlineChecked,
                        callType : "BOTH",
                        objectName : this.__objectName,
                        lookupContext : "",
                        lookupQueryField : "",
                        searchOperator : "contains",
                        parentNodeId : this.__config.parent.__node.id
                    }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __find : function(params){
            SVMX.getCurrentApplication().blockUI();
            this.__parentNodeId = this.__parent.__node.id;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE." + this.__config.mvcEvent, this,
                    {request : {
                        context : this,
                        handler : params.handler,
                        doQueryMFL : params.doQueryMFL,
                        doQueryOnline :params.doQueryOnline,
                        fields : params.fields || this.__fields,
                        searchFields : this.__searchFields,
                        objectName: params.objectName || this.__objectName,
                        text : params.text,
                        id : params.value,
                        fieldsDescribe: this.__fieldsMap,
                        parentNodeId : this.__config.parent.__node.id
                    }});
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        __findComplete : function(data, isValid, parentNodeId, gridColomns){
            SVMX.getCurrentApplication().unblockUI();
            if(parentNodeId !== this.__parentNodeId){
                return;
            }
            if(data.length || isValid){
                data = this.__checkForEmptyLocalRecNameValue(data);
                this.__store.loadData(data);
                // This is implemented for LookupConfig. Do not call __getUI() insted call __ShowUI() and it will call __getUI()
                //this.__win.show();
                //this.__win = this.__getUI(gridColomns);
            }else{
                this.__initDisable();
            }
        },

        __checkForEmptyLocalRecNameValue : function(data){
             var i = 0, j = data.length;
             for(i = 0; i < j; i++){
                 if(data[i] && data[i].Name !== undefined && data[i].Name.length === 0 && (data[i].Id.indexOf("-") >= 0 || data[i].Id.indexOf("_") >= 0)){
                    data[i].Name = data[i].Id;
                 }
             }
             return data;
        },

        __initialLoad : function(data){
            SVMX.getCurrentApplication().unblockUI();
            if(data && data[0]){
                this.setDisplayValue(data[0].Name, data[0].Id);

            }else{
                //search actual records, which may search remote (thereby slower)
                this.__find({value: this.__value, handler : this.__getNameFieldComplete});
            }
        },

        __getNameFieldComplete: function(data, isValid, parentNodeId){
            SVMX.getCurrentApplication().unblockUI();
            if(parentNodeId !== this.__parentNodeId){
                return;
            }
            if(data && data[0]){
                this.setDisplayValue(data[0].Name, data[0].Id);
            }else{
                this.setDisplayValue('');
            }
        },

        __searchComplete : function(data, isValid, parentNodeId){
            SVMX.getCurrentApplication().unblockUI();
            this.__store.loadData(data);
        },
        
        launchScanner : function(textView) {
			var  me = this;
			var d = SVMX.Deferred();
			var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
			var browserRequest = nativeservice.createScanRequest();
			browserRequest.bind("REQUEST_COMPLETED", function(evt){
			debugger;
			if (evt.data.data && !evt.data.data.cancelled) {
				var text = evt.data.data.text;
				textView.setValue(text);
			} else if (evt.data.data && evt.data.data.cancelled) {
				//SVMX.getCurrentApplication().getRoot().setEnableHardwareBack(false);
			}
				d.resolve(evt);
			}, this);
			browserRequest.bind("REQUEST_ERROR", function(evt){
				d.reject({
				  //text: TS.T("TODO", "The application does not exist. Please contact your system administrator to update the application path or install the necessary software."),
				  //type: "INFO"
				});
			}, this);

			browserRequest.execute({
				link: ""
			},function(a,b){
				
			});

			return d.promise();
		},
        
       getItem : function(searchText,barCode,goButton){
            	var items = [];
            	if(window.parent.SVMX.getClient().isBarCodeEnabled())
            		return [searchText,barCode,goButton];
            	else
            		return [searchText,goButton];
        },

        __init : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance(), me = this;
            syncService.getSObjectInfo(this.__config.objectName)
            .done(function(info){
                me.__objectInfo = info;
                me.__fieldsMap = {};
                if(info){
                    var i = 0,l = info.fields.length;
                    for(i = 0; i < l; i++){
                        me.__fieldsMap[info.fields[i].name] = info.fields[i]
                    }
                }else{
                    me.__fieldsMap = {
                        Id : {type : "text"},
                        Name : {type : "text"}
                    };
                    me.__objectInfo = {
                        fields : [
                            {name : "Name", label : "Name"}
                        ]
                    }
                }
                me.__initComplete();
            });
        },

        __initComplete : function(){
            this.__inited = true;
            this.__showUI();
        },

        __initDisable : function(){
            // Amar Joshi : Don't know the reason why below two line was implemented. To Fix defect 021250 - Lookup gets disabled if searched with a value that has no match,
            // commented bolow two lines

            /*this.__lookupText.disable();
            this.__lookupBtn.disable();*/
            //SVMX.getCurrentApplication().showQuickMessage("info", "No records found");
            var evt = SVMX.create("com.servicemax.client.installigence.svmxPopup.popupMessage", {
				height: 150,
				width: 390,
				layout: 'fit',
				buttonAlign: 'center',
				closable: false,
				text : $TR.__getValueFromTag($TR.PRODIQ001_TAG123,'No records found'),
				title : $TR.__getValueFromTag($TR.PRODIQ001_TAG056,'info'),
                textAlign : "display:inline-block;text-align:center"
			});
			evt.filterButtonAction(evt);
			evt.show();

            if(this.__win){
                this.__win.close();
            }
        },

        __showUI : function(){
            var me = this;
          /*  me.__checkConnectivity().done(function(result){
                me.__isConnected = true;
                if(result == 'False'){
                    me.__isConnected = false;
                }
                me.__find({handler : me.__findComplete, text : me.__lookupText.getValue(), fields: me.__fields, doQueryMFL : true});
                me.__win = me.__getUI();
                me.__win.show();
            });*/
            me.__find({handler : me.__findComplete, text : me.__lookupText.getValue(), fields: me.__fields, doQueryMFL : true, doQueryOnline : true});
            //this.__find1({handler : this.__findComplete, keyWord : this.__lookupText.getValue(), objectName : this.__objectName});
            this.__win = this.__getUI();
        me.__win.show();

        },

        getValue : function(){
            return this.__value;
        },

        getDisplayValue : function(){
            return this.__displayValue;
        },

        readOnly : function(){
            this.__lookupText.readOnly = true;
            this.__lookupBtn.disabled = true;
        },

        //LUMA : renaming RecordName with SFRecordName
        setValue: function(value){
            this.__value= value;
            if(!value || value == ""){
                this.setDisplayValue(""); return;
            }
            if(this.__store == null || this.__store.find("Id", value) == -1){
                this.setDisplayValue('');
                this.__find({value: value, handler : this.__initialLoad, objectName : "SFRecordName"});
            }else{
                this.setDisplayValue(this.__store.findRecord("Id", value).get("Name"), value);
            }
        },

        setDisplayValue: function(value, id){
            this.__displayValue = value;
            this.__lookupText.setValue(value);
            if(id && (id.indexOf("_") >= 0 || id.indexOf("-") >= 0) && (!value && value == "")){
                this.__displayValue = id;
                this.__lookupText.setValue(id);
            }

        },

        getLookupText: function(){
            return this.__lookupText;
        },

        getLookupBtn: function(){
            return this.__lookupBtn;
        },

        __lookupField : function(){

            // show the field
            var me = this;
            var items = [];
            this.__lookupBtn = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                iconCls: 'svmx-lookup-icon',
                margin: '0, 5',
                disabled: this.__config.fld.readOnly,
                handler: function(){
                    me.__showWindow();
                }
            });

            this.__lookupText = SVMX.create('com.servicemax.client.installigence.lookup.TextField', {
                value: this.getValue(),
                readOnly: this.__config.fld.readOnly,
                allowBlank: this.__config.fld.required,

                listeners: {
                    specialkey: function(f,e){
                        if(e.getKey() == e.ENTER){
                            me.__showWindow();
                        }
                    },
                    //Rahman: To fix 028142 added below code
                    // afterrender: function(c) {
                    //     c.inputEl.on('click', function() {
                    //         me.__showWindow();
                    //     });
                    // },
                    blur: function(){
                        if(this.getValue().trim() === ''){
                            // Clear lookup value
                            me.setValue('');
                        }
                    }
                }
            });

            /* wrapper for lookup label and button */
            this.__lookupWrapper = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXContainer',{
                    cls: 'svmx-priq-lookup-field',
                    layout: { type : 'hbox'},
                    items: [this.__lookupText,this.__lookupBtn]
                });
            this.__config.items.push(this.__lookupWrapper);
        },

        __checkConnectivity : function(){
            var d = SVMX.Deferred();
            var me = this;
            var params = {
                type : "CONNECTIVITY",
                method : "CHECKCONNECTIVITY"
            };

            // var req = com.servicemax.client.installigence.offline.sal.model.nativeservice.Facade.createConnectivityRequest();
            var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
            var req = nativeservice.createConnectivityRequest();
            req.bind("REQUEST_COMPLETED", function(evt){
                d.resolve(evt.data.data);
            }, me);
            req.bind("REQUEST_ERROR", function(evt){
                d.resolve("False");
            }, me);
            req.execute(params);
            return d;
        },

        __getUI : function(){//displayCols
            var cols = this.__fields, i, l = cols.length, me = this;
            /*if(displayCols && displayCols !== undefined && displayCols.length > 0){
                cols = displayCols;
                l = cols.length;
            }*/
            // store
            var fields = [];
            for(i = 0; i < l; i++){ fields.push(cols[i]); }
            var store = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {fields:fields, data:[]});

            //grid
            var gridColumns = [], objectInfo = this.__objectInfo, j, oFields = objectInfo.fields, t = oFields.length, c;
            for(i = 0; i < l; i++){
                c = cols[i];
                for(j = 0; j < t; j++){
                    if(c == oFields[j].name && c != "Id"){
                        gridColumns.push({ text : oFields[j].label, minWidth: 175, dataIndex : c, flex : 1, cls:'installigence-lookup-grid-header' });
                    }
                }
            }

            //LUMA : Renaming RecordName with SFRecordName.
            var grid = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXGrid', {
                store: store,
                cls : 'installigence-lookup-grid',
                forceFit : true, columns: gridColumns, flex : 1, width: "100%", autoScroll: true,
                viewConfig: {
                    listeners: {
                        itemdblclick: function(dataview, record, item, index, e) {
                            // TODO: remove this mapping eventually
                            if(me.__objectName === "Product2"){
                                for(var i = 0; i < me.__parent.items.items.length; i++){
                                    var item = me.__parent.items.items[i];
                                    if(item.fld.name === "Category__c"){
                                        item.setValue(record.data.CategoryId__c);
                                    }else if(item.fld.name === "DeviceType2__c"){
                                        item.setValue(record.data.DeviceType2__c);
                                    }else if(item.fld.name === "Brand2__c"){
                                        item.setValue(record.data.Brand2__c);
                                    }
                                }
                            }
                            me.__selectedRecord = {};
                            me.__selectedRecord = record.data;
                            me.setValue(record.data.Id);
                            me.setDisplayValue(record.data.Name);
                            me.__lookupText.focus();
                            me.__win.close();
                            if(record.data.SVMXIsFromServer){
                                me.__find({value: record.data.Id, handler : me.__LocalCheckComplete, objectName : "SFRecordName"});
                            }
                        }
                    }
                }
            });

                        // searchText
            var searchText = SVMX.create("com.servicemax.client.installigence.ui.components.SVMXTextField", {
                width: '40%', emptyText : 'Search', enableKeyEvents : true,
                value: me.getDisplayValue(),
                listeners : {
                    keyup : function(that, e, opts) {
                        if(e.getKey() == e.ENTER){
                            me.__find({
                                text : searchText.getValue(),
                                handler : me.__searchComplete,
                                fields: me.__fields,
                                doQueryMFL : true,
                                doQueryOnline : true
                            });
                        }
                    }
                }
            });  
            
            var barCode = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXButton', {
                	 iconCls: 'svmx_BarIcon_button',
                	 text : ' ',
 					 margin: '0, 5', 
 					 width: '15%',
                     flex: 1,
                     handler : function(){
					     me.launchScanner(searchText);
					}
            });
            
            var goButton =  {
                                xtype: 'button', 
                                text: $TR.__getValueFromTag($TR.PRODIQ001_TAG139,'Go'), 
                                handler : function(){
                                    me.__find({
                                        text : searchText.getValue(),
                                        handler : me.__searchComplete,
                                        fields: me.__fields,
                                        doQueryMFL : true,
                                        doQueryOnline : true
                                        
                                    });
                                }
                            };
            var toolBarItems = me.getItem(searchText,barCode,goButton);
                 
            // window
            var win = SVMX.create("com.servicemax.client.ui.components.controls.impl.SVMXWindow", {
                layout : {type : "vbox"}, height : 400, width : 820,
                cls: 'LookUP-Poup-Centered',
                closable: false, maximizable: false, animateTarget: me.__lookupBtn,
                titleAlign:'center',
                title: this.__fieldLabel +$TR.__getValueFromTag($TR.IPAD014_TAG136,'Lookup'),
                dockedItems : [
                    {
                        dock: 'top', xtype: 'toolbar', margin: '0',
                        items : toolBarItems
                    }
                ],
                tools:[
                    {
                        xtype: 'button', 
                        text: $TR.__getValueFromTag($TR.PRODIQ001_TAG098,'Cancel'),
                        handler : function(){
                        me.__win.close();
                    }
                }],
                listeners: {
                    show: function(win) {
                        if (this.modal) {
                            var dom = Ext.dom.Query.select('.x-mask');
                            for(var i=0; i<dom.length;i++){
                                     Ext.get(dom[i]).setStyle('opacity',1);
                                     var el = Ext.get(dom[i]);
                                     el.addCls('customWinMask');

                            }
                        }
                    },
                    close:  function(win) {
                        if (this.modal) {
                            var dom = Ext.dom.Query.select('.x-mask');
                            for(var i=0; i<dom.length;i++){
                                     Ext.get(dom[i]).setStyle('opacity',1);
                                     var el = Ext.get(dom[i]);
                                     el.removeCls('customWinMask');

                            }
                        }
                    }
                },
                minWidth: this.__lookupText.width , layout: {
                    padding: 5
                }, layout : 'fit', items : [grid], modal : true
            });
            // var toXY = this.__lookupText.getXY();
            win.setPosition(window.screen.width/4, window.screen.height/6);
            this.__store = store;
            this.__grid = grid;
            return win;
        },

        //LUMA : Renaming RecordName with SFRecordName.

        __LocalCheckComplete : function(data){
            SVMX.getCurrentApplication().unblockUI();
            if(data.length == 0){
                SVMX.getCurrentApplication().blockUI();
                var recordNames = [];
                recordNames.push({
                    Id : this.__selectedRecord.Id,
                    Name : this.__selectedRecord.Name
                });
                var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
                queryObj.replaceInto("SFRecordName")
                .columns([{name : "Id"}, {name : "Name"}])
                .values(recordNames)
                .execute().done(function(){
                    SVMX.getCurrentApplication().unblockUI();
                });
            }
        }

    });
}
})();
