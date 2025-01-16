/**
 * SFW (wizard) data
 * 
 * @author Jon Kinsting
 */
(function(){
	
	var wizardData = SVMX.Package("com.servicemax.client.sfwdelivery.wizarddata");
	
wizardData.init = function(){
	/**
	 * SFW model
	 */
	SVMX.define("com.servicemax.client.sfwdelivery.wizarddata.SFWData",{
		extend : 'com.servicemax.client.lib.api.Object',
		alias : 'widget.sfw.data',
//		eventModel : "com.servicemax.client.sfmeventdelivery.ui.sfmcalendar.EventModel",
//		userId : null,
		
		constructor : function(config){
//			this.__logger = SVMX.getLoggingService().getLogger('SFM-CALENDAR');
			
			this.callParent([config]);
		},
		
		initComponent : function(){
//			this.superclass.initComponent.call(this);
//			
//			// apply user id to new events
//			this.on('eventadded', function(data){
//				if(this.userId){
//					data.record.set({OwnerId : 'USER-'+this.userId});
//				}
//			});
		}
	});
};
})();