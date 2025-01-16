({
    loadRecordType : function(component,event, helper) {
	    	component.set("v.CurrentUserId",$A.get("$SObjectType.CurrentUser.Id"));
			if($A.util.isUndefinedOrNull(component.get("v.pageReference"))
				|| $A.util.isUndefinedOrNull(component.get("v.pageReference").state)
				|| $A.util.isUndefinedOrNull(component.get("v.pageReference").state.recordTypeId)){ //codescanfix-A conditionally executed single line should be denoted by indentation
					component.set("v.RecordTypeId",'Community');
			}
	        else{
					component.set("v.RecordTypeId",component.get("v.pageReference").state.recordTypeId);
			}
            component.set("v.Closed",false);
            component.set("v.CheckLoad",true);
	    	
    }
})