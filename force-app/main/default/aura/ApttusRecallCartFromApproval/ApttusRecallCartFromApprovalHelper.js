({   
    
    recallQuote : function(component,event,helper) {
           
        let quote = component.get("v.objTargetProposal");
        if(quote.Apttus_Proposal__Approval_Stage__c === 'Draft' || quote.Apttus_Proposal__Approval_Stage__c === 'Approval Required' || quote.Apttus_Proposal__Approval_Stage__c === 'Approved' || quote.Apttus_Proposal__Approval_Stage__c === 'Rejected' || quote.Apttus_Proposal__Approval_Stage__c === 'Generated' || quote.Apttus_Proposal__Approval_Stage__c === 'Presented'){
            $A.get("e.force:closeQuickAction").fire();
              helper.showErrorToast('Recall is available only when a quote is In Review');
               
        }
        else if(quote.Apttus_Proposal__Approval_Stage__c === 'Accepted' || quote.Apttus_Proposal__Approval_Stage__c === 'Denied'){
            
             $A.get("e.force:closeQuickAction").fire();
              helper.showErrorToast('Cannot recall after quote is converted to an order');
        }
        else{
            
            let recordId = component.get("v.recordId");
            helper.callServer(component,"c.recallQuotation",function(response){
                
                if(response == 'SUCCESS'){              
                    $A.get('e.force:refreshView').fire(); 
                    $A.get("e.force:closeQuickAction").fire();
                }
            },{"quoteId": recordId},false,false);
            console.log(recordId);           
        }
        
    }
    
   
})