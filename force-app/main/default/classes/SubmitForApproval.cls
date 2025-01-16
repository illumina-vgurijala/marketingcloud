/**
 *    @author Vignesh S
 *    @date   27-04-2020
 *    @description  Class to Submit agreement for Approvals.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                         Date                     Description
 *    Vignesh S                       27-04-2020            Initial Version
 *    ------------------------------------------------------------------------------------                     
 */
public with sharing class SubmitForApproval{
    /**
     *  @author  Vignesh S
     *  @description Method that calls Queuable class for submitting record for approval and locks record.Created for DCP-37225
     *  @return void
     **/
    @AuraEnabled
    public static string initiateSubmission(string ctxSObjectId){
        system.debug('====');
        try{
        Apttus__APTS_Agreement__c objAgr = new ApttusAgreementSelectors().selectAgreements(new set<ID>{ctxSObjectId})[0];
        if(objAgr.Is_Agreement_under_Approvals_submission__c != true){
            objAgr = new Apttus__APTS_Agreement__c();
            objAgr.Id = ctxSObjectId;
            objAgr.Is_Agreement_under_Approvals_submission__c = true;
            objAgr.Submission_Failed_Error_Message__c = Null;
            update objAgr;
        }
        
        Id jobId = system.enqueueJob(new QueuableSubmitForApprovals(ctxSObjectId));
        
        objAgr.Approval_Submission_Job_Id__c = jobId;
        Update objAgr;
            return Label.Agreement_submission_for_Approvals.replace('{0}','Succesfull');
        }catch(Exception e){
            system.debug(e.getMessage());
        	return Label.Agreement_submission_for_Approvals.replace('{0}','Failed')+e.getMessage() ;
        }
    }
}