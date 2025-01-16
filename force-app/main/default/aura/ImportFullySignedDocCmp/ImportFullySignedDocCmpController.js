({
    doInit : function(component, event, helper){
        let pageReference = component.get("v.pageReference");
        if(pageReference!==undefined && pageReference!==null && pageReference.state!=null)
        {
            let recordId=pageReference.state.c__recordId; 
            component.set("v.recordId",recordId);
        }
    },
    handleUploadFinished: function (component, event, helper) {
        // show spinner by toggling class
        let spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        //  call component helper function
        helper.updateStatus(component, event, helper);        
    }
})