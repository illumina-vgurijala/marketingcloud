/**
 *    @author Vignesh S
 *    @date   27-04-2020
 *    @description  Class to Submit agreement for Approvals.
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                         Date                     Description
 *    Vignesh S                       27-04-2020            Initial Version
 *    Nishan Shetty                22-April-2022         CodeScan Fix-Avoid Literals in If condition. 
 *    Aman Tyagi                   12-Dec-2022           CodeScan Fixes
 *    ------------------------------------------------------------------------------------                     
 */
public without sharing class QueuableSubmitForApprovals implements Queueable {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ERROR_MSG_LENGTH = 255;
    //End CodeScan Fix
    
    public Id agrId;
	public static Boolean catchException = false;
    
    /**
     *  @author  Vignesh S
     *  @description Constructor to assign Agreement Id.Created for DCP-37225
     *  @return void
     **/
    public QueuableSubmitForApprovals(Id agrId){
        this.agrId = agrId;
    }
    
    /**
     *  @author  Vignesh S
     *  @description Method to Submit Agreement Record for Approvals.Created for DCP-37225
     *  @modification CMSI-38 Emitting exception to ApexExceptions class with Workstream.
     *  @return void
     **/
    public void execute(QueueableContext context) {
        Savepoint sp = Database.setSavepoint();
        try{
            Apttus_Approval.ApprovalsWebService.submitForApprovals( 'Apttus__APTS_Agreement__c',agrId);
			if(catchException == true){
			throw new AuraHandledException('Throwing Custom Exception');
			}
		}catch(Exception e){
            Database.rollback(sp);
            unlockrecord(agrId, e.getMessage());
            //CMSI-38 Emitting exception to ApexExceptions class with Workstream.
            ApexExceptions.emit('QueueableSubmitForApproval',e,ilib_LogEvent.getWorkstream());
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();            
            if(!Test.isRunningTest()) {
            	throw e;
            }
        }
    }
    
     /**
     *  @author  Vignesh S
     *  @description Method to unlock Agreement Record on failure of the submit Request.Created for DCP-37225
     *  @return void
     **/
    public void unlockrecord(Id agrId,string msg) {
        Apttus__APTS_Agreement__c objAgr = new Apttus__APTS_Agreement__c();
        objAgr.Id = agrId;
        objAgr.Is_Agreement_under_Approvals_submission__c = false;
        string errorMsg = system.Label.Agreement_Approval_Submission_Error+msg;
        if(errorMsg.length() > INTEGER_ERROR_MSG_LENGTH){
            errorMsg = errorMsg.substring(0,254);
        }
        objAgr.Submission_Failed_Error_Message__c = errorMsg;
        update objAgr;
        
        FeedItem post = new FeedItem();
        post.ParentId = agrId;
        post.Body = errorMsg;
        insert post;

    }
}
