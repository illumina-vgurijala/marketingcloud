/**
 * 
 */

(function(){
    var metaImpl = SVMX.Package("com.servicemax.client.installigence.metamodel");
    
    metaImpl.Class("AbstractMetamodel", com.servicemax.client.lib.api.EventDispatcher, {
        __constructor : function(){
            this.__base();
        },
        
        initialize : function(){
            // do nothing
        },

        refresh : function() {
            // do nothing
        }
        
    }, {});
    
    metaImpl.Class("Root", com.servicemax.client.installigence.metamodel.AbstractMetamodel, {
        filters     : null,
        actions     : null,
        mappings    : null,
        profileId   : null,
        profileName : null,
        ibPriorityFields : null,
        ibHiddenFields : null,
        productDisplayFields : null,
        productSearchFields : null,
        locPriorityFields : null,
        locHiddenFields : null,
        slocPriorityFields : null,
        slocHiddenFields : null,
        accPriorityFields : null,
        accHiddenFields : null,
        ibDisplayFields : null,
        ibSearchFields : null,
        advanceSearch:null,
        
        __constructor : function(){
            this.__base();
            
            this.filters = [];
            this.actions = [];
            this.ibPriorityFields = [];
            this.ibHiddenFields = [];
            this.productSearchFields = [];
            this.productDisplayFields = [];
            this.locPriorityFields = [];
            this.locHiddenFields = [];
            this.slocPriorityFields = [];
            this.slocHiddenFields = [];
            this.accPriorityFields = [];
            this.accHiddenFields = [];
            this.ibDisplayFields = [];
            this.ibSearchFields = [];
            this.__bindSyncEvents();
            this.advanceSearch = {};
        },
        
        initialize : function(){
            this.refresh();
        },

        refresh : function(){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_METADATA", this, {request : {context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance()
                .triggerEvent(evt);
        },

        onGetMetadataComplete : function(data){
            // TODO: should it be more or less explicit here?
            var i, keys = Object.keys(data), l = keys.length;
            for(i = 0; i < l; i++){
                var key = keys[i];
                this[key] = data[key];
            }
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                    "INSTALLIGENCE.GET_IBSEARCHCONFIG", this, {request : {context : this}});
            com.servicemax.client.installigence.impl.EventBus.getInstance()
                .triggerEvent(evt);
            this.__notifyUpdate();
        },
	onGetMetadataCompleteForAdvanceSearch:function(searchConfig) {
            var displayFields = [];
            var searchFields = [];
			var refrenceDict = [];
			var advancedExpression;

            if (searchConfig) {
                for (var i = 0; i < searchConfig.length; i++) {
                    var searches = searchConfig[i].searches;
                    if (searches) {
                        for (var j = 0; j < searches.length; j++) {
                            var searchConfigFields = searches[j].searchfields;
                            refrenceDict = searches[j].searchfields;
                            advancedExpression = searches[j].advancedExpression; 
                        }
                    }
                }
            }

            // for (var i=0; i<data.length;i++) {
            //     var currentDictionary = data[i];
            //     var fieldType = currentDictionary.fieldType;
            //     var fieldName = currentDictionary.fieldName;

            //     if (fieldType == "Search"){
            //         searchFields.push(fieldName);
            //     }

            //     if (fieldType == "Result"){
            //         displayFields.push(fieldName);
            //     }
            // }

            this.advanceSearch = refrenceDict;//{"displayFields":displayFields,"searchFields":searchFields};
			this.advancedExpression = advancedExpression;
            this.__notifyUpdate();
        },

        __notifyUpdate : function(params){
            var evt = SVMX.create("com.servicemax.client.lib.api.Event", "MODEL.UPDATE", this, params);
            this.triggerEvent(evt);
        },

        __bindSyncEvents : function(){
            var syncService = SVMX.getClient().getServiceRegistry()
                .getService("com.servicemax.client.installigence.sync").getInstance();

            syncService.bind("SYNC.STATUS", function(evt){
                var status = evt.data.type;
                var syncType = evt.data.syncType;
                if(status === "complete"){
                    if(syncType === "initial" || syncType === "reset" || syncType === "config"){
                        this.refresh();
                    }
                }
            }, this);
        }
        
    }, {});
    
})();

// end of file
