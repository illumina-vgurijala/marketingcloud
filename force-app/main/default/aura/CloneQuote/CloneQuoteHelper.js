({
	handleRecordUpdated : function(component,event){
        
        let objQuote = component.get('v.objTargetQuote');
        let recordId = component.get('v.recordId');
        let helper=this;
        let strErrorMsg = $A.get("$Label.c.UI_ErrorMessage_CloneInvalidQuote");

        if(objQuote.Invalid_Quote__c)
        	helper.showErrorAndQuit(component, helper,strErrorMsg);
        else{
        	let urlEvent = $A.get("e.force:navigateToURL");
            let navUrl = "/apex/Apttus_QPConfig__ProposalClone?Id="+recordId;
            urlEvent.setParams({"url":navUrl});
            urlEvent.fire();
        }
    },
        
    /*
    * @author Rahul Sharma
    * @date   30-Oct-2018
    * @description  show error and reload the page
    * 
    */
	 showErrorAndQuit: function (component, helper,strMessage) {
         setTimeout(function(){
             helper.showErrorToast(strMessage);
         }, '200')
         helper.redirectToPageURL('/'+component.get('v.recordId'));
     },
})