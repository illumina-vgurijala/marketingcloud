/**
 * This file creates the toolbar items like search, action and filter.
 * @class com.servicemax.client.insralligence.src.ui.toolbar.js
 * @author Madhusudhan HK
 *
 * @copyright 2015 ServiceMax, Inc.
 **/

(function(){

	var toolBarImpl = SVMX.Package("com.servicemax.client.installigence.ibToolBar");

	toolBarImpl.init = function(){
		Ext.define("com.servicemax.client.installigence.ibToolBar.ToolBarItems",
			{
				extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
               alias: 'widget.installigence.ibToolBar',width:'100%',

               __meta: null,
               __contentarea: null,
               __installbaseSearch: null,
               __popup: null,
               
                constructor: function(config) {
						var me = this;
                        this.__contentarea = config.contentarea;
                        this.__meta = config.meta;
                        var actions = SVMX.create("com.servicemax.client.installigence.actions.Actions", {
                            region: 'east', collapsed: false, split: false, cls: "ibtoolbar-action-panel", style: 'border:0px;text-align:right', floatable: true, meta : this.__meta,
                            contentarea : this.__contentarea, width : '89%'
                        });
						
                        config = Ext.apply({
                        
                        ui: 'svmx-white-panel',
                        cls: 'filter-region',
                        layout : {type : "hbox"},
                        defaults : {padding : '0 5 0 0'},
                        items : [ 
                        /*{ xtype: 'button', 
                                    iconCls: 'filter-icon',
                                    margin: '9 20 20 20', //TODO. Relative margion has to be applied here
                                    handler : function(){
                                       
                                       var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "FILTER_ACTION_CALL",
                                                             this);
                                        SVMX.getClient().triggerEvent(evt);


                                    }
                                },*/{ 
                                    xtype: 'button', 
                                    text : $TR.__getValueFromTag($TR.PRODIQ001_TAG053,'Search'),
                                    cls: 'ibtoolbar-search-heading-btn',
                                    height: 30,
                                    width : '10%',
                                    textAlign : 'left',
                                    margin: '10',  
                                    handler : function(){
                                        
                                        //Ext.Msg.alert('Search', 'Implement search here.');
                						//me.__installbaseSearch = SVMX.create("com.servicemax.client.installigence.search.Search",{
                						//config : me.__meta.advanceSearch,mvcEvent : "SEACH_INSTALLBASE"});
            							//me.__installbaseSearch.find();
                                        
                                        if(me.__meta.advanceSearch  && me.__meta.advanceSearch.length > 0){
                                         	var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "IB_SEARCH_ACTION_CALL",
                                                             this);
                                        	SVMX.getClient().triggerEvent(evt);
                                            me.__triggerClearFilters();
                                            
                                            //Disabling PIQ back button button 
                                            var btn = window.parent.Ext.getCmp('piqComBackbtn');
                          					btn.hide();
                                        }else{
                                        	var evt = SVMX.create("com.servicemax.client.installigence.svmxPopup.popupMessage", {
												height: 150,
												width: 390,
												layout: 'fit',
												buttonAlign: 'center',
												closable: false,
												text : $TR.__getValueFromTag($TR.PRODIQ001_TAG121,'Search (SFM) is not configured for this profile.'),
												title : $TR.__getValueFromTag($TR.MSG,'Message'),
                                                textAlign : "display:inline-block;text-align:center"
											});
											evt.filterButtonAction(evt);
                                        	evt.show();
                                        } 
                                        
                                    }
                                },
                                // { xtype: 'button', 
                                //     text : 'Action',
                                //     width: 150,
                                //     height: 30,
                                //     margin: '-30 0 0 750', //TODO. Relative margion has to be applied here
                                      
                                //     handler : function(){
                                        
                                //         Ext.Msg.alert('Action', 'Implement Action here.');
                                //     }
                                // }
                                actions
                            ]
                        
                            } , config || {});

                         this.callParent([config]);

                },

                __triggerClearFilters : function() {

                    var data = {};
                    var evt = SVMX.create("com.servicemax.client.lib.api.Event", "CLEAR_FILTERS_MESSAGE", this, data);
                    SVMX.getClient().triggerEvent(evt); 
                },

                filterButtonAction : function(){

                        
                },

                searchButtonAction: function(){

                        
                }    
			});
	}

})();

/* custom code for popup */
Ext.define('SVMX.alertPopup.message', {
    extend: 'com.servicemax.client.ui.components.controls.impl.SVMXWindow',
    alias: 'widget.installigence.ibToolBar',
    height: 150,
    width: 390,
    id: 'popup',
    layout: 'fit',
    buttonAlign: 'center',
    closable: false,
    text : 'No sfm search',
    title : 'Message',
    msglbl:null,
    parent:null,
    items: [
        {
            xtype: 'form',
            frame: false,
            border: 0,
            layout: {
                type: 'hbox',
                align: 'middle'
            },
            fieldDefaults: {
                msgTarget: 'side',
                labelWidth: 55
            },
            items: [
                {
                    xtype: 'container',
                    flex: 1,
                    padding: 2,
                    layout: {
                        type: 'vbox',
                        align: 'stretch'
                    },
                    items: [
                    	{
                        	xtype: 'label',
                        	itemId: 'msglblId',
                        	text : 'Search (SFM) is not configured for this profile',
                        	style: 'display:inline-block;text-align:center'
                    	}
                    ]
                }
            ],
            listeners: [
			]
        }
    ],
    buttons: [
        {
            text: 'ok',//$TR.__getValueFromTag($TR.PRODIQ001_TAG112,'OK'),
            itemId: 'okBtnId',
            listeners: {
        		click : function(b, e) {
             		parent.close();
             	}
       	 	}
        }
    ],
    closeme : function(me, title, bodyText){
    	parent = me;
    	title: title;
    	text: bodyText;
    }
});