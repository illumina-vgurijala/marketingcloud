/**
 *  Attachment.
 * @class com.servicemax.client.insralligence.admin.attachment.js
 * @author Madhusudhan HK
 *
 * @copyright 2016 ServiceMax, Inc.
 **/

  (function(){

	var attachment = SVMX.Package("com.servicemax.client.installigence.admin.attachment");
	attachment.init = function() {


		Ext.define("com.servicemax.client.installigence.admin.Attachment", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",

	         __root: null,
	         constructor: function(config) {
	         	var me = this;
	         	config = config || {};
				config.title = $TR.ATTACHMENTS;
				config.id = "attachment";
				this.__root = config.root;
				this.__registerForDidProfileSelectCall();

				me.showProfiles = config.root.showProfiles;

				 me.enableAttachmentCheckbox = SVMX.create("com.servicemax.client.installigence.ui.components.Checkbox", {
                    boxLabel : $TR.ENABLE_ATTACHMENTS_DOWNLOAD_DURING_SYNC,
                    scope: this,
                    disabled: true,
                    handler : function(field, value){
                        if (value) {
                        	me.__enableOrDisableAttachmentTabFields(false);
                        } else {
							me.__enableOrDisableAttachmentTabFields(true);
                        }
                    }
                });

				me.horizontalLine = {
				    xtype: 'box',
				    autoEl : {
				        tag : 'hr'
				    }
				}; 

				me.attachmentSettingTitle = {
			    	xtype : 'label',
			    	forId : 'myFieldId',
			    	text : $TR.ATTACHMENT_SETTING_TITLE, 
			    	style: 'font-weight: 600;',
			    	margin : '40 0 10 10'
			    }; 


				 me.fileTypeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   width : 600,
	    		   disabled: true,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.DOWNLOAD_ONLY_THESE_FILES_TYPE,
	    	   });

				 me.maxFileSizeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   disabled: true,
	    		   width : 600,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.ENTER_MAXIMUM_FILES_SIZE_TO_DOWNLOAD,
	    		   maskRe: /[0-9]/
	    	   });

				me.sfilesSettingTitle = {
			    	xtype : 'label',
			    	forId : 'myFieldId',
			    	text : $TR.SFILE_SETTING_TITLE, 
			    	style: 'font-weight: 600;',
			    	margin : '40 0 10 10'
			    }; 

			    me.sfileTypeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   width : 600,
	    		   disabled: true,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.DOWNLOAD_ONLY_THESE_FILES_TYPE,
	    	    });

				me.sfileMaxFileSizeTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   disabled: true,
	    		   width : 600,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.ENTER_MAXIMUM_FILES_SIZE_TO_DOWNLOAD,
	    		   maskRe: /[0-9]/
	    	    });	 

			    me.sfileTagsTextFields = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXTextField',{
	    		   allowBlank : true,
	    		   editable : true,
	    		   disabled: true,
	    		   width : 600,
	    		   margin:'40 0 10 10',
	    		   labelStyle: 'width:300px; white-space: nowrap;', 
	    		   fieldLabel: $TR.SFILE_TAGS_TYPES
	    	    });	



				config.items = [me.enableAttachmentCheckbox,me.horizontalLine,me.attachmentSettingTitle,me.fileTypeTextFields,me.maxFileSizeTextFields, me.sfilesSettingTitle, me.sfileTypeTextFields,me.sfileMaxFileSizeTextFields,me.sfileTagsTextFields];
				this.callParent([config]);

	         },

	         __enableOrDisableAttachmentTabFields:function(isDisable) {
         		this.fileTypeTextFields.setDisabled(isDisable);
				this.maxFileSizeTextFields.setDisabled(isDisable);
				this.sfileTypeTextFields.setDisabled(isDisable);
				this.sfileMaxFileSizeTextFields.setDisabled(isDisable);
				this.sfileTagsTextFields.setDisabled(isDisable);
	         },

			__updateAttachmentDetails:function(combo, record){

				if(combo.getSelectedRecord().get("profileId") == "--None--"){
					this.enableAttachmentCheckbox.setDisabled(true);
					this.__enableOrDisableAttachmentTabFields(true);
				}else{

					this.enableAttachmentCheckbox.setDisabled(false);

					if (this.enableAttachmentCheckbox.getValue()) {
						this.__enableOrDisableAttachmentTabFields(false);
					} else {
						this.__enableOrDisableAttachmentTabFields(true);
					}
					
				}

				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().attachment == undefined){
					this.enableAttachmentCheckbox.setValue(false);
					this.fileTypeTextFields.setValue('');
					this.maxFileSizeTextFields.setValue('');
					this.sfileTypeTextFields.setValue('');
					this.sfileMaxFileSizeTextFields.setValue('');
					this.sfileTagsTextFields.setValue('');

				}else if(selecetedProfile.getData().attachment.length > 0){
					
					var pAttachment = selecetedProfile.getData().attachment[0];
					(pAttachment.isAttachmentsEnabled == 'true'? this.enableAttachmentCheckbox.setValue(true): this.enableAttachmentCheckbox.setValue(false)) ;
					this.fileTypeTextFields.setValue(pAttachment.fileTypes);
					this.maxFileSizeTextFields.setValue(pAttachment.maximumFileSize);
					this.sfileTypeTextFields.setValue(pAttachment.sfdcFileTypes);
					this.sfileMaxFileSizeTextFields.setValue(pAttachment.maxSfdcFileSize);
					this.sfileTagsTextFields.setValue(pAttachment.sfdcFileTags);


				}else{
					//TODO: 
				}
				
			},
			__registerForDidProfileSelectCall: function(){
				var me = this;
	           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){

	              	 var data = SVMX.toObject(evt.data);
	            	 var combo = evt.target.result.combo;
	            	 var record = evt.target.result.record;
	            	 this.showProfiles.setRawValue(record.get('profileName'));
	          	 	this.__updateAttachmentDetails(combo, record);	
					

	           }, this); 
			},

			__persistAttachment:function(selecetedProfile){
				
				var pAttachment;
				if(selecetedProfile.getData().attachment == undefined){
					selecetedProfile.set("attachment", []);
					pAttachment = {};
				}else if(selecetedProfile.getData().attachment.length > 0){
					
					pAttachment = selecetedProfile.getData().attachment[0];
					
				}else{
					pAttachment = {};
				}
				

				pAttachment.isAttachmentsEnabled = this.enableAttachmentCheckbox.getValue().toString();
				pAttachment.fileTypes = this.fileTypeTextFields.getValue();
				pAttachment.maximumFileSize = this.maxFileSizeTextFields.getValue();

				pAttachment.sfdcFileTypes = this.sfileTypeTextFields.getValue();
				pAttachment.maxSfdcFileSize = this.sfileMaxFileSizeTextFields.getValue();
				pAttachment.sfdcFileTags = this.sfileTagsTextFields.getValue();

				selecetedProfile.set('attachment',[pAttachment]);
			}
			
	     });

	}
})();

