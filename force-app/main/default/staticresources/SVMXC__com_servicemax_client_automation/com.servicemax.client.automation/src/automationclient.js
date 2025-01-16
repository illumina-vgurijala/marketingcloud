/**
 * This file needs a description 
 * @class com.servicemax.client.automation.automationclient.impl
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var automationClientImpl = SVMX.Package("com.servicemax.client.automation.automationclient.impl");
	
	automationClientImpl.Class("AutomationClient", com.servicemax.client.lib.api.Object, {
		__params : null, __rootAutomationItem : null, _logger : null, _currentTestSuite : null, 
		_currentTestCase : null, __logTarget : null,
		__constructor : function(params){
			this.__params = params;

			// set up the static instance
			automationClientImpl.AutomationClient.instance = this;
			
			// set up automation agent
			// !! TODO should discover dynamically !! 
			var agent = new com.servicemax.client.automation.automationagent.impl.AutomationAgent();
			
			// set up the root automation item
			this.__rootAutomationItem = new automationClientImpl.AutomationItem({agent : agent, target : params.root});
			
			// set up the log target
			this.__logTarget = new automationClientImpl.AutomationLogTarget();
			
			this._logger = SVMX.getLoggingService().getLogger("SVMX-AUTOMATION");
		},
		
		startTestSuite : function(tsInfo){
			this._currentTestSuite = tsInfo;
			this._logger.info("Starting TestSuite: " + this._currentTestSuite);
		},
		
		endTestSuite : function(){
			this._logger.info("Ending TestSuite: " + this._currentTestSuite);
			this._currentTestSuite = null;
		},
		
		startTestCase : function(tcInfo){
			this._currentTestCase = tcInfo;
			this._logger.info("Starting TestCase: " + this._currentTestCase);
		},
		
		endTestCase : function(){
			this._logger.info("Ending TestCase: " + this._currentTestCase);
			this._currentTestCase = null;
		},
		
		assertFalse : function(value, message){
			if(value == false){
				this._logger.error("Assert failed: " + message);	
			}
		},
		
		waitFor : function(seconds, callback){
			this._logger.info("Waiting for " + seconds + " second(s)...");
			var timeout = seconds * 1000;
			setTimeout(function(){
				callback();
			}, timeout);
		},
		
		getRootAutomationItem : function(){
			return this.__rootAutomationItem;
		},
		
		run : function(options){
			
			this.__logTarget.show();
			
			if(options.tsPath){
				var loader = com.servicemax.client.lib.services
								.ResourceLoaderService.getInstance().createResourceLoader();
				loader.bind("LOAD_COMPLETE", this.__configLoadSuccess, this);
				loader.bind("LOAD_ERROR", this.__configLoadError, this);
				loader.loadAsync({url : options.tsPath, responseType : "text"});
			}
		},
		
		__configLoadSuccess : function(rle){
			
			var steps = this.__prepareSteps(rle.data);
			eval(steps);
		},
		
		__configLoadError : function(rle){
			// YUI Compressor cribs
			//debugger;
		},
		
		__prepareSteps : function(steps){
			return steps;
		}
	}, {
		instance : null // there can be only one instance of automation client at any point in time!
	});
	
	automationClientImpl.Class("AutomationItem", com.servicemax.client.lib.api.Object, {
		_parent : null, _automationAgent : null, _target : null, _logger : null, searchedBy : null,
		__constructor : function(params){
			this._parent = params.parent;
			this._automationAgent = params.agent;
			this._target = params.target;
			this._logger = SVMX.getLoggingService().getLogger("SVMX-AUTOMATION");
		},
		
		fieldByLabel : function(label){ 
			var ret = this._automationAgent.fieldByLabel(label, this._target); 
			
			if(ret){
				ret.searchedBy = label + "<field-label>";
			}else{
				// throw error
			}
			
			return ret;
		},
		
		fieldByTooltip : function(label){ 
			var ret = this._automationAgent.fieldByLabel(label, this._target); 
			
			if(ret){
				ret.searchedBy = label + "<field-tooltip>";
			}else{
				// throw error
			}
			
			return ret;
		},
		
		checkboxByLabel : function(label){ 
			var ret = this._automationAgent.checkboxByLabel(label, this._target); 
			
			if(ret){
				ret.searchedBy = label + "<checkbox-label>";
			}else{
				// throw error
			}
			
			return ret;
		},
		
		buttonByLabel : function(label){ 
			var ret = this._automationAgent.buttonByLabel(label, this._target); 
			
			if(ret){
				ret.searchedBy = label + "<button-label>";
			}else{
				// throw error
			}
			
			return ret;
		},
		
		buttonByTooltip : function(tooltip){ 
			var ret = this._automationAgent.buttonByTooltip(tooltip, this._target); 
			
			if(ret){
				ret.searchedBy = tooltip + "<button-tooltip>";
			}else{
				// throw error
			}
			
			return ret;
		},
		
		currencyByLabel : function(label){ 
			var ret = this._automationAgent.currencyByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<currency-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		percentByLabel : function(label){ 
			var ret = this._automationAgent.percentByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<percent-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		emailByLabel : function(label){ 
			var ret = this._automationAgent.emailByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<email-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		urlByLabel : function(label){ 
			var ret = this._automationAgent.urlByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<url-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		phoneByLabel : function(label){ 
			var ret = this._automationAgent.phoneByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<phone-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		lookupFieldByLabel : function(label){ 
			var ret = this._automationAgent.lookupFieldByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<lookup-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		picklistByLabel : function(label){ 
			var ret = this._automationAgent.picklistByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<picklist-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		multipicklistByLabel : function(label){ 
			var ret = this._automationAgent.multipicklistByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<multipicklist-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		textareaByLabel : function(label){ 
			var ret = this._automationAgent.textareaByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<textarea-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		numberByLabel : function(label){ 
			var ret = this._automationAgent.numberByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<number-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		datetimeByLabel : function(label){ 
			var ret = this._automationAgent.datetimeByLabel(label, this._target);
			
			if(ret){
				ret.searchedBy = label + "<datetime-label>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		windowByTitle : function(title){ 
			var ret = this._automationAgent.windowByTitle(title);
			
			if(ret){
				ret.searchedBy = title + "<window-title>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		tabByTitle : function(title){ 
			var ret = this._automationAgent.tabByTitle(title, this._target);
			
			if(ret){
				ret.searchedBy = title + "<tabpanel-title>";
			}else{
				// throw error
			}
			
			return ret; 
		},
		
		childByAlias : function(alias, index){
			if(index === undefined) index = 0;
			
			var ret = this._automationAgent.childByAlias(alias, index, this._target);
			
			if(ret){
				ret.searchedBy = alias + "<child-alias>";
			}else{
				// throw error
			}
			
			return ret;
		},
		
		setAutomationAgent : function(agent){ this._automationAgent = agent; },
		getParent : function(){ return this._parent; },
		clickImpl : function(evtParams){},
		keysImpl : function(evtParams){},
		clearValueImpl : function(evtParams){},
		submitImpl : function(evtParams){},
		setValueImpl : function(evtParams){},
		setActiveImpl : function(evtParams){},
		setCurrentDatetimeImpl : function(evtParams){},
		checkImpl : function(evtParams){},
		unCheckImpl : function(evtParams){},
		getId : function(){ return this.searchedBy; },
		
		click : function(evtParams){ 
			this._logger.info("Executing click() on : " + this.getId());
			this.clickImpl(evtParams); 
		},
		
		keys : function(evtParams){
			this._logger.info("Executing keys() on : " + this.getId()); 
			this.keysImpl(evtParams); 
		},
		
		clearValue : function(evtParams){
			this._logger.info("Executing clearValue keys() on : " + this.getId()); 
			this.clearValueImpl(evtParams); 
		},
		
		submit : function(evtParams){ 
			this._logger.info("Executing submit() on : " + this.getId());
			this.submitImpl(evtParams); 
		},
		
		setValue : function(evtParams){
			this._logger.info("Executing setValue() on : " + this.getId());
			this.setValueImpl(evtParams);
		},
		
		setActive : function(evtParams){
			this._logger.info("Executing setActive() on : " + this.getId());
			this.setActiveImpl(evtParams);
		},
		
		setCurrentDatetime : function(evtParams){
			this._logger.info("Executing setCurrentDatetime() on : " + this.getId());
			this.setCurrentDatetimeImpl(evtParams);
		},
		
		check : function(evtParams){
			this._logger.info("Executing check() on : " + this.getId());
			this.checkImpl(evtParams);
		},
		
		unCheck : function(evtParams){
			this._logger.info("Executing unCheck() on : " + this.getId());
			this.unCheckImpl(evtParams);
		}
	}, {});
	
	automationClientImpl.Class("AutomationLogTarget", com.servicemax.client.lib.services.AbsractLogTarget, {
		__ui : null,
		__constructor : function(options){
			this.__base(options);
		},
		
		log : function(message, options){
			
			if(options.source != "SVMX-AUTOMATION") return;
			
			var type = options.type;

			if(message instanceof Error){
				message = message.stack ? message.stack.toString() : message.toString();
			}
			
			message = type + ": " + message;
			var ui = this.__ui.getComponent(0), val = ui.getValue();
			ui.setValue(val + "\n" + message);
			ui.selectText(ui.getValue().length);
		},
		
		show : function(){
			this.__ui = SVMX.create("com.servicemax.client.ui.components.composites.impl.SVMXWindow", {
				width : 500, height : 200, title : "Automation Log", layout : {type: 'fit'},
				items : [{xtype : "svmx.textarea"}]
			});
			this.__ui.show();
			this.__ui.setZIndex(75000);
		},
		
		clear : function(){
			// TODO:
		},
		
		close : function(){
			// TODO:
		}
	}, {});
	
	function fieldByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().fieldByLabel(label);
	}
	
	function checkboxByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().checkboxByLabel(label);
	}
	
	function buttonByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().buttonByLabel(label);
	}
	
	function buttonByTooltip(tooltip){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().buttonByTooltip(tooltip);
	}
	
	function currencyByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().currencyByLabel(label);
	}
	
	function percentByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().percentByLabel(label);
	}
	
	function emailByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().emailByLabel(label);
	}
	
	function urlByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().urlByLabel(label);
	}
	
	function phoneByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().phoneByLabel(label);
	}
	
	function fieldByTooltip(tooltip){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().fieldByTooltip(tooltip);
	}
	
	function lookupFieldByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().lookupFieldByLabel(label);
	}
	
	function textareaByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().textareaByLabel(label);
	}
	
	function picklistByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().picklistByLabel(label);
	}
	
	function multipicklistByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().multipicklistByLabel(label);
	}
	
	function numberByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().numberByLabel(label);
	}
	
	function datetimeByLabel(label){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().datetimeByLabel(label);
	}
	
	function windowByTitle(title){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().windowByTitle(title);
	}
	
	function tabByTitle(title){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().tabByTitle(title);
	}
	
	function childByAlias(alias, index){
		return automationClientImpl.AutomationClient
				.instance.getRootAutomationItem().childByAlias(alias, index);
	}
	
	function waitFor(seconds, callback){
		return automationClientImpl.AutomationClient
				.instance.waitFor(seconds, callback);
	}
	
	function startTestSuite(tsInfo){
		return automationClientImpl.AutomationClient
				.instance.startTestSuite(tsInfo);
	}
	
	function endTestSuite(){
		return automationClientImpl.AutomationClient
				.instance.endTestSuite();
	}
	
	function startTestCase(tcInfo){
		return automationClientImpl.AutomationClient
				.instance.startTestCase(tcInfo);
	}
	
	function endTestCase(){
		return automationClientImpl.AutomationClient
				.instance.endTestCase();
	}
	
	function assertFalse(value, message){
		return automationClientImpl.AutomationClient
				.instance.assertFalse(value, message);
	}
})();

// end of file
