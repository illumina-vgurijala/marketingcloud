({
    navigate : function(component, event, helper) {
        let recordId = component.get("v.recordId");
        var action = component.get("c.checkRecordAccess"); 
        action.setParams({
            oppId : recordId
            }); 
		helper.toggleSpinner(component.getSuper());
        action.setCallback(this,function(response){
            let state = response.getState();
            if(state === "SUCCESS"){
                let res = response.getReturnValue();
                if(res === "success"){
                	helper.showSuccessToast('Prices have been updated.');   
                }
                else if(res === "Quote Present Error"){
                    helper.showErrorToast('Products cannot be added or modified once a quote has been generated. Please contact your Partner Account Manager or Sales Operations.');
                }
                else if(res.includes('*#')){
                	res.replace('*#', '');
                    let strerror = res.substring(response.indexOf(',') + 1, res.lastIndexOf(':'));
                    helper.showErrorToast(strerror);
                }
                else if(res === "Pricing not available."){
                    helper.showErrorToast('Pricing not available.');
                }
                else{
                	helper.showErrorToast('You do not have access to edit the opportunity');        
                    }
                    
                setTimeout(function(){
                	location.reload();   
            	},3500);
            }
            else{
                helper.showErrorToast(response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})