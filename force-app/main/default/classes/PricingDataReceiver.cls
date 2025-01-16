/**
 * @author Akshay Mohan
 * @date   2018-06-26
 * @description    US-1101:  List Price Synchronization to DCP (INT_O-020-002)
 * @Test Class coverage for atleast 90%.      
 *      - TestPricingDataReceiver
 *    @Test Class coverage for at least 75% 
 *      - TestPricingDataReceiver
 * Modification Log:
 * -----------------
 * Akshay Mohan        27/06/2018   : Comments Updated    Original Version
 * Aman Tyagi          31/03/2022   : Codescan fixes
 * -----------------
 */
@RestResource(urlMapping='/PricingSyncInterface/*')
global with sharing class PricingDataReceiver extends ilib_RestReceiver {

    private static PricingWrapper wrapPricing;

    @HttpPost

    /*
    * @Author: Akshay Mohan
    * @Description : this method has logic for upsert the incoming values
    * @param : null
    * @return: void 
    */ 
    global static void upsertIncomingValues()
    {
        // get the (non-static context) details
        PricingDataReceiver instantiated = new PricingDataReceiver();
        ilib_RestInterface.InterfaceDetails interfaceDetails = instantiated.interfaceDetails;
        ilib_LogEvent.setTitle(interfaceDetails.name);
        String strRestError = null;
        Id primaryRecordId;

        String strJsonInput = ((String.isNotBlank(RestContext.request.requestBody.toString())) ? (RestContext.request.requestBody.toString()) : (null));
        System.debug(LoggingLevel.INFO, 'JSON Input:\n' + strJsonInput);

        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, RestContext.request);

        try
        {
            if (String.isBlank(strJsonInput)) throw new UtilsRest.InterfaceException('Input JSON is missing');

            deserializeInputs(strJsonInput);
            instantiated.addFriendlyJsonToLog(log, wrapPricing);

            primaryRecordId = upsertIncomingValuesImpl();
        }

        catch (Exception e){
            strRestError = UtilsRest.handleCustomRestError(e);
        }

        Boolean isSuccess = String.isBlank(strRestError);
        if (isSuccess)
        {
            UtilsRest.handleCustomRestSuccess();
        }

        ilib_LogInterface.finalizeLog(
            log,
            (isSuccess ? ilib_LogInterface.RESULT_SUCCESS : ilib_LogInterface.RESULT_FAIL),
            (isSuccess ? null : 'Exception: ' + strRestError),
            primaryRecordId
        );

        if (!isSuccess)
        {
            KnownErrorNotifications.checkForKnownErrors(interfaceDetails, log.logRecordId, primaryRecordId, null, ilib_LogInterface.RESULT_FAIL, strRestError);
            
            ilib_LogEvent.push('upsertIncomingValues');
            ilib_LogEvent.error('Error Description' + strRestError +'----');
            ilib_LogEvent.pop();
        }
        ilib_LogEvent.emit();
    }

    private static void deserializeInputs(String jsonInput)
    {
        wrapPricing = (PricingWrapper) System.JSON.deserialize(jsonInput, PricingWrapper.class);
        System.debug('wrapPricing::::'+wrapPricing);
    }

    private static Id upsertIncomingValuesImpl()
    {
        // Register custom helpers
        ilib_UpsertHelpers.PriceListUnitOfWorkHelper priceListWork = new ilib_UpsertHelpers.PriceListUnitOfWorkHelper();
        ilib_UpsertHelpers.PliUnitOfWorkHelper priceListItemWork = new ilib_UpsertHelpers.PliUnitOfWorkHelper();
        ilib_UpsertHelpers.PriceBookEntryUnitOfWorkHelper priceBookEntryWork = new ilib_UpsertHelpers.PriceBookEntryUnitOfWorkHelper(); // Helper for price book entry


        //Unit of Work
        ilib_SObjectUnitOfWork uow = new ilib_SObjectUnitOfWork(
            new List<Schema.SObjectType> {
                PricebookEntry.SObjectType,
                Apttus_Config2__PriceList__c.SObjectType,
                Apttus_Config2__PriceListItem__c.SObjectType
        });


        uow.registerWork(priceBookEntryWork);
        uow.registerWork(priceListWork);
        uow.registerWork(priceListItemWork);

        Map<String, Apttus_Config2__PriceList__c> externalIdToPriceList = new Map<String, Apttus_Config2__PriceList__c>();
        Map<String, Apttus_Config2__PriceListItem__c> externalIdsToPriceListItem = new Map<String, Apttus_Config2__PriceListItem__c>();

        Map<String, List<Apttus_Config2__PriceListItem__c>> productCodeToPLIs = new Map<String, List<Apttus_Config2__PriceListItem__c>>();

        //DCP-58381 start
        Map<Id, List<String>> productAndAllCurrencyMap = new Map<Id, List<String>>(); // Map of product and all currencies related to it (e.g PRD_ID -> {INR, EUR, USD})
        Id standardPriceBookId;  // Id of standard price book 
        List<String> newPriceBookEntry = new List<String>(); // this is created to prevent duplicate price book entry
        //DCP-58381 end

        for (PricingWrapper.priceList wrapPrice: wrapPricing.priceList) 
        {
            Apttus_Config2__PriceList__c objPriceList;
            if (externalIdToPriceList.containsKey(wrapPrice.PriceListExternalId))
            {
                objPriceList = externalIdToPriceList.get(wrapPrice.PriceListExternalId);
            }
            else
            {
                objPriceList = wrapPrice.getSObject();
                externalIdToPriceList.put(wrapPrice.PriceListExternalId, objPriceList);
                priceListWork.registerUpsert(objPriceList);
            }
            System.debug('check inside');

            for (PricingWrapper.priceListItems wrapPriceListsItem : wrapPrice.priceListItems)
            {
                System.debug('check inside if');
                Apttus_Config2__PriceListItem__c pli;
                if (externalIdsToPriceListItem.containsKey(wrapPriceListsItem.PriceListItemExternalId))
                {
                    pli = externalIdsToPriceListItem.get(wrapPriceListsItem.PriceListItemExternalId);
                }
                else
                {
                    pli = wrapPriceListsItem.getSObject();
                    externalIdsToPriceListItem.put(wrapPriceListsItem.PriceListItemExternalId, pli);
                    //priceListWork.registerUpsert(pli);

                    if (productCodeToPLIs.containsKey(wrapPriceListsItem.ProductId))
                        productCodeToPLIs.get(wrapPriceListsItem.ProductId).add(pli);
                    else
                            productCodeToPLIs.put(wrapPriceListsItem.ProductId, new List<Apttus_Config2__PriceListItem__c>{pli});

                    uow.registerRelationship(pli, Apttus_Config2__PriceListItem__c.Apttus_Config2__PriceListId__c, objPriceList);
                }
            }
        }

        //get existing price book entries data
        productAndAllCurrencyMap = getExistingPriceBookEntries(productCodeToPLIs.keySet()); 
        //get standard price book
        standardPriceBookId = getStandardPriceBookId();

        for (Product2 pr : [SELECT id, ProductCode FROM Product2 WHERE ProductCode IN :productCodeToPLIs.keySet()])
        {
            if (productCodeToPLIs.containsKey(pr.ProductCode))
            {
                for (Apttus_Config2__PriceListItem__c pli : productCodeToPLIs.get(pr.ProductCode))
                {
                    pli.Apttus_Config2__ProductId__c = pr.Id;
                    priceListItemWork.registerUpsert(pli);

                    if(standardPriceBookId != null){

                        //create and register price book entry DCP-58381
                        PricebookEntry priceBookEntryObj = createPriceBookEntries(pli, productAndAllCurrencyMap, standardPriceBookId, newPriceBookEntry);
                        if(priceBookEntryObj != null){
                            priceBookEntryWork.registerUpsert(priceBookEntryObj);
                        }
                    }
                }
            }
        }

        // any business logic for incoming values goes in here
        businessRules(uow);

        uow.commitWork();
        //priceBookEntryWork.doWork(); // Upsert price book entry
        return null; // not likely a single price record
    }

    /*
    * @Author: Rohan
    * @Description : static method for business rules
    * @param : ilib_SObjectUnitOfWork uow
    * @return: void
    */ 
    public static void businessRules(ilib_SObjectUnitOfWork uow) { }

    /*
    * @Author: Jitesh
    * @Description : static method for Creating price book entries
    * @param : pliObj - Price List Item Object, productWithAllCurrencyMap - Map of existing price book entries, standrdPriceBookId - id of the standard price book, newPriceBookEntry - to avoid duplicate
    * @return: PricebookEntry
    */
    public static PricebookEntry createPriceBookEntries(Apttus_Config2__PriceListItem__c pliObj, Map<Id, List<String>> productWithAllCurrencyMap, Id standardPriceBookId, List<String> newPriceBookEntry){

        PricebookEntry newPriceBookEntryObj;

        if(productWithAllCurrencyMap.containsKey(pliObj.Apttus_Config2__ProductId__c) && !productWithAllCurrencyMap.get(pliObj.Apttus_Config2__ProductId__c).contains(pliObj.CurrencyIsoCode) &&
            !newPriceBookEntry.contains(pliObj.Apttus_Config2__ProductId__c + '_' +pliObj.CurrencyIsoCode)){

            //create PEB
            newPriceBookEntryObj = createPriceBookEntry(pliObj, standardPriceBookId);
            newPriceBookEntry.add(pliObj.Apttus_Config2__ProductId__c + '_' +pliObj.CurrencyIsoCode); // prevent duplicate
        }
        
        else if(!newPriceBookEntry.contains(pliObj.Apttus_Config2__ProductId__c + '_' +pliObj.CurrencyIsoCode) 
        && !productWithAllCurrencyMap.containsKey(pliObj.Apttus_Config2__ProductId__c)){
            
            //create PEB
            newPriceBookEntryObj = createPriceBookEntry(pliObj, standardPriceBookId);
            newPriceBookEntry.add(pliObj.Apttus_Config2__ProductId__c + '_' +pliObj.CurrencyIsoCode); // prevent duplicate
        }

        return newPriceBookEntryObj;
    }

    /*
    * @Author: Jitesh
    * @Description : static method for fetching existing price book entries
    * @param : productCodeSet
    * @return: Map<Id, List<String>>
    */
    public static Map<Id, List<String>> getExistingPriceBookEntries(Set<String> productCodeSet) {
        
        Map<Id, List<String>> productAndCurrencyMap = new Map<Id, List<String>>();

        for (PricebookEntry priceBookEntryObj : new PriceBookEntrysSelector().selectByProductCode(productCodeSet)) {
            
            if(productAndCurrencyMap.containsKey(priceBookEntryObj.Product2Id)){

                productAndCurrencyMap.get(priceBookEntryObj.Product2Id).add(priceBookEntryObj.CurrencyIsoCode);
            } 
            else{
                productAndCurrencyMap.put(priceBookEntryObj.Product2Id,new List<String>{priceBookEntryObj.CurrencyIsoCode});
            }
        }
        return productAndCurrencyMap;
    } 

    /*
    * @Author: Jitesh
    * @Description : static method for fetching standard price book
    * @param : 
    * @return: Id
    */
    public static Id getStandardPriceBookId(){

        Id standardPriceBookId;
        List<Pricebook2> priceBookList = new PriceBook2Selector().selectByStandardPriceBook();
        if(!priceBookList.isEmpty()){

            standardPriceBookId = priceBookList[0].Id;
        }
        return standardPriceBookId;
    } 

    /*
    * @Author: Jitesh
    * @Description : static method for preparing price book Entry with default values
    * @param : pliObj - Price List Item Object, standardPriceBookId - Standard Price Book Id
    * @return: PricebookEntry
    */
    public static PricebookEntry createPriceBookEntry(Apttus_Config2__PriceListItem__c pliObj, Id standardPriceBookId) {
        
        PricebookEntry newPriceBookEntryObj = new PricebookEntry();
        newPriceBookEntryObj.UnitPrice = 0;
        newPriceBookEntryObj.CurrencyIsoCode = pliObj.CurrencyIsoCode; 
        newPriceBookEntryObj.Pricebook2Id = standardPriceBookId;
        newPriceBookEntryObj.Product2Id = pliObj.Apttus_Config2__ProductId__c;
        newPriceBookEntryObj.IsActive = true;

        return newPriceBookEntryObj;
    }

}