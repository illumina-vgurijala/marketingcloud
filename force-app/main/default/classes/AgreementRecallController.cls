/**
*    @author Rishab Wali
*    @date   2020-08-11
*    @description  DCP-37233 Controller to Recall Pending Approval Request on Agreement
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Rishab Wali                 2020-08-11            Initial Version
*    Nesar Mohan                 2022-01-04            CodeScan Fix - Code Comments
*    ------------------------------------------------------------------------------------                  
*/
public without sharing class AgreementRecallController {
    
    public static final String AGREEMENTAPINAME = 'Apttus__APTS_Agreement__c';
    public static final String SUCCESS = 'SUCCESS';
        
    /*
    *  @author      : Rishab Wali
    *  @description : Method to cancel the approvals
    *  @param       : String
    *  @return      : String
    */
    @AuraEnabled
    public static String recallAgreement(String agreementId){
        
        //Boolean result;
        
        try {
            Apttus_Approval.ApprovalsWebService.cancelApprovals(AGREEMENTAPINAME, agreementId);           
            return SUCCESS;
            
        }catch(Exception e){
                 return System.Label.UI_Error_Message_Recall_Agreement;
       }
        
    }
}