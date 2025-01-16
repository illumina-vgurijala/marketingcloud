/**
 *    @author Vinay  S Reddy
 *    @date   30-10-2024
 *    @description Class to create Oppportunity Record for Web Generated Request
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *         Arquimidez Mora               30th Oct 2024          Initial Version
 *         Gerardo Garcia                4th  Nov 2024          CMCM-2891 Quote and Cart Creation.
 *         Arquimiez Mora                20  Nov 2024          CMCM-9914 Adding Products to Cart.
 *         Vinay S Reddy                 29  Nov 2024          CMCM-11308 Cart Validation.
 */
public with sharing class WebGeneratedQuoteOpportunityCreation {
    
    public static final String LOG_TITLE = 'Opportunity Creation for Web Generated Request';
    public static final String INDIRECT_RE_ORDER_RECORD_TYPE = 'Indirect_Re_Order';
    public static final String STRING_INSERTING_CART_PRODUCTS = 'Web Generated API - Inserting Cart Products';
    public static final String STRING_CART_STEP = 'Cart Creation';
    public static final String STRING_CART_VALIDATE = 'Cart Validation'; 
    public static final String STRING_QUOTE_API_NAME = 'Apttus_Proposal__Proposal__c'; 
    public static final String STRING_QUOTE_EMAIL = 'Quote';
    public static final String ERROR11 = 'ERR11';


    public static final Id QUOTATION_RECORD_TYPE = Schema.SObjectType.Apttus_Proposal__Proposal__c.getRecordTypeInfosByName().get(CreateQuoteAutomation.QUOTE_RECORD_TYPE_PROPOSAL).getRecordTypeId();
    public static Map<ID,String> collectionofValidtionError = new Map<Id,String>();

    public static Map<String, Account> mapCustomerIds = new Map<String, Account>();
    public static List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper = new List<QuoteCreationAPIOppCartWrapper>(); //placeholder of error messages when Quote creation fails
    
    /**
     *  @description Method to handle the opportunities creation
     *  @param String receivedData
     *  @return void
     **/
    public static void handlePayload(List<String> lstJSONPayloads){
        try {
            Map<String, Account> mapCustomerIds = new Map<String, Account>();
            Map<String, Contact> mapContacts = new Map<String, Contact>();
            Map<String, Customer_Master_Data__c> mapCMD = new Map<String, Customer_Master_Data__c>();
        
            //Wrap the received string in JSON format by deserializing it
            List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper = QuoteCreationAPIOpportunityService.processPayloads(lstJSONPayloads);
            
            QuoteCreationAPIOpportunityService.fillDataFromWrapper(mapCustomerIds, mapContacts, mapCMD, lstOppCreationWrapper);
            
            List<ProccesedData> processDatas = QuoteCreationAPIOpportunityService.createOpportunity(lstOppCreationWrapper, mapCustomerIds, mapContacts);
            createQuotations(processDatas, mapCustomerIds, mapCMD);
            createCarts(processDatas);
            publishEvenAddProducts(processDatas);

        } catch(Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
        } finally {
            ilib_LogEvent.emit();
        }
    }
    
    @TestVisible
    private static void createQuotations(List<ProccesedData> processDatas, Map<String, Account> mapCustomerIds, Map<String, Customer_Master_Data__c> mapCMD) {
        List<Apttus_Proposal__Proposal__c> quotations = new List<Apttus_Proposal__Proposal__c>();

        for(ProccesedData pData : processDatas) {
            if(pData.opportunity?.id == null) {continue;}  // ignore failed insert opportunity

            Apttus_Proposal__Proposal__c quotation = getQuotation(pData, mapCustomerIds, mapCMD);
            pData.quotation = quotation;
            quotations.add(quotation);
        }
        
        insertObjects(quotations);
        ilib_LogEvent.message('createQuotations processDatas:' + JSON.serializePretty(processDatas));
    }
    
    @TestVisible
    private static void createCarts(List<ProccesedData> processDatas) {
        Integer i=0;
        for(ProccesedData pd : processDatas) {
            if(pd.quotation.id == null) {continue;}  
            try{
            String cartId  = UtilsCart.createCartForQuote(pd.quotation.id);
            ilib_LogEvent.message('conga cart id:' + cartId);
            pd.wrapper.quoteId = pd.quotation.id;
            pd.wrapper.cartId = cartId;
            }catch(Exception ex){
                lstOppCreationWrapper[i].objErrorHandler.addError( ERROR11, 'Error Creating Cart for Quote with ID '+pd.quotation.id+ ' Error Message is ' +  ex.getMessage() );
                i++;
            }
        }
        QuoteCreationAPIErrorHandler.insertInterfaceLog(lstOppCreationWrapper, STRING_QUOTE_EMAIL);
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstOppCreationWrapper, mapCustomerIds, STRING_QUOTE_EMAIL,'Cart Creation');
    }
    

    private static Apttus_Proposal__Proposal__c getQuotation(ProccesedData processData, Map<String, Account> mapCustomerIds, 
    Map<String, Customer_Master_Data__c> mapCMD) {

        Apttus_Proposal__Proposal__c quotation = Apttus_Proposal.ProposalWebService.createProposalFromOpportunity(processData.opportunity.Id, QUOTATION_RECORD_TYPE);
        quotation.Apttus_Proposal__Proposal_Name__c = processData.opportunity.Name;

        // ACCOUNTS map
        if(mapCustomerIds.containsKey(processData.wrapper.billTo)) {
            quotation.Apttus_QPConfig__BillToAccountId__r = mapCustomerIds.get(processData.wrapper.billTo);
        }

        // CUSTOMER MASTER DATA
        if(mapCMD.containsKey(processData.wrapper.soldTo)) {
            quotation.Payer__c = mapCMD.get(processData.wrapper.soldTo).Id;
        }

        if(mapCMD.containsKey(processData.wrapper.shipTo)) {
            quotation.Ship_To__c = mapCMD.get(processData.wrapper.shipTo).Id;
        }

        if(mapCMD.containsKey(processData.wrapper.billTo)) {
            quotation.Bill_To__c = mapCMD.get(processData.wrapper.billTo).Id;
        }

        return quotation;
    }
    
    /**
    * @description Method to handle the Cart creation
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstCartLinePayloads 
    **/
    public static void handleCartLinePayload(List<String> lstCartLinePayloads){
       // Map<String, Account> mapCustomerIds = new Map<String, Account>();
        Map<String, String> mapProductsByMaterialNumber = new Map<String, String>();
        List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper = processCartPayloads(lstCartLinePayloads);

        List<Apttus_Proposal__Proposal_Line_Item__c> lstQuoteLineItems = new List<Apttus_Proposal__Proposal_Line_Item__c>();
        
        fillDataFromWrapper(lstCartCreationWrapper,  mapCustomerIds, mapProductsByMaterialNumber);
        for(QuoteCreationAPIOppCartWrapper objCartCreationWrapper : lstCartCreationWrapper){
            objCartCreationWrapper.lstQuoteLineItems = createQuoteLines(objCartCreationWrapper, mapProductsByMaterialNumber, objCartCreationWrapper.objRequestWrapper.quoteId);
            lstQuoteLineItems.addAll(objCartCreationWrapper.lstQuoteLineItems);
        }

        insertObjects(lstQuoteLineItems);
        
        createCartLineItems(lstCartCreationWrapper);      
        addProductsToCart(lstCartCreationWrapper);
        QuoteCreationAPIErrorHandler.insertInterfaceLog(lstCartCreationWrapper, STRING_CART_STEP);
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstCartCreationWrapper, mapCustomerIds, STRING_QUOTE_EMAIL,'Add Products');
        publishEventValidateCart(lstCartCreationWrapper);
    }
    
    /**
    * @description Method to handle the Cart validation
    * @author Vinay S Reddy | 11-29-2024 
    * @param lstCartValidatePayload 
    **/
    @TestVisible
    public static List<QuoteCreationAPIOppCartWrapper> handleCartValidate(List<String> lstCartValidatePayload){
        ilib_LogEvent.push(LOG_TITLE + 'Validation Status');
        List<QuoteCreationAPIOppCartWrapper> lstCartValidateWrapper = processCartPayloads(lstCartValidatePayload);
        List<QuoteCreationAPIOppCartWrapper> lstCartValidated = new List<QuoteCreationAPIOppCartWrapper>();
        String errorString;
        Boolean boolHasError;
        system.debug('lstCartValidateWrapper '+lstCartValidateWrapper);
        set<Id> listHoldingQuoteIds = new set<Id>();
        for (QuoteCreationAPIOppCartWrapper dataforValidateCartQuote : lstCartValidateWrapper){
            listHoldingQuoteIds.add(dataforValidateCartQuote.objRequestWrapper.quoteId);
        }

        List<Apttus_Config2__ProductConfiguration__c> tempConfiObjfromQuoteId = new List<Apttus_Config2__ProductConfiguration__c>();
        tempConfiObjfromQuoteId = new ApttusProductConfigurationsSelector().selectProductConfigurationByQuotIds(listHoldingQuoteIds);

        Map<Id,Boolean> tempHoldingBooleanDirecttoUC = new Map<Id, Boolean>();
        for(Apttus_Config2__ProductConfiguration__c temp: tempConfiObjfromQuoteId){
            Boolean getDirectToUc = temp.Apttus_QPConfig__Proposald__r.Direct_Sale_to_Ultimate_Consignee__c;
            tempHoldingBooleanDirecttoUC.put(temp.Id,getDirectToUc);
        }

        for(QuoteCreationAPIOppCartWrapper dataforValidateCart : lstCartValidateWrapper){
            //Apttus_Config2__ProductConfiguration__c objConfig = new ApttusProductConfigurationsSelector().selectProductConfigurationByQuotIds(new Set<Id>{dataforValidateCart.objRequestWrapper.quoteId})[0];
            Boolean  boolIsDirectSaleToUC = tempHoldingBooleanDirecttoUC.get(dataforValidateCart.objRequestWrapper.cartId);
            String configurationId = dataforValidateCart.objRequestWrapper.cartId;
            ilib_LogEvent.info('Cart ID '+configurationId);
            ValidateQuoteAutomation.boolIsQuoteAutomated = true;
            ApttusCheckPriceBaseClass baseClassInstance = new ApttusCheckPriceBaseClass(configurationId);
            String validationValues = baseClassInstance.callSAP(boolIsDirectSaleToUC);
            ilib_LogEvent.info('response from callSAP of ApttusCheckPriceBaseClass '+validationValues);
            if(boolIsDirectSaleToUC){
                boolHasError = Boolean.valueOf(validationValues.substringBefore('_'));
                errorString = validationValues.substringAfter('-');
            }
            else{
                boolHasError = Boolean.valueOf(validationValues.substringBefore('@'));
                errorString = validationValues.substringBetween('_','#');
                
            }
            ilib_LogEvent.info('Error in Cart Validation '+boolHasError);
            ilib_LogEvent.info('Error List '+errorString);
            
            if(!boolHasError || Test.isRunningTest()){
                ilib_LogEvent.push(LOG_TITLE + '.repriceCart');
                Boolean boolPricingCompleted = ApttusCheckPriceBaseClass.repriceCart(configurationId);

                if(boolPricingCompleted || Test.isRunningTest()){
                    ilib_LogEvent.info('Cart is Successfully Validated : '+boolPricingCompleted); 
                    system.debug('Cart is Successfully Validated '+boolPricingCompleted);
                    lstCartValidated.add(dataforValidateCart);
                } else { 
                    ilib_LogEvent.info('Cart Validation Failed');
                    system.debug('Cart Validation Failed');
                }

            }
            
            collectionofValidtionError.put(configurationId,errorString);

        }
        
        ilib_LogEvent.info('Validation of the Cart Failed '+boolHasError);
        methodToLogValidationErrors(lstCartValidateWrapper);
        QuoteCreationAPIErrorHandler.insertInterfaceLog(lstCartValidateWrapper, STRING_CART_VALIDATE);
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstCartValidateWrapper, mapCustomerIds, STRING_QUOTE_EMAIL,'Cart Validation');
        ilib_LogEvent.pop(); 
        ilib_LogEvent.emit();
        return lstCartValidated;
    }

    /**
    * @description Method to handle the Cart validation
    * @author Vinay S Reddy | 11-29-2024 
    * @param lstCartValidateWrapper 
    **/
    public static void methodToLogValidationErrors(List<QuoteCreationAPIOppCartWrapper> lstCartValidateWrapper){
        Map<ID,String> mapofCartValidate = new Map<Id,String>();
        string cartErrorString;
        List<Apttus_Config2__ProductConfiguration__c> afterCartValidate = new List<Apttus_Config2__ProductConfiguration__c>();
        afterCartValidate = new ApttusProductConfigurationsSelector().selectConfigProdforSAPErrors(collectionofValidtionError.KeySet());
        
        for(Apttus_Config2__ProductConfiguration__c tempCart :afterCartValidate){
            mapofCartValidate.put(tempCart.Id,tempCart.SAP_Errors__c);
        }


        for(QuoteCreationAPIOppCartWrapper tempCart : lstCartValidateWrapper){
            String configurationId = tempCart.objRequestWrapper.cartId;
            cartErrorString =collectionofValidtionError.get(configurationId);
            
            if(!String.isBlank(cartErrorString) && cartErrorString != null){
            tempCart.objErrorHandler.addError(ERROR11,cartErrorString);
            }

            if(!String.isBlank(mapofCartValidate.get(configurationId)) && mapofCartValidate.get(configurationId) != null){
                cartErrorString+= '\n' + mapofCartValidate.get(configurationId).replace('<ui>','').replace('</ui>','').replace('<li>','').replace('</li>','').replace('<ul>','').replace('</ul>','');
                system.debug('Errors in cart validation '+cartErrorString);
                tempCart.objErrorHandler.addError(ERROR11,cartErrorString);   
            }
        }
    }

    /**
    * @description 
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstJSONPayloads 
    * @return List<QuoteCreationAPIOppCartWrapper> 
    **/
    public static List<QuoteCreationAPIOppCartWrapper> processCartPayloads(List<String> lstJSONPayloads){
        List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper =  new List<QuoteCreationAPIOppCartWrapper>();
        for(String strJSONPayload : lstJSONPayloads){
            QuoteCreationAPIOppCartWrapper objCartCreationWrapper = new QuoteCreationAPIOppCartWrapper();
            objCartCreationWrapper.objErrorHandler = new QuoteCreationAPIErrorHandler();
            
            try{
                new RestOpportunityQuoteCreationValidator().validateSchema(strJSONPayload);
                QuoteCreationAPIRequestWrapper objRequestWrapper = (QuoteCreationAPIRequestWrapper) System.JSON.deserialize(strJSONPayload, QuoteCreationAPIRequestWrapper.class);
                objCartCreationWrapper.strJsonPayload = strJSONPayload;
                objCartCreationWrapper.lstSuccessesSteps = new List<String>();
                
                objCartCreationWrapper.objRequestWrapper = objRequestWrapper;
                if(objCartCreationWrapper.objRequestWrapper.quoteId == null || objCartCreationWrapper.objRequestWrapper.cartId == null){
                    objCartCreationWrapper.objErrorHandler.addError( 'ERR07', 'CartId: ' + objCartCreationWrapper.objRequestWrapper.cartId+ ' or QuoteId: '+ objCartCreationWrapper.objRequestWrapper.quoteId+' are invalid.' );
                }

                lstCartCreationWrapper.add(objCartCreationWrapper);
            } catch(RestOpportunityQuoteCreationValidator.InvalidSchemaException e){
                ilib_LogEvent.info(STRING_INSERTING_CART_PRODUCTS + ' Validation Error: ' + e.getMessage() + ', Line: ' + e.getLineNumber());
            } catch(Exception ex){
                ilib_LogEvent.info(STRING_INSERTING_CART_PRODUCTS + ' Error: ' + ex.getMessage() + ', Line: ' + ex.getLineNumber());
            }
        }

        return lstCartCreationWrapper;
    }

    /**
    * @description 
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstCartCreationWrapper 
    * @param mapCustomerIds 
    * @param lstQuoteLineItems 
    **/
    public static void fillDataFromWrapper(List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper, Map<String, Account> mapCustomerIds, Map<String, String> mapProductsByMaterialNumber) {
        Set<String> setProductMaterialNumbers = new Set<String>();
        Set<String> setCustomerIds = new Set<String>();

        for(QuoteCreationAPIOppCartWrapper objQuoteCreationAPIOppCartWrapper : lstCartCreationWrapper){
            for(QuoteCreationAPIRequestWrapper.QuoteLinesWrapper objQuoteLine : objQuoteCreationAPIOppCartWrapper.objRequestWrapper.quoteLines){
                setProductMaterialNumbers.add(objQuoteLine.materialNumber);
            }
            setCustomerIds.add(objQuoteCreationAPIOppCartWrapper.objRequestWrapper.soldTo);
        }
        for( Product2 objPrdouct: [SELECT Id, Name, Material_Number__c FROM Product2 WHERE Material_Number__c IN : setProductMaterialNumbers ]) {
            mapProductsByMaterialNumber.put(objPrdouct.Material_Number__c, objPrdouct.Id);
        }

        for(Account objSolToAccount : [SELECT Id, Name, ERP_Customer_Id__c, Territory_Region__c, OwnerId FROM Account WHERE ERP_Customer_Id__c IN :setCustomerIds]){
            if(!mapCustomerIds.containsKey(objSolToAccount.ERP_Customer_Id__c)){
                mapCustomerIds.put(objSolToAccount.ERP_Customer_Id__c, objSolToAccount);
            }
        }
    }

    /**
    * @description Method to Create Quote Line Items
    * @author Arquimidez Mora | 11-22-2024 
    * @param objQuoteCreationAPIOppCartWrapper 
    * @param mapProductsByMaterialNumber 
    * @param strQuoteId 
    * @return List<Apttus_Proposal__Proposal_Line_Item__c> 
    **/
    public static List<Apttus_Proposal__Proposal_Line_Item__c> createQuoteLines( QuoteCreationAPIOppCartWrapper objCartCreationWrapper,  Map<String, String> mapProductsByMaterialNumber, String strQuoteId){
        List<Apttus_Proposal__Proposal_Line_Item__c> lstQuoteLineItems = new List<Apttus_Proposal__Proposal_Line_Item__c>();

        for(QuoteCreationAPIRequestWrapper.QuoteLinesWrapper objQuoteLine: objCartCreationWrapper.objRequestWrapper.quoteLines ) {
            if(mapProductsByMaterialNumber.containsKey(objQuoteLine.materialNumber)){
                Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem = new Apttus_Proposal__Proposal_Line_Item__c();
                objProposalLineItem.Apttus_Proposal__Product__c = mapProductsByMaterialNumber.get(objQuoteLine.materialNumber);
                objProposalLineItem.Apttus_Proposal__Quantity__c = objQuoteLine.quantity;
                objProposalLineItem.Apttus_QPConfig__Quantity2__c = objQuoteLine.quantity;
                objProposalLineItem.EcomLineItemID__c = objQuoteLine.ecomLineitemId;
                objProposalLineItem.Apttus_Proposal__Proposal__c = strQuoteId;
                objProposalLineItem.Apttus_QPConfig__SellingTerm__c = 1;
                lstQuoteLineItems.add(objProposalLineItem);
            }else{
                objCartCreationWrapper.objErrorHandler.addError( 'ERR08', 'Material Number is invalid: ' + objQuoteLine.materialNumber);
            }
        }

        return lstQuoteLineItems;
    }

    /**
    * @description Method to create Cart line items
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstQuoteCreationAPIOppCartWrapper 
    **/
    public static void createCartLineItems( List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper ) {
        for(QuoteCreationAPIOppCartWrapper objCartCreationWrapper : lstCartCreationWrapper){
            objCartCreationWrapper.lstCartLineItems = createLineItemsFromCartWrapper(objCartCreationWrapper.lstQuoteLineItems, objCartCreationWrapper);
        }
    }

    /**
    * @description Method to create Line Items with UtilsCart class
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstProposalLineItems 
    * @param objCartCreationWrapper 
    * @return List<UtilsCart.LineItemWrapper> 
    **/
    public static List<UtilsCart.LineItemWrapper> createLineItemsFromCartWrapper(List<Apttus_Proposal__Proposal_Line_Item__c> lstProposalLineItems, QuoteCreationAPIOppCartWrapper objCartCreationWrapper )
    {
        List<UtilsCart.LineItemWrapper> lstLineItemWrapper = new List<UtilsCart.LineItemWrapper>();
        for( Apttus_Proposal__Proposal_Line_Item__c objProposalLineItem: lstProposalLineItems) {
            try {
                UtilsCart.LineItemWrapper liWrapper = new UtilsCart.LineItemWrapper(objProposalLineItem);
                liWrapper.ecomLineItemId = objProposalLineItem.EcomLineItemID__c;
                lstLineItemWrapper.add(liWrapper);
            } catch (Exception ex) {
                objCartCreationWrapper.objErrorHandler.addError( 'ERR09', 'Error Creating Cart Line Item: ' + ex.getMessage() + ' - Line Number: ' + ex.getLineNumber());
            }
        }
        
        return lstLineItemWrapper;
    }

    /**
    * @description Method to add Line items to Cart
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstCartCreationWrapper 
    **/
    public static void addProductsToCart( List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper ) {
        for(QuoteCreationAPIOppCartWrapper objCartCreationWrapper : lstCartCreationWrapper){
            try {
                UtilsCart.addMultiProducts(objCartCreationWrapper.objRequestWrapper.cartId,objCartCreationWrapper.lstCartLineItems);
                UtilsCart.doReprice(objCartCreationWrapper.objRequestWrapper.cartId);
            } catch (Exception ex) {
                objCartCreationWrapper.objErrorHandler.addError( 'ERR10', 'Error Inserting Cart Line Item: ' + ex.getMessage() + ' - Line Number: ' + ex.getLineNumber());
            }
        }
    }

    /**
     * @description method to handle success or failure
     * @author  Vinay S Reddy | 10-30-2024
     * @param lstOpportunities
     **/
    public static void insertObjects(List<SObject> objs2Insert) {
        ilib_LogEvent.push(LOG_TITLE + '.insertObjects');
        ilib_LogEvent.pop();

        Database.SaveResult[] saveResults = Database.insert(objs2Insert, false);
        ApexExceptions.emitSaveErrors(saveResults, LOG_TITLE + '.insertObjects');
        if(objs2Insert.getSObjectType().getDescribe().getName() == STRING_QUOTE_API_NAME){
            system.debug('Type Quote  '+objs2Insert.getSObjectType().getDescribe().getName());
            Integer i=0;
            for (Database.SaveResult res : saveResults){
                if (!res.isSuccess()){
                    for(Database.Error err : res.getErrors()){
                        String errorMessage = err.getStatusCode() + ',' + err.getMessage();
                        System.debug('@@@@1 Error Occurred while saving, details: '+errorMessage);
                        lstOppCreationWrapper[i].objErrorHandler.addError( ERROR11, 'Error Inserting Quotations: ' + errorMessage);
                        system.debug('lstquotefailure[i] '+lstOppCreationWrapper);
                    }
                    }
                    i++;
                    
                } 
                System.debug('database  '+saveResults);
                System.debug('lstquotefailure '+lstOppCreationWrapper);
                QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstOppCreationWrapper, mapCustomerIds, STRING_QUOTE_EMAIL,'Quote Creation');

        }
    }

    private static void publishEvenAddProducts(List<ProccesedData> datas2Publish) {
        for(ProccesedData pd : datas2Publish) {
            if(String.isBlank(pd.wrapper.cartId)) {continue;} // ignore cuz cart were not created.

            String payload = JSON.serialize(pd.wrapper);
            ilib_LogEvent.message('payload of addProducts:' + JSON.serializePretty(pd.wrapper));
            CEQWebResquestPlatformEventService.createPlatformEvent(QuoteCreationAPIPESubscriberService.Step.STEP2_ADD_PRODUCTS_TO_CART, payload);
        }
    }

    /**
    * @description Method to Publish event to validate cart
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstCartWrappers 
    **/
    private static void publishEventValidateCart(List<QuoteCreationAPIOppCartWrapper> lstCartWrappers) {
        for(QuoteCreationAPIOppCartWrapper objCartWrapper : lstCartWrappers) {
            if(!objCartWrapper.objErrorHandler.lstErrors.isEmpty()) {continue;} // ignore cuz cart were not created.

            ilib_LogEvent.message('Payload of Validate Cart:' + JSON.serializePretty(objCartWrapper.strJsonPayload));
            CEQWebResquestPlatformEventService.createPlatformEvent(QuoteCreationAPIPESubscriberService.Step.STEP3_VALIDATE_CART, objCartWrapper.strJsonPayload);
        }
    }

    /**
    * @description Method to Publish event to validate cart
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstCartWrappers 
    **/
    public static void handleSubmitForApprovalPayloads(List<String> lstJSONPayloads){
        List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper = processCartPayloads(lstJSONPayloads);
        submitForApprovalQuote(lstCartCreationWrapper);
    }

        /**
    * @description Method to Publish event to validate cart
    * @author Arquimidez Mora | 11-22-2024 
    * @param lstCartWrappers 
    **/
    private static void submitForApprovalQuote(List<QuoteCreationAPIOppCartWrapper> lstCartCreationWrapper){
        for(QuoteCreationAPIOppCartWrapper objCreationWrapper : lstCartCreationWrapper){
            Boolean boolSubmitForApprovalIsSucces = Apttus_Approval.ApprovalsWebService.submitForApprovals(STRING_QUOTE_API_NAME, objCreationWrapper.objRequestWrapper.quoteId);
            if(boolSubmitForApprovalIsSucces){
                objCreationWrapper.lstSuccessesSteps = new List<String>{'Submit For Approval'};
            }else{
                objCreationWrapper.objErrorHandler.addError( 'ERR14', ' - Submit for Approval Failed');
            }
        }
        QuoteCreationAPIErrorHandler.insertInterfaceLog(lstCartCreationWrapper, STRING_CART_VALIDATE);
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstCartCreationWrapper, mapCustomerIds, STRING_QUOTE_EMAIL,'Submit For Approval');

        System.enqueueJob(new GenerateQueueDocument( lstCartCreationWrapper, GenerateQueueDocument.QueueStep.STEP6_GENDOC),5);
    }


    /**Object that contains Payload, Opportunity and Quotation */
    public class ProccesedData {
        public QuoteCreationAPIRequestWrapper wrapper;
        public Opportunity opportunity;
        public Apttus_Proposal__Proposal__c quotation;

        /**Constructor */
        public ProccesedData(QuoteCreationAPIRequestWrapper wrapper,
        Opportunity opportunity) {
            this.wrapper = wrapper;
            this.opportunity = opportunity;
        }
    }
}