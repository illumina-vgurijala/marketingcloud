(function(){
	var search = SVMX.Package("com.servicemax.client.installigence.admin.search");

search.init = function() {

		Ext.define("com.servicemax.client.installigence.admin.Search", {
			extend: "com.servicemax.client.installigence.ui.components.SVMXPanel",
			__root: null,
			constructor: function(config) {
				var me = this;
				this.__registerForDidProfileSelectCall();
				this.__root = config.root;
				var profiles = config.metadata.svmxProfiles;
				var profilesData = [{profileId: "--None--", profileName: $TR.NONE}];
				var objectsData = [{objectName: "--None--", objectLabel: $TR.NONE}, {objectName: SVMX.OrgNamespace  + "__Installed_Product__c", objectLabel: "Installed Product"}];
				var availSearchData = [{sfdcId: "--None--", searchLabel: $TR.NONE}].concat(config.metadata.availableSearchProc.searches);
				var searches = [];

				var iProfile = 0, iProfileLength = profiles.length;
				for(iProfile = 0; iProfile < iProfileLength; iProfile++) {
					if(profiles[iProfile].profileId !== 'global'){
						profilesData.push(profiles[iProfile]);
					}
				}

				me.profiles = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['profileId', 'profileName'],
			        data: profilesData
			    });

			    me.objects = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['objectName', 'objectLabel'],
			        data: objectsData
			    });

			    me.availableSearches = SVMX.create('com.servicemax.client.ui.components.composites.impl.SVMXStore', {
			        fields: ['sfdcId', 'searchLabel'],
			        data: availSearchData
			    });
				/*me.showProfiles = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_PROFILE,
			        store: me.profiles,
			        labelWidth: 140,
			        width: 450,
			        displayField: 'profileName',
			        queryMode: 'local',
			        editable: false,
			        selectedProfile: undefined,
			        listeners: {
			        	select: {
			        		fn: me.__didSelectProfileWithInfo,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('profileName'));
						}
						afterrender :{
							fn : me.__showProfilesAfterrender,
							scope : me
						}
			        }
				});*/

				me.showProfiles = config.root.showProfiles;

				//'Select a Object'
				me.showObjects = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_OBJECT,
			        store: me.objects,
			        labelWidth: 150,
			        width: 450,
			        displayField: 'objectLabel',
			        valueField:'objectName',
			        queryMode: 'local',
			        editable: false,
			        margin:'10 0',
			        disabled: true,
			        selectedObject: undefined,
			        listeners: {
			        	select: {
			        		fn: me.__onSelectObjects,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('objectLabel'));
						}
			        }
				});

				me.showSearchs = SVMX.create('com.servicemax.client.installigence.ui.components.SVMXComboBox',{
					fieldLabel: $TR.SELECT_SEARCH,
			        store: me.availableSearches,
			        labelWidth: 150,
			        width: 450,
			        displayField: 'searchLabel',
			        valueField:'sfdcId',
			        queryMode: 'local',
			        editable: false,
			        disabled: true,
			        listeners: {
			        	select: {
			        		fn: me.__persistSearchData,
			        		scope: me
			        	},
						afterrender: function(combo) {
							var recordSelected = combo.getStore().getAt(0);                     
							combo.setValue(recordSelected.get('searchLabel'));
						}
			        }
				});

				config = config || {};
				config.items = [];
				//config.items.push(me.showProfiles);
				config.items.push(me.showObjects);
				config.items.push(me.showSearchs);

				
				config.title = $TR.SEARCH_EMPTY_TEXT; //
				config.id = "Search";
				this.callParent([config]);

			},

			__showProfilesAfterrender : function(combo){
				
					var recordSelected; 
						if(this.__root.selectedProfile)
						{
							recordSelected =  this.__root.selectedProfile; 
						}else
						{
							recordSelected = combo.getStore().getAt(0);
						}
						combo.setValue(recordSelected.get('profileName'));

			},
			__didSelectProfileWithInfo:function(combo, record){
				this.__root.selectedProfile = record;
				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 
                                                             "SELECTED_PROFILE_CALL",{result: {combo:combo,record:record}},
                                                             this);
                    SVMX.getClient().triggerEvent(evt);
                    

			},
			__onSelectProfile: function(combo, record){

				this.showObjects.setValue('--None--');
				this.showSearchs.setValue('--None--');

				
				if(combo.getSelectedRecord().get("profileId") == "--None--"){
					this.showObjects.setDisabled(true);
					this.showSearchs.setDisabled(true);
				}else{
					this.showObjects.setDisabled(false);
				}

				if(combo.getSelectedRecord() && combo.getSelectedRecord().get("profileId") !== "--None--"){
					var selProfileObj = this.showProfiles.selectedProfile;
				}

				if(combo.getSelectedRecord().get("profileId") !== "--None--"){
					this.showProfiles.selectedProfile = record;
				}else{
					this.showProfiles.selectedProfile = undefined;
				}
			},

			__onSelectObjects: function(combo, record){
				if(combo.getSelectedRecord().get("objectName") == "--None--"){
					this.showSearchs.setDisabled(true);
				}else{
					this.showSearchs.setDisabled(false);
				}
				this.__loadSearchData(combo, record);

			},

			__persistSearchData: function(){
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				if(selecetedProfile.getData().search == undefined){
					selecetedProfile.set("search", []);
				}
				if(this.showObjects.getSelectedRecord() && this.showObjects.getSelectedRecord() !== undefined &&
					this.showObjects.getSelectedRecord().get("objectName") !== "--None--"){

					var searchName = this.showSearchs.getSelectedRecord().get("searchName");	
					var objectName = this.showObjects.getSelectedRecord().get("objectName");
					var sfdcId = this.showSearchs.getSelectedRecord().get("sfdcId");
					var selectedSearchObject = this.__getObjectSearchData(selecetedProfile, objectName);

					if(!selectedSearchObject){
						selectedSearchObject = {objectName: objectName};
						selecetedProfile.set("search", [selectedSearchObject]);
					}
					if(sfdcId == "--None--") sfdcId = "";
					selectedSearchObject.searches = [{sfdcId: sfdcId}];
					if(selectedSearchObject.searches.length > 0 && sfdcId) {
						selectedSearchObject.searches[0].sfdcId = sfdcId;
					}
					if(selectedSearchObject.searches.length > 0 && searchName) {
						selectedSearchObject.searches[0].searchName = searchName;
					}

				}
			},
			__getObjectSearchData: function(selectedProfile, objectName){
				var iSearchData = 0, iSearchLen = selectedProfile.getData().search.length;
				for(iSearchData = 0; iSearchData < iSearchLen; iSearchData++){
					if(selectedProfile.getData().search[iSearchData].objectName == objectName){
						return selectedProfile.getData().search[iSearchData];
					}
				}
				return undefined;
			},

			__loadSearchData: function(combo, record){
				var selectedObjectName = combo.getSelectedRecord().get("objectName");
				var selecetedProfile = this.showProfiles.getSelectedRecord();
				var selectedSearch = "";
				var selectedSearchProcessId = '';
				var selectedSearchObject = '';
				if(selectedObjectName !== "--None--" && selecetedProfile.getData().search){
					selectedSearchObject = this.__getObjectSearchData(selecetedProfile, selectedObjectName);
					if(selectedSearchObject){
						//get the selected object search data
						selectedSearch = selectedSearchObject.searches[0].sfdcId;
						selectedSearchProcessId = selectedSearchObject.searches[0].searchName;
					}
				}
				var item = this.showSearchs.store.data.items.find(function(object){
								if(object.data.sfdcId == selectedSearch) return true;
								return false;
							});
				if(!item) { //incase if  process is not available for selected sfdcid then show none.
					var len = this.showSearchs.getStore().data.items.length, items = this.showSearchs.getStore().data.items, matched = false;
					for(var i = 0; i < len; i++) {
						var currentProcessId = items[i].data.searchName;
						if(currentProcessId === selectedSearchProcessId) {
							//update the sfdcId here.
							selectedSearch = items[i].data.sfdcId;
							matched = true;
							var selecetedProfile = this.showProfiles.getSelectedRecord();
							if(selecetedProfile.getData().search == undefined){
								selecetedProfile.set("search", []);
							}
							var selectedSearchObject = this.__getObjectSearchData(selecetedProfile, selectedObjectName);
							if(!selectedSearchObject){
								selectedSearchObject = {selectedObjectName: selectedObjectName};
								selecetedProfile.set("search", [selectedSearchObject]);
							}
							if(selectedSearch === "--None--") selectedSearch = "";
							selectedSearchObject.searches = [{sfdcId: selectedSearch}];
							if(selectedSearchObject.searches.length > 0 && selectedSearch) {
								selectedSearchObject.searches[0].sfdcId = selectedSearch;
							}
							if(selectedSearchObject.searches.length > 0 && selectedSearchProcessId) {
								selectedSearchObject.searches[0].searchName = selectedSearchProcessId;
							}
							break;
						}
					}
					if(!matched) {
						selectedSearch = "--None--";
					}
				}

				if(!selectedSearch || selectedSearch.length == 0) selectedSearch = "--None--";

    		   this.showSearchs.setValue(selectedSearch);
			},

			__registerForDidProfileSelectCall: function(){

           SVMX.getClient().bind("SELECTED_PROFILE_CALL", function(evt){
               var data = SVMX.toObject(evt.data);
             var combo = evt.target.result.combo;
             var record = evt.target.result.record;
          	 
             this.__onSelectProfile(combo, record);
             this.showProfiles.setRawValue(record.get('profileName'));
           		}, this); 
			}
		});

	}
	})();