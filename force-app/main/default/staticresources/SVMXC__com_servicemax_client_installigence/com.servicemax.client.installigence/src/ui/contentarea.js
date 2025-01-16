/**
 * 
 */

(function(){
	
	var contentareaImpl = SVMX.Package("com.servicemax.client.installigence.contentarea");

contentareaImpl.init = function(){
	
	/**
	 * EVENTS:
	 * 01. node_selected
	 */
	Ext.define("com.servicemax.client.installigence.contentarea.ContentArea", {
        extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
        alias: 'widget.installigence.contentarea',
        __ibtree : null, __record : null, __meta : null, __mashUp : null, __recordInformation : null, __details : null,
        
        constructor: function(config) {
        	
        	this.__meta = config.meta;
        	var ibtree = SVMX.create("com.servicemax.client.installigence.ibtree.IBTree", {
                cls: 'installigence-ibtree', 
    			width: '33.3%', margin: '0', meta : config.meta, root : config.root
    		});
        	var me = this;
        	ibtree.on("node_selected", function(nodes){
                if(this.__mashUp){
                    this.__mashUp.setVisible(false); 
                }
                if(this.__record){
                    this.__record.setVisible(true); 
                }
                // Enable details tab for nodeType IB and disable for others.
                if(nodes.nodeType == 'IB' && this.__meta.isTechnicalAttributesEnabled == 'true'){
                    if(me.__recordInformation.tabPanel.items.length >= 2){}else{
                    	this.__details = null;
                    	this.__details = SVMX.create("com.servicemax.client.installigence.recordDetails.RecordDetails", {
                			flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
               				 parentPanelContext: recordInformation, tree:ibtree
            			});
            			me.__recordInformation.tabPanel.add(this.__details);
            		}
                    me.__details.__findTemplate(nodes);
                }else{
                    me.__recordInformation.tabPanel.remove(me.__details);
                }
        		this.fireEvent("node_selected", nodes);
        	}, this);
        	
    		/*var documents = SVMX.create("com.servicemax.client.installigence.documents.Documents", {
    			flex: 1, margin: '2 3 0 0', collapsible:true, collapseDirection:'left'
    		});
    		
    		var topography = SVMX.create("com.servicemax.client.installigence.topography.Topography", {
    			flex: 1, margin: '2 7 0 4', collapsible:true, collapseDirection:'right'
    		});
    		
    		var configuration = SVMX.create("com.servicemax.client.installigence.configuration.Configuration", { 
    			flex: 1, margin: '0 7 0 2', collapsible:true, collapseDirection:'right'
    		});*/
    		
    		 var recordInformation = SVMX.create("com.servicemax.client.installigence.recordInformation.RecordInformation", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
                tree : ibtree, meta : this.__meta,layout: 'fit'
            });
             this.__recordInformation = recordInformation;
             //overview.
             var record = SVMX.create("com.servicemax.client.installigence.record.Record", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
                tree : ibtree, meta : this.__meta, parentPanelContext: recordInformation
            });
             //details.
             this.__details = SVMX.create("com.servicemax.client.installigence.recordDetails.RecordDetails", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px',cls:'ibinstall-record-container',
                parentPanelContext: recordInformation, tree:ibtree
            });
             
             recordInformation.tabPanel.add(record);
             //recordInformation.tabPanel.add(this.__details); // defect #035443.
             recordInformation.tabPanel.setActiveItem(0)
    		
            var mashup = SVMX.create("com.servicemax.client.installigence.mashups.Mashups", {
                flex: 1, margin: '0 0 0 0', style: 'padding: 10px', hidden : true
            });
	
        	config = Ext.apply({
        		cls: 'mid-panels-container',
				style: 'border-width: 0 !important;',
				layout: {
					type: 'hbox',
					align: 'stretch'
				},
				items:[
				       {
						xtype: 'container', width: '100%',
						layout: { type: 'vbox', align: 'stretch' },
						items: [{
							xtype: 'container', flex: 1,
							layout: { type: 'hbox', align: 'stretch' },
							items: [ibtree, recordInformation, mashup/*configuration*/]
						}/*,{
							xtype: 'container', flex: 1,
							layout: { type: 'hbox', align: 'stretch' },
							items: [documents, topography]
						}*/]
					}
				]
            }, config || {});
        	
        	this.__ibtree = ibtree;
            this.__record = record;
            this.__mashUp = mashup;
        	this.setup();
            this.callParent([config]);
        },
        
        addToTree : function(children, parent, type){
            this.__ibtree.addToTree(children, parent, type);
        },

        addClonedToTree : function(record, cloned, type, cascade){
            this.__ibtree.addClonedToTree(record, cloned, type, cascade);
        },

        deleteFromTree : function(node){
            this.__ibtree.deleteFromTree(node);
        },
        
        refreshContent : function(params){
        	this.__ibtree.refreshContent(params);
        },

        refreshRecord : function(){
            this.__record.refreshData();
        },

        selectTreeNode : function(recordId){
            this.__ibtree.selectTreeNode(recordId);
        },
        
        setup : function() {
            this.__meta.bind("MODEL.UPDATE", function(evt){
                this.refresh(evt);
            }, this);
        },
        
        refresh : function(data) {
        	var me = this;
            if(data.target.isTechnicalAttributesEnabled == 'true'){
            	if(this.__recordInformation.tabPanel.items.length >= 2){}else{
            		this.__recordInformation.tabPanel.add(this.__details);
            	}
            }else{
            	this.__recordInformation.tabPanel.remove(this.__details);
            }
        },

        openCustomURL : function(preparedurl, actionName){
            if(this.__mashUp){
                this.__mashUp.__urlToLoad = preparedurl;
                this.__mashUp.__title = actionName;
                
                //Ext.getCmp("TestURLId").autoEl.src = preparedurl;
                this.__mashUp.setVisible(true); 

                 var frame = Ext.getCmp('TestURLId'); 
                 if(frame && frame.rendered ){ 
                    frame.getEl().dom.src = preparedurl;//"http://it.wikipedia.org/wiki/Robot"; 
                 }

            }
            if(this.__record){
                this.__record.setVisible(false); 
            }
        }
    });
};

})();

// end of file