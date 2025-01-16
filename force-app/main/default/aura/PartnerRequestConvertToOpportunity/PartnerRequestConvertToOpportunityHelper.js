({
    
    retrieveProfilePageLayout:function(component,event,helper){
        let recordTypeID=component.get("v.recordTypeId");
        console.log("RecordtypeId-->"+recordTypeID);
        let finalName;
        
        let params = {
            RecordTypeID : recordTypeID,
            
        };
        helper.callServer(component,"c.getPageLayoutAssignment",function(response){
            let pageLayout = response;
            finalName="Opportunity-"+pageLayout.toString();
            component.set("v.pageLayoutName", finalName);
            let _self = this ;
            _self.loadPageLayourMetadata(component,helper);
        },params);
        
    },
    retrievePartnerAccount:function(component,event,helper){
        let prRecId = component.get("v.recordId");
        console.log(prRecId);
        
        let params = {
            RecID : prRecId,
            
        };
        helper.callServer(component,"c.getPartnerAccount",function(response){
            let pageLayout = response;
            
            component.set("v.PartnerAccountId", pageLayout.toString());
            console.log("---->"+"v.PartnerAccountId");
            let _self = this ;
            _self.retrieveProfilePageLayout(component,event,helper);
        },params);
        
        
    },
    retrieveOpportunityRecordTypeId:function(component,event,helper){
        let params = {
            MetaDataAPI : "Opportunity",
        };
        helper.callServer(component,"c.getOppRecordTypeId",function(response){
            let pageLayout = response;
            
            component.set("v.recordTypeId", pageLayout.toString());
            console.log("-helper--->"+pageLayout.toString());
            let _self = this ;
            _self.retrievePartnerAccount(component,event,helper);
            
        },params);
        
        
    },
    
    loadPageLayourMetadata : function(component, helper) {
        let params = {
            pageLayoutName : component.get("v.pageLayoutName"),            
        };
        helper.callServer(component,"c.getPageLayoutMetadata",function(response){
            let pageLayout = response;
            component.set("v.pageLayout", pageLayout);
        },params);
    },
    
    loadAccountDetails : function(component, helper) {
        let additonalParams=decodeURIComponent(helper.getURLQueryStringValues()['additionalParams']);
        let accountId=additonalParams.split("=")[2];
        accountId=accountId.substring(0,15);
        
        let params = {
            AccountId : accountId,            
        };
        helper.callServer(component,"c.getAccountDetails",function(response){
            component.set("v.Account", response);
        },params);
    },
    
	updateStatusPartnerRequest: function(component, event,oppID) {
        //var oppID = component.get('v.OpportunityId');
        console.log('Opportunity ID opp' + oppID);
        let action = component.get("c.updateStatusonPartnerRequest");
        action.setParams({OpportunityId :  oppID});
        action.setCallback(this,function(response) {
            let state = response.getState();
            console.log('Hello' +state);
        });

        $A.enqueueAction(action);
    },
	
    onsuccess : function(component, event, helper) {
        let params = event.getParams(); //get event params
        let recordId = params.response.id; //get record id
        console.log('Record Id - ' + recordId);
        component.set('v.OpportunityId',recordId);
        helper.updateStatusPartnerRequest(component, event,recordId);
        
    },
    isFormValid: function (cmp, evt, helper) {
        console.log("testing");
        const requiredFields = cmp.find('inputField') || [];
        let isValid = true;
        requiredFields.forEach(e => {
            //alert('vv--'+e.get('v.class'));
            if (e.get('v.class') == 'Required' && (e.get('v.value')=='' || e.get('v.value').trim().length==0 ) ) {
            
            isValid = false;
        }
                               });
        
        return isValid;
    },
    
})