/**
 *    @author Arquimidez Mora
 *    @date   30-10-2024
 *    @description Class to create Oppportunity Record for Web Generated Request
 *    @Tested By: TestQuoteCreationAPIErrorHandler
 *    @Tested By: TestQuoteCreationAPIPlatformEvents
 *    Modification Log:
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *    -----------------------------------------------------------------------------------------------------------------------------------
 *         Arquimidez Mora                 06 Nov 2024          Initial Version
 */
public with sharing class QuoteCreationAPIOpportunityService {

    public static final String LOG_TITLE = 'Opportunity Creation for Web Generated Request';
    public static final String STRING_INSERTING_OPPORTUNITY = 'Web Generated API - Inserting Opportunity';
    public static final String DIST_CHANNEL_01 = '01';
    public static final String DIST_CHANNEL_02 = '02';
    public static final String STRING_OPPORTUNITY_NAME_WEBGENERATED = 'webgenerated';
    public static final String STRING_OPPORTUNITY_TYPE_WEB_GENERATED = 'Web Generated';
    public static final String STRING_OPPORTUNITY_STAGE_DEVELOP = 'Develop';
    public static final String STRING_OPPORTUNITY_FORECAST_NOT_FORECASTED = 'Not Forecasted';
    public static final String STRING_CONTACT_ROLE_MAIN_CONTACT = 'Main Contact';
    public static final String STRING_OPPORTUNITY_EMAIL = 'Opportunity';
    public static final String STRING_OPPORTUNITY_STEP = 'Opportunity Creation';

    public static final Id OPP_DIRECT_REORDER = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Label.OpportunityRTDirectReOrder).getRecordTypeId();
    public static final Id OPP_INDIRECT_REORDER = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(Label.IndirectReOrder).getRecordTypeId();

    /**
    * @description Handle the payload from Web Generated Quote Creation API
    * @author Arquimidez Mora | 11-06-2024 
    * @param lstJSONPayloads 
    * @return List<QuoteCreationAPIRequestWrapper> 
    **/
    public static List<QuoteCreationAPIOppCartWrapper> processPayloads(List<String> lstJSONPayloads){
        List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper =  new List<QuoteCreationAPIOppCartWrapper>();
        for(String strJSONPayload : lstJSONPayloads){
            QuoteCreationAPIOppCartWrapper objOppCreationWrapper = new QuoteCreationAPIOppCartWrapper();
            try{
                new RestOpportunityQuoteCreationValidator().validateSchema(strJSONPayload);
                QuoteCreationAPIRequestWrapper objRequestWrapper = (QuoteCreationAPIRequestWrapper) System.JSON.deserialize(strJSONPayload, QuoteCreationAPIRequestWrapper.class);
                objOppCreationWrapper.strJsonPayload = strJSONPayload;
                objOppCreationWrapper.objRequestWrapper = objRequestWrapper;
                objOppCreationWrapper.objErrorHandler = new QuoteCreationAPIErrorHandler();
                objOppCreationWrapper.lstSuccessesSteps = new List<String>();
                lstOppCreationWrapper.add(objOppCreationWrapper);
            } catch(RestOpportunityQuoteCreationValidator.InvalidSchemaException e){
                ilib_LogEvent.info(STRING_INSERTING_OPPORTUNITY + ' Validation Error: ' + e.getMessage() + ', Line: ' + e.getLineNumber());
            } catch(Exception ex){
                ilib_LogEvent.info(STRING_INSERTING_OPPORTUNITY + ' Error: ' + ex.getMessage() + ', Line: ' + ex.getLineNumber());
            }
        }
        return lstOppCreationWrapper;
    }

    /**
    * @description 
    * @author Arquimidez Mora | 11-06-2024 
    * @param mapCustomerIds 
    * @param mapContacts 
    * @param lstOppCreationWrapper 
    **/
    public static void fillDataFromWrapper(Map<String, Account> mapCustomerIds, Map<String, Contact> mapContacts, 
    Map<String, Customer_Master_Data__c> mapCMD, List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper) {
        Set<String> setCustomerIds = new Set<String>();
        Set<String> setContactEmails = new Set<String>();
        
        ilib_LogEvent.push(LOG_TITLE);
        
        for (QuoteCreationAPIOppCartWrapper objOpportunityCreationWrapper : lstOppCreationWrapper) {
            QuoteCreationAPIRequestWrapper objDataReceivedWrapper = objOpportunityCreationWrapper.objRequestWrapper;
            
            fillCustomerIds(setCustomerIds, objDataReceivedWrapper);

            if(objDataReceivedWrapper.primaryContact != null && objOpportunityCreationWrapper.objErrorHandler.validateEmailAddress(objDataReceivedWrapper.primaryContact.replace('.invalid', ''))){
                setContactEmails.add(objDataReceivedWrapper.primaryContact);
            }else{
                objOpportunityCreationWrapper.objErrorHandler.addError( 'ERR01', 'Email is null or has an invalid format: ' + objDataReceivedWrapper.primaryContact);
            }
        }

        for(Account objSolToAccount : [SELECT Id, Name, ERP_Customer_Id__c, Territory_Region__c, OwnerId FROM Account WHERE ERP_Customer_Id__c IN :setCustomerIds]){
            if(!mapCustomerIds.containsKey(objSolToAccount.ERP_Customer_Id__c)){
                mapCustomerIds.put(objSolToAccount.ERP_Customer_Id__c, objSolToAccount);
            }
        }
        
        for(Customer_Master_Data__c cmd : new CustomerMasterDataSelector().selectByAccountERPId(setCustomerIds)) {
            mapCMD.put(cmd.ERP_Customer_Id__c, cmd);
        }

        for(Contact objContact: [SELECT Id, Name, Email FROM Contact WHERE Email IN :setContactEmails]){
            if(!mapContacts.containsKey(objContact.Email)){
                mapContacts.put(objContact.Email, objContact);
            }
        }
    }

    private static void fillCustomerIds(Set<String> setCustomerIds, QuoteCreationAPIRequestWrapper objDataReceivedWrapper) {
        // accounts
        if(String.isNotBlank(objDataReceivedWrapper.soldTo)){
            setCustomerIds.add(objDataReceivedWrapper.soldTo);
        }
        if(String.isNotBlank(objDataReceivedWrapper.ultimateConsignee)){
            setCustomerIds.add(objDataReceivedWrapper.ultimateConsignee);
        }
        if(String.isNotBlank(objDataReceivedWrapper.shipTo)){
            setCustomerIds.add(objDataReceivedWrapper.shipTo);
        }
        if(String.isNotBlank(objDataReceivedWrapper.billTo)){
            setCustomerIds.add(objDataReceivedWrapper.billTo);
        }
    }


    /**
     * @description Method to create Opportunities
     * @author Vinay  S Reddy | 10-30-2024
     * @param lstDataReceivedWrapper
     * @param mapSoldTo
     * @param mapUltimateConsignee
     * @return Opportunity
     **/
    public  static List<WebGeneratedQuoteOpportunityCreation.ProccesedData> createOpportunity(List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper,
        Map<String, Account> mapCustomerIds, Map<String, Contact> mapContacts){
        List<WebGeneratedQuoteOpportunityCreation.ProccesedData> processDatas = new List<WebGeneratedQuoteOpportunityCreation.ProccesedData>();
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for(QuoteCreationAPIOppCartWrapper objOpportunityCreationWrapper : lstOppCreationWrapper){
            Opportunity opp = getOpportunity(objOpportunityCreationWrapper, mapCustomerIds, mapContacts);
            if(objOpportunityCreationWrapper.objErrorHandler.lstErrors.isEmpty()){
                opportunities.add(opp);
                processDatas.add(new WebGeneratedQuoteOpportunityCreation.ProccesedData(objOpportunityCreationWrapper.objRequestWrapper, opp));
            }
        }

        insertOpportunities(opportunities, lstOppCreationWrapper);
        QuoteCreationAPIErrorHandler.insertInterfaceLog(lstOppCreationWrapper, STRING_OPPORTUNITY_STEP);
        QuoteCreationAPIEmailMessagingService.handleErrorEmail(lstOppCreationWrapper, mapCustomerIds, STRING_OPPORTUNITY_EMAIL, null);

        ilib_LogEvent.message('createOpportunity processDatas:' + JSON.serializePretty(processDatas));

        return processDatas;
    }


    /**
    * @description Method to set up the data of an Opportunity
    * @author Arquimidez Mora | 11-06-2024 
    * @param objOpportunityCreationWrapper 
    * @param mapCustomerIds 
    * @param mapContacts 
    * @return Opportunity 
    **/
    private static Opportunity getOpportunity(QuoteCreationAPIOppCartWrapper objOpportunityCreationWrapper, Map<String, Account> mapCustomerIds, Map<String, Contact> mapContacts) {
        QuoteCreationAPIRequestWrapper objDataReceivedWrapper = objOpportunityCreationWrapper.objRequestWrapper;
        Account objSoldTo = mapCustomerIds.get(objDataReceivedWrapper.soldTo);
        Contact objContact = mapContacts.get(objDataReceivedWrapper.primaryContact);
        String strRecordTypeId = '';
        Opportunity webGeneratedOpportunity = new Opportunity();
        
        //Selecting Recordtype based on Distribution Channel
        if(String.isNotBlank(objDataReceivedWrapper.distributionChannel) && (objDataReceivedWrapper.distributionChannel == DIST_CHANNEL_01 || objDataReceivedWrapper.distributionChannel == DIST_CHANNEL_02)){
            if(objDataReceivedWrapper.distributionChannel == DIST_CHANNEL_01){
                strRecordTypeId = OPP_DIRECT_REORDER;
            } else if (objDataReceivedWrapper.distributionChannel == DIST_CHANNEL_02){
                strRecordTypeId = OPP_INDIRECT_REORDER;
                webGeneratedOpportunity.Distributor__c = objSoldTo?.Id;
            }
            webGeneratedOpportunity.RecordTypeId = strRecordTypeId;
        }else{
            objOpportunityCreationWrapper.objErrorHandler.addError( 'ERR02', 'Distribution channel received invalid value: ' +objDataReceivedWrapper.distributionChannel);
        }

        webGeneratedOpportunity.Name = objSoldTo?.Name+'_' + System.Now() + '_'+objSoldTo?.ERP_Customer_Id__c + '_' + STRING_OPPORTUNITY_NAME_WEBGENERATED;
        if( objSoldTo!=null ){
            webGeneratedOpportunity.AccountId = objSoldTo.Id;
            webGeneratedOpportunity.Ultimate_Consignee__c = objSoldTo.Id;
            webGeneratedOpportunity.OwnerId = objSoldTo.OwnerId;
        }else {
            objOpportunityCreationWrapper.objErrorHandler.addError( 'ERR03', 'Account was not found for customer Id: ' +objDataReceivedWrapper.soldTo);
        }
        
        webGeneratedOpportunity.Type = STRING_OPPORTUNITY_TYPE_WEB_GENERATED;
        webGeneratedOpportunity.StageName = STRING_OPPORTUNITY_STAGE_DEVELOP;
        
        webGeneratedOpportunity.CloseDate = Date.today().addDays(30);
        
        webGeneratedOpportunity.Opportunity_Forecast_Category__c = STRING_OPPORTUNITY_FORECAST_NOT_FORECASTED;
        
        webGeneratedOpportunity.CurrencyIsoCode = objDataReceivedWrapper.quoteCurrency;
        if( objContact!=null){
            webGeneratedOpportunity.Primary_Contact__c = objContact.Id;
        } else {
            objOpportunityCreationWrapper.objErrorHandler.addError( 'ERR04', 'Contact could not be found for email: ' + objDataReceivedWrapper.primaryContact);
        }
        
        webGeneratedOpportunity.Sales_Org_Override__c = objDataReceivedWrapper.salesOrg;
        webGeneratedOpportunity.Sold_to_Distribution_Channel__c = objDataReceivedWrapper.distributionChannel;
        
        webGeneratedOpportunity.Amount = 0;
        
        webGeneratedOpportunity.EcomId__c = objDataReceivedWrapper.ecomId;
        if( objDataReceivedWrapper.requestType!=null){
            webGeneratedOpportunity.RequestType__c =objDataReceivedWrapper.requestType;
        } else {
            objOpportunityCreationWrapper.objErrorHandler.addError( 'ERR05', 'Request Type need to be an accepted Type, received invalid value: ' + objDataReceivedWrapper.requestType);
        }
        webGeneratedOpportunity.Is_Updated_By_System__c  = true;
        return webGeneratedOpportunity;
    }

    /**
     * @description method to handle success or failure inserting
     * @author  Vinay S Reddy | 10-30-2024
     * @param lstOpportunities
     * @return list of success Opportunities.
     **/
    public static List<Opportunity> insertOpportunities(List <Opportunity> lstOpportunities, List<QuoteCreationAPIOppCartWrapper> lstOppCreationWrapper) {
        List<Opportunity> successOpps = new List<Opportunity>();
        List<OpportunityContactRole> contactRoles = new List<OpportunityContactRole>();
        Database.SaveResult[] saveResults = Database.insert(lstOpportunities, false);
        Integer i = 0;
        ilib_LogEvent.push(LOG_TITLE + '.insertOpportunities');
        for (Database.SaveResult saveResult: saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error e: saveResult.getErrors()) {
                    ilib_LogEvent.info(STRING_INSERTING_OPPORTUNITY + ' Error: ' + e.getStatusCode() + ' - ' + e.getMessage());
                    lstOppCreationWrapper[i].objErrorHandler.addError( 'ERR06',  'Error while inserting opportunity: ' + e.getStatusCode() + ' - ' + e.getMessage());
                }
            }
            if (saveResult.isSuccess()) {
                lstOppCreationWrapper[i].strOpportunityId = saveResult.getId();
                ilib_LogEvent.info('Success Status for opportunity records  ' + saveResult);
                Opportunity opp = lstOpportunities[i]; 
                if(opp.Primary_Contact__c != null){
                    fillContacRoles(opp, contactRoles);
                }
                successOpps.add(opp);
            }
            i++;
        }
        if(!contactRoles.isEmpty()){
            WebGeneratedQuoteOpportunityCreation.insertObjects(contactRoles);
        }
        ilib_LogEvent.pop();
        return successOpps;
    }

    /**
    * @description Method to create a Contact Role
    * @author Arquimidez Mora | 11-06-2024 
    * @param opp 
    * @param contactRoles 
    **/
    public static void fillContacRoles(Opportunity opp, List<OpportunityContactRole> contactRoles) {
        OpportunityContactRole contactRoleforWebGenOpp = new OpportunityContactRole();
        contactRoleforWebGenOpp.OpportunityId = opp.Id;
        contactRoleforWebGenOpp.Role = STRING_CONTACT_ROLE_MAIN_CONTACT;
        contactRoleforWebGenOpp.IsPrimary = true;
        contactRoleforWebGenOpp.ContactId = opp.Primary_Contact__c;
        contactRoles.add(contactRoleforWebGenOpp);
    }
}