({
    
    retrieveProfilePageLayout:function(component,helper){
        let recordTypeID=component.get("v.recordTypeId");
        let finalName;
        let params = {
            RecordTypeID : recordTypeID,
            
            };
        //changed for DCP-26543
        helper.callServer(component,"c.loadPage",function(response){
            response = JSON.parse(response);
            helper.consoleLog('Result: ',false,response);
            let pageLayout = response.name;
            component.set("v.mapLabels", response.mapLabels);
            finalName="Master_Data_Request__c-"+pageLayout.toString();
            component.set("v.pageLayoutName", finalName);
            helper.loadPageLayourMetadata(component,helper);
        },params);
        
    },

    loadPageLayourMetadata : function(component, helper) {
        let params = {
            pageLayoutName : component.get("v.pageLayoutName"),            
        	};
        helper.callServer(component,"c.getPageLayoutMetadata",function(response){
            let pageLayout = response;
            component.set("v.pageLayout", pageLayout);
            helper.loadAccountDetails(component,helper);
        },params);
    },

    loadAccountDetails : function(component, helper) {
        let AdditonalParams=decodeURIComponent(helper.getURLQueryStringValues()['additionalParams']);
        let AccountId=AdditonalParams.split("=")[2];
      	AccountId=AccountId.substring(0,15);
        component.set("v.strAccountId",AccountId);
        
        let params = {
            AccountId : AccountId,            
        };
        helper.callServer(component,"c.getAccountDetails",function(response){
            component.set("v.Account", response);
        },params);
    },

    //added for DCP-26543
    canSave : function(component, event, helper) {
        if(helper.isFormValid(component,event,helper)){
			return true;
		}else {
            helper.showDismissableError(helper,"Required Fields Missing");
            return false;
        }
    },
       
	isFormValid: function (cmp, evt, helper) {
        const requiredFields = cmp.find('inputField') || [];
        let isValid = true;
        requiredFields.forEach(e => {
            helper.consoleLog('Class--> '+e.get('v.class'));
            helper.consoleLog('Field--> '+e.get('v.value'));
            helper.consoleLog('Valid--> '+e.isValid());
            if(e.get('v.class') == 'Required' && 
               $A.util.isEmpty(e.get('v.value'))
              ) 
                isValid = false;
            
        });

        return isValid;
    },

    //added for DCP-26543
    showDismissableError: function (helper,strMessage) {
        helper.showErrorToast(strMessage,'dismissible',5000);
    },

    //added for DCP-26543
    showDismissableSuccess: function (helper,strMessage) {
        helper.showSuccessToast(strMessage,'dismissible',5000);
    }
   
})