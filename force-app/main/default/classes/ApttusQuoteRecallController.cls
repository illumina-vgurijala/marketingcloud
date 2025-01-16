/**
* @author Deepesh Malhotra
* @date   2018-10-05
* @description    To recall Quote
* Modification Log:
* ------------------------------------------------------------------------------------ 
*       Deepesh Malhotra         2018-10-05            Original Version 
*       Indra Ganesan            2019-02-22            Added Exception Handling
*       Aman Tyagi               2022-03-31            CodeScan Fixes
*  ------------------------------------------------------------------------------------    
*/
public class ApttusQuoteRecallController {
    
    @AuraEnabled
    /*
    * @Author: Indra Ganesan
    * @Description : method for calling out quotation based on quotation id
    * @param  :  String quoteId
    * @return :  String
    */
    public Static String recallQuotation(String quoteId){
        
        Boolean result ;
        
        try {
            result=  Apttus_Approval.ApprovalsWebService.cancelApprovals('Apttus_Proposal__Proposal__c', quoteId); 
            List<Apttus_Proposal__Proposal__c> lstQuotation = new ApttusProposalsSelector().selectById(new Set<Id>{quoteId}); 
            system.debug('result' +result);        
            if(result && !lstQuotation.isEmpty())
                 lstQuotation.get(0).Apttus_Proposal__Approval_Stage__c = Label.QuoteStageDraft;
                 update lstQuotation;
                 return 'SUCCESS';
            
        }catch(Exception e){
                // ApexExceptions.emit('Aura:ApttusQuoteRecallController', quoteId, 'Error Occured while calling Recall button');
                 return 'The following exception has occurred:' + e.getMessage() + 'at line no' + e.getLineNumber();
       }
        
    }  
    
}