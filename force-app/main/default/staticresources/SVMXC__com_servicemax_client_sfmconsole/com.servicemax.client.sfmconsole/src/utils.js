/**
 * This file needs a description
 * @class com.servicemax.client.sfmconsole.utils
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */

(function(){
	var sfmconsoleutil = SVMX.Package("com.servicemax.client.sfmconsole.utils");


	// These classes have been moved out of init due to the many files that depend upon them

	/**
	 * This class is responsible for managing the translation related activities
	 * Right now, it looks at the structure from SVMXC.COMM_TagsDefinition
	 */
	sfmconsoleutil.Class("Translation", com.servicemax.client.lib.api.Object, {
		__data  : null,
		__parent: null,
		__constructor : function(data, parent){
			this.__data = {};
			this.__data = this.__convertData(data);
			this.__parent = parent;
		},

		__convertData : function(data) {
			var result = {};
			if ($.isArray(data)) {
				var i, l = data.length;
				for(i = 0; i < l; i++){
					result[data[i].Key] = data[i].Value;
				}
			} else {
				result = data;
			}
			return result;
		},

		replaceData : function(data) {
			data = this.__convertData(data);
			$.extend(this.__data, data);
		},

		getTagArray : function() {
			var data = [];
			SVMX.forEachProperty(this.__data, function(inKey, inValue) {
				data.push({Key: inKey, Value: inValue});
			});
			return data;
		},

		isEmpty : function() {
		    for (var key in this.__data) {
		        return false;
		    }
		    return true;
		},

		T : function(key, defaultValue){
			if (key.match(/\./)) return this.__parent.T(key, defaultValue);
		    if (key in this.__data) {
			   return this.__data[key];
			} else {
			    return defaultValue || "";
			}
		}

	}, {});

	sfmconsoleutil.Class("TranslationService", com.servicemax.client.lib.api.Object, {
		__data : null,
		__hasData : false,
		__constructor : function(){
			this.__data = {};
		},

		addData : function(data, name) {
			this.__hasData = true;

			// There may already be pointers to this empty dictionary so update the object rather than replace with new object
			if (this.__data[name]) {
				this.__data[name].replaceData(data);
			} else {
				this.__data[name] = new sfmconsoleutil.Translation(data, this);
			}
		},

		/*
		 * Array of {module_id: x, tag_id: y, value: z}
		 */
		setData : function(data) {
			var result = {};

            // TODO: Remove true once the database is getting us the right data
            SVMX.array.forEach(data, function(inItem) {
                if (!result[inItem.module_id]) result[inItem.module_id] = {};
                result[inItem.module_id][inItem.tag_id] = inItem.value;
            });

            var commonData = result.COMMON || {};

            SVMX.forEachProperty(result, SVMX.proxy(this, function(inKey, inValue) {
                $.extend(inValue, commonData);
                this.addData(inValue, inKey);
            }));

		},

		isEmpty : function() {
		    return !this.__hasData;
		},

		getDictionary : function(name) {
			if (!this.__data[name]) this.__data[name] = new sfmconsoleutil.Translation({}, this);
			return this.__data[name];
		},

		T : function(key, defaultValue) {
			var index = key.indexOf(".");
			var dictionaryName = key.substring(0, index);
			key = key.substring(index + 1);
			var dictionary = this.getDictionary(dictionaryName);
			if (dictionary) {
				return dictionary.T(key, defaultValue);
			} else {
				return defaultValue;
			}
		}
	}, {});

sfmconsoleutil.init = function(){

	/**
	 * Use this class when want to batch a series of MVC events. All the events are processed
	 * simultaneously. The result of all the calls are made available on the callback handler.
	 */
	sfmconsoleutil.Class("EventCollection", com.servicemax.client.lib.api.Object,{
		__eventBus : null, __eventItems : null, __stackIndex : 0, __handler : null, __context : null,
		__constructor : function(eventBus, items){
			this.__eventBus = eventBus;
			this.__eventItems = [];
			this.__stackIndex = 0;

			for(var i = 0; i < items.length; i++){
				var ei = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollectionItem", items[i]);

				this.__eventItems[i] = ei;
				this.__eventItems[i].itemParent = this;
			}
		},

		addEvent : function(evt){
			var ei = SVMX.create("com.servicemax.client.sfmconsole.utils.EventCollectionItem", evt);

			this.__eventItems[this.__eventItems.length] = ei;
			this.__eventItems[this.__eventItems.length - 1].itemParent = this;
		},

		triggerAll : function(handler, context){
			this.__handler = handler;
			this.__context = context;

			// Some triggers may return immediately so lets sort out the count now
			// rather than incrementing the count as we trigger.
			this.__stackIndex = (this.__stackIndex + this.__eventItems.length);

			for(var i = 0; i < this.__eventItems.length; i++){
				this.__eventItems[i].trigger();
			}
		},

		handleResponse : function(eventItem){
			this.__stackIndex--;
			if(this.__stackIndex == 0){
				this.__handler.call(this.__context, this);
			}
		},

		getEventBus : function(){
			return this.__eventBus;
		},

		items : function(){
			return this.__eventItems;
		}
	},{});

	sfmconsoleutil.Class("EventCollectionItem", com.servicemax.client.mvc.api.Responder,{
		__event : null, response : null, itemParent : null,
		__constructor : function(event){
			this.__event = event;
			this.__event.data.responder = this;
		},

		trigger : function(){
			this.itemParent.getEventBus().triggerEvent(this.__event);
		},

		type : function(){
			return this.__event.type;
		},

		getEventObj : function(){
			return this.__event;
		},

		result : function(data) {
			this.response = data;
			this.itemParent.handleResponse(this);
		},

		fault : function(data) {
			var err = "Error during event <" + this.__event.type + ">";
			SVMX.getLoggingService().getLogger().error(err);
			throw new Error(err);
		}
	},{});

	/**
	 * Manages a state stack and provides state change events
	 */
	sfmconsoleutil.Class("StateService", com.servicemax.client.lib.api.EventDispatcher, {
		__state : null,
		__index : null,

		__constructor : function(){
			this.__state = [];
			this.__index = 0;
		},

		// TODO: All forward state should be cleared
		pushState : function(params){
			var stateParams = params.stateParameters || {};
			delete params.stateParameters;


			params.index = this.__index;

			// Previous version assumed we always add to end of stack, but since we don't
			// purge from stack when clicking back, and new items must go directly after
			// the current item, we now use the index.
			if (this.__state[this.__index]) this.__index++; //this.__state.length;

			var oldState = this.getState();
			this.__state[this.__index] = params;

			if (oldState && !stateParams.noEvent) {
				this.triggerStateDestroyed(oldState);
			}

			this.triggerStateChange();
			return this.getState();
		},

		replaceState : function(params){
			var stateParams = params.stateParameters || {};
			delete params.stateParameters;

			var oldState = this.getState();

			params.index = this.__index;
			this.__state[this.__index] = params;

			//To destroy console app, we need to trigger the destroy event
			// after the state is replaced and no longed used in the state manager
			if (oldState && !stateParams.noEvent) {
				this.triggerStateDestroyed(oldState);
			}

			if (!stateParams.noEvent) {
				this.triggerStateChange();
			}
			return this.getState();
		},

		modifyState : function(params){
			var stateParams = params.stateParameters || {};
			delete params.stateParameters;
			for(var key in params){
				this.__state[this.__index][key] = params[key];
			}

			if (!stateParams.noEvent) {
				this.triggerStateChange("STATE_MODIFIED");
			}
			return this.getState();
		},

		getState : function(index){
			var index = index === undefined ? this.__index : index;
			var state = this.__state[index];
			return state;
		},

		getPriorState : function() {
			if (this.__index > 0) {
				return this.getState(this.__index-1);
			} else {
				return null;
			}
		},

		getIndex : function(){
			return this.__index;
		},

		back : function(){
                        if(this.__index > 0) {
                            this.__index--;
                        }
			this.triggerStateChange();
		},

		forward : function(){
			this.__index++;
			this.triggerStateChange();
		},

		go : function(steps){
			this.__index += steps;
			this.triggerStateChange();
		},

		// Use this when the user has performed some operation that should clear the history.
		// FUTURE WORK: We may hold off on clearing the state until the next pushState call
		// to support a forward operation.
		reset : function() {
			this.__index = 0;
			var state = this.__state
			this.__state = [];
			SVMX.array.forEach(state, this.triggerStateDestroyed, this);

		},

		findByField : function(fieldName, fieldValue) {
			for (var i = this.__state.length-1; i >= 0; i--) {
				var item = this.__state[i];
				if (item[fieldName] == fieldValue) return item;
			}
			return false;
		},

		triggerStateChange : function(optionalType){
			var state = this.getState();
			var evt = new com.servicemax.client.lib.api.Event(optionalType || "STATE_CHANGE", this, state);
			return this.triggerEvent(evt);
		},

		// There should be no way to remove a state from the stack (or overwrite a state in the stack)
		// without first triggering an event notifying everyone that the state and any resources
		// it holds can be cleaned up.
		triggerStateDestroyed : function(state) {
			var evt = new com.servicemax.client.lib.api.Event("STATE_DESTROYED", this, state);
			return this.triggerEvent(evt);
		}
	}, {});


	/**
	 * ConnectionUtil - For Easy Connectivity Check
	 * Static Method.checkConnectivity
	 * Usage: com.servicemax.client.sfmconsole.utils.ConnectionUtil.checkConnectivity
	 *
	 * Returns a Deferred with the result or "false" as tring to the bound callback function
	 */
	sfmconsoleutil.Class("ConnectionUtil", com.servicemax.client.lib.api.Object,
		{

			__logger: null,

			__constructor: function () {
				this.__logger = SVMX.getLoggingService().getLogger("SFMDelivery : PlatformSpecifics");
			},
		},
		{
			checkConnectivity : function() {
				var d = SVMX.Deferred();
				var me = this;
				var params = {
					type: "CONNECTIVITY",
					method: "CHECKCONNECTIVITY"
				};
				var req = com.servicemax.client.offline.sal.model.nativeservice.Facade.createConnectivityRequest();
				req.bind("REQUEST_COMPLETED", function (evt) {
					d.resolve(evt.data.data);
				}, me);
				req.bind("REQUEST_ERROR", function (evt) {
					d.resolve("false");
				}, me);
				req.execute(params);
				return d;
			}
		}
	);

};

})();

// end of file