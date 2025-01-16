/**
 * This file creates the toolbar items like search, action and filter.
 * @class com.servicemax.client.insralligence.src.ui.toolbar.js
 * @author Madhusudhan HK
 *
 * @copyright 2015 ServiceMax, Inc.
 **/

(function(){

	var toolBarImpl = SVMX.Package("com.servicemax.client.installigence.svmxPopup");

	toolBarImpl.init = function(){
		Ext.define("com.servicemax.client.installigence.svmxPopup.popupMessage",
			{
				extend: "com.servicemax.client.ui.components.controls.impl.SVMXWindow",
               	alias: 'widget.installigence.svmxPopup',
               	width:'100%',
               	__popup: null,
                constructor: function(config) {
                	var me = this;
                	 config = Ext.apply({
                        extend: 'com.servicemax.client.ui.components.controls.impl.SVMXWindow',
    					alias: 'widget.installigence.ibToolBar',
   	 					height: config.height,
    					width: config.width,
    					layout: config.layout,
    					buttonAlign: config.buttonAlign,
    					closable: config.closable,
    					text : config.text,
    					title : config.title,
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
												text : config.text,
												style: config.textAlign
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
								text: $TR.__getValueFromTag($TR.PRODIQ001_TAG112,'Ok'),
								itemId: 'okBtnId',
								listeners: {
									click : function(b, e) {
										me.__popup.close();
									}
								}
							}
						]
                    } , config || {});
                    this.callParent([config]);
				},

                filterButtonAction : function(popup){
					this.__popup = popup;
                        
                },

                searchButtonAction: function(){

                        
                }    
			});
		}
	})
();
