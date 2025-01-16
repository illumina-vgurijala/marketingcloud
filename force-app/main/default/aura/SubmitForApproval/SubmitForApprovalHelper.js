({
    loadRecord : function(component, helper) {
        // get record ID
        let recId = component.get("v.pageReference").state.c__recordId;
        component.set("v.recordId", recId);
        helper.callServer(component, "c.initiateSubmission",function(response) {
            console.log(response);
            if(response.toString().includes('Succesfull')){
                setTimeout(function(){
                    helper.showSuccessToast(response.toString(), 'dismissible');
                    window.location.replace("/lightning/r/Apttus__APTS_Agreement__c/"+recId+"/view");
                },'200')
            }else{   
                console.log(response.toString());
                setTimeout(function(){
                    helper.showErrorToast(response.toString(),'dismissible');
                    window.location.replace("/lightning/r/Apttus__APTS_Agreement__c/"+recId+"/view");
                },'200')
            }
        },{
            "ctxSObjectId" : recId
        });
    },
})