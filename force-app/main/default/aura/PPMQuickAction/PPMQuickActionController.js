({
    doInit : function(component, event, helper) {
        if(component.get('v.booIsPageLoaded')){ //codescanfix-A conditionally executed single line should be denoted by indentation
		    helper.toggleSpinner(component.getSuper());
        }
    },
    changeGlobalLanguage : function(component, event, helper)    {
        let childCmp = component.find("idGlblLang");
        let sppmVal=component.get("v.strPostPrimaryMsg");
        let sProposalId=component.get("v.recordId");
        childCmp.set("v.booIsTextArea",component.get('v.setNonStandardPicklistValues').has(sppmVal));
        // call the aura:method in the child component
        childCmp.acceptppmValue(sppmVal,sProposalId);
    },
   handleRecordUpdated : function(component, event, helper){
        helper.handleRecordUpdated(component, event, helper);
    },

    validate:function(component, event, helper){
        helper.validate(component, event);
    },
    save : function(component, event, helper){
        helper.save(component, event);
    },
    
    cancel : function(component, event, helper){
        let closeEvent = $A.get("e.force:closeQuickAction");
        if(closeEvent){
            closeEvent.fire();
        } else{
            alert('force:closeQuickAction event is not supported in this Ligthning Context');
        }
    }
})