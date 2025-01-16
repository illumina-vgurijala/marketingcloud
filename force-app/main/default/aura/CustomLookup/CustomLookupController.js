({
   onfocus : function(component,event,helper){
        $A.util.addClass(component.find("mySpinner"), "slds-show");
        let forOpen = component.find("searchRes");
        $A.util.addClass(forOpen, 'slds-is-open');
        $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC  
        let getInputkeyWord = '';
        helper.searchHelper(component,event,getInputkeyWord);
    },
    onblur : function(component,event,helper){       
        component.set("v.lstListOfSearchRecords", null );
        let forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    keyPressController : function(component, event, helper) {
       // get the search Input keyword   
       let getInputkeyWord = component.get("v.strSearchKeyWord");
       // check if getInputKeyWord size id more then 0 then open the lookup result List and 
       // call the helper 
       // else close the lookup result List part.   
      if( getInputkeyWord.length > 0 ){
			  let forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
      }else{  
            component.set("v.lstListOfSearchRecords", null ); 
            let forclose = component.find("searchRes");
            $A.util.addClass(forclose, 'slds-is-close');
            $A.util.removeClass(forclose, 'slds-is-open');
      }
	},
    
  // function for clear the Record Selaction 
    clear :function(component,event,heplper){
         let pillTarget = component.find("lookup-pill");
         let lookUpTarget = component.find("lookupField"); 
        
         $A.util.addClass(pillTarget, 'slds-hide');
         $A.util.removeClass(pillTarget, 'slds-show');
        
         $A.util.addClass(lookUpTarget, 'slds-show');
         $A.util.removeClass(lookUpTarget, 'slds-hide');
      
         component.set("v.strSearchKeyWord",null);
         component.set("v.lstListOfSearchRecords", null );
         component.set("v.objSelectedRecord", {} );   
    },
    
  // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {
    // get the selected Account record from the COMPONETN event 	 
        let selectedAccountGetFromEvent = event.getParam("objRecordByEvent");        
	    component.set("v.objSelectedRecord" , selectedAccountGetFromEvent); 
       
          let forclose = component.find("lookup-pill");
           $A.util.addClass(forclose, 'slds-show');
           $A.util.removeClass(forclose, 'slds-hide');
  
          forclose = component.find("searchRes");
           $A.util.addClass(forclose, 'slds-is-close');
           $A.util.removeClass(forclose, 'slds-is-open');
        
        let lookUpTarget = component.find("lookupField");
            $A.util.addClass(lookUpTarget, 'slds-hide');
            $A.util.removeClass(lookUpTarget, 'slds-show');
        let etcompEventCampaignSelected = component.getEvent("etCampaignSelected");
        etcompEventCampaignSelected.setParams({"EventSelected" : "True" }); 
		etcompEventCampaignSelected.fire();      
	},
})