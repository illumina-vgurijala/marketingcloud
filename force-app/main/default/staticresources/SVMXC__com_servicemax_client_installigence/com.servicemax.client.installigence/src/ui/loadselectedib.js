/**
 * 
 */

(function(){
    
    var loadselectedibImpl = SVMX.Package("com.servicemax.client.installigence.loadselectedib");

loadselectedibImpl.init = function(){
    loadselectedibImpl.Class("LoadSelectedIB", com.servicemax.client.lib.api.Object, {
    __selectedIB : null, __parent : null, __root : null, __parentIBs : null, __accountNode : null,
    __ibtree : null, __treeDataById : null, __isCallback : null,
    __focusFromSearch : null,

    
    __constructor : function(options){
        this.__root = options.root;
        this.__parent = options.parent;
        this.__ibtree = options.parent.getTree();
        this.__treeDataById = options.parent.getTreeDataById();
        this.__callback = options.callback || function(){};
        this.__selectedFirst = null;
        this.__params = options.params;

        if (options.selectedIB.focused) {
            this.__focusFromSearch = options.selectedIB.focused
        }

        var loadingMore = false;
        for(var i = 0; i < options.selectedIB.recordIds.length; i++){
            var recordId = options.selectedIB.recordIds[i];

            var ibNode = this.__ibtree.getStore().getNodeById(recordId);
            if (ibNode != null) {
                // Only select the first path
                if (this.__selectedFirst !== true) {
                    this.__selectedFirst = true;
                    this.__parent.fireEvent("node_selected", ibNode.data);
                    this.__ibtree.selectPath(ibNode.getPath());
                }
                continue;
            }
            loadingMore = true;
            var evt = SVMX.create("com.servicemax.client.lib.api.Event",
                "INSTALLIGENCE.GET_ALL_PARENT_IBS", this, {
                    request : { context : this, params : {}, record : {Id : recordId}, 
                        handler : this.onAllParentIBsComplete
                        }
                });
            com.servicemax.client.installigence.impl.EventBus.getInstance().triggerEvent(evt);

        }
        if(!loadingMore){
            this.__callback();
        }
    },
        
    onAllParentIBsComplete : function(data) {
        if (data == null || data.length == 0) {
            if (this.__parent.__selectFromExternal) {
                this.__callback();
                this.showMessageForParent();
            }
        } else {
            this.traverseNodes(data);
        }
    },
    
    traverseNodes : function (data) {
        if (data.length == 0) {
            return;
        }
        var rec = data.pop();
        var ibNode = this.__ibtree.getStore().getNodeById(rec.ids);
        if (!ibNode) {
            this.__callback();
            this.showMessageForParent();
            return;
        }
        var parentNode = this.__treeDataById[ibNode.id];
        if (data.length == 0 && this.__selectedFirst !== true) {
            this.__selectedFirst = true;
            this.__parent.fireEvent("node_selected", ibNode.data);
            this.__ibtree.selectPath(ibNode.getPath());
            
            if(!this.__isCallback){
               this.__isCallback = true; 
               this.__callback();
            }
            
            return;
        }else if(data.length == 0){
            if(!this.__isCallback){
               this.__isCallback = true; 
               this.__callback();
            }
            return;
        }
        // Children are already loaded. Lazy loading is not required.
        if (parentNode != null && parentNode.allIBsLoaded == true) {
            this.traverseNodes(data);
        }
        this.__parent.on("node_loaded", function(input) {
                this.traverseNodes(data);
        }, this, {single : true});

        // ibNode.expand(false);
        var time = 15;
        if (this.__focusFromSearch === true) {
            time = 800;
        }
        setTimeout(function(){
                    ibNode.expand(false);
         }, time);
    },

    showMessageForParent : function(){

        if (this.params === undefined) {
            return;
        }
         if (!this.__params.viaFilter === true) { // this.__params === undefined  ||
         
         /* Using custom window for message */
         	var evt = SVMX.create("com.servicemax.client.installigence.svmxPopup.popupMessage", {
				height: 175,
				width: 550,
				layout: 'fit',
				buttonAlign: 'center',
				closable: false,
				text : $TR.__getValueFromTag($TR.PRODIQ001_TAG046,'Installed product or Location record(s) may not be available in the tree view because not all required data has been downloaded. Please download the associated Account or Installed Product record(s) and retry.'),
				title : $TR.__getValueFromTag($TR.PRODIQ001_TAG056,'Info'),
                textAlign : "display:inline-block;text-align:left"
			});
			evt.filterButtonAction(evt);
			evt.show();
			
            //SVMX.getCurrentApplication().showQuickMessage("Info", $TR.MESSAGE_IB_NOT_EXISTS);
            delete this.__parent.__selectFromExternal;
        } 
    }
            
    }, {});
    
};

})();

// end of file