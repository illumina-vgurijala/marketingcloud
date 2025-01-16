/**
 * @description       : 
 * @author            : Arquimidez Mora
 * @Modification Log  : 
 * Ver         Date             Author             Modification
 * 1.0      19-Sep-2024      Arquimidez Mora      Initial Version 
**/
public with sharing class GenerateQueueDocument implements Queueable, Finalizer, Database.AllowsCallouts {
    private List<QuoteCreationAPIOppCartWrapper> lstQuoteCreationWrapper = new List<QuoteCreationAPIOppCartWrapper>();
    private List<String> lstCartValidate = new List<String>();
    private  String aVALIDATECARTSTEP = 'Cart Validation';
    private  String aFINALIZECARTSTEP = 'Finalize Cart';
    private  String aSYNCCARTSTEP = 'Sync Cart';
    private  String aSTRINGPROTECTIONLEVEL = 'Read only';
    private  String aSTRINGDOCFORMAT = 'PDF';
    private  String aSTRINGAPISERVERURL = System.Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/60.0/' + UserInfo.getOrganizationId();
    private  String aSTRINGTEMPLATE = 'English_Direct';
    private static final String APPROVED = 'Approved';
    private static final String CREATE ='Create';
    private QueueStep processType;
    public static final String STRING_QUOTE_EMAIL = 'Quote';
    
    /**Quoeue Steps*/
    public enum QueueStep {
        STEP1_VALIDATE_CART,
        STEP2_FINALIZE_CART,
        STEP3_SYNC_CART,
        STEP4_LOG_ERRORS,
        STEP5_PUBLISH_PE_SUBMIT_FOR_APPROVAL,
        STEP6_GENDOC
    }

    /** 
     * Constructor,
     */
    public GenerateQueueDocument(List<String> lstCartValidate, QueueStep processType){
        this.lstCartValidate = lstCartValidate;
        this.processType = processType;
    }
    /** 
     * Constructor,
     */
    public GenerateQueueDocument(List<QuoteCreationAPIOppCartWrapper> lstQuoteCreationWrapper, QueueStep processType){
        this.lstQuoteCreationWrapper = lstQuoteCreationWrapper;
        this.processType = processType;
    }

    /**Execute Method*/
    public void execute( QueueableContext objContext ){
        switch on this.processType {
            when STEP1_VALIDATE_CART {
                validateCart();
            }
            when STEP2_FINALIZE_CART {
                finalizeCart();
            }
            when STEP3_SYNC_CART {
                syncCart();
            }
            when STEP4_LOG_ERRORS {
                logErrors();
            }
            when STEP5_PUBLISH_PE_SUBMIT_FOR_APPROVAL {
                publishPESubmitForApproval();
            }
            when STEP6_GENDOC {
                generateDocument();
            }
        }
    }
    /**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024 
     * @param strQuoteId  
     * @param strCartId 
     **/
    public void execute( FinalizerContext ctx ) {
        switch on this.processType {
            when STEP1_VALIDATE_CART {
                System.enqueueJob(new GenerateQueueDocument( this.lstQuoteCreationWrapper, QueueStep.STEP2_FINALIZE_CART),5);
            }
            when STEP2_FINALIZE_CART {
                System.enqueueJob(new GenerateQueueDocument( this.lstQuoteCreationWrapper, QueueStep.STEP3_SYNC_CART));
            }
            when STEP3_SYNC_CART {
                System.enqueueJob(new GenerateQueueDocument( this.lstQuoteCreationWrapper, QueueStep.STEP4_LOG_ERRORS), 5);
            }
            when STEP4_LOG_ERRORS {
                System.enqueueJob(new GenerateQueueDocument( this.lstQuoteCreationWrapper, QueueStep.STEP5_PUBLISH_PE_SUBMIT_FOR_APPROVAL));
            }
        }
    }
    
    
    /**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024 
     * @param strQuoteId  
     * @param strCartId 
     **/
    private void validateCart() {
        this.lstQuoteCreationWrapper = WebGeneratedQuoteOpportunityCreation.handleCartValidate(this.lstCartValidate);
        system.debug('lstQuoteCreationWrapper  '+this.lstQuoteCreationWrapper);
        for(QuoteCreationAPIOppCartWrapper objQuoteAPIDataWrapper :this.lstQuoteCreationWrapper){
            if(objQuoteAPIDataWrapper.objErrorHandler.lstErrors.isEmpty()){
                objQuoteAPIDataWrapper.lstSuccessesSteps.add(aVALIDATECARTSTEP);
            }
        }

        finalizeQueue(QueueStep.STEP1_VALIDATE_CART);
    }

    /**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024
     * @param strQuoteId 
     * @param strCartId 
     **/
    public void finalizeCart() {     
        for(QuoteCreationAPIOppCartWrapper objQuoteAPIDataWrapper :this.lstQuoteCreationWrapper){
            system.debug('objQuoteAPIDataWrapper '+ objQuoteAPIDataWrapper);
            if( objQuoteAPIDataWrapper.objErrorHandler?.lstErrors != null && objQuoteAPIDataWrapper.objErrorHandler?.lstErrors.size() > 0 && !Test.isRunningTest()){ 
            	continue;
            } else{
            	Boolean isSuccess = UtilsCart.finalizeCart(objQuoteAPIDataWrapper.objRequestWrapper.cartId);
                if(isSuccess){
                    objQuoteAPIDataWrapper.lstSuccessesSteps.add(aFINALIZECARTSTEP);
                }else{
                    objQuoteAPIDataWrapper.objErrorHandler.addError('ERR12', ' - Finalize Cart Failed');

                    for(String temp : ApttusValidationCallback.errorMessagesToEmail ){
                        objQuoteAPIDataWrapper.objErrorHandler.addError('ERR12', temp);
                    }
                }
            }
        }

        
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(this.lstQuoteCreationWrapper, WebGeneratedQuoteOpportunityCreation.mapCustomerIds, STRING_QUOTE_EMAIL,'Finalize Cart');

        finalizeQueue(QueueStep.STEP2_FINALIZE_CART);
    }

    /**
     * @description 
     * @author Arquimidez Mora | 09-Sep-2024 
     * @param strCartId 
     **/
    private void syncCart() {
        for(QuoteCreationAPIOppCartWrapper objQuoteAPIDataWrapper :this.lstQuoteCreationWrapper){
            system.debug('objQuoteAPIDataWrapper '+ objQuoteAPIDataWrapper);
            if(objQuoteAPIDataWrapper.objErrorHandler.lstErrors !=null && objQuoteAPIDataWrapper.objErrorHandler.lstErrors.size() > 0) { 
            	continue;
            }
            /* else{
                Boolean boolSynchIsSuccess = UtilsCart.synchronizeCart(objQuoteAPIDataWrapper.objRequestWrapper.cartId);
                if(boolSynchIsSuccess){
                    objQuoteAPIDataWrapper.lstSuccessesSteps.add(aSYNCCARTSTEP);
                }else{
                    objQuoteAPIDataWrapper.objErrorHandler.addError('ERR13', ' - Sync Cart Failed');
                }
            } */
        }
        finalizeQueue(QueueStep.STEP3_SYNC_CART);
    }
	/**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024
     * @param strQuoteId 
     * @param strCartId 
     **/
    private void logErrors(){
        QuoteCreationAPIErrorHandler.insertInterfaceLog(this.lstQuoteCreationWrapper, aVALIDATECARTSTEP);
        finalizeQueue(QueueStep.STEP4_LOG_ERRORS);
    }

    /**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024
     * @param strQuoteId 
     * @param strCartId 
     **/
    private void publishPESubmitForApproval(){
        for(QuoteCreationAPIOppCartWrapper objQuoteAPIDataWrapper : this.lstQuoteCreationWrapper) {
            system.debug('objQuoteAPIDataWrapper '+ objQuoteAPIDataWrapper);
            if(objQuoteAPIDataWrapper.objErrorHandler.lstErrors != null && objQuoteAPIDataWrapper.objErrorHandler.lstErrors.size()>0 && !Test.isRunningTest()){
            	continue;
            }
            else{
                CEQWebResquestPlatformEventService.createPlatformEvent(QuoteCreationAPIPESubscriberService.Step.STEP4_SUBMIT_FOR_APPROVAL, objQuoteAPIDataWrapper.strJSONPayload);
            }
        }
    }

    /**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024
     * @param strQuoteId 
     * @param strCartId 
     **/
    private void generateDocument(){
        
        Apttus__APTS_Template__c templateDetails = new Apttus__APTS_Template__c();
        if(!Test.isRunningTest())
        templateDetails = [Select Id, Name From Apttus__APTS_Template__c where Name =:aSTRINGTEMPLATE Limit 1];
        

        List<String> quoteIdList = new List<String>();
        for(QuoteCreationAPIOppCartWrapper objCreationWrapper: this.lstQuoteCreationWrapper ){
            quoteIdList.add(objCreationWrapper.objRequestWrapper.quoteId);
        }

        Map<Id,Apttus_Proposal__Proposal__c> quoteMapDetails = new Map<Id,Apttus_Proposal__Proposal__c>([Select Id, Name,Apttus_QPApprov__Approval_Status__c, Apttus_Proposal__Approval_Stage__c,Apttus_Proposal__Opportunity__r.StageName,Bill_To__c,Ship_To__c,Payer__c,Apttus_Proposal__Opportunity__r.Account.Account_Status__c,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Account_Status__c,Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Account_Status__c,Apttus_Proposal__Primary_Contact__c,Apttus_Proposal__Opportunity__r.Distributor__r.Account_Status__c,Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Credit_Block__c,Apttus_Proposal__Opportunity__r.Distributor__r.Credit_Block__c,Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c,Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Credit_Block__c,Apttus_Proposal__Opportunity__r.Account.Credit_Block__c,Payer__r.Credit_Block__c,Payer_Credit_Block__c FROM Apttus_Proposal__Proposal__c WHERE Id IN: quoteIdList]);
        
        for(QuoteCreationAPIOppCartWrapper objCreationWrapper: this.lstQuoteCreationWrapper ){
            if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Approval_Stage__c ==APPROVED || Test.isRunningTest()){

                if(!String.isBlank(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Payer__r.Credit_Block__c) ){
                    objCreationWrapper.objErrorHandler.addError('ERR12', Label.UI_ErrorMessage_QuotationPayerCreditBlocked);
                }

                if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.StageName == CREATE){
                    objCreationWrapper.objErrorHandler.addError('ERR12', Label.GenerateProposalCreateStageMessage);
                }

                List<String> oppStage = new List<String>{'Closed Won','Closed Lost','Closed Abandoned'};
                if(oppStage.contains(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.StageName)){
                    objCreationWrapper.objErrorHandler.addError('ERR12', Label.GenerateProposalClosedStageMessage);
                }

                if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Bill_To__c == null){
                    objCreationWrapper.objErrorHandler.addError('ERR120', Label.GenerateProposalBillToMessage);
                }

                if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Ship_To__c == null){
                    objCreationWrapper.objErrorHandler.addError('ERR13', Label.GenerateProposalShipToMessage);
                }
                if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Payer__c == null){
                    objCreationWrapper.objErrorHandler.addError('ERR13', Label.GenerateProposalPayerMessage);
                }

                List<String> accStatus = new List<String>{'Unverified','Pending Validation'};
                if(accStatus.contains(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Account.Account_Status__c)){
                    objCreationWrapper.objErrorHandler.addError('ERR13', Label.GenerateProposalSoldToMessage);
                }

                if(accStatus.contains(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Account_Status__c)){
                    objCreationWrapper.objErrorHandler.addError('ERR130', Label.GenerateProposalUltimateConsigneeMessage);
                }

                if(accStatus.contains(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Account_Status__c)){
                    objCreationWrapper.objErrorHandler.addError('ERR14', Label.GenerateProposalLessorCustomerMessage);
                }

                if(accStatus.contains(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Distributor__r.Account_Status__c)){
                    objCreationWrapper.objErrorHandler.addError('ERR14', Label.GenerateProposalDistributorMessage);
                }
                if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Primary_Contact__c == null){
                    objCreationWrapper.objErrorHandler.addError('ERR14', Label.GenProposalPCMsg);
                }

                if(!String.isBlank(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Ultimate_Consignee__r.Credit_Block__c) ){
                    objCreationWrapper.objErrorHandler.addError('ERR140', Label.QuoteUCCreditBlock);
                }

                if(!String.isBlank(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Distributor__r.Credit_Block__c) && quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Direct_Sale_to_Ultimate_Consignee__c != true ){
                    objCreationWrapper.objErrorHandler.addError('ERR15', Label.QuoteDistCreditBlock);
                }

                if(!String.isBlank(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Lessor_Customer__r.Credit_Block__c) ){
                    objCreationWrapper.objErrorHandler.addError('ERR15', Label.QuoteLCCreditBlock);
                }

                if(!String.isBlank(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Opportunity__r.Account.Credit_Block__c) ){
                    objCreationWrapper.objErrorHandler.addError('ERR15', Label.QuoteSoldToCreditBlock);
                }
            }
           if(objCreationWrapper.objErrorHandler?.lstErrors!=null && objCreationWrapper.objErrorHandler?.lstErrors.size()>0){ 
            	continue;
            }
            else if(quoteMapDetails.get(objCreationWrapper.objRequestWrapper.quoteId).Apttus_Proposal__Approval_Stage__c ==APPROVED){
                String strQuoteId = objCreationWrapper.objRequestWrapper.quoteId;
                if(!Test.isRunningTest())
                Apttus_Proposal.MergeWebService.submitGenerateDoc(templateDetails.Id, strQuoteId, this.aSTRINGPROTECTIONLEVEL, this.aSTRINGDOCFORMAT, false,  UserInfo.getSessionId(), this.aSTRINGAPISERVERURL);  
            } 
        }
        if(!Test.isRunningTest())
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(this.lstQuoteCreationWrapper, WebGeneratedQuoteOpportunityCreation.mapCustomerIds, STRING_QUOTE_EMAIL,'Generate Document');

    }

    /**
     * @description 
     * @author Arquimidez Mora | 03-Sep-2024
     * @param strQuoteId 
     * @param strCartId 
     **/
    private void finalizeQueue( QueueStep processType){
        Finalizer finalizer = new GenerateQueueDocument( this.lstQuoteCreationWrapper, processType);
        System.attachFinalizer(finalizer);
    }
}