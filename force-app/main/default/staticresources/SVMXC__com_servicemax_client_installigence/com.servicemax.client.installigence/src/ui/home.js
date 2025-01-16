/**
 * 
 */

(function(){
    
    var homeImpl = SVMX.Package("com.servicemax.client.installigence.home");

homeImpl.init = function(){
    
    Ext.define("com.servicemax.client.installigence.home.Home", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.home',
        meta : null, root : null,
        __contentArea : null,
        __actions : null,
        __menu : null,
        
        constructor: function(config) { 
            
            this.meta = config.meta;
            this.root = config.root;
            this.__setSelectedAccountId();
            
            /*
            var filters = SVMX.create("com.servicemax.client.installigence.filters.Filters", {
                region: 'west', collapsed: true, collapsible: true, split: false, width: 200, meta : this.meta
            });
			*/
            
            var contentarea = SVMX.create("com.servicemax.client.installigence.contentarea.ContentArea", {
                region: 'center', collapsible: false, floatable: false, split: false, meta : this.meta, root : this.root
            });
            
            var actions = SVMX.create("com.servicemax.client.installigence.actions.Actions", {
                region: 'east', collapsed: false, split: false, width: 200, floatable: true, meta : this.meta,
                contentarea : contentarea
            });
            
           var toolBarItems = SVMX.create("com.servicemax.client.installigence.ibToolBar.ToolBarItems", {
                region: 'north', margin: '0 0 0 0',cls:'ibtoolbar-home-account-filter', collapsed: false, split: false, height:50, floatable: true, meta : this.meta,
                contentarea : contentarea
                
            });

            // Prevent context menu
           /* Ext.getDoc().on('contextmenu', function(e){
               e.preventDefault();
            });*/

            var me = this;
            config = Ext.apply({
                //title: '<span class="title-text">ProductIQ</span> <div class="logo img"/></div> <div class="logo spinner" style="background-image: none"/></div>',
                //titleAlign: 'center', 
                // frame: 'true',
                collapsible : false,
                // style: 'margin:10px',
                // height : SVMX.getWindowInnerHeight() - 40,
                height : SVMX.getWindowInnerHeight() - 2,
                
                layout: {
                    type: 'border'
                    // padding: '3'
                },
                defaults: {
                    collapsible: true,
                    split      : true
                },
                //items : [ contentarea, actions ]
                items : [ contentarea, toolBarItems ]
            }, config || {});

            if(!SVMX.getCurrentApplication().isAppEmbedded()) {
                config = Ext.apply({
                    title: '<span class="title-text">ProductIQ</span> <div class="logo img"/></div> <div class="logo spinner" style="background-image: none"/></div>',
                    titleAlign: 'center', 
                    toolPosition: 0,
                    tools: [{
                        type:'hamburger',
                        cls: 'hamburger',
                        handler: function(e, el, owner, tool){
                            
                            if(!me.__showingMenu){
                                me.__showingMenu = true;
                                me.getMenu(owner).showBy(owner,'tl-bl?');
                            }else{
                                me.__showingMenu = false;
                                me.getMenu(owner).hide();
                            }
                        }
                    }]
                }, config || {});
            }
            
            this.__contentArea = contentarea;
            this.__actions = actions;

            this.__bindSyncEvents();

            this.callParent([config]);
        },

        __bindSyncEvents : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
            .getService("com.servicemax.client.installigence.sync").getInstance();
            syncService.bind("SYNC.STATUS", function(evt){
                var status = evt.data.type;
                var message = evt.data.msg;
                var syncType = evt.data.syncType;
                if(status === "start"){
                    this._disableMenuItem($TR.__getValueFromTag($TR.PRODIQ001_TAG049,'Sync Data'));
                }else if(status === "complete" || status === "canceled"){
                    this._enableMenuItem($TR.__getValueFromTag($TR.PRODIQ001_TAG049,'Sync Data'));
                }
            }, this);
        },
        
        getMenu : function(){
            var me = this;
            if (!me.__menu) {
                me.__menu = SVMX.create('com.servicemax.client.installigence.ui.components.Menu', {
                    cls: 'svmx-nav-menu',
                    plain: true,
                    height: '80%',
                    items: [
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG027,'Find & Get'), handler : function(){
                                me._handleFindAndGet({syncType : "ib"});
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG048,'Sync Configuration'), handler : function(){
                                me._handleConfigSync();
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG049,'Sync Data'), handler : function(){
                                me._handleIncrementalSync();
                            }},
                            // TODO: $TR.SYNC_CONFLICTS
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG099,'Sync Conflicts'), handler : function(){
                                me._showSyncConflicts();
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG095,'Purge Data'), handler : function(){
                                me._handlePurgeSync();
                            }},
                            {text: $TR.__getValueFromTag($TR.PRODIQ001_TAG051,'Reset Application'), handler : function(){
                                me._handleResetApplication();
                            }}
                    ]
                });
            }
            return me.__menu;
        },

        _disableMenuItem : function(menuText){
            var items = this.getMenu().items.items;
            for(var i = 0; i < items.length; i++){
                if(items[i].text === menuText){
                    items[i].disable();
                    break;
                }
            }
        },

        _enableMenuItem : function(menuText){
            var items = this.getMenu().items.items;
            for(var i = 0; i < items.length; i++){
                if(items[i].text === menuText){
                    items[i].enable();
                    break;
                }
            }
        },
        
        _handleResetApplication : function(){
            this.root.handleResetApplication();
        },
        
        _handleFindAndGet : function(){
            this.root.handleFindAndGet();
        },

        _handleConfigSync : function(){
            this.root.handleConfigSync();
        },

        _handleIncrementalSync : function(){
            this.root.handleIncrementalSync();
        },

        _handlePurgeSync : function(){
            this.root.handlePurgeSync();
        },

        _showSyncConflicts : function(){
            this.root.showSyncConflicts();
        },
        
        handleFocus : function(params){
            this.__contentArea.refreshContent(params);
        },

        selectTreeNode : function(recordId){
            this.__contentArea.selectTreeNode(recordId);
        },

        __setSelectedAccountId : function() {
            var me = this;
            SVMX.getClient().bind("ACCOUNT_ID_MESSAGE", function(evt){
                var data = SVMX.toObject(evt.data);
                if (data.accountId) { 
                    me.meta.accountId = data.accountId;
                }
            });
        } 
    });
};

})();

// end of file
