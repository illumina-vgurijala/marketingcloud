/**
 * This file needs a description 
 * @class com.servicemax.client.automation.automationagent.impl
 * @singleton
 * @author unknown 
 * 
 * @copyright 2013 ServiceMax, Inc. 
 */

(function(){
	
	var automationAgentImpl = SVMX.Package("com.servicemax.client.automation.automationagent.impl");

automationAgentImpl.init = function(){
		
	automationAgentImpl.Class("AutomationAgent", com.servicemax.client.lib.api.Object, {
		__constructor : function(params){
			
		},
		
		_selectSingle : function(searchString, parent){
			var ret = this._selectAll(searchString, parent);
			if(ret.length > 0){
				ret = ret[0];
			}else{
				ret = null;
			}
			
			return ret;
		},
		
		_selectAll : function(searchString, parent){
			return Ext.ComponentQuery.query(searchString, parent);
		},
		
		fieldByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				ret = new automationAgentImpl.TextFieldAutomationItem({
					parent : parent, agent : this, target : ret
				});
			}
			
			return ret;	
		},
		
		fieldByTooltip : function(tooltip, parent){
			var searchString = '[tooltip=' + tooltip + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		checkboxByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		buttonByLabel : function(label, parent){
			var searchString = '[text=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		buttonByTooltip : function(tooltip, parent){
			var searchString = '[tooltip=' + tooltip + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		textareaByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		currencyByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		percentByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		emailByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		urlByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		phoneByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		numberByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				var retCls = this.__getAutomationItemTypeFor(ret);
				ret = new retCls({parent : parent, agent : this, target : ret});
			}
			return ret;	
		},
		
		lookupFieldByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				ret = new automationAgentImpl.LookupAutomationItem({
					parent : parent, agent : this, target : ret
				});
			}
			return ret;	
		},
		
		picklistByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				ret = new automationAgentImpl.PickListAutomationItem({
					parent : parent, agent : this, target : ret
				});
			}
			
			return ret;	
		},
		
		multipicklistByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				ret = new automationAgentImpl.MultiPickListAutomationItem({
					parent : parent, agent : this, target : ret
				});
			}
			
			return ret;	
		},
		
		datetimeByLabel : function(label, parent){
			var searchString = '[fieldLabel=' + label + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				ret = new automationAgentImpl.DatetimeAutomationItem({
					parent : parent, agent : this, target : ret
				});
			}
			
			return ret;	
		},
		
		windowByTitle : function(title){
			var searchString = 'window[title=' + title + ']';
			var ret = this._selectSingle(searchString);
			
			if(ret){
				ret = new automationAgentImpl.WindowAutomationItem({
					parent : null, agent : this, target : ret
				});
			}
			return ret;
		},
		
		tabByTitle : function(title, parent){
			var searchString = 'panel[title=' + title + ']';
			var ret = this._selectSingle(searchString, parent);
			
			if(ret){
				ret = new automationAgentImpl.TabAutomationItem({
					parent : parent, agent : this, target : ret
				});
			}
			return ret;
		},
		
		childByAlias : function(alias, index, parent){
			var searchString = '[alias=widget.' + alias + ']';
			var ret = this._selectAll(searchString, parent), target;
			if(ret.length > 0){
				target = ret[index];
				var retCls = this.__getAutomationItemTypeFor(target);
				ret = new retCls({parent : parent, agent : this, target : target});
			}else{
				ret = null;
			}
			return ret;
		},
		
		__getAutomationItemTypeFor : function(item){
			var controlsImpl = com.servicemax.client.ui.components.controls.impl;
			var compositesImpl = com.servicemax.client.ui.components.composites.impl;
			if(item instanceof controlsImpl.SVMXPicklist){
				return automationAgentImpl.PicklistAutomationItem;
			}else if(item instanceof controlsImpl.SVMXText){
				return automationAgentImpl.TextFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXButton){
				return automationAgentImpl.ButtonAutomationItem;
			}else if(item instanceof compositesImpl.SVMXToolbar){
				return automationAgentImpl.ToolbarAutomationItem;
			}else if(item instanceof compositesImpl.SVMXListComposite){
				return automationAgentImpl.ListAutomationItem;
			}else if(item instanceof controlsImpl.SVMXDatetime){
				return automationAgentImpl.DatetimeAutomationItem;
			}else if(item instanceof compositesImpl.SVMXTabPanel){
				return automationAgentImpl.TabAutomationItem;
			}else if(item instanceof compositesImpl.SVMXSection){
				return automationAgentImpl.SectionAutomationItem;
			}else if(item instanceof controlsImpl.SVMXCurrency){
				return automationAgentImpl.CurrencyFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXPercent){
				return automationAgentImpl.PercentFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXEmail){
				return automationAgentImpl.EmailFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXUrl){
				return automationAgentImpl.URLFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXPhone){
				return automationAgentImpl.PhoneFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXTextArea){
				return automationAgentImpl.TextAreaFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXNumber){
				return automationAgentImpl.NumberFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXCheckbox){
				return automationAgentImpl.CheckboxFieldAutomationItem;
			}else if(item instanceof controlsImpl.SVMXMultiSelectPicklist){
				return automationAgentImpl.MultiSelectPicklistFieldAutomationItem;
			}
			
		}
	}, {});	
	
	automationAgentImpl.Class("AutomationItemBase", com.servicemax.client.automation.automationclient.impl.AutomationItem, {
		
		__constructor : function(params){
			this.__base(params);
		}
	}, {});
	
	automationAgentImpl.Class("TextFieldAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		keysImpl : function(evtParams){
			this._target.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendKeysFromString(
				evtParams.strKeys, this._target.inputEl.dom);
		},
		
		clearValueImpl : function(evtParams){
			this._target.focus();
			if(evtParams == "DEL"){
				com.servicemax.client.automation.chromeutils.EventHelper.sendDeleteKey(this._target.inputEl.dom);
			}else if(evtParams == "BACKSPACE"){
				com.servicemax.client.automation.chromeutils.EventHelper.sendBackspaceKey(this._target.inputEl.dom);
			}
		}
		
	}, {});
	
	automationAgentImpl.Class("TextAreaFieldAutomationItem", automationAgentImpl.TextFieldAutomationItem, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("EmailFieldAutomationItem", automationAgentImpl.TextFieldAutomationItem, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("URLFieldAutomationItem", automationAgentImpl.TextFieldAutomationItem, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("PhoneFieldAutomationItem", automationAgentImpl.TextFieldAutomationItem, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("NumberFieldAutomationItem", automationAgentImpl.TextFieldAutomationItem, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("CurrencyFieldAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		keysImpl : function(evtParams){
			this._target.currencyValue.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendKeysFromString(
				evtParams.strKeys, this._target.currencyValue.inputEl.dom);
		}
	}, {});
	
	automationAgentImpl.Class("PercentFieldAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		keysImpl : function(evtParams){
			this._target.percentValue.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendKeysFromString(
				evtParams.strKeys, this._target.percentValue.inputEl.dom);
		}
	}, {});
	
	automationAgentImpl.Class("ButtonAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		clickImpl : function(evtParams){
			this._target.el.dom.click();
		}
	}, {});
	
	automationAgentImpl.Class("CheckboxFieldAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		checkImpl : function(evtParams){
			this._target.setValue(true);
		},
		
		unCheckImpl : function(evtParams){
			this._target.setValue(false);
		}
	}, {});
	
	automationAgentImpl.Class("LookupAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		submitImpl : function(evtParams){
			this._target.lookupText.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendEnterKey(this._target.lookupText.inputEl.dom);
		},
		
		keysImpl : function(evtParams){
			this._target.lookupText.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendKeysFromString(
				evtParams.strKeys, this._target.lookupText.inputEl.dom);
		}
	}, {});
	
	automationAgentImpl.Class("PickListAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		setValueImpl : function(evtParams){
			this._target.setValue(evtParams);
		},
		
		keysImpl : function(evtParams){
			this._target.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendKeysFromString(
				evtParams.strKeys, this._target.inputEl.dom);
		}
	}, {});
	
	automationAgentImpl.Class("MultiPickListAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		setValueImpl : function(evtParams){
			/*var i, l = evtParams.length, argsStr = "";
			for(i = 1; i < l; i++){
				argsStr += "arguments[" + i + "],";
			}
			this._target.setValue(argsStr);*/
		},
		
		keysImpl : function(evtParams){
			this._target.focus();
			com.servicemax.client.automation.chromeutils.EventHelper.sendKeysFromString(
				evtParams.strKeys, this._target.inputEl.dom);
		}
	}, {});
	
	automationAgentImpl.Class("DatetimeAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		setCurrentDatetimeImpl : function(evtParams){
			this._target.currentDatetimeBtn.el.dom.click();
		}
	}, {});
	
	automationAgentImpl.Class("WindowAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("ToolbarAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("TabAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		setActiveImpl : function(evtParams){
			var tab = this.tabByTitle(evtParams);
			this._target.setActiveTab(tab._target);
		}
		
	}, {});
	
	automationAgentImpl.Class("SectionAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		}
		
	}, {});
	
	automationAgentImpl.Class("ListAutomationItem", automationAgentImpl.AutomationItemBase, {
		
		__constructor : function(params){
			this.__base(params);
		},
		
		getCount : function(){
			return 0;
		},
		
		select : function(row){
			// need a better way of selecting a list row
			this._target.getSelectionModel().select(0);
		}
	}, {});
}	
})();

// end of file