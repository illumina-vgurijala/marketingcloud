/**
*    @author Akshay Mohan
*    @date   2021-05-06
*    @description    DCP-38809: Perform SAP callout
*    @Test Class for 75% Coverage : TestQuoteGenerationQueueable
*    @Test Class for 90% Coverage : TestQuoteGenerationQueueable
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer               Date                Description
*         Akshay Mohan            2021-05-06          Initial Version
*         Anshaj Sinha            2022-09-16          CMSI-204 Instrumented class with latest changes in Logging Framework
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class QuoteGenerateSAPCallQueueable implements IOpportunityQuoteAutomation,Database.AllowsCallouts{
    private Id idQuotation,idQuoteOutput;
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.QUOTE_APPROVED;
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'QuoteGenerateSAPCallQueueable';
    public Boolean boolTestScenario=false;
    public Boolean catchException = false;
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
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATION_BLOCKED) ? Label.OpportunityQuoteAutomation_QUOTE_GENERATION_BLOCKED : Label.OpportunityQuoteAutomation_OTHER;
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
            ilib_LogEvent.info('objProposal: ' + objProposal); 
            //check if generate button is visible
            if(!ApttusProposalsService.isGenerateButtonVisible(objProposal)){
                strErrorMessage = objProposal.Generate__c;
                status = OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATION_BLOCKED;
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }
            ilib_LogEvent.info('Generate button visible'); 
            //check if generate SAP checks are fine
            if(!boolTestScenario){//in test class callout will fail
                new ApttusGenerateQuoteController(objProposal.id);
                ApttusGenerateQuoteController.reCheckPricing();
            }else if(ApttusGenerateQuoteController.boolHasError==null){//handle null
                ApttusGenerateQuoteController.boolHasError=false;
            }
            ilib_LogEvent.info('Generate SAP error: '+ApttusGenerateQuoteController.boolHasError); 
            if(ApttusGenerateQuoteController.boolHasError){
                strErrorMessage = ApttusGenerateQuoteController.strErrorMsg;
                status = OpportunityQuoteAutomationQueueable.STATUS.QUOTE_GENERATION_BLOCKED;
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return;
            }
            ilib_LogEvent.info('Generate SAP call successfull'); 
            idQuoteOutput=idQuotation;
            if(catchException == true){
                throw new AuraHandledException('throwing custom exception');
            }
        }catch(Exception e){
            strErrorMessage = e.getMessage();
            idQuoteOutput = null;
            ilib_LogEvent.error('Exception '+e);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            ApexExceptions.emit(LOG_TITLE,idQuotation,e);
        }
        ilib_LogEvent.pop(); 
        ilib_LogEvent.emit();
    }
}