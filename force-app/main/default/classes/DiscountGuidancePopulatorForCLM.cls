/*************************
 * Author : Shalin Shah
 * Description : Class to perform process and populate Discount Guidance on Agreement Line Items.
 *************************/

public without sharing class DiscountGuidancePopulatorForCLM {
    
    private final static String DELIMITER = '#';
    private final static Set<String> MATERIAL_LINE_TYPE_SET = new Set<String>{'Material', 'Price Group - Material', 'UC - Material'};
    private final static Set<String> MATERIAL_GROUP_LINE_TYPE_SET = new Set<String>{'Material Group 1', 'Price Group - Material Group 1', 'UC - Material Group 1'};
    private final static Set<String> FIELDS_TO_CHECK_FOR_UPDATE_FOR_DISCOUNT_GUIDANCE = new Set<String>{'Customer_ERP_Number__c', 'Ultimate_Consignee_ERP_Number__c', 'Sales_Org__c', 'CurrencyIsoCode', 'Material_Number__c', 'Material_Group_1__c', 'Apttus_CMConfig__StartDate__c', 'Apttus_CMConfig__LineStatus__c'};
    private static final String LOG_TITLE = 'DiscountGuidancePopulatorForCLM';
    
    /*****************
     * DGP-103, DGP-416 : Main method to derive all Discount Guidance related field values on given list of Agreement Line Items.
     *****************/
    public void deriveFieldValuesForDiscountGuidance(List<Apttus__AgreementLineItem__c> newLineItemList, Map<Id, Apttus__AgreementLineItem__c> oldLineItemMap) {
        ilib_LogEvent.push(LOG_TITLE + '.deriveFieldValuesForDiscountGuidance()');
        // Validate Line Items
        Formula.recalculateFormulas(newLineItemList); //DGP-908
        List<Apttus__AgreementLineItem__c> validLineItemList = new List<Apttus__AgreementLineItem__c>();
        
        for(Apttus__AgreementLineItem__c lineItem : newLineItemList) {
            Apttus__AgreementLineItem__c oldLineItem = oldLineItemMap != null ? oldLineItemMap.get(lineItem.Id) : null;
            
            if(isValidLineItemForDiscountGuidance(lineItem, oldLineItem)) {
                validLineItemList.add(lineItem);
            }
        }
        ilib_LogEvent.info('validLineItemList Size > '+validLineItemList.size());
        if(validLineItemList.size() > 0) {
            // Create Wrapper for Valid Agreement Line Items
            List<AgreementLineItemWrapper> lineItemWrapperList = getAgreementLineItemWrapperList(validLineItemList);
            ilib_LogEvent.info('lineItemWrapperList Size > '+lineItemWrapperList.size());
            
            // DGP-416 : To populate Customer Historical Discount
            populateCustomerHistoricalDiscount(lineItemWrapperList);
            
            // DGP-103 : To populate Median and Max Discount Guidance
            populateMedianAndMaxDiscountGuidance(lineItemWrapperList);
        }
        ilib_LogEvent.pop();
    }
    
    
    /**
     * Method to check if given line item is valid for Discount Guidance. If not valid, the line will be ignored for Discount Guidance.
     **/
    private Boolean isValidLineItemForDiscountGuidance(Apttus__AgreementLineItem__c lineItem, Apttus__AgreementLineItem__c oldLineItem) {
        ilib_LogEvent.push(LOG_TITLE + '.isValidLineItemForDiscountGuidance()');
        Boolean isValidLine = true;
        
        // Record Type : Open Offer Agreement
        if(lineItem.Agreement_Record_Type__c == Label.AgreementRecordTypeNameOpenOffer) {
            isValidLine = false;
            ilib_LogEvent.info('Open Offer Agreement > '+isValidLine);
        }
        
        // Record Type : Special Programs AND SubType : Reagent Rental
        else if(lineItem.Agreement_Record_Type__c == Label.AgreementLIRecordTypeSpecialPrograms && lineItem.Agreement_Subtype__c == Label.AgreementTypeReagentRental) {
            isValidLine = false;
            ilib_LogEvent.info('Record Type : Special Programs AND SubType : Reagent Rental > '+isValidLine);
        }
        
        // Do Not Run Discount Guidance
        else if(lineItem.Do_Not_Run_Discount_Guidance__c) {
            isValidLine = false;
            ilib_LogEvent.info('Do Not Run Discount Guidance > '+isValidLine);
        }
        
        // Line Type OR Distribution Channel is Blank
        else if(String.isBlank(lineItem.Line_Type__c) || String.isBlank(lineItem.Distribution_Channel__c)) {
            isValidLine = false;
            ilib_LogEvent.info(' Line Type OR Distribution Channel is Blank > '+isValidLine);
        }
        
        // Distribution Channel Mistmatch
        else if(lineItem.Distribution_Channel__c != lineItem.Agreement_Distribution_Channel__c) {
            isValidLine = false;
            ilib_LogEvent.info(' Distribution Channel Mistmatch > '+isValidLine);
        }
        
        // Direct Channel and Empty Customer ERP Number
        else if(lineItem.Distribution_Channel__c == Label.DirectDistributionChannelCode && String.isBlank(lineItem.Customer_ERP_Number__c)) {
            isValidLine = false;
            ilib_LogEvent.info('Direct Channel and Empty Customer ERP Number > '+isValidLine);
        }
        
        // Indirect Channel and Empty Customer ERP Number
        else if(lineItem.Distribution_Channel__c == Label.IndirectDistributionChannelCode && String.isBlank(lineItem.Ultimate_Consignee_ERP_Number__c)) {
            isValidLine = false;
            ilib_LogEvent.info('Indirect Channel and Empty Customer ERP Number > '+isValidLine);
        }
        
        // Line Type : Material  AND  blank Material Number on Line Item
        else if(MATERIAL_LINE_TYPE_SET.contains(lineItem.Line_Type__c) && String.isBlank(lineItem.Material_Number__c)) {
            isValidLine = false;
            ilib_LogEvent.info('Line Type : Material  AND  blank Material Number on Line Item > '+isValidLine);
        }
        
        // Line Type : Material Group 1
        else if(MATERIAL_GROUP_LINE_TYPE_SET.contains(lineItem.Line_Type__c)) {
            
            // Material Group Blank  OR  Material Group Metadata is Not Existing  OR  Exclude Discount Guidance for Material Group
            if(String.isBlank(lineItem.Material_Group_1__c)
                    || Material_Group__mdt.getInstance(lineItem.Material_Group_1__c) == null
                    || Material_Group__mdt.getInstance(lineItem.Material_Group_1__c).Exclude_For_Discount_Guidance__c) {
                
                isValidLine = false;
                ilib_LogEvent.info('Material Group Blank  OR  Material Group Metadata is Not Existing  OR  Exclude Discount Guidance for Material Group > '+isValidLine);
            }
        }
        
        // If No Field Updated
        else if(oldLineItem != null && !isAnyFieldUpdated(lineItem, oldLineItem, FIELDS_TO_CHECK_FOR_UPDATE_FOR_DISCOUNT_GUIDANCE)) {
            isValidLine = false;
            ilib_LogEvent.info('If No Field Updated > '+isValidLine);
        }
        
        // Existing Line 
        else if(lineItem.Apttus_CMConfig__LineStatus__c == Label.AgreementLineItemLineStatusExisting) {
            isValidLine = false;
            ilib_LogEvent.info('Existing Line > '+isValidLine);
        }
        
        ilib_LogEvent.info('Return > '+isValidLine);
        ilib_LogEvent.pop();
        return isValidLine;
    }
    
    /**
     * Method to check if any of the given set of fields is updated.
     **/
    private Boolean isAnyFieldUpdated(Apttus__AgreementLineItem__c lineItem, Apttus__AgreementLineItem__c oldLineItem, Set<String> fieldSet) {
        ilib_LogEvent.push(LOG_TITLE + '.isAnyFieldUpdated()');
        Boolean isFieldUpdated = false;
        
        for(String field : fieldSet) {
            if(lineItem.get(field) != oldLineItem.get(field)) {
            ilib_LogEvent.info('Updated '+field+' > New > '+ lineItem.get(field) +' :: Old > '+oldLineItem.get(field));
                isFieldUpdated = true;
            }
        }
        ilib_LogEvent.info('isFieldUpdated > '+isFieldUpdated);
        ilib_LogEvent.pop();
        return isFieldUpdated;
    }
    
    
    /**
     * Method to get wrapper for each agreement line item in given list.
     **/ 
    public List<AgreementLineItemWrapper> getAgreementLineItemWrapperList(List<Apttus__AgreementLineItem__c> lineItemList) {
        ilib_LogEvent.push(LOG_TITLE + '.getAgreementLineItemWrapperList()');
        // Fetch Account and related Account Sales Area records
        List<Account> accountList = getAccountAndRelatedSalesAreaRecords(lineItemList);
        
        // Process Account records
        Set<String> nationalGroupNumberSet = new Set<String>();
        Map<String, Account> erpCustomerIdWiseAccountMap = new Map<String, Account>();
        Map<String, String> erpCustIdSalesOrgDistChannelWisePriceListType = new Map<String, String>();
        
        ilib_LogEvent.info('accountList size > '+accountList.size());
        for(Account accountRec : accountList) {
            String erpCustomerId = accountRec.ERP_Customer_Id__c;
            String nationalGroupNumber = String.isNotBlank(accountRec.National_Group_Number__c) ? accountRec.National_Group_Number__c : erpCustomerId;
            
            nationalGroupNumberSet.add(nationalGroupNumber);
            erpCustomerIdWiseAccountMap.put(erpCustomerId, accountRec);
            
            setAccountSalesAreaPriceListTypeInMap(erpCustomerId, accountRec.Account_Sales_Areas__r, erpCustIdSalesOrgDistChannelWisePriceListType);
        }
        
        // National Group Number wise Customer Historical Spend
        Map<String, Customer_Historical_Spend__c> ngnWiseHistoricalSpendRecordMap = getNationalGroupNumberWiseHistoricalSpendRecord(nationalGroupNumberSet);
        
        // Currency Code Wise Conversion Rate
        Map<String, Decimal> currencyCodeWiseConversionRate = getCurrencyCodeWiseConversionRate();
        
        
        // Create Line Item Wrapper
        List<AgreementLineItemWrapper> lineItemWrapperList = new List<AgreementLineItemWrapper>();
        
        for(Apttus__AgreementLineItem__c lineItem : lineItemList) {
            String erpCustomerId = getErpCustomerIdBasedOnDistributionChannel(lineItem);
            Account accountRec = erpCustomerIdWiseAccountMap.get(erpCustomerId);
            
            AgreementLineItemWrapper wrapper = new AgreementLineItemWrapper();
            
            wrapper.agreementLineItem = lineItem;
            wrapper.erpCustomerId = erpCustomerId;
            wrapper.salesOrg = lineItem.Sales_Org__c;
            wrapper.discountGridGroup = lineItem.Discount_Grid_Group__c;
            wrapper.skuOrMG1 = getMaterialNumberOrMG1BasedOnLineType(lineItem);
            wrapper.distributionChannelCode = lineItem.Distribution_Channel__c;
            wrapper.distributionChannel = getDistributionChannelBasedOnCode(lineItem);
            wrapper.agreementLineStartDate = lineItem.Apttus_CMConfig__StartDate__c;
            wrapper.currencyIsoCode = (lineItem.Discount_Type__c == Label.AliDiscountTypePercent) ? lineItem.Agreement_Currency__c : lineItem.CurrencyIsoCode;
            
            wrapper.accountRegion = accountRec != null ? accountRec.Territory_Region__c : null;
            wrapper.billingCountry = accountRec != null ? accountRec.BillingCountry : null;
            wrapper.billingCountryCode = accountRec != null ? accountRec.BillingCountryCode : null;
            wrapper.nationalGroupNumber = (accountRec != null && String.isNotBlank(accountRec.National_Group_Number__c)) ? accountRec.National_Group_Number__c : wrapper.erpCustomerId;
            
            setCustomerHistoricalSpendDetailsInWrapper(ngnWiseHistoricalSpendRecordMap, wrapper, currencyCodeWiseConversionRate);
            
            wrapper.priceListType = erpCustIdSalesOrgDistChannelWisePriceListType.get(wrapper.erpCustomerId + DELIMITER + wrapper.salesOrg + DELIMITER + wrapper.distributionChannelCode);
            ilib_LogEvent.info('wrapper > '+wrapper);
            lineItemWrapperList.add(wrapper);
        }
        ilib_LogEvent.pop();
        return lineItemWrapperList;
    }
    
    /**
     * Method to interate through given list of Account Sales Area records and set their Price List Type in given Map.
     **/
    private void setAccountSalesAreaPriceListTypeInMap(String erpCustomerId, List<Account_Sales_Area__c> accountSalesAreaList, Map<String, String> erpCustIdSalesOrgDistChannelWisePriceListType) {
        ilib_LogEvent.push(LOG_TITLE + '.setAccountSalesAreaPriceListTypeInMap()');
        if(accountSalesAreaList == null || accountSalesAreaList.isEmpty())
            return;
        
        for(Account_Sales_Area__c accountSalesArea : accountSalesAreaList) {
            String key = erpCustomerId + DELIMITER + accountSalesArea.Sales_Organization__c + DELIMITER + accountSalesArea.Distribution_Channel__c;
            erpCustIdSalesOrgDistChannelWisePriceListType.put(key, accountSalesArea.Price_List_Type__c);
        }
        ilib_LogEvent.info('erpCustIdSalesOrgDistChannelWisePriceListType > '+ erpCustIdSalesOrgDistChannelWisePriceListType);
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to set details of Customer Historical Spend in given wrapper for Agreement Line Item.
     **/
    private void setCustomerHistoricalSpendDetailsInWrapper(Map<String, Customer_Historical_Spend__c> ngnWiseHistoricalSpendRecordMap, AgreementLineItemWrapper wrapper, Map<String, Decimal> currencyCodeWiseConversionRate) {
        ilib_LogEvent.push(LOG_TITLE + '.setCustomerHistoricalSpendDetailsInWrapper()');
        if(ngnWiseHistoricalSpendRecordMap.get(wrapper.nationalGroupNumber) == null)
            return;
            
        Customer_Historical_Spend__c historicalSpend = ngnWiseHistoricalSpendRecordMap.get(wrapper.nationalGroupNumber);
        Decimal historicSpendValue = historicalSpend.Customer_Historic_Spend__c;
        
        wrapper.primaryCustomerType = historicalSpend.Primary_Customer_Type__c;
        wrapper.instrumentCredit = historicalSpend.Total_Instrument_Credits__c == null ? 0 : historicalSpend.Total_Instrument_Credits__c;
        wrapper.customerSpend = historicSpendValue == null ? 0 : historicSpendValue * currencyCodeWiseConversionRate.get(wrapper.currencyIsoCode);
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to fetch Account and associated Account Sales Area records (inline query) using given list of Agreement Line Items.
     **/
    private List<Account> getAccountAndRelatedSalesAreaRecords(List<Apttus__AgreementLineItem__c> lineItemList) {
        ilib_LogEvent.push(LOG_TITLE + '.getAccountAndRelatedSalesAreaRecords()');
        // Set of ERP Customer ID and Sales Org
        Set<String> salesOrgSet = new Set<String>();
        Set<String> erpCustomerIdSet = new Set<String>();
        
        for(Apttus__AgreementLineItem__c lineItem : lineItemList) {
            salesOrgSet.add(lineItem.Sales_Org__c);
            erpCustomerIdSet.add(getErpCustomerIdBasedOnDistributionChannel(lineItem));
        }
        
        ilib_LogEvent.pop();
        // Fetch Account records with related Account Sales Area
        return fetchAccountAndRelatedSalesAreaRecords(erpCustomerIdSet, salesOrgSet);
    }
    
    /**
     * Method to fetch Account and associated Account Sales Area records (inline query) using given set of ERP Customer ID and Sales Org.
     **/
    private List<Account> fetchAccountAndRelatedSalesAreaRecords(Set<String> erpCustomerIdSet, Set<String> salesOrgSet) {
        AccountsSelector selector = new AccountsSelector();
        List<Account> accountList = selector.fetchAccountAndRelatedSalesAreaRecords(erpCustomerIdSet, salesOrgSet);
        
        return accountList;
    }
    
    
    /**
     * Method to get map of National Group Number wise Customer Historical Spend record.
     **/
    private Map<String, Customer_Historical_Spend__c> getNationalGroupNumberWiseHistoricalSpendRecord(Set<String> nationalGroupNumberSet) {
        
        Map<String, Customer_Historical_Spend__c> ngnWiseHistoricalSpendRecord = new Map<String, Customer_Historical_Spend__c>();
        List<Customer_Historical_Spend__c> customerHistoricalSpendList = fetchCustomerHistoricalSpendRecords(nationalGroupNumberSet);
        
        for(Customer_Historical_Spend__c spendRecord : customerHistoricalSpendList) {
            ngnWiseHistoricalSpendRecord.put(spendRecord.ERP_ID__c, spendRecord);
        }
        
        return ngnWiseHistoricalSpendRecord;
    }
    
    /**
     * Method to fetch Customer Historical Spend records for given set of National Group Numbers.
     **/ 
    private List<Customer_Historical_Spend__c> fetchCustomerHistoricalSpendRecords(Set<String> nationalGroupNumberSet) {
        CustomerHistoricalSpendSelector selector = new CustomerHistoricalSpendSelector();
        List<Customer_Historical_Spend__c> customerHistoricalSpendList = selector.fetchCustomerHistoricalSpendRecords(nationalGroupNumberSet);
        
        return customerHistoricalSpendList;
    }
    
    
    /**
     * Method to create and return map of Currency ISO Code wise Conversion Rate.
     **/
    private Map<String, Decimal> getCurrencyCodeWiseConversionRate() {
        Map<String, Decimal> currencyCodeWiseConversionRate = new Map<String, Decimal>();
        List<CurrencyType> currencyTypeList = fetchCurrencyTypeRecordsForAllIsoCodes();
        
        for(CurrencyType currType : currencyTypeList) {
            currencyCodeWiseConversionRate.put(currType.IsoCode, currType.ConversionRate);
        }
        
        return currencyCodeWiseConversionRate;
    }
    
    /**
     * Method to fetch Currency Type records for all Currency ISO Codes.
     **/
    private List<CurrencyType> fetchCurrencyTypeRecordsForAllIsoCodes() {
        CurrencyCodesSelector selector = new CurrencyCodesSelector();
        return selector.fetchCurrencyTypeRecordsForAllIsoCodes();
    }
    
    
    
    /*****************
     * DGP-416 : To populate Customer Historical Discount on Agreement Line Items as exist in given list of wrappers.
     *****************/
    private void populateCustomerHistoricalDiscount(List<AgreementLineItemWrapper> lineItemWrapperList) {
        ilib_LogEvent.push(LOG_TITLE + '.populateCustomerHistoricalDiscount()');
        Set<String> skuOrMG1Set = new Set<String>();
        Set<String> erpCustomerIdSet = new Set<String>();
        
        for(AgreementLineItemWrapper lineItemWrapper : lineItemWrapperList) {
            skuOrMG1Set.add(lineItemWrapper.skuOrMG1);
            erpCustomerIdSet.add(lineItemWrapper.erpCustomerId);
        }
        
        ilib_LogEvent.info('skuOrMG1Set > '+ skuOrMG1Set);
        ilib_LogEvent.info('erpCustomerIdSet > '+ erpCustomerIdSet);
        // Fetch Historical Discount
        Map<String, Decimal> erpCustomerAndSkuMG1WiseHistoricalDiscount = getErpCustomerAndSkuMG1WiseHistoricalDiscount(erpCustomerIdSet, skuOrMG1Set);
        
        ilib_LogEvent.info('erpCustomerAndSkuMG1WiseHistoricalDiscount size > '+ erpCustomerAndSkuMG1WiseHistoricalDiscount.size());
        // Set Historical Discount on Line Items
            setHistoricalDiscountOnLineItems(lineItemWrapperList, erpCustomerAndSkuMG1WiseHistoricalDiscount);
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to get ERP Customer ID and Material/MG1 wise Customer Historical Discont.
     **/
    private Map<String, Decimal> getErpCustomerAndSkuMG1WiseHistoricalDiscount(Set<String> erpCustomerIdSet, Set<String> skuOrMG1Set) {
        ilib_LogEvent.push(LOG_TITLE + '.getErpCustomerAndSkuMG1WiseHistoricalDiscount()');
        Map<String, Decimal> erpCustomerAndSkuMG1WiseHistoricalDiscount = new Map<String, Decimal>();
        
        // Fetch Discount Records
        List<Customer_Historical_Discount__c> customerHistoricalDiscountList = fetchCustomerHistoricalDiscountRecords(erpCustomerIdSet, skuOrMG1Set);
        
        ilib_LogEvent.info('customerHistoricalDiscountList size > '+ customerHistoricalDiscountList.size());
        // Create Map for Historical Discount
        for(Integer index = 0; index < customerHistoricalDiscountList.size(); index++) {
            
            Customer_Historical_Discount__c discountRecord = customerHistoricalDiscountList.get(index);
            String key = discountRecord.ERP_ID__c + DELIMITER + discountRecord.SKU_MG1__c;
            
            if(erpCustomerAndSkuMG1WiseHistoricalDiscount.get(key) == null) {
                erpCustomerAndSkuMG1WiseHistoricalDiscount.put(key, discountRecord.Historical_Discount__c);
            }
        }
        ilib_LogEvent.pop();
        return erpCustomerAndSkuMG1WiseHistoricalDiscount;
    }
    
    /**
     * Method to fetch list of Customer Historical Discount records for given set of ERP Customer IDs and Material Numbers / MG1s.
     **/
    private List<Customer_Historical_Discount__c> fetchCustomerHistoricalDiscountRecords(Set<String> erpCustomerIdSet, Set<String> skuOrMG1Set) {
        CustomerHistoricalDiscountSelector selector = new CustomerHistoricalDiscountSelector();
        List<Customer_Historical_Discount__c> customerHistoricalDiscountList = selector.fetchCustomerHistoricalDiscountRecords(erpCustomerIdSet, skuOrMG1Set);
        
        return customerHistoricalDiscountList;
    }
    
    /**
     * Method to set Customer Historical Discount on Agreement Line Items.
     **/
    private void setHistoricalDiscountOnLineItems(List<AgreementLineItemWrapper> lineItemWrapperList, Map<String, Decimal> erpCustomerAndSkuMG1WiseHistoricalDiscount) {
        
        for(AgreementLineItemWrapper wrapper : lineItemWrapperList) {
            String key = wrapper.erpCustomerId + DELIMITER + wrapper.skuOrMG1;
            wrapper.agreementLineItem.Customer_Historical_Discount__c = erpCustomerAndSkuMG1WiseHistoricalDiscount.get(key);
        }
    }
    
    
    
    /*****************
     * DGP-103 : To populate Median and Max Discount Guidance on Agreement Line Items as exist in given list of wrappers.
     *****************/
    public void populateMedianAndMaxDiscountGuidance(List<AgreementLineItemWrapper> lineItemWrapperList) {
        ilib_LogEvent.push(LOG_TITLE + '.populateMedianAndMaxDiscountGuidance()');
        // Fetch Discount Guidance records
        List<Discount_Guidance__c> discountGuidanceList = fetchDiscountGuidanceRecords(lineItemWrapperList);
        
        // Process Discount Guidance records
        Map<String, List<Discount_Guidance__c>> countryWiseDiscountGuidanceRecords = new Map<String, List<Discount_Guidance__c>>();
        Map<String, List<Discount_Guidance__c>> priceListTypeWiseDiscountGuidanceRecords = new Map<String, List<Discount_Guidance__c>>();
        
        ilib_LogEvent.info('discountGuidanceList size > '+ discountGuidanceList.size());
        for(Integer index = 0; index < discountGuidanceList.size(); index++) {
            Discount_Guidance__c discountGuidance = discountGuidanceList.get(index);
            
            // Country Type Records
            addToCountryWiseDiscountGuidanceRecordsMap(discountGuidance, countryWiseDiscountGuidanceRecords);
            
            // Price List Type Records
            addToPriceListTypeWiseDiscountGuidanceRecordsMap(discountGuidance, priceListTypeWiseDiscountGuidanceRecords);
        }
        ilib_LogEvent.info('countryWiseDiscountGuidanceRecords > '+ countryWiseDiscountGuidanceRecords);
        ilib_LogEvent.info('priceListTypeWiseDiscountGuidanceRecords > '+ priceListTypeWiseDiscountGuidanceRecords);
        
        // Set Discount Guidance on Agreement Line Items
        setDiscountGuidanceOnLineItem(lineItemWrapperList, countryWiseDiscountGuidanceRecords, priceListTypeWiseDiscountGuidanceRecords);
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to fetch Discount Guidance records based on values in given list of Agreement Line Item wrapper records.
     **/
    private List<Discount_Guidance__c> fetchDiscountGuidanceRecords(List<AgreementLineItemWrapper> lineItemWrapperList) {
        
        DiscountGuidanceSelector selector = new DiscountGuidanceSelector();
        
        for(AgreementLineItemWrapper wrapper : lineItemWrapperList) {
            selector.addChannelToSet(wrapper.distributionChannel);
            selector.addPriceListTypeToSet(wrapper.priceListType);
            selector.addDiscountGridGroupToSet(wrapper.discountGridGroup);
            selector.addBillingCountryCodeToSet(wrapper.billingCountryCode);
            selector.addPrimaryCustomerTypeToSet(wrapper.primaryCustomerType);
            selector.addCustomerSpendToSet(wrapper.customerSpend);
            selector.addCurrencyIsoCodeToSet(wrapper.currencyIsoCode);
            selector.addInstrumentCreditToSet(wrapper.instrumentCredit);
            selector.addDateValueToSet(wrapper.agreementLineStartDate);
        }
        
        return selector.fetchDiscountGuidanceRecordsForLineItems();
    }
    
    /**
     * Method to add Discount Guidance record in map for country wise list of records for each country.
     **/ 
    private void addToCountryWiseDiscountGuidanceRecordsMap(Discount_Guidance__c discountGuidance, Map<String, List<Discount_Guidance__c>> countryWiseDiscountGuidanceRecords) {
        
        if(discountGuidance.Discount_Guidance_Level__c != Label.UI_Label_Country || String.isBlank(discountGuidance.Country__c))
            return;
        
        List<String> countryCodeList = discountGuidance.Country__c.split(';');
        
        for(String countryCode : countryCodeList) {
            String key = countryCode + DELIMITER + discountGuidance.Primary_Customer_Type__c + DELIMITER
                            + discountGuidance.Discount_Grid_Group__c + DELIMITER + discountGuidance.Channel__c;
            
            if(countryWiseDiscountGuidanceRecords.get(key) == null) {
                countryWiseDiscountGuidanceRecords.put(key, new List<Discount_Guidance__c>());
            }
            
            countryWiseDiscountGuidanceRecords.get(key).add(discountGuidance);
        }
    }
    
    /**
     * Method to add Discount Guidance record in map for price list type wise list of records.
     **/
    private void addToPriceListTypeWiseDiscountGuidanceRecordsMap(Discount_Guidance__c discountGuidance, Map<String, List<Discount_Guidance__c>> priceListTypeWiseDiscountGuidanceRecords) {
        
        if(discountGuidance.Discount_Guidance_Level__c != Label.Price_List_Type || String.isBlank(discountGuidance.Price_List_Type__c))
            return;
        
        String key = discountGuidance.Price_List_Type__c + DELIMITER + discountGuidance.Primary_Customer_Type__c + DELIMITER
                        + discountGuidance.Discount_Grid_Group__c + DELIMITER + discountGuidance.Channel__c;
        
        if(priceListTypeWiseDiscountGuidanceRecords.get(key) == null) {
            priceListTypeWiseDiscountGuidanceRecords.put(key, new List<Discount_Guidance__c>());
        }
        
        priceListTypeWiseDiscountGuidanceRecords.get(key).add(discountGuidance);
    }
    
    /**
     * Method to set Discount Guidance record and Median & Max Discount Guidance on Agreement Line Item.
     **/
    private void setDiscountGuidanceOnLineItem(List<AgreementLineItemWrapper> lineItemWrapperList, Map<String, List<Discount_Guidance__c>> countryWiseDiscountGuidanceRecords, Map<String, List<Discount_Guidance__c>> priceListTypeWiseDiscountGuidanceRecords) {
        
        for(AgreementLineItemWrapper wrapper : lineItemWrapperList) {
            
            Discount_Guidance__c latestDiscountGuidanceRecord;
            String countryKey = wrapper.billingCountryCode + DELIMITER + wrapper.primaryCustomerType + DELIMITER + wrapper.discountGridGroup + DELIMITER + wrapper.distributionChannel;
            String priceListTypeKey = wrapper.priceListType + DELIMITER + wrapper.primaryCustomerType + DELIMITER + wrapper.discountGridGroup + DELIMITER + wrapper.distributionChannel;
            
            if(countryWiseDiscountGuidanceRecords.containsKey(countryKey)) {
                latestDiscountGuidanceRecord = getLatestMatchingDiscountGuidanceRecord(wrapper, countryWiseDiscountGuidanceRecords.get(countryKey));
            } else if(priceListTypeWiseDiscountGuidanceRecords.containsKey(priceListTypeKey)) {
                latestDiscountGuidanceRecord = getLatestMatchingDiscountGuidanceRecord(wrapper, priceListTypeWiseDiscountGuidanceRecords.get(priceListTypeKey));
            }
            
            wrapper.agreementLineItem.Discount_Guidance__c = latestDiscountGuidanceRecord != null ? latestDiscountGuidanceRecord.Id: null;
            wrapper.agreementLineItem.Max_Discount_Guidance__c = latestDiscountGuidanceRecord != null ? latestDiscountGuidanceRecord.Max_Discount__c : null;
            wrapper.agreementLineItem.Median_Discount_Guidance__c = latestDiscountGuidanceRecord != null ? latestDiscountGuidanceRecord.Median_Discount__c : null;
        }
    }
    
    /**
     * Method to get the latest Discount Guidance record that matches Start Date and Customer Spend/Instrument Credit specific criteria.
     **/  
    private Discount_Guidance__c getLatestMatchingDiscountGuidanceRecord(AgreementLineItemWrapper wrapper, List<Discount_Guidance__c> discountGuidanceList) {
        Discount_Guidance__c latestDiscountGuidanceRecord;
        
        for(Integer index = 0; index < discountGuidanceList.size(); index++) {
            Boolean isMatching = true;
            Discount_Guidance__c discountGuidance = discountGuidanceList.get(index);
            
            // Start Date OR End Date NOT Matching 
            if(wrapper.agreementLineStartDate < discountGuidance.Start_Date__c
                    || wrapper.agreementLineStartDate > discountGuidance.End_Date__c) {
                isMatching = false;
            }
            
            // Customer Spend NOT Matching
            if(discountGuidance.Tier_Type__c == Label.TierTypeSpend
                    && (wrapper.currencyIsoCode != discountGuidance.CurrencyIsoCode || wrapper.customerSpend < discountGuidance.Tier_Min__c || wrapper.customerSpend > discountGuidance.Tier_Max__c)) {
                isMatching = false;
            }
            
            // Instrument Credit NOT Matching
            if(discountGuidance.Tier_Type__c == Label.TierTypeCredit
                    && (wrapper.instrumentCredit < discountGuidance.Tier_Min__c || wrapper.instrumentCredit > discountGuidance.Tier_Max__c)) {
                isMatching = false;
            }
            
            if(isMatching) {
                latestDiscountGuidanceRecord = discountGuidance;
                break;
            }
        }
        
        return latestDiscountGuidanceRecord;
    }
    
    
    
    /**
     * Method to get ERP Customer Id based on Distribution Channel for given Agreement Line Item.
     **/
    private String getErpCustomerIdBasedOnDistributionChannel(Apttus__AgreementLineItem__c lineItem) {
        if(lineItem.Distribution_Channel__c == Label.IndirectDistributionChannelCode) {
            return lineItem.Ultimate_Consignee_ERP_Number__c;
        } else {
            return lineItem.Customer_ERP_Number__c;
        }
    }
    
    /**
     * Method to get Material Number OR Material Group 1 based on line type of given line item.
     **/
    private String getMaterialNumberOrMG1BasedOnLineType(Apttus__AgreementLineItem__c lineItem) {
        if(MATERIAL_LINE_TYPE_SET.contains(lineItem.Line_Type__c)) {
            return lineItem.Material_Number__c;
        } else if(MATERIAL_GROUP_LINE_TYPE_SET.contains(lineItem.Line_Type__c)) {
            return lineItem.Material_Group_1__c;
        }
        return null;
    }
    
    /**
     * Method to get Distribution Channel based on code on given agreement line item.
     **/
    private String getDistributionChannelBasedOnCode(Apttus__AgreementLineItem__c lineItem) {
        if(lineItem.Distribution_Channel__c == Label.DirectDistributionChannelCode) {
            return Label.DistributionChannelDirect;
        } else if(lineItem.Distribution_Channel__c == Label.IndirectDistributionChannelCode) {
            return Label.DistributionChannelIndirect;
        }
        return null;
    }
    
    
    
    /**
     * Wrapper class for each new Agreement Line Item record.
     **/
    public class AgreementLineItemWrapper {
        
        public String skuOrMG1 {get; private set;}
        public String salesOrg {get; private set;}
        public String accountRegion {get; private set;}
        public String erpCustomerId {get; private set;}
        public String priceListType {get; private set;}
        public String billingCountry {get; private set;}
        public String billingCountryCode {get; private set;}
        public String nationalGroupNumber {get; private set;}
        public String currencyIsoCode {get; private set;}
        public String discountGridGroup {get; private set;}
        public String primaryCustomerType {get; private set;}
        public String distributionChannel {get; private set;}
        public String distributionChannelCode {get; private set;}
        
        public Decimal customerSpend {get; private set;}
        public Decimal instrumentCredit {get; private set;}
        public Date agreementLineStartDate {get; private set;}
        public Apttus__AgreementLineItem__c agreementLineItem {get; private set;}
    }
}