/**
 * This file needs a description
 * @class com.servicemax.client.sfmconsole.api
 * @singleton
 * @author unknown
 *
 * @copyright 2013 ServiceMax, Inc.
 */
(function(){

	// This package will be used by any subclass of AbstractConsoleApp.
	// WARNING: If your subclass will have its own subclasses, make it an Abstract class
	// and do NOT make it part of this package.
	SVMX.Package("com.servicemax.client.sfmconsole.ui");

	// The Real package for this class
	var clientConsoleApi = SVMX.Package("com.servicemax.client.sfmconsole.api");
	clientConsoleApi.Class("AbstractConsoleApp", com.servicemax.client.lib.api.Object, {
		__parent                    : null,
		__windowTitle               : null,
		__callbackContext           : null,
		__windowId                  : null,
		__options					: null,

		__constructor : function(inParams){
			this.__parent = inParams.parent;
			this.__options = inParams.options;
			this.__appConfig = inParams.appConfig;
			this.__windowId = this.__generateWindowId();
		},

		/*
		 * All window Ids come from this one method, which means changing this one method should redefine windowIds
		 * throughout the application
		 */
		__generateWindowId : function(consoleAppContainer, consoleAppInfo) {
		    return clientConsoleApi.AbstractConsoleApp.getNextId();
		},


		/*
		 * Basic accessors
		 */
		getId : function() {return this.__windowId;},


		// *** INterface to the App's configuration

		/** */
		getAppTypeId : function() {return this.__appConfig.app.id;},

		/** */
		getAppConfig : function() {return this.__appConfig;},

		/** */
		isSingleton : function() {return !this.__appConfig.multiple;},

		// *** Interface to the dom node for this console app ***

		/** */
		show : function() {
	        SVMX.doLater(SVMX.proxy(this, "onShow")); // trigger an onShow event... later.
		},

		/** */
		hide : function() {
		    SVMX.doLater(SVMX.proxy(this, "onHide")); // trigger an onHide event... later.
		},

	    /** */
		isShowing : function() {
			throw "Subclass must implement isShowing";
		},

		/** */
		destroy : function() {
		},

		// Allows different ConsoleAppImpl subclasses to trigger behaviors before and after
		// the start method is called
		__start: function(options) {
			this.start(options);
		},

		start : function() {

		},

		/**
		 * @public
		 * When a console wants to be closed, it calls request close and the Application
		 * will manage the process, including a call to onCanClose to verify that the
		 * app is ready to be closed
		 */
		requestClose : function () {
			this.__parent.destroyConsoleApp(this);
		},

		/**
		 * @public
		 * Subclasses of AbstractConsole should provide their own onCanClose which calls
		 * callback(true) if they are willing to be closed, callback(false) if they are not.
		 * Reasons for not being willing: User has unsaved changes, and perhaps was prompted
		 * if they wanted to leave the page and said "no".
		 */
		onCanClose : function (callback) {
			callback(true);
		},

		/**
		 * @event
		 * Subclasses override onClose to be notified when they are being closed so that they have time to clean up
		 * all resources and call destroy on anything needing destroying.
		 * The parent method is currently empty, but may be used to clean up resources at the window level
		 */
		onClose : function () {

		},

		/**
		 * @event
		 * Called immediately after this console app is hidden. Not called if its being hidden because its being destroyed;
		 * use onClose for that event.
		 */
		onHide : function() {


		},

		/**
		 * @event
		 * Called immediately after this console app is shown. Not called when it is being created; this is intended
		 * to restore any state or function disabled via onHide.
		 */
		onShow : function() {

		},

		showLoadMask : function(target) {
			this.__parent.showSpinner(target);
		},

		hideLoadMask : function(target) {
			this.__parent.hideSpinner();
		},

		getWindowId : function () {
			return this.__windowId;
		},

		// Window Titles only used by Laptop Client at this time
		// TODO: Move all calls to places only used by Laptop Client.
		setWindowTitle : function(title){
		},

		getWindowTitle : function () {
			return "";
		},


		setRootContainer : function (container) {
		},

		setAppInfo : function (options) {
			options = options || {};

			this.__windowTitle = options.windowTitle;

			this.__parent.applyAppInfo(this, options);
		}
	}, {
		lastId: 0,
		getNextId: function() {
			this.lastId++;
			return this.lastId;
		}
	});

	/**
	 * Passes all events triggered by SyncManager and also triggers events meant for user interactions
	 *
	 * SYNC_INFO_IMPL
	 * SYNC_ERROR_IMPL
	 * SYNC_FAILED_IMPL
	 * SYNC_STARTED_IMPL
	 * SYNC_PROGRESS_IMPL
	 * SYNC_COMPLETED_IMPL
	 * SYNC_GROUP_STARTED_IMPL
	 * SYNC_GROUP_COMPLETED_IMPL
	 * SYNC_EVENT_STARTED_IMPL
	 * SYNC_EVENT_COMPLETED_IMPL
	 * SYNC_EVENT_REQUEST_STARTED_IMPL
	 * SYNC_EVENT_REQUEST_COMPLETED_IMPL
	 * SYNC_ATTACHMENTS_STARTED_IMPL
	 * SYNC_ATTACHMENTS_COMPLETED_IMPL
	 *
	 * -- ADITIONAL EVENT TYPES --
	 *
	 * SYNC_PROFILE_ERROR_DIALOG
	 * SYNC_CONNECTION_ERROR_DIALOG
	 * SYNC_FAILED_DIALOG
	 * SYNC_FINISHED_INITIALIZING  -- triggered after SYnc has first started and the SFM Console can continue to initialize
	 *
	 * Upon receiving one of these events, a dialog should be displayed giving a user a choice
	 * of action. Upon user's selection the additional methods will need to be called on
	 * this object to complete the flow.
	 */
	clientConsoleApi.Class("AbstractSync", com.servicemax.client.lib.api.EventDispatcher, {
		__syncManager : null,
		__constructor : function(){},
		run : function() {},

		/**
		 * There was a connection error and user has chosen to retry
		 * To be called after a SYNC_CONNECTION_ERROR_DIALOG event
		 */
		connectionErrorRetry : function() {},

		/**
		 * There was a connection error and the user has chosen to cancel
		 * To be called after a SYNC_CONNECTION_ERROR_DIALOG event
		 */
		connectionErrorCancel : function() {},

		/**
		 * There was a sync failure error and the user has chosen to retry
		 * To be called after a SYNC_FAILED_DIALOG event
		 */
		failedErrorRetry : function() {},

		/**
		 * There was a sync failure error and the user has chosen to continue accepting the errors
		 * To be called after a SYNC_FAILED_DIALOG event
		 */
		failedErrorContinue : function() {},

		getSyncManager : function(){
			return this.__syncManager;
		}
	}, {});

	clientConsoleApi.Class("AbstractDeliveryEngine", com.servicemax.client.lib.api.Object, {

		__constructor : function(){

		},

		init: function() {
			// Do nothing, required by ExtJS UI Controller
		},

		destroy: function() {
			// Do nothing, required by ExtJS UI Controller
		},

		getView: function() {
			// Do nothing, required by ExtJS UI Controller
			return null;
		},

		initAsync : function(options){},

		run : function(options){},

		getInterface : function(){
			return this;
		}

	}, {});

	clientConsoleApi.Class("CompositionMetaModel", com.servicemax.client.lib.api.EventDispatcher, {
		_data : null, _parent : null, _children : null, isDisplayOnly : false,

		__constructor : function(data, parent, isDisplayOnly){
			this.__base();
			this._data = data;
			this._parent = parent;
			this._children = {};
			if(parent){
				this.isDisplayOnly = parent.isDisplayOnly;
			}else{
				this.isDisplayOnly = false;
			}
		},

		getChildNode : function(name){
			return this._children[name];
		},

		getData : function(){
			return this._data;
		},

		getRoot : function(){
			if(this._parent === null)
				return this;
			else
				return this._parent.getRoot();
		},

		resolveDependencies : function(){}

	}, {});

})();
