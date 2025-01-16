/**
*    @author Adyasha Satapathy
*    @date   2021-05-06
*    @description    DCP-38809, DCP-39763: Automate Validate Cart Real time Callout to SAP
*    Modification Log:
*    Test coverage 75% :-TestApttusPricingCallBack, TestPricingAndValidationCallback, TestQuoteApprovalQueueable, 
                    TestQuoteGenerationQueueable, TestValidateQuoteAutomation
    Test coverage 90% :-TestApttusPricingCallBack, TestPricingAndValidationCallback, TestQuoteApprovalQueueable, 
                    TestQuoteGenerationQueueable, TestValidateQuoteAutomation
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-05-06            Initial Version
*         KD                           2021-05-10            DCP-46472 : Error handling 
*         Arif,Dalali                  2022-09-12            CMSI-205 Instrumentation 
---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ValidateQuoteAutomation implements IOpportunityQuoteAutomation
{
    private Id configurationId;
    private Id proposalId;
    private Boolean boolIsDirectSaleToUC = false;
    public static Boolean boolIsQuoteAutomated = false;
    Apttus_Config2__ProductConfiguration__c objConfig;
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.CART_LINE_CREATED;
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'ValidateQuoteAutomation';
    public static Boolean catchException = false;
    /**
    *   DCP-38809
    *   @author Adyasha Satapathy
    *   @param NA
    *   @return Id of configuration
    **/
    public Id getRecordId()
    {
        return configurationId;
    }

    /**
    *   DCP-38809
    *   @author Adyasha Satapathy
    *   @param Quote Id
    *   @return void
    **/
    public void setRecordId(Id parentRecordId)
    {
        this.proposalId = parentRecordId;
    }

    /**
    *   DCP-46472 
    *   @author Adyasha Satapathy
    *   @param NA
    *   @return OpportunityQuoteAutomationQueueable.EmailWrapper
    **/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        ilib_LogEvent.push(LOG_TITLE + '.getErrorDetails()');
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails= new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.setErrorDetails(strErrorMessage);
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.CART_VALIDATION_BLOCKED) ? Label.OpportunityQuoteAutomation_CART_VALIDATION_BLOCKED : Label.OpportunityQuoteAutomation_OTHER;
        ValidateQuoteAutomation.handleErrorValidateApproval(proposalId,wrapDetails);
        ilib_LogEvent.info('wrapDetails: '+wrapDetails); 
        ilib_LogEvent.pop();
        return wrapDetails;
    }

    /**
    *   DCP-46472 
    *   @author KD
    *   @param Id idQuotation, OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails
    *   @return void
    **/
    public static void handleErrorValidateApproval(Id idQuotation, OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails){

        ilib_LogEvent.push(LOG_TITLE + '.handleErrorValidateApproval()');
        ilib_LogEvent.info('idQuotation : ' +idQuotation);
        Apttus_Proposal__Proposal__c objProposal=new ApttusProposalsSelector().selectById(new Set<Id>{idQuotation}).get(0);
        wrapDetails.idRecord=idQuotation;
        wrapDetails.setEmail(objProposal.Work_Order__r.OwnerId);
        wrapDetails.idProposal=idQuotation;
        wrapDetails.idSourceWorkOrder=objProposal.Work_Order__c;
        wrapDetails.strQuoteName = objProposal.Name;
        wrapDetails.strWOName=objProposal.Work_Order__r.Name;
        wrapDetails.strRegion=objProposal.Work_Order__r.Account_Region__c;
        ilib_LogEvent.info('wrapDetails: '+wrapDetails); 
        ilib_LogEvent.pop();
    }

    /**
    *   DCP-38809
    *   @author Adyasha Satapathy
    *   @param QueueableContext
    *   @return void
    **/
    public void execute(QueueableContext context)
    {
        ilib_LogEvent.setTitle(Log_Title,ilib_LogEvent.SALES); 
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        try
        {
            fetchProposalDetails();
            callSAP();
            ilib_LogEvent.info('configurationId: ' +configurationId);
            if(catchException == true){
                throw new AuraHandledException('throwing custom exceptions');
            }
        
        }
        catch(Exception e)
        {
            configurationId = null;
            ilib_LogEvent.info('ValidateQuoteAutomation exception' +e); 
            ApexExceptions.emit(LOG_TITLE,proposalId, e, ilib_LogEvent.SALES); 
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }
       
        ilib_LogEvent.pop();
        ilib_LogEvent.emit(); 
    }

    /**
    *   DCP-38809
    *   @author Adyasha Satapathy
    *   @description Fetch Quote Details
    *   @param NA
    *   @return NA
    **/
    public void fetchProposalDetails()
    {
        ilib_LogEvent.push(LOG_TITLE + '.fetchProposalDetails()');
        objConfig = new ApttusProductConfigurationsSelector().selectProductConfigurationByQuotIds(new Set<Id>{proposalId})[0];
        ilib_LogEvent.info('@@@@fetchProposalDetails, value of config ' +objConfig);
        if(objConfig == null){ return;}
        boolIsDirectSaleToUC = objConfig.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c;
        configurationId = objConfig.Id;
        ilib_LogEvent.pop();
    }

    /**
    *   DCP-38809
    *   @author Adyasha Satapathy
    *   @description calls SAP method of ApttusCheckPriceBaseClass
    *   @param NA
    *   @return NA
    **/
    public void callSAP()
    {
        ilib_LogEvent.push(LOG_TITLE + '.callSAP()');
        boolIsQuoteAutomated = true;
        ilib_LogEvent.info('boolIsQuoteAutomated : ' +boolIsQuoteAutomated);
        ApttusCheckPriceBaseClass baseClassInstance = new ApttusCheckPriceBaseClass(configurationId);
        String validationValues = baseClassInstance.callSAP(boolIsDirectSaleToUC);
        Boolean boolHasError = Boolean.valueOf(validationValues.substringBefore('@'));
        if(validationValues.contains('*'))
        {
            strErrorMessage = validationValues.substringBetween('_','*');
        }
        else { 
            strErrorMessage = validationValues.substringBetween('_','#');
        }

        ilib_LogEvent.info('boolHasError ----'+boolHasError); 
        ilib_LogEvent.info('strErrorMessage ----'+strErrorMessage); 

        if(boolHasError) 
        {
            configurationId = null;
            status = OpportunityQuoteAutomationQueueable.STATUS.CART_VALIDATION_BLOCKED;
            ilib_LogEvent.info('configurationId : ' +configurationId);
        }
        else 
        {
            repriceCartBillFlow();
        }
        ilib_LogEvent.pop();
    }

    /**
    *   DCP-38809
    *   @author Adyasha Satapathy
    *   @description calls reprice Cart of ApttusCheckPriceBaseClass
    *   @param NA
    *   @return NA
    **/    
    public void repriceCartBillFlow()
    {
        ilib_LogEvent.push(LOG_TITLE + '.repriceCartBillFlow()');
        Boolean boolPricingCompleted = ApttusCheckPriceBaseClass.repriceCart(configurationId);
        ilib_LogEvent.info('boolPricingCompleted : '+boolPricingCompleted); 
        if(boolPricingCompleted)
        {
            status=OpportunityQuoteAutomationQueueable.STATUS.CART_VALIDATED;
        }
        else 
        {
            configurationId = null;
            status=OpportunityQuoteAutomationQueueable.STATUS.CART_VALIDATION_BLOCKED;
        }
        ilib_LogEvent.info('configurationId : ' +configurationId);
        ilib_LogEvent.pop();
    }
}