global class BatchStagedPLItems { //extends ilib_ScheduleAndBatch implements Database.Stateful {

//    global Integer successCount;
//    global Integer errorCount;
//
//    global override Database.QueryLocator start(Database.BatchableContext BC)
//    {
//        initCounts();
//
//        return Database.getQueryLocator('SELECT Id, CreatedDate, '
//                + 'Contract_Number__c, CurrencyIsoCode, PLI_Key__c, '
//                + 'CustomerId__c, SalesOrganization__c, DistributionChannel__c, Division__c, '
//                + 'MaterialId__c, PriceListType__c, ListPrice__c, CustomerPrice__c, '
//                + 'Quantity__c, UOM__c, ValidFrom__c, ValidTo__c, Processed_Date__c ' //, Success_Date__c, Failure_Count__c '
//                + 'FROM Apttus_PLI_Staging__c '
//                + 'WHERE Processed_Date__c = null '
//                + 'ORDER BY Contract_Number__c, CurrencyIsoCode, CreatedDate');
//    }
//
//    @TestVisible private void initCounts()
//    {
//        successCount = 0;
//        errorCount = 0;
//    }
//
//    global override void execute(Database.BatchableContext BC, List<sObject> stagingRows)
//    {
//        ilib_LogEvent.rootTitle = 'Staged PLI Processing';
//        ilib_LogEvent.push('BatchStagedPLItems.execute');
//
//        try
//        {
//            Map<String, Apttus_Config2__PriceList__c> contractNumberToPriceList =
//                    generateNumberToPriceList(stagingRows);
//
//            generatePriceListItems(stagingRows, contractNumberToPriceList);
//        }
//        catch (Exception e)
//        {
//            ApexExceptions.emit('BatchStagedPLItems', e);
//        }
//
//        ilib_LogEvent.pop();
//        ilib_LogEvent.emit();
//    }
//
//    global override void finish(Database.BatchableContext BC)
//    {
//        Map<String, String> resultCounts = new Map<String, String> {
//            'Success Count' => String.valueOf(successCount),
//            'Error Count' => String.valueOf(errorCount)
//        };
//
//        ilib_LogEvent.quickEmit('PLI Staging Batch Finished', resultCounts);
//
//        ilib_RestInterface.InterfaceDetails interfaceDetails = ilib_RestInterface.getInterfaceDetails(String.valueOf(this).split(':')[0]);
//        ilib_LogInterface.LogDetails log = ilib_LogInterface.initiateLog(interfaceDetails, JSON.serializePretty(resultCounts));
//        ilib_LogInterface.finalizeLog(log, ilib_LogInterface.RESULT_SUCCESS, null, null);
//    }
//
//
//
//    private Map<String, Apttus_Config2__PriceList__c> generateNumberToPriceList(List<Apttus_PLI_Staging__c> stagingRows)
//    {
//        ilib_LogEvent.push('generateNumberToPriceList');
//
//        Map<String, Apttus_Config2__PriceList__c> contractNumberToPriceList = new Map<String, Apttus_Config2__PriceList__c>();
//
//        // Contract_Number__c is a formula field which is customerId_salesArea
//        // this is what we are using for contract number, the same value
//        // is stored on account_sales_area as well as priceList
//        // ex data: 6000006891_SG010100
//        Set<String> setStagedContractNumbers = UtilsCollection.getSetOfStrings(stagingRows, 'Contract_Number__c');
//        ilib_LogEvent.message('setStagedContractNumbers ' + setStagedContractNumbers);
//
//        // retrieve matching price lists
//        List<Apttus_Config2__PriceList__c> lstExtantPriceLists = new ApttusPriceListsSelector().selectByContract(setStagedContractNumbers);
//
//        // compare extant lists with the list names in the staged rows
//        for (Apttus_Config2__PriceList__c pl : lstExtantPriceLists)
//        {
//            String strPriceListName = pl.Name;
//            if (setStagedContractNumbers.contains(strPriceListName))
//                // PL exists, all good
//                contractNumberToPriceList.put(strPriceListName, pl);
//                // remove from list, those that are left will be created later
//                setStagedContractNumbers.remove(strPriceListName);
//        }
//        ilib_LogEvent.message('setStagedContractNumbers (remaining after query) ' + setStagedContractNumbers);
//
//        // if any remain, they need to be created
//        if (!setStagedContractNumbers.isEmpty())
//        {
//            Map<String, String> contractNumbersToCurrency = findCurrencyForNewContracts(stagingRows);
//
//            // NOTE: this method inserts the PLs
//            // don't love the lack of encapsulation but the conciseness is nice so I'll call it ok
//            Map<String, Apttus_Config2__PriceList__c> moreContractNumberToPriceList = createPriceLists(setStagedContractNumbers, contractNumbersToCurrency);
//            for (String contractNumber : moreContractNumberToPriceList.keySet())
//            {
//                contractNumberToPriceList.put(contractNumber, moreContractNumberToPriceList.get(contractNumber));
//            }
//        }
//        ilib_LogEvent.message('final contractNumberToPriceList ' + contractNumberToPriceList);
//
//        ilib_LogEvent.pop();
//        return contractNumberToPriceList;
//    }
//
//    private Map<String, String> findCurrencyForNewContracts(List<Apttus_PLI_Staging__c> stagingRows)
//    {
//        Map<String, String> contractNumbersToCurrency = new Map<String, String>();
//        for (Apttus_PLI_Staging__c rec : stagingRows)
//            contractNumbersToCurrency.put(rec.Contract_Number__c, rec.CurrencyIsoCode);
//
//        return contractNumbersToCurrency;
//    }
//
//    private void generatePriceListItems(List<Apttus_PLI_Staging__c> lstStagingRows, Map<String, Apttus_Config2__PriceList__c> contractNumberToPriceList)
//    {
//        ilib_LogEvent.push('generatePriceListItems');
//        List<Apttus_Config2__PriceListItem__c> lstPlisToUpsert = new List<Apttus_Config2__PriceListItem__c>();
//
//        // TODO (error reruns): filter out successfully processed only
//        // filter out processed rows, these rows were queried for and processed in a prior batch
//        for (Integer i = lstStagingRows.size() - 1; i >= 0; i--)
//        {
//            if (lstStagingRows.get(i).Processed_Date__c != null)
//                lstStagingRows.remove(i);
//        }
//
//        // PLI_Key__c is a combination of contract, material, and currency
//        // other than date range it's a unique identifier of a PLI
//        Set<String> setPliKeys = UtilsCollection.getSetOfStrings(lstStagingRows, 'PLI_Key__c');
//        ilib_LogEvent.message('setPliKeys ' + setPliKeys);
//
//        // combine batched staging rows with extant staging rows, those that have the same PLI Keys
//        List<Apttus_PLI_Staging__c> lstAllRelevantStagingRows = getAllRelevantStagingRows(lstStagingRows, setPliKeys);
//
//        // group staging rows by PLI key
//        Map<String, List<Apttus_PLI_Staging__c>> keyToStagingRows =
//                (Map<String, List<Apttus_PLI_Staging__c>>)UtilsCollection.getMapOfStringToSObjects(lstAllRelevantStagingRows, 'PLI_Key__c');
//
//        // determine the most recent staging row for each key value
//        // the most recent one is the one that will get transformed to a PLI
//        // the rest are obsolete
//        Map<String, Apttus_PLI_Staging__c> keyToMostRecentStagingRow = getKeyToMostRecentStagingRow(keyToStagingRows);
//        ilib_LogEvent.message('keyToMostRecentStagingRow ' + keyToMostRecentStagingRow);
//
//        // query and group PLI rows by PLI key
//        Map<String, List<Apttus_Config2__PriceListItem__c>> keyToExtantPlis = getKeyToExtantPlis(setPliKeys);
//
//        Map<String, String> materialNumberToCategoryGroup = retreiveCategoryGroups(lstStagingRows);
//
//        // process each staging row
//        // we will end up with a new PLI row
//        // and may deactivate some extant PLI rows along the way
//        for (String key : keyToMostRecentStagingRow.keySet())
//        {
//            Apttus_PLI_Staging__c stagingRow = keyToMostRecentStagingRow.get(key);
//            ilib_LogEvent.message('processing stagingRow ' + stagingRow);
//
//            // transform the staging row to a PLI
//            Id priceListId = contractNumberToPriceList.get(stagingRow.Contract_Number__c).Id;
//            lstPlisToUpsert.add(stagingToPLI(stagingRow, priceListId, materialNumberToCategoryGroup));
//
//            // if there are no matching PLIs we are done with this staging row
//            if (!keyToExtantPlis.containsKey(key))
//                continue;
//
//            // deactivate any extant PLI rows who's dates overlapping with the staging row
//            for (Apttus_Config2__PriceListItem__c matchingPli : keyToExtantPlis.get(key))
//            {
//                if (dateRangesOverlap(stagingRow, matchingPli))
//                {
//                    ilib_LogEvent.message('pli was a match, deactivating ' + matchingPli);
//                    matchingPli.Apttus_Config2__Active__c = false;
//                    lstPlisToUpsert.add(matchingPli);
//                }
//            }
//        }
//
//        List<Database.UpsertResult> lstResults = Database.upsert(lstPlisToUpsert, false);
//
//        // TODO (error reruns): different values
//        // mark all relevant staging rows as processed
//        for (Apttus_PLI_Staging__c staged : lstAllRelevantStagingRows)
//            staged.Processed_Date__c = Date.today();
//        update lstAllRelevantStagingRows;
//
//        handleUpsertResults(lstResults);
//        ilib_LogEvent.pop();
//    }
//
//    private void handleUpsertResults(List<Database.UpsertResult> lstResults)
//    {
//        for (Database.UpsertResult res : lstResults)
//        {
//            if (res.isSuccess())
//            {
//                successCount = successCount + 1;
//            }
//            else
//            {
//                errorCount = errorCount + 1;
//
//                // quick serialize error description
//                Map<String, String> errorDescription = new Map<String, String>();
//                for (Integer i = 0; i < res.getErrors().size(); i++)
//                    errorDescription.put('Error ' + i, res.getErrors().get(i).getMessage());
//
//                ilib_LogEvent.quickEmit('PLI Staging Batch Error', errorDescription);
//            }
//        }
//    }
//
//    private Boolean dateRangesOverlap(Apttus_PLI_Staging__c stagingRow, Apttus_Config2__PriceListItem__c pliRow)
//    {
//        if (String.isBlank(stagingRow.ValidFrom__c) || String.isBlank(stagingRow.ValidTo__c)) return false;
//        if (pliRow.Apttus_Config2__EffectiveDate__c == null || pliRow.Apttus_Config2__ExpirationDate__c == null) return false;
//
//        // using algorithm
//        // dateRangesOverlap = max(start1, start2) < min(end1, end2)
//        // NOTE: should the algorithm part go in UtilsObject?
//
//        Datetime dtStagingStart = UtilsObject.parseSapDate(stagingRow.ValidFrom__c, true);
//        Datetime dtStagingEnd = UtilsObject.parseSapDate(stagingRow.ValidTo__c, false);
//        Datetime dtMaxStartDate = (dtStagingStart > pliRow.Apttus_Config2__EffectiveDate__c ? dtStagingStart : pliRow.Apttus_Config2__EffectiveDate__c);
//        Datetime dtMinEndDate = (dtStagingEnd > pliRow.Apttus_Config2__ExpirationDate__c ?  pliRow.Apttus_Config2__ExpirationDate__c : dtStagingEnd);
//
//        return (dtMaxStartDate < dtMinEndDate);
//    }
//
//    private List<Apttus_PLI_Staging__c> getAllRelevantStagingRows(List<Apttus_PLI_Staging__c> stagingRows, Set<String> setPliKeys)
//    {
//        List<Apttus_PLI_Staging__c> lstAllRelevantStagingRows = new List<Apttus_PLI_Staging__c>();
//
//        // TODO (error reruns): different criteria
//        // query for staging rows outside the current batch which have the same PLI keys
//        Set<Id> stagingRowIds = UtilsCollection.getSetOfIds(stagingRows, 'Id');
//        List<Apttus_PLI_Staging__c> extantStagingRows = new ApttusPliStagingsSelector().selectByContractsWithCurrencies(setPliKeys, stagingRowIds);
//
//        // combine two lists and return
//        lstAllRelevantStagingRows.addAll(stagingRows);
//        lstAllRelevantStagingRows.addAll(extantStagingRows);
//        return lstAllRelevantStagingRows;
//    }
//
//    private Map<String, Apttus_PLI_Staging__c> getKeyToMostRecentStagingRow(Map<String, List<Apttus_PLI_Staging__c>> keyToStagingRows)
//    {
//        Map<String, Apttus_PLI_Staging__c> keyToMostRecentStagingRow = new Map<String, Apttus_PLI_Staging__c>();
//        for (String key : keyToStagingRows.keySet())
//        {
//            List<Apttus_PLI_Staging__c> candidates = keyToStagingRows.get(key);
//            DateTime dtMostRecentCandidateDate = DateTime.newInstance(1900, 1, 1); // start with arbitrarily old date
//            for (Apttus_PLI_Staging__c candidate : candidates)
//            {
//                if (candidate.CreatedDate > dtMostRecentCandidateDate)
//                {
//                    dtMostRecentCandidateDate = candidate.CreatedDate;
//                    keyToMostRecentStagingRow.put(key, candidate);
//                }
//            }
//        }
//
//        return keyToMostRecentStagingRow;
//    }
//
//    private Map<String, List<Apttus_Config2__PriceListItem__c>> getKeyToExtantPlis(Set<String> setPliKeys)
//    {
//        List<Apttus_Config2__PriceListItem__c> extantPlis = new ApttusPriceListItemsSelector().selectByContractsWithCurrencies(setPliKeys);
//
//        return (Map<String, List<Apttus_Config2__PriceListItem__c>>)UtilsCollection.getMapOfStringToSObjects(extantPlis, 'PLI_Key__c');
//    }
//
//    private Map<String, Apttus_Config2__PriceList__c> createPriceLists(Set<String> setContractNumbers, Map<String, String> contractNumbersToCurrency)
//    {
//        Map<String, Apttus_Config2__PriceList__c> contractNumberToPriceList = new Map<String, Apttus_Config2__PriceList__c>();
//
//        for (String strContractNumber : setContractNumbers)
//        {
//            Apttus_Config2__PriceList__c priceList = generatePL(strContractNumber, contractNumbersToCurrency);
//            contractNumberToPriceList.put(priceList.Name, priceList);
//        }
//
//        insert contractNumberToPriceList.values();
//        return contractNumberToPriceList;
//    }
//
//    private Map<String, String> retreiveCategoryGroups(List<Apttus_PLI_Staging__c> lstStagingRows)
//    {
//        Map<String, String> materialNumberToCategoryGroup = new Map<String, String>();
//        Set<String> setMaterialNumbers = UtilsCollection.getSetOfStrings(lstStagingRows, 'MaterialId__c');
//        List<Product2> categoryDetails = [SELECT Id, Material_Number__c,
//        (SELECT Id, Category_Group__c FROM Product_Sales_Areas__r LIMIT 1)
//        FROM Product2
//        WHERE Material_Number__c IN :setMaterialNumbers];
//
//        for (Product2 p : categoryDetails)
//        {
//            if (p.Product_Sales_Areas__r == null) continue;
//            Product_Sales_Area__c psa = p.Product_Sales_Areas__r;
//            if (String.isBlank(psa.Category_Group__c)) continue;
//            if (String.isBlank(p.Material_Number__c)) continue;
//
//            materialNumberToCategoryGroup.put(p.Material_Number__c, psa.Category_Group__c);
//        }
//
//        return materialNumberToCategoryGroup;
//    }
//
//
//    // NOTE: the below functions could be domain functions but there's no domain class so leave here
//
//    private Apttus_Config2__PriceList__c generatePL(String strContractNumber, Map<String, String> contractNumbersToCurrency)
//    {
//        Apttus_Config2__PriceList__c pl = new Apttus_Config2__PriceList__c(
//            Name = strContractNumber,
//            Apttus_Config2__ContractNumber__c = strContractNumber,
//            Apttus_Config2__Active__c = true
//        );
//
//        if (contractNumbersToCurrency.containsKey(strContractNumber))
//            pl.CurrencyIsoCode = contractNumbersToCurrency.get(strContractNumber);
//
//        return pl;
//    }
//
//    private Apttus_Config2__PriceListItem__c stagingToPLI(Apttus_PLI_Staging__c stagingRow, Id priceListId, Map<String, String> materialNumberToCategoryGroup)
//    {
//        Apttus_Config2__PriceListItem__c pli = new Apttus_Config2__PriceListItem__c(
//            Apttus_Config2__PriceListId__c = priceListId,
//            Apttus_Config2__ProductId__r = new Product2(Material_Number__c = stagingRow.MaterialId__c),
//            Apttus_Config2__ChargeType__c = 'Standard Price',
//            Apttus_Config2__ListPrice__c = stagingRow.ListPrice__c,
//            Customer_Specific_Price__c = stagingRow.CustomerPrice__c,
//            CurrencyIsoCode = stagingRow.CurrencyIsoCode,
//            Apttus_Config2__EffectiveDate__c = UtilsObject.parseSapDate(stagingRow.ValidFrom__c, false),
//            Apttus_Config2__ExpirationDate__c = UtilsObject.parseSapDate(stagingRow.ValidTo__c, true),
//            Apttus_Config2__PriceUom__c = transformUom(stagingRow.UOM__c),
//            Apttus_Config2__DefaultQuantity__c = stagingRow.Quantity__c,
//            Apttus_Config2__Active__c = true
//        );
//
//        if (materialNumberToCategoryGroup.containsKey(stagingRow.MaterialId__c))
//            if (materialNumberToCategoryGroup.get(stagingRow.MaterialId__c) == Products.CATEGORY_GROUP_SAP_RENEWABLE_CODE)
//            pli.Apttus_Config2__PriceType__c = PriceListItems.PRICE_TYPE_RECURRING;
////        else
////            pli.Apttus_Config2__PriceType__c = PriceListItems.PRICE_TYPE_ONE_TIME;
//        return pli;
//    }
//
//
//    private static String transformUom(String raw)
//    {
//        if (raw == 'EA') return 'Each';
//        return '';
//    }

}