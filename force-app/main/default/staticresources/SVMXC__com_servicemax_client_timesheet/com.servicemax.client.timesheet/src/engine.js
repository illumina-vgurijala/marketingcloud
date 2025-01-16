
(function(){

	var engine = SVMX.Package("com.servicemax.client.timesheet.engine");

	engine.init = function(){

		engine.Class("DeliveryEngineImpl", com.servicemax.client.sfmconsole.api.AbstractDeliveryEngine, {

			__constructor: function(currApp) {
				this.__base();
			},

			initAsync: function(options) {

                var ni = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.niservice").getInstance();
                this.__eventBus = SVMX.create("com.servicemax.client.timesheet.impl.TimesheetEngineEventBus", {});

                // create the named default controller
                ni.createNamedInstanceAsync("CONTROLLER", {
                    handler: function(controller) {
                        // now create the named default model
                        ni.createNamedInstanceAsync("MODEL", {
                            handler: function(model) {
                                controller.setModel(model);
                                // Now it is the view's turn
                                ni.createNamedInstanceAsync("TIMESHEET.VIEW",{ handler : function(view){
                                    this.__view = view;
                                    options.handler.call(options.context);
                                }, context: this, additionalParams: {eventBus: this.getEventBus()}});
                            },
                            context: this
                        });
                    },
                    context: this,
                    additionalParams: {
                        eventBus: this.__eventBus
                    }
                });
                //this.loadTheme();
            },

            getEventBus: function() {
                return this.__eventBus;
            },

            __appCurrentState: "",
            changeApplicationState: function(newState) {
                if (this.__appCurrentState === newState) return;

                this.__appCurrentState = newState;
                if (!this.__loadMask) {
                    this.__loadMask = new com.servicemax.client.ui.components.utils.LoadMask({
                        parent: this.__adminRoot
                    });
                }
                if (newState == "block") {                    
                    this.__loadMask.show({});
                    this.__loadMask.setZIndex(50000); // some high number
                } else if (newState == "unblock" && this.__loadMask !== null) {
                    if (this.__loadMask !== null) {
                        this.__loadMask.hide();
                    }
                }
            },

            reset: function() {
                this.getRoot().destroy();
                this.__adminRoot = null;
                this.run(this.options);
            },

			triggerEvent: function(evt) {
				this.getEventBus().triggerEvent(evt);
			},

			loadTheme: function() {
				this.__themeService = SVMX.getClient().getServiceRegistry().getService("com.servicemax.client.themeservice").getInstance();
				this.__themeService.loadTheme("TIMESHEET");
			},

			run: function() {
				//----Start-----Added for the story BAC-3268 to translate Date and DateTime component language based on user language by calling below event
				var userInfo = SVMX.toObject(SVMX.getClient().getApplicationParameter('svmx-timesheet-userinfo'));
                var client = SVMX.getClient();
                var evtUserInfo = SVMX.create('com.servicemax.client.lib.api.Event', 'GLOBAL.HANDLE_USER_INFO', this, userInfo);
                client.triggerEvent(evtUserInfo);
                //----End-----Added for the story BAC-3268 to translate Date and DateTime component language based on user language by calling below event
				
				var evtCol,
					eventList = [	
						
						SVMX.create("com.servicemax.client.lib.api.Event",
							"TIMESHEET.EVENT.GetBusinessHours", this, {request : {}}),

						SVMX.create("com.servicemax.client.lib.api.Event",
							"TIMESHEET.EVENT.GetAllTimezones", this, {request : {}}),

						SVMX.create("com.servicemax.client.lib.api.Event",
							"TIMESHEET.EVENT.GetObjectMappingAndSVMXRules", this, {request : {}}),

						SVMX.create("com.servicemax.client.lib.api.Event",
							"TIMESHEET.EVENT.GetWorkDetailOwnership", this, {request : {}}),

						SVMX.create("com.servicemax.client.lib.api.Event",
							"TIMESHEET.EVENT.GetPriorPeriods", this, {request : {fieldName: SVMX.OrgNamespace+"__SM_Prior_Timesheet_Periods__c", objName: SVMX.OrgNamespace+"__ServiceMax_Config_Data__c"}}),
						
						SVMX.create("com.servicemax.client.lib.api.Event",
							"TIMESHEET.EVENT.GetAllTimesheetProcess", this, {request : {}})
						
				 	];

				evtCol = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollection", this.getEventBus(), eventList);
				evtCol.triggerAll( function( col ) {

					var items = col.items();

					for( var i = 0; i < items.length; i++ ) {

						var item = items[i];

						if(item.type() == "TIMESHEET.EVENT.GetAllTimesheetProcess") {
							this.onGetAllTimesheetsComplete( item.response );
						}

						if(item.type() == "TIMESHEET.EVENT.GetBusinessHours") {
							this.onGetBusinessHours( item.response );
						}

						if(item.type() == "TIMESHEET.EVENT.GetObjectMappingAndSVMXRules") {
							this.onGetObjectMappingAndSVMXRules( item.response );
						}

						if(item.type() == "TIMESHEET.EVENT.GetWorkDetailOwnership") {
							this.onGetWorkDetailOwnership( item.response );
						}

						if(item.type() == "TIMESHEET.EVENT.GetAllTimezones") {
							this.onGetAllTimezones( item.response );
						}
						if(item.type() == "TIMESHEET.EVENT.GetPriorPeriods") {
							this.onGetPriorPeriods( item.response );
						}						
					}
					this.__root.unblockApplication();
				}, this);
			},

			onGetBusinessHours: function(data) {

				this.businessHours = data.businessHoursList;
			},

			onGetAllTimezones: function(data) {

				this.timezones = data.timezoneList;
			},

            onGetPriorPeriods: function(data) {

				this.priorperiods = data.priorPeriodList;
			},

			onGetObjectMappingAndSVMXRules: function(data) {

				this.workDetailsMappingList = data.workDetailsMappingList;
        		this.workDetailsRuleList = data.workDetailsRuleList;
        		this.taskMappingList = data.taskMappingList;
        		this.taskRuleList = data.taskRuleList;
        		this.eventMappingList = data.eventMappingList;
        		this.eventRuleList = data.eventRuleList;
        		this.servicemaxEventMappingList = data.servicemaxEventMappingList;
        		this.servicemaxEventRuleList = data.servicemaxEventRuleList;
			},

			onGetWorkDetailOwnership: function(data) {

				this.workDetailOwnership = data.workDetailOwnershipList;
			},

			onGetAllTimesheetsComplete: function(data) {

				this.timesheets = data.timesheetInfoList;
				this.profiles = data.profileAssociationList;	

				//------Start-----Added for the story BAC-5414
				var statusList = [];
				for(var key in data.tsHeaderStatusMap){
					var statusObject = {
						Id: key,
						tsHeaderStatus: data.tsHeaderStatusMap[key]
					};
					statusList.push(statusObject);
				}
				this.headerStatusList = statusList;
				//------End------Added for the story BAC-5414

				var options = {
					__engine: this
				};

				if(!this.__root){
					this.__root = this.__view.createComponent("ROOTCONTAINER", options);
				}
				this.__root.run();
			},

			//Added for the story BAC-5414
			getHeaderStatusMap: function() {
				return this.headerStatusList;
			},

			getTemplates: function() {
				return this.timesheets;
			},

			getProfiles: function() {
				return this.profiles;
			},

			getBusinessHours: function() {
				return this.businessHours;
			},

			getAllTimezones: function() {
				return this.timezones;
			},

            getPriorPeriods: function() {
				return this.priorperiods;
			},

			getWorkDetailOwnership: function() {
				return this.workDetailOwnership;
			},

			getWorkDetailsMappingList: function() {
				return this.workDetailsMappingList;
			},
        	
        	getWorkDetailsRuleList: function() {
        		return this.workDetailsRuleList;
        	},

        	getTaskMappingList: function() {
        		return this.taskMappingList;
        	},
        	
        	getTaskRuleList: function() {
        		return this.taskRuleList;
        	},

        	getEventMappingList: function() {
        		return this.eventMappingList;
        	},

        	getEventRuleList: function() {
        		return this.eventRuleList;
        	},

        	getServicemaxEventMappingList: function() {
        		return this.servicemaxEventMappingList;
        	},

        	getServicemaxEventRuleList: function() {
        		return this.servicemaxEventRuleList;
        	},
        	
			saveTimesheet: function(timesheet) {

				var responder = SVMX.create("com.servicemax.client.timesheet.commands.TimesheetResponder", {
					handler: this.onSaveTimesheetCompleted,
					context: this
				});

				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'TIMESHEET.EVENT.SaveTimesheetConfiguration', this, 
					{ request: timesheet, responder: responder }
				);

				this.triggerEvent(evt);
			},

			onSaveTimesheetCompleted: function(data) {

				if(data.success) {			
					this.run();
				} else {
					this.__root.unblockApplication();
					this.__root.onFailure(data.message);
				}
			},

			deleteTimesheets: function( processId ) {

				var responder = SVMX.create("com.servicemax.client.timesheet.commands.TimesheetResponder", {
					handler: this.onDeleteTimesheetsCompleted,
					context: this
				});

				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'TIMESHEET.EVENT.DeleteTimesheetProcess', this, 
					{ request: {timesheetProcessId: processId }, responder: responder }
				);

				this.triggerEvent(evt);
			},

			onDeleteTimesheetsCompleted: function(data) {

				if( data.success == false ) {

					this.__root.unblockApplication();
					this.__root.onFailure(data.message);
				}

				this.run();
			},

			executeBatch: function(processId, scheduleType){
                this.changeApplicationState("block");

                var responder = SVMX.create("com.servicemax.client.timesheet.commands.TimesheetResponder", {
					handler: this.onExecuteBatchCompleted,
					context: this
				});

				var request = {
					timesheetProcessId: processId,
					scheduleType: scheduleType
				};

				var evt = SVMX.create("com.servicemax.client.lib.api.Event", 'TIMESHEET.EVENT.ExecuteBatch', this, 
					{ request: request, responder: responder }
				);

                this.triggerEvent(evt);
            },

            onExecuteBatchCompleted: function(result, callback){
                this.changeApplicationState("unblock");   
                if(result.success) {			
					this.__root.onSuccess(result.message);
				} else {
					this.__root.onFailure(result.message);
				}
            },

			getRoot: function() {
                return this.__adminRoot;
            },

			onResize: function(size) {
                this.getRoot().resize(size);
            }
		});
	};
})();