/**
 * 
 */

(function(){
    
    var actionsImpl = SVMX.Package("com.servicemax.client.installigence.actions");

    actionsImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.actions.Actions", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.actions',

            __allActions : null,
            __allActionProviders : null,
            __showingDisabledActions : true,
            __contentarea : null,
            __nodesSelected : null, 
            __meta : null,
            __menu:null,
            __Apikey:null,
            __objectInfo:null,
            __SelectedNode:null,


            constructor:function(config) {
                var me = this;
                this.__allActions = [];
                this.__allActionProviders = [];
                this.__showingDisabledActions = true;
                this.__meta = config.meta;
				this.__Apikey = this.__getApiKey();
				this.__objectInfo = SVMX.getCurrentApplication().getObjectInfo();

                this.__menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    showSeparator : false,
                    plain:true,
                    width: 310,
                    scrollable: true,
                    maxHeight: 500,
                    layout: 'vbox'

                });

                config = Ext.apply({
                    items : [ 
                        { 
                            xtype: 'button', 
                            text: $TR.__getValueFromTag($TR.PRODIQ001_TAG047,'Actions'), 
                            cls: 'ibtoolbar-actions-btn',
                            textAlign: 'right',
                            menuAlign: 'tr-br',
                            margin : '10 ',
                            width : '100px',
                            menu:this.__menu,
                            handler: function(){
                            	//me.checkingForOnline();
                            }

                        }
                    ]


                }, config || {});
                
                config.contentarea.on("node_selected", function(nodes){
                    // actions should work with more that one node.
                    // for now, we will mimic it
                    this.__SelectedNode = nodes;
                    if(!(nodes instanceof Array)) nodes = [nodes];
                        this.handleNodeSelect(nodes);
                        
                    //With ib node, we have to disable customAction 
                    this.disableCustomActionForLocation(nodes, me);
                    
                }, this);
                
                this.__contentarea = config.contentarea;
                this.callParent([config]);


                this.setup();


            }, // end of the constructor.
            
            checkingForOnline : function (){
            	var nodes = this.__SelectedNode;
            	if(nodes){
					if(nodes.nodeType == "LOCATION" || nodes.nodeType == "SUBLOCATION"){
						this.__isCustomActionUrlButtonEnabled(true, this);
					}else{
						this.disableURLIfOffline();
					}
				}else{
					this.disableURLIfOffline();
				}
            },
            
            disableURLIfOffline : function(){
            	var isEnabled = window.navigator.onLine;
				if(isEnabled)
					this.__isCustomActionUrlButtonEnabled( !isEnabled, this);
				else
					this.__isCustomActionUrlButtonEnabled( !isEnabled, this);
            },
            
        	disableCustomActionForLocation : function(nodes, me){
        		if(nodes){
					for(var i = 0; i < nodes.length; i++){
						if(nodes[i].nodeType == "LOCATION" || nodes[i].nodeType == "SUBLOCATION")
							me.__isCustomActionUrlButtonEnabled(true, me);
						else
							me.__isCustomActionUrlButtonEnabled(false, me);
					}
				}
        	},

           
            handleNodeSelect : function(nodes){
                    this.__nodesSelected = nodes;

                    var i, actions = this.__allActions, l = actions.length, ac, ap,menu=this.__menu;
                    for(i = 0; i < l; i++){
                        ac = actions[i]; ap = ac.provider;
                        ap.setContext(nodes);
                        if(ap.isValid()){
                            if (menu.items.items[i]) {
                                    menu.items.items[i].setDisabled(false);
                                    menu.items.items[i].setVisible(true);
                            }
                        }else{
                            if (menu.items.items[i]) {
                                menu.items.items[i].setDisabled(true);
                            }
                            if(!this.__showingDisabledActions){
                                menu.items.items[i].setVisible(false);
                            }
                        }
                    }
            }, //end of handleNodeSelect method.

            getNodesSelected : function(){
                return this.__nodesSelected;
            }, // end of the getNodesSelected method.
        
            setup : function() {
                this.__setupDefaults();
                this.meta.bind("MODEL.UPDATE", function(evt){
                    this.refresh();
                }, this);
            }, // end of setup method.

            __setupDefaults : function(){
                    var me = this;

                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.AddNew"});
                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.CloneInstalledProduct"});
                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.AddNewLocation"});
                    this.addActionProvider({className : "com.servicemax.client.installigence.actions.DeleteNew"});
                    // this.addActionProvider({className : "com.servicemax.client.installigence.actions.ComponentReplacement"});
                    //TODO: need to implement below methods.

                    // default actions
                    var i,l = this.__allActionProviders.length, b, ap,menuItem;
                    for(i = 0; i < l; i++){
                        ap = SVMX.create(this.__allActionProviders[i].className, {});

                        menuItem = {
                                    text: ap.getName(),
                                    provider : ap, 
                                    disabled : true,
                                    margin: '6 0 12 10',
                                //     draggable: {

                                //     //overriding the draggable delegates to stop eventPropogations
                                //             onDrag: function(e) {
                                            
                                //             },
                                //             onEnd: function(e) {
                                            
                                //             }
                                            
                                // },
                                    handler : function(){
                                                this.provider.act(this, me);
                                    }
                        };
                         

                        this.__menu.add(menuItem);
                        this.__allActions.push(menuItem);
                    }
                    
                    // add separator
                    var separator = SVMX.create("com.servicemax.client.installigence.ui.components.Label", {
                        html : "<div></div>", width: '100%', padding : 0, height : 25, style : {"background-color" : "#D0CDCD"}
                    });
                    // this.__menu.add(separator);
            }, //end of setupDefaults method.

            refresh : function(){
                var me = this;

                this.removeCustomActions();

                if(!this.meta.actions || !this.meta.actions.length){
                    return;
                }
                var m = this.meta.actions, l = m.length, i, b, ap;
                for(i = 0; i < l; i++){
                    if(m[i].isHidden){
                        if(m[i].isHidden === true)
                            continue;
                    }
                    m[i].mapping = this.__getMappingByName(m[i].action);
                    m[i].customUrls = this.__getCustomURLs(m[i].action);

                    ap = SVMX.create("com.servicemax.client.installigence.actions.CustomActionProvider", m[i]);

                    menuItem = {
                                    text: ap.getName(),
                                    provider : ap, 
                                    disabled : true,
                                    margin: '6 0 12 10',
                                    actionType: m[i].actionType,
                                    custom:true,
                                    ApiKey : this.__Apikey,
                                    // draggable: {

                                    // //overriding the draggable delegates to stop eventPropogations
                                    //         onDrag: function(e) {
                                            
                                    //         },
                                    //         onEnd: function(e) {
                                            
                                    //         }
                                            
                                    // },
                                    handler : function(){
                                                this.provider.act(this, me);
                                    }
                        };
                         

                    this.__menu.add(menuItem);
                    this.__allActions.push(menuItem);
                }
                this.__registorForNetworkStatusNotification();
            },// end of refresh method.

            __registorForNetworkStatusNotification : function(){
                
               
                 /* adding events online and offline to detecting the network changes*/
                var me = this,
                isOnline = function(){
               		//me.__isCustomActionUrlButtonEnabled(false, me);
            
                },isOffline = function(){
                	//me.__isCustomActionUrlButtonEnabled(true, me);
                }

                 if (window.addEventListener) {
                        /*
                            Works well in Firefox and Opera and Google Chrome.
                        */
                        window.addEventListener("online", isOnline, false);
                        window.addEventListener("offline", isOffline, false);
                    }
                    else {
                        /*
                            Works in IE.
                        */
                        document.body.ononline = isOnline;
                        document.body.onoffline = isOffline;
                    }
                /* End- online and offiline events*/

            },
             __isCustomActionUrlButtonEnabled: function(isEnabled, me){

                var i = me.__allActions.length,menu=me.__menu,menuItem;

                while(i > 0){
                    i--;
                    menuItem = menu.items.items[i];
                    if(menuItem){
                        if (menuItem.custom && menuItem.actionType === "customurl") {
                            menu.items.items[i].setDisabled(isEnabled);
                        }
                    }
                }
            },
            removeCustomActions : function(){
                var i = this.__menu.items.items.length,menu=this.__menu,menuItem;
                while(i > 0){
                    i--;
                    menuItem = menu.items.items[i];
                    if(menuItem.custom){
                        // var b = this.__allActions.splice(i, 1)[0];
                        this.__menu.remove(menuItem);
                    }
                }
            },

            __getMappingByName : function(mapName){
                if(!this.meta.mappings) return null;
                var i, l = this.meta.mappings.length;
                for(i = 0; i < l; i++){
                    if(this.meta.mappings[i].name === mapName){
                        return this.meta.mappings[i];
                    }
                }
            },

            __getCustomURLs : function(customURLName){
                if(!this.meta.customUrls) return null;
                var i, l = this.meta.customUrls.length;
                for(i = 0; i < l; i++){
                    if(this.meta.customUrls[i].name === customURLName){
                        return this.meta.customUrls[i];
                    }
                }
            },
        
            showDisabledActions : function(){
                var i, l = this.__allActions.length;
                for(i = 0; i < l; i++){
                    this.__allActions[i].setVisible(true);
                }
                this.__showingDisabledActions = true;
            },
        
            hideDisabledActions : function(){
                var i, l = this.__allActions.length;
                for(i = 0; i < l; i++){
                    if(this.__allActions[i].isDisabled()) this.__allActions[i].setVisible(false);
                }
                this.__showingDisabledActions = false;
            },
            
            toggleOptions : function(){
                this.__optionsPanel.toggleCollapse();
                this.doLayout();
            },
            
            addActionProvider : function(info){
                this.__allActionProviders.push(info);
            },
        
            getContentArea : function(){
                return this.__contentarea;
            },
            
            /* making request for API key for Literals */
            __getApiKey : function() {
				var me = this;
				// var nativeService = window.parent.com.servicemax.client.offline.sal.model.nativeservice.Facade;
                // var request = nativeService.createGenerateApiKeyRequest();

                var nativeService = SVMX.getCurrentApplication().getNativeServiceRequest();
                var request = nativeService.createGenerateApiKeyRequest();
                
 				request.bind("REQUEST_COMPLETED", function(evt){
				   me.__Apikey = evt.data.data;
				}, this);

				request.bind("REQUEST_ERROR", function(evt){
					me.__ApiKey = "";
				}, this);
				request.execute();
        }

        
    }); // ********* end of the define.

    actionsImpl.Class("ActionProvider", com.servicemax.client.lib.api.Object, {
            _meta : null, _context : null,
            __constructor : function(meta){ 
                this.__base(); 
                this._meta = meta;
            },
            getName: function(){
                return this._meta.name;
            },
            
            setContext : function(context){
                this._context = context;
            },
            
            isValid : function(){
                throw new Error("Please override this method <ActionProvider.isValid()>");
            },
            
            act : function(source, parent){
                throw new Error("Please override this method <ActionProvider.act()>");
            },

            _getTargetRecordIds : function(parent){
                var targetIds = [];
                var nodes = parent.getNodesSelected();
                var i, l = nodes.length;
                for(i = 0; i < l; i++){
                    targetIds.push(nodes[i].id);
                }
                return targetIds;
            }
    }, {}); // end of ActionProvider class.

    actionsImpl.Class("AddNew", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG032,'Add New Installed Product')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && (this._context[0].nodeType == "IB" || this._context[0].nodeType == "LOCATION" || this._context[0].nodeType == "SUBLOCATION")){ 
                return true;
            }else{ 
                return false;
            }
        },

        /*act : function(source, parent){
            var parentNode = this._context[0];
            var addType = "IB";
            parent.getContentArea().addToTree({}, parentNode, addType);
        }*/
        
        act : function(source, parent){

            //Hide the popover.
            var me = this;
            var parentNode = this._context[0];
            var displayFields = parent.__meta.productDisplayFields || [];
            var searchFields = parent.__meta.productSearchFields || [];
            var productSearch = SVMX.create("com.servicemax.client.installigence.objectsearch.ObjectSearch", {
                objectName : "Product2",
                columns : displayFields.length ? displayFields : [{name: 'Name'}],
                searchColumns : searchFields.length ? searchFields : [{name: 'Name'}],
                multiSelect : true,
                sourceComponent : source,
                mvcEvent : "FIND_PRODUCTS",
                createHandler : function(){
                    var records = [{Name: "New Installed Product"}];
                    parent.getContentArea().addToTree(records, parentNode, "IB");
                }
            });
            productSearch.find().done(function(results){
                parent.getContentArea().addToTree(results, me._context[0], "IB");
            });
        }
    }, {}); // end of the addNew class.

    actionsImpl.Class("CloneInstalledProduct", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG100,'Clone Install Product')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && this._context[0].nodeType == "IB"){ 
                return true;
            }else{ 
                return false;
            }
        },
        
        act : function(source, parent){
            var me = this;
            window.action_cascade = false;
            SVMX.getCurrentApplication().showQuickMessage('confirm', $TR.__getValueFromTag($TR.PRODIQ001_TAG125,'Are you sure?') + '<br/><br/><label><input type="checkbox" onclick="window.action_cascade=this.checked" />' + $TR.__getValueFromTag($TR.PRODIQ001_TAG138,'Clone all child records') +'</label>', function(resp){
                if(resp === "yes"){
                    me.__cascade = window.action_cascade;
                    me.__doCloneRecord(source, parent);
                }
            });
        },

        __doCloneRecord : function(source, parent){
            SVMX.getCurrentApplication().blockUI();
            this.__parent = parent;
            var targetId = this._getTargetRecordIds(parent)[0];
            var targetObject = SVMX.getCustomObjectName("Installed_Product");
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.CLONE_RECORD", this, {
                    request : {
                        context : this,
                        targetId : targetId,
                        objectName : targetObject,
                        cascade : this.__cascade
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onCloneComplete : function(record){
            SVMX.getCurrentApplication().unblockUI();
            this.__parent.getContentArea().addClonedToTree(record, this._context[0], "IB", this.__cascade);
        }

    }, {}); //end of cloneIB.


    actionsImpl.Class("AddNewLocation", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG033,'Add New Location')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && (this._context[0].nodeType == "ACCOUNT" || this._context[0].nodeType == "LOCATION")){ 
                return true;
            }else{ 
                return false;
            }
        },
        
        act : function(source, parent){
            var parentNode = this._context[0];
            var addType = "LOCATION";
            parent.getContentArea().addToTree({}, parentNode, addType);
        }
    }, {}); // end of new location class.

    actionsImpl.Class("DeleteNew", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG101,'Delete')}); 
        },
        
        isValid : function(){
            var node = this._context.length === 1 && this._context[0];
            if(node){
                if(!this.__areAllNodesTransient(node)){
                    return false;
                }
                var nodeType = node.nodeType;
                if(nodeType == "IB" || nodeType == "LOCATION" || nodeType == "SUBLOCATION"){ 
                    return true;
                }
            }
            return false;
        },
        
        act : function(source, parent){
            var targetNode = this._context[0];
            SVMX.getCurrentApplication().showQuickMessage("confirm", $TR.__getValueFromTag($TR.DELETE_CONFIRM_MESSAGE,'Are you sure?'), function(resp){
                if(resp === "yes"){
                    parent.getContentArea().deleteFromTree(targetNode); 
                    source.setDisabled(true);
                }
            });
        },

        __areAllNodesTransient : function(node){
            if(node.recordId.indexOf('local') !== 4){
                return false;
            }else{
                return checkChildren(node.children);
            }
            function checkChildren(children){
                if(!children){
                    return true;
                }
                var areTransient = true;
                for(var i = 0; i < children.length; i++){
                    var childId = children[i].recordId;
                    if(childId && childId.indexOf('local') !== 4){
                        areTransient = false;
                    }
                    areTransient = areTransient && checkChildren(children[i].children);
                }
                return areTransient;
            }
        }
    }, {}); // end of delete class.

    // IB Swep 
    actionsImpl.Class("ComponentReplacement", actionsImpl.ActionProvider, {
        __constructor : function(){ 
            this.__base({name : $TR.__getValueFromTag($TR.PRODIQ001_TAG102,'Component Replacement')}); 
        },
        
        isValid : function(){
            if(this._context.length == 1 && this._context[0].nodeType == "IB"){ 
                return true;
            }else{ 
                return false;
            }
        },
        
        act : function(source, parent){
            var me = this;
            var ibSwap = SVMX.create("com.servicemax.client.installigence.ibswap.IBSwap",{source : source, parent : parent});
            var selectedNode = parent.__contentarea.__ibtree.__selectedNodeId;
            ibSwap.getChildIBs(selectedNode);
        },
        
    }, {});

    actionsImpl.Class("CustomActionProvider", actionsImpl.ActionProvider, {
        __parent : null,

        __constructor : function(meta){
            this.__base(meta);
        },

        act : function(source, parent){
            var me = this;
            window.action_cascade = false;
            //SVMX.getCurrentApplication().showQuickMessage("confirm", 'Are you sure?<br/><br/><label><input type="checkbox" onclick="window.action_cascade=this.checked" /> Apply to child nodes</label>', function(resp){
                //if(resp === "yes"){
                    me.__cascade = window.action_cascade;
                    me.__doCustomAction(source, parent);


                //}
            //});
        },

        __doCustomAction : function(source, parent){
            var me = this;
            this.__parent = parent;
            var targetIds = this._getTargetRecordIds(parent);
            switch(this._meta.actionType){
                // TODO: remove "Field Map"
                case "Field Map":
                case "fieldupdate":
                    SVMX.getCurrentApplication().showQuickMessage("confirm", 'Are you sure?<br/><br/><label><input type="checkbox" onclick="window.action_cascade=this.checked" /> Apply to child nodes</label>', function(resp){
                        if(resp === "yes"){
                            var mapName = me._meta.action;
                            me.__cascade = window.action_cascade;
                            me.__applyFieldUpdate(targetIds, mapName);
                        }
                    });
                    break;
                case "customurl":
                    this.__openCustomURL();
                    break;
            }
        },

        __openCustomURL : function(){
            var me = this;

            this.getCustomURL(me).done(function(preparedurl){
                var customUrlName = me._meta.name;
                if(preparedurl)
                {
                    me.__launchUrl(preparedurl);
                }

            });
        },
        
        /* This method is responsible for launching CustomActionCall */
        __launchUrl : function(urlToLaunch) {
                var d = SVMX.Deferred();
                // var nativeService = window.parent.com.servicemax.client.offline.sal.model.nativeservice.Facade;
                var nativeservice = SVMX.getCurrentApplication().getNativeServiceRequest();
                var browserRequest = nativeservice.createBrowserRequest();

                browserRequest.bind("REQUEST_COMPLETED", function(evt){
                    var result = evt.data.data;
                    d.resolve(result);
                }, this);
                browserRequest.bind("REQUEST_ERROR", function(evt){
                    d.reject({
                      text: TS.T("TODO", "The application does not exist. Please contact your system administrator to update the application path or install the necessary software."),
                      type: "INFO"
                    });
                }, this);

                browserRequest.execute({
                    link: urlToLaunch
                });

                return d.promise();
            },

        getCustomURL : function(me){
            var d = SVMX.Deferred();

            this.getRecord(me).done(function(record) {
                var preparedurl = me._meta.customUrls.targetURL;
                var urlParameters = me._meta.customUrls.urlParameters;
                if(urlParameters && urlParameters.length > 0){
                	// if the link does not have a colon, we are assuming this is a url, so we prepend http://
                	preparedurl = (preparedurl.indexOf(":") == -1) ? "http://" + preparedurl : preparedurl;
                    preparedurl += "?";
                    for(var i=0; i<urlParameters.length ; i++){
                        if(i === 0)
                            preparedurl += me.__getEncriptValuevalue(urlParameters[i].name) + "=";
                        else
                            preparedurl += "&" + me.__getEncriptValuevalue(urlParameters[i].name) + "=";
                        
                        if(urlParameters[i].parameterType === "Field Name"){
                            if(record)
                                preparedurl += me.__getEncriptValuevalue(record[urlParameters[i].value]);
                            else
                                continue;
                        }else if(urlParameters[i].parameterType === "Value"){
                        	var value = me.__checkingForLitralsAndPassValue(urlParameters[i].value);
                            preparedurl += me.__getEncriptValuevalue(value);
                        }
                    }
                }
                d.resolve(preparedurl);
            }); 	
            return d;
        },
        
        __getEncriptValuevalue : function(plainText){
        	return encodeURIComponent(plainText);
        },
        
         __checkingForLitralsAndPassValue : function(value){
			var litralValue = value.toUpperCase();
			var updatedValue = '';
			switch (litralValue) {
				case "SVMX.PRODUCTIQWORKORDERID": // Here passing name os the WO
					if(this.__parent.__objectInfo.object == SVMX.getCustomObjectName("Service_Order"))
						updatedValue = this.__parent.__objectInfo.objectId;
					else
						updatedValue = "";
					break;
				case "SVMX.USERNAME":
					var userName = window.parent.SVMX.getCurrentApplication().__userInfo.UserLogin;
					updatedValue = userName;
					break;
				case "SVMX.DATAACCESSAPIKEY":
					updatedValue = this.__parent.__Apikey;
					break;
				default:
					updatedValue = value || "";
			}
			return updatedValue;
		},
		
        getRecord : function(currentContext){
            var d1 = SVMX.Deferred();
            var objName = currentContext._meta.customUrls.sourceObjectName;
            var recId = currentContext.__parent.__nodesSelected[0].recordId;
            if(!recId)
                d1.resolve();

            var queryObj = SVMX.create("com.servicemax.client.installigence.offline.model.utils.Query", {});
            queryObj.select("*").from(objName)
            .where("Id = '" + recId + "'");
            queryObj.execute()
            .done(function(resp){
                d1.resolve(resp[0]);
            });

            return d1;
            //var recId = currentContext.
        },

        __applyFieldUpdate : function(targetIds, mapName){
            SVMX.getCurrentApplication().blockUI();
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.APPLY_FIELD_UPDATE", this, {
                    request : {
                        context : this,
                        targetIds : targetIds,
                        mapName : mapName,
                        cascade : this.__cascade
                    }
            });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);
        },

        onApplyFieldUpdateComplete : function(success){
            SVMX.getCurrentApplication().unblockUI();
            if(success){
                this.__parent.getContentArea().refreshRecord();
                //SVMX.getCurrentApplication()
                //    .showQuickMessage('success', $TR.FIELD_UPDATE_APPLIED_MESSAGE);
            }
        },

        isValid : function(){
            var targetObjectName = null;
            if(this._context[0].nodeType === "LOCATION"){
                targetObjectName = SVMX.getCustomObjectName("Site");
            }else if(this._context[0].nodeType === "SUBLOCATION"){
                targetObjectName = SVMX.getCustomObjectName("Sub_Location");
            }else if(this._context[0].nodeType === "ACCOUNT"){
                targetObjectName = "Account";
            }else if(this._context[0].nodeType === "IB"){
                targetObjectName = SVMX.getCustomObjectName("Installed_Product");
            }
            if(this._meta.actionType && this._meta.actionType === "fieldupdate"){
                if(this._meta && this._meta.mapping && this._meta.mapping.targetObjectName === targetObjectName){
                    return true;
                }else{
                    return false;
                }    
            }else if(this._meta.actionType && this._meta.actionType === "customurl"){
                if(this._meta.customUrls && this._meta.customUrls.sourceObjectName === targetObjectName)
                    return true;
                else
                    return false;
            }else{
                return false;
            }
        }

    }, {}); // end of CustomActionProvider class.


    
  }; // end of the init.

})();

// end of file 