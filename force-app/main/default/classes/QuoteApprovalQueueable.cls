/**
*    @author Akshay Mohan
*    @date   2021-05-10
*    @description    DCP-38809: Check if Approval not required then auto approve
*    @Test Class for 75% coverage : TestQuoteApprovalQueueable
*    @Test Class for 90% coverage : TestQuoteApprovalQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-10         Initial Version
*         Anshaj Sinha            2022-09-14         CMSI-203 Instrumented Class for logging Framework
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class QuoteApprovalQueueable implements IOpportunityQuoteAutomation{
    private Id idQuotation,idQuoteOutput;
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.CART_SYNCED;
    @testVisible
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'QuoteApprovalQueueable';
    public static Boolean catchException = false;
    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return Id of quote
	**/
    public Id getRecordId(){
        return idQuoteOutput;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param Id of Quote
	*	@return void
	**/
    public void setRecordId(String idQuotation){
        this.idQuotation = idQuotation;   
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param NA
	*	@return OpportunityQuoteAutomationQueueable.EmailWrapper
	**/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        ilib_LogEvent.push(LOG_TITLE + '.getErrorDetails()');
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails = new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.setErrorDetails(strErrorMessage);
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.QUOTE_APPROVAL_BLOCKED) ? Label.OpportunityQuoteAutomation_QUOTE_APPROVAL_BLOCKED : Label.OpportunityQuoteAutomation_OTHER;
        ValidateQuoteAutomation.handleErrorValidateApproval(idQuotation,wrapDetails);
        ilib_LogEvent.pop();
        return wrapDetails;
    }

    /**DCP-38809
	*	@author Akshay Mohan
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext context){
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try{
            Apttus_Proposal__Proposal__c objProposal=new ApttusProposalsSelector().selectById(new Set<Id>{idQuotation}).get(0);
            ilib_LogEvent.info('Quote Record fetched : '+objProposal);
            //check if formula button is visible or not. If not visible block approval
            if(!ApttusProposalsService.isApprovalSubmitButtonVisible(objProposal)){
                strErrorMessage = objProposal.Submit_For_Approval__c;
                status = OpportunityQuoteAutomationQueueable.STATUS.QUOTE_APPROVAL_BLOCKED;
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }
            ilib_LogEvent.info('Submit for Approval button visible'); 
            //check if fields signifying approval is required are balnk or not. If not blank block approval
            if(String.isNotBlank(objProposal.Approval_Hierarchy_Transborder__c)
                || String.isNotBlank(objProposal.Approval_Hierarchy_Record_Owner__c)
                || String.isNotBlank(objProposal.Approval_Category__c) ){
                status = OpportunityQuoteAutomationQueueable.STATUS.QUOTE_APPROVAL_BLOCKED;
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }
            ilib_LogEvent.info('Approval not required'); 
            Apttus_Proposal__Proposal__c objUpdate = new Apttus_Proposal__Proposal__c(id=objProposal.id,
                                                            Apttus_QPApprov__Approval_Status__c=Label.QuotationApprovalStatusApproved,
                                                            Apttus_Proposal__Approval_Stage__c=Label.QuotationApprovalStatusApproved,
                                                            Is_Updated_By_System__c=true);
            update objUpdate;
            ilib_LogEvent.info('Approved'); 
            ilib_LogEvent.info('Record Updated : '+objUpdate);
            idQuoteOutput=objProposal.id;
            status = OpportunityQuoteAutomationQueueable.STATUS.QUOTE_APPROVED;
            if(catchException == true){
                throw new AuraHandledException('throwing custom exception');
            }
        }catch(Exception e){
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            strErrorMessage = e.getMessage();
            ApexExceptions.emit(LOG_TITLE,idQuotation,e, ilib_LogEvent.SALES);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
}