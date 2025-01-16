/*************************
 * Author : Shalin Shah
 * Description : Class to perform process and populate Discount Guidance on Produt Config Line Items.
 * 				 Class will populate Median & Max Discount, Customer Historical Discount, Min Discount and Approval Matrix.
 *************************/

public without sharing class DiscountGuidancePopulatorForCPQ {
    
    private static final String DELIMITER = '-';
    private static final String CUSTOM = 'Custom'; // DGP-11
    private static final String RECORD_OWNER = 'Record Owner'; // DGP-11
    private static final String CPQ_DISCOUNT = 'CPQ_Discount'; // DGP-11
    private static final String CPQ_MATERIAL_NUMBER = 'CPQ_Material_Number'; // DGP-11
    private static final String CPQ_MATERIAL_GROUP1 = 'CPQ_Material_Group_1'; // DGP-11
    private static final String MULTISELECT_VALUE_DELIMITER = ';'; // DGP-11
    private static final String LOG_TITLE = 'DiscountGuidancePopulatorForCPQ';
    
    
    /*****************
     * DGP-42, DGP-358, DGP-11, DGP-354 : Main method to derive all Discount Guidance related field values on given list of Line Items.
     *****************/
    public void deriveFieldValuesForDiscountGuidance(List<Apttus_Config2__LineItem__c> lineItemList) {
        ilib_LogEvent.push(LOG_TITLE + '.deriveFieldValuesForDiscountGuidance()');
        
        Apttus_Config2__ProductConfiguration__c configSO = fetchConfigAndProposalforDG(lineItemList[0].Apttus_Config2__ConfigurationId__c);
        ConfigAndProposalFieldValueWrapper proposalHeaderWrapper = getConfigAndProposalFieldValueWrapper(configSO, lineItemList);
        
        // DGP-11 & 354 : To populate Approval Matrix (Record Owner & Custom) and Min Discount%
        populateApprovalMatrixAndMinDiscount(proposalHeaderWrapper, lineItemList);
        
        // Get Non Open Offer Line Items for Discount Guidance
        List<Apttus_Config2__LineItem__c> nonOpenOfferLineItemList = getNonOpenOfferLineItemList(proposalHeaderWrapper, lineItemList);
        
        if(nonOpenOfferLineItemList.size() > 0) {
            // DGP-358 : To populate Customer Historical Discount
            populateCustomerHistoricalDiscount(proposalHeaderWrapper, nonOpenOfferLineItemList);
            
            //DGP-42 : To populate Discount Guidance : Median & Max Discount Guidance
            populateMedianAndMaxDiscountGuidance(proposalHeaderWrapper, nonOpenOfferLineItemList);
        }
        
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to return Product Configuration record for given configuration record ID.
     **/
    private Apttus_Config2__ProductConfiguration__c fetchConfigAndProposalforDG(String configId) {
        ApttusProductConfigurationsSelector configSelector = new ApttusProductConfigurationsSelector();
        Apttus_Config2__ProductConfiguration__c configSO = configSelector.fetchConfigAndProposalforDG(configId);
        
        return configSO; 
    }
    
    
    /*****************
     * Method get wrapper of header field values for given sobject record of Product Configuration.
     *****************/
    public ConfigAndProposalFieldValueWrapper getConfigAndProposalFieldValueWrapper(Apttus_Config2__ProductConfiguration__c configSO, List<Apttus_Config2__LineItem__c> lineItemList) {
        ilib_LogEvent.push(LOG_TITLE + '.getConfigAndProposalFieldValueWrapper()');
        
        Account quoteAccount = getAccountBasedOnDistributionChannel(configSO);
        ConfigAndProposalFieldValueWrapper proposalHeaderWrapper = new ConfigAndProposalFieldValueWrapper();
        
        proposalHeaderWrapper.configId = configSO.Id;
        proposalHeaderWrapper.proposalId = configSO.Apttus_QPConfig__Proposald__c;
        proposalHeaderWrapper.distributionChannel = getDistributionChannelBasedOnCode(configSO);
        proposalHeaderWrapper.distributionChannelCode = configSO.Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c;
        proposalHeaderWrapper.currencyIsoCode = configSO.Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PriceListId__r.CurrencyIsoCode;
        proposalHeaderWrapper.priceListType = configSO.Apttus_QPConfig__Proposald__r.Apttus_Proposal__Opportunity__r.Price_List_Type__c;
        
        ilib_LogEvent.info('quoteAccount : '+quoteAccount);
        
        if(quoteAccount != null) {
            proposalHeaderWrapper.accountRegion = quoteAccount.Territory_Region__c;
            proposalHeaderWrapper.erpCustomerId = quoteAccount.ERP_Customer_Id__c;
            proposalHeaderWrapper.billingCountry = quoteAccount.BillingCountry;
            proposalHeaderWrapper.billingCountryCode = quoteAccount.BillingCountryCode;
            proposalHeaderWrapper.nationalGroupNumber = String.isBlank(quoteAccount.National_Group_Number__c) ? quoteAccount.ERP_Customer_Id__c : quoteAccount.National_Group_Number__c;
            
            setCustomerHistoricalSpendInWrapper(proposalHeaderWrapper);
        }
        
        proposalHeaderWrapper.discountGridGroupSet = getDiscountGridGroupSet(lineItemList);
        proposalHeaderWrapper.quoteForOpenOfferCustomer = configSO.Apttus_QPConfig__Proposald__r.Quote_For_Open_Offer_Customer__c;
        proposalHeaderWrapper.quotePricingDate = configSO.Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PricingDate__c == null ? null : configSO.Apttus_QPConfig__Proposald__r.Apttus_QPConfig__PricingDate__c.date();
        
        ilib_LogEvent.info('discountGridGroupSet : '+proposalHeaderWrapper.discountGridGroupSet);
        ilib_LogEvent.pop();
        
        return proposalHeaderWrapper;
    }
    
    /**
     * Method to fetch Customer Historical Spend details in given wrapper by fetching it.
     **/
    private void setCustomerHistoricalSpendInWrapper(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper) {
        ilib_LogEvent.push(LOG_TITLE + '.setCustomerHistoricalSpendInWrapper()');
        
        Customer_Historical_Spend__c historicalSpend = fetchCustomerHistoricalSpendRecord(proposalHeaderWrapper.nationalGroupNumber);
        ilib_LogEvent.info('historicalSpend : '+historicalSpend);
        
        // To set Historical Spend values 
        if(historicalSpend != null) {
            proposalHeaderWrapper.primaryCustomerType = historicalSpend.Primary_Customer_Type__c;
            proposalHeaderWrapper.customerSpend = historicalSpend.Customer_Historic_Spend__c == null ? 0 : historicalSpend.Customer_Historic_Spend__c;
            proposalHeaderWrapper.instrumentCredit = historicalSpend.Total_Instrument_Credits__c == null ? 0 : historicalSpend.Total_Instrument_Credits__c;
        }
        
        // To perform currency coversion for Historical Spend
        if(proposalHeaderWrapper.customerSpend != null && proposalHeaderWrapper.customerSpend > 0) {
            Decimal conversionRate = fetchCurrencyConversionRate(proposalHeaderWrapper.currencyIsoCode);
            proposalHeaderWrapper.customerSpend = proposalHeaderWrapper.customerSpend * conversionRate;
        }
        
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to fetch Customer Historical Spend record for given National Group Number.
     **/
    private Customer_Historical_Spend__c fetchCustomerHistoricalSpendRecord(String nationalGroupNumber) {
        CustomerHistoricalSpendSelector selector = new CustomerHistoricalSpendSelector();
        List<Customer_Historical_Spend__c> historicalSpendList = selector.fetchCustomerHistoricalSpendRecords(new Set<String>{nationalGroupNumber});
        
        return (historicalSpendList != null && historicalSpendList.size() > 0) ? historicalSpendList.get(0) : null;
    }
    
    /**
     * Method to fetch Coversion Rate for given currency ISO code.
     **/
    private Decimal fetchCurrencyConversionRate(String currencyIsoCode) {
        CurrencyCodesSelector selector = new CurrencyCodesSelector();
        List<CurrencyType> currencyTypeList = selector.getCurrencyTypeRecordsFromIsoCodes(new Set<String>{currencyIsoCode});
        
        return (currencyTypeList.size() == 0) ? 0 : currencyTypeList[0].ConversionRate;
    }
    
    /**
     * Method to get list of line items that are eligible for Discount Guidance.
     **/
    private List<Apttus_Config2__LineItem__c> getNonOpenOfferLineItemList(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper, List<Apttus_Config2__LineItem__c> lineItemList) {
        ilib_LogEvent.push(LOG_TITLE + '.getNonOpenOfferLineItemList()');
        
        Boolean isQuoteForOpenOfferCustomer = proposalHeaderWrapper.quoteForOpenOfferCustomer;
        List<Apttus_Config2__LineItem__c> nonOpenOfferLineItemList = new List<Apttus_Config2__LineItem__c>();
        
        for(Apttus_Config2__LineItem__c lineItem : lineItemList) {
            
            // Condition for Non Open Offer
            if(!isQuoteForOpenOfferCustomer || String.isBlank(lineItem.Open_Offer_Product_Category__c)) {
                nonOpenOfferLineItemList.add(lineItem);
            }
        }
        
        ilib_LogEvent.pop();
        return nonOpenOfferLineItemList;
    }
    
    
    
    /*****************
     * DGP-11 & DGP-354 : To populate Approval Matrix (Record Owner), Approval Matrix (Custom) and Min Discount% on given list of line items.
     *****************/ 
    public void populateApprovalMatrixAndMinDiscount(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper, List<Apttus_Config2__LineItem__c> lineItemList) {
        ilib_LogEvent.push(LOG_TITLE + '.populateApprovalMatrixAndMinDiscount()');
        
        String accountRegion = proposalHeaderWrapper.accountRegion;
        Set<String> materialNumberSet = getSetOfMaterialNumbers(lineItemList);
        
        List<Custom_Approval_Matrix__c> approvalMatrixRecords = fetchApprovalMatrixRecordsForCPQ(accountRegion, materialNumberSet);
        Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix = prioritizeApprovalMatrixRecords(proposalHeaderWrapper, approvalMatrixRecords);
        
        setApprovalMatrixAndMinDiscountOnLineItems(lineItemList, combinationWisePriorityApprovalMatrix);
        
        ilib_LogEvent.pop();
    }
    
    /**
     * Method to fetch Custom Approval Matrix and associated Custom Approval Matrix Records for given account region
     * and set of material number.
     **/
    private List<Custom_Approval_Matrix__c> fetchApprovalMatrixRecordsForCPQ(String accountRegion, Set<String> materialNumberSet) {
        CustomApprovalMatrixSelector selector = new CustomApprovalMatrixSelector();
        List<Custom_Approval_Matrix__c> approvalMatrixRecords = selector.fetchApprovalMatrixRecordsForCPQ(accountRegion, materialNumberSet);
        
        return approvalMatrixRecords; 
    }
    
    /**
     * Method to get priority approval matrix records based on combination key.
     * 
     * For "CPQ Material Number" matrix - combination key is matrix Record Type, Approval Hierarchy Type and Material Number.
     * For "CPQ Material Group1" & "CPQ Discount" matrix - combination key is Matrix Record Type and Approval Hierarchy Type.
     **/
    private Map<String, Custom_Approval_Matrix__c> prioritizeApprovalMatrixRecords(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper, List<Custom_Approval_Matrix__c> approvalMatrixRecords) {
        
        Map<String, Decimal> matrixPriorityMap = getApprovalMatrixPriorityMapFromMetadata();
        
        Map<String, Decimal> combinationWiseMatrixPriorityValue = new Map<String, Decimal>();
        Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix = new Map<String, Custom_Approval_Matrix__c>();
        
        for (Custom_Approval_Matrix__c matrix : approvalMatrixRecords) {
            
            String matrixRecordType = matrix.RecordType.DeveloperName;
            
            // Calculate the key for priority value
            String keyForMatrixPriority = buildPriorityKey(matrix, proposalHeaderWrapper);
            Double currentMatrixPriority = matrixPriorityMap.get(keyForMatrixPriority);
            
            // Ignore if Matrix Priority is NOT Found
            if(currentMatrixPriority == null) {
                continue;
            }
            
            // Process Approval Matrix based on Record Type
            if(matrixRecordType.equals(CPQ_MATERIAL_NUMBER)) {
                processMaterialNumberMatrixRecord(matrix, currentMatrixPriority, combinationWisePriorityApprovalMatrix, combinationWiseMatrixPriorityValue);
            } else if(matrixRecordType.equals(CPQ_MATERIAL_GROUP1)) {
                processMaterialGroupMatrixRecord(matrix, currentMatrixPriority, combinationWisePriorityApprovalMatrix, combinationWiseMatrixPriorityValue);
            } else if(matrixRecordType.equals(CPQ_DISCOUNT)) {
                processCpqDiscountMatrixRecord(matrix, currentMatrixPriority, combinationWisePriorityApprovalMatrix, combinationWiseMatrixPriorityValue);
            }
        }
        
        return combinationWisePriorityApprovalMatrix;
    }
    
    /**
     * Method to read records of Approval_Priority_Combination__mdt custom metadata and get map of priorities.
     **/
    private Map<String, Decimal> getApprovalMatrixPriorityMapFromMetadata() {
        
        Map<String, Decimal> matrixPriorityMap = new Map<String, Decimal>();
        List<Approval_Priority_Combination__mdt> priorityCombinationList = Approval_Priority_Combination__mdt.getAll().values();
        
        for(Approval_Priority_Combination__mdt priorityCombination : priorityCombinationList) {
            
            String key = toStringLowerCase(priorityCombination.Region_Check__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Region_Blank__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Distribution_Channel_Check__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Distribution_Channel_Blank__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Price_List_Type_Check__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Price_List_Type_Blank__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Country_Check__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Country_Blank__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Currency_Check__c, true) + DELIMITER
                + toStringLowerCase(priorityCombination.Currency_Blank__c, true);
            
            matrixPriorityMap.put(key, priorityCombination.Value__c);
        }
        
        return matrixPriorityMap;
    }
    
    /**
     * Method to build key to determine priority for given Custom Approval Matrix record based on Proposal header values.
     **/
    private String buildPriorityKey(Custom_Approval_Matrix__c matrix, ConfigAndProposalFieldValueWrapper proposalHeaderWrapper) {
        
        Boolean regionBlank = String.isBlank(matrix.Region__c);
        Boolean countryBlank = String.isBlank(matrix.Country__c);
        Boolean currencyBlank = String.isBlank(matrix.Currency__c);
        Boolean priceListTypeBlank = String.isBlank(matrix.Price_List_Type__c);
        Boolean distributionChannelBlank = String.isBlank(matrix.Distribution_Channel__c);
        
        Boolean regionCheck = String.isNotBlank(matrix.Region__c) && String.isNotBlank(proposalHeaderWrapper.accountRegion) && matrix.Region__c.contains(proposalHeaderWrapper.accountRegion);
        Boolean currencyCheck = String.isNotBlank(matrix.Currency__c) && String.isNotBlank(proposalHeaderWrapper.currencyIsoCode) && matrix.Currency__c.contains(proposalHeaderWrapper.currencyIsoCode);
        Boolean countryCheck = String.isNotBlank(matrix.Country__c) && String.isNotBlank(proposalHeaderWrapper.billingCountryCode) && matrix.Country__c.contains(proposalHeaderWrapper.billingCountryCode);
        Boolean priceListTypeCheck = String.isNotBlank(matrix.Price_List_Type__c) && String.isNotBlank(proposalHeaderWrapper.priceListType) && matrix.Price_List_Type__c.equals(proposalHeaderWrapper.priceListType);
        Boolean distributionChannelCheck = String.isNotBlank(matrix.Distribution_Channel__c) && String.isNotBlank(proposalHeaderWrapper.distributionChannel) && matrix.Distribution_Channel__c.contains(proposalHeaderWrapper.distributionChannel);
        
        
        return toStringLowerCase(regionCheck, true) + DELIMITER
            + toStringLowerCase(regionBlank, true) + DELIMITER
            + toStringLowerCase(distributionChannelCheck, true) + DELIMITER
            + toStringLowerCase(distributionChannelBlank, true) + DELIMITER
            + toStringLowerCase(priceListTypeCheck, true) + DELIMITER
            + toStringLowerCase(priceListTypeBlank, true) + DELIMITER
            + toStringLowerCase(countryCheck, true) + DELIMITER
            + toStringLowerCase(countryBlank, true) + DELIMITER
            + toStringLowerCase(currencyCheck, true) + DELIMITER
            + toStringLowerCase(currencyBlank, true);
    }
    
    /**
     * Method to process Custom Approval Matrix with "CPQ Material Number" record type and update priority based map.
     **/
    private void processMaterialNumberMatrixRecord(Custom_Approval_Matrix__c matrix, Double currentMatrixPriority, Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix, Map<String, Decimal> combinationWiseMatrixPriorityValue) {
        
        String approvalHierarchyType = matrix.Approval_Hierarchy_Type__c;
        
        if (matrix.Custom_Approval_Matrix_Products__r != null && matrix.Custom_Approval_Matrix_Products__r.size() > 0) {
            
            for (Custom_Approval_Matrix_Products__c matrixProduct : matrix.Custom_Approval_Matrix_Products__r) {
                String materialNumber = matrixProduct.Product__r.ProductCode;
                String combinationKey = CPQ_MATERIAL_NUMBER + DELIMITER + materialNumber + DELIMITER + approvalHierarchyType;
                
                setPriorityMatrixInMap(combinationKey, matrix, currentMatrixPriority, combinationWisePriorityApprovalMatrix, combinationWiseMatrixPriorityValue);
            }
        }
    }
    
    /**
     * Method to process Custom Approval Matrix with "CPQ Material Group 1" record type and update priority based map.
     **/
    private void processMaterialGroupMatrixRecord(Custom_Approval_Matrix__c matrix, Double currentMatrixPriority, Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix, Map<String, Decimal> combinationWiseMatrixPriorityValue) {
        
        if(String.isBlank(matrix.Material_Group_1__c)) {
            return;
        }
        
        String approvalHierarchyType = matrix.Approval_Hierarchy_Type__c;
        List<String> materialGroup1List = matrix.Material_Group_1__c.split(MULTISELECT_VALUE_DELIMITER);
        
        for(String materialGroup1 : materialGroup1List) {
            String combinationKey = CPQ_MATERIAL_GROUP1 + DELIMITER + materialGroup1 + DELIMITER + approvalHierarchyType;
            setPriorityMatrixInMap(combinationKey, matrix, currentMatrixPriority, combinationWisePriorityApprovalMatrix, combinationWiseMatrixPriorityValue);
        }
    }
    
    /**
     * Method to process Custom Approval Matrix record with "CPQ Discount" record type and update priority based map.
     **/
    private void processCpqDiscountMatrixRecord(Custom_Approval_Matrix__c matrix, Double currentMatrixPriority, Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix, Map<String, Decimal> combinationWiseMatrixPriorityValue) {
        
        String approvalHierarchyType = matrix.Approval_Hierarchy_Type__c;
        String combinationKey = CPQ_DISCOUNT + DELIMITER + approvalHierarchyType;
        
        setPriorityMatrixInMap(combinationKey, matrix, currentMatrixPriority, combinationWisePriorityApprovalMatrix, combinationWiseMatrixPriorityValue);
    }
    
    /**
     * Method to Set prioriy matrix in map based on current matrix priority and existing matrix priority in map.
     **/
    private void setPriorityMatrixInMap(String combinationKey, Custom_Approval_Matrix__c matrix, Double currentMatrixPriority, 
        Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix, 
        Map<String, Decimal> combinationWiseMatrixPriorityValue) {
        
        if (combinationWisePriorityApprovalMatrix.get(combinationKey) == null || currentMatrixPriority < combinationWiseMatrixPriorityValue.get(combinationKey)) {
            combinationWisePriorityApprovalMatrix.put(combinationKey, matrix);
            combinationWiseMatrixPriorityValue.put(combinationKey, currentMatrixPriority);
        }
    }
    
    /**
     * Method to populate Approval Matrix(Record Owner), Approval Matrix(Custom) and Min Discount% on given list of line items.
     **/
    private void setApprovalMatrixAndMinDiscountOnLineItems(List<Apttus_Config2__LineItem__c> lineItemList, Map<String, Custom_Approval_Matrix__c> combinationWisePriorityApprovalMatrix) {
        ilib_LogEvent.push(LOG_TITLE + '.setApprovalMatrixAndMinDiscountOnLineItems()');
        
        for(Apttus_Config2__LineItem__c lineItem : lineItemList) {
            Custom_Approval_Matrix__c approvalMatrixCustom = null;
            Custom_Approval_Matrix__c approvalMatrixRecordOwner = null;
            
            String materialNumber = lineItem.Product_Code__c;
            String materialGroup1 = lineItem.Material_Group_1__c;
            
            String materialNumberRecordOwnerKey = CPQ_MATERIAL_NUMBER + DELIMITER + materialNumber + DELIMITER + RECORD_OWNER;
            String materialGroup1RecordOwnerKey = CPQ_MATERIAL_GROUP1 + DELIMITER + materialGroup1 + DELIMITER + RECORD_OWNER;
            String cpqDiscountRecordOwnerKey = CPQ_DISCOUNT + DELIMITER + RECORD_OWNER;
            String materialNumberCustomKey = CPQ_MATERIAL_NUMBER + DELIMITER + materialNumber + DELIMITER + CUSTOM;
            String materialGroup1CustomKey = CPQ_MATERIAL_GROUP1 + DELIMITER + materialGroup1 + DELIMITER + CUSTOM;
            String cpqDiscountCustomKey = CPQ_DISCOUNT + DELIMITER + CUSTOM;
            
            // For Approval Matrix (Record Owner)
            if(combinationWisePriorityApprovalMatrix.get(materialNumberRecordOwnerKey) != null) {
                approvalMatrixRecordOwner = combinationWisePriorityApprovalMatrix.get(materialNumberRecordOwnerKey);
            } else if(combinationWisePriorityApprovalMatrix.get(materialGroup1RecordOwnerKey) != null) {
                approvalMatrixRecordOwner = combinationWisePriorityApprovalMatrix.get(materialGroup1RecordOwnerKey);
            } else if(combinationWisePriorityApprovalMatrix.get(cpqDiscountRecordOwnerKey) != null) {
                approvalMatrixRecordOwner = combinationWisePriorityApprovalMatrix.get(cpqDiscountRecordOwnerKey);
            }
            
            // For Approval Matrix (Custom)
            if(combinationWisePriorityApprovalMatrix.get(materialNumberCustomKey) != null) {
                approvalMatrixCustom = combinationWisePriorityApprovalMatrix.get(materialNumberCustomKey);
            } else if(combinationWisePriorityApprovalMatrix.get(materialGroup1CustomKey) != null) {
                approvalMatrixCustom = combinationWisePriorityApprovalMatrix.get(materialGroup1CustomKey);
            } else if(combinationWisePriorityApprovalMatrix.get(cpqDiscountCustomKey) != null) {
                approvalMatrixCustom = combinationWisePriorityApprovalMatrix.get(cpqDiscountCustomKey);
            }
            
            lineItem.Approval_Matrix_Custom__c = approvalMatrixCustom == null ? null : approvalMatrixCustom.Id;
            lineItem.Approval_Matrix_Record_Owner__c = approvalMatrixRecordOwner == null ? null : approvalMatrixRecordOwner.Id;
            lineItem.Min_Discount__c = approvalMatrixRecordOwner == null ? 0 : approvalMatrixRecordOwner.Min_Discount__c;
        }
        
        ilib_LogEvent.pop();
    }
    
    
    
    /*****************
     * DGP-358 : Method to populate Customer Historical Discount on each line item
     *****************/
    public void populateCustomerHistoricalDiscount(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper, List<Apttus_Config2__LineItem__c> lineItemList) {
        
        String erpCustomerId = proposalHeaderWrapper.erpCustomerId;
        Set<String> materialNumberSet = getSetOfMaterialNumbers(lineItemList);
        
        Map<String, Decimal> materialWiseHistoricalDiscount = getMaterialWiseHistoricalDiscount(erpCustomerId, materialNumberSet);
        
        // Set Historical Discount on Line Items
        setHistoricalDiscountOnLineItems(lineItemList, materialWiseHistoricalDiscount);
    }
    
    /**
     * Method to get Material/MG1 wise Customer Historical Discount for given ERP Customer ID.
     **/ 
    private Map<String, Decimal> getMaterialWiseHistoricalDiscount(String erpCustomerId, Set<String> materialNumberSet) {
        ilib_LogEvent.push(LOG_TITLE + '.getMaterialWiseHistoricalDiscount()');
        
        Map<String, Decimal> materialWiseHistoricalDiscount = new Map<String, Decimal>();
        
        // Fetch Discount Records
        List<Customer_Historical_Discount__c> customerHistoricalDiscountList = fetchCustomerHistoricalDiscountRecords(erpCustomerId, materialNumberSet);
        
        // Create Map for Historical Discount
        for(Integer index = 0; index < customerHistoricalDiscountList.size(); index++) {
            Customer_Historical_Discount__c discountRecord = customerHistoricalDiscountList.get(index);
            
            if(materialWiseHistoricalDiscount.get(discountRecord.SKU_MG1__c) == null) {
                materialWiseHistoricalDiscount.put(discountRecord.SKU_MG1__c, discountRecord.Historical_Discount__c);
            }
        }
        
        ilib_LogEvent.pop();
        return materialWiseHistoricalDiscount;
    }
    
    /**
     * Method to fetch Customer Historical Discount records for given set of ERP IDs and Material Numbers.
     **/
    private List<Customer_Historical_Discount__c> fetchCustomerHistoricalDiscountRecords(String erpCustomerId, Set<String> materialNumberSet) {
        CustomerHistoricalDiscountSelector selector = new CustomerHistoricalDiscountSelector();
        List<Customer_Historical_Discount__c> customerHistoricalDiscountList = selector.fetchCustomerHistoricalDiscountRecords(new Set<String>{erpCustomerId}, materialNumberSet);
        
        return customerHistoricalDiscountList;
    }
    
    /**
     * Method to set Historical Discount on each line item based on material number.
     **/
    private void setHistoricalDiscountOnLineItems(List<Apttus_Config2__LineItem__c> lineItemList, Map<String, Decimal> materialWiseHistoricalDiscount) {
        
        for(Apttus_Config2__LineItem__c lineItem : lineItemList) {
            lineItem.Customer_Historical_Discount__c = materialWiseHistoricalDiscount.get(lineItem.Product_Code__c);
        }
    }
    
    
    
    /*****************
     * DGP-42 : Method to populate Median and Max Discount Guidance on each line item
     *****************/
    public void populateMedianAndMaxDiscountGuidance(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper, List<Apttus_Config2__LineItem__c> lineItemList) {
        
        if(proposalHeaderWrapper.discountGridGroupSet.size() > 0) {
            
            List<Discount_Guidance__c> discountGuidanceList = fetchDiscountGuidanceRecords(proposalHeaderWrapper);
            
            Map<String, Discount_Guidance__c> countryWiseDiscountGuidanceMap = new Map<String, Discount_Guidance__c>();
            Map<String, Discount_Guidance__c> priceListTypeWiseDiscountGuidanceMap = new Map<String, Discount_Guidance__c>();
            
            fillCategoryTypeWiseDiscountGuidanceMap(discountGuidanceList, countryWiseDiscountGuidanceMap, priceListTypeWiseDiscountGuidanceMap);
            
            setDiscountGuidanceOnLineItems(lineItemList, countryWiseDiscountGuidanceMap, priceListTypeWiseDiscountGuidanceMap);
        }
    }
    
    /**
     * Method to fetch Discount Guidance records based on parameters captured in given proposal header wrapper.
     **/
    private List<Discount_Guidance__c> fetchDiscountGuidanceRecords(ConfigAndProposalFieldValueWrapper proposalHeaderWrapper) {
        ilib_LogEvent.push(LOG_TITLE + '.fetchDiscountGuidanceRecords()');
        
        DiscountGuidanceSelector selector = new DiscountGuidanceSelector();
        
        selector.addChannelToSet(proposalHeaderWrapper.distributionChannel);
        selector.addPriceListTypeToSet(proposalHeaderWrapper.priceListType);
        selector.addBillingCountryCodeToSet(proposalHeaderWrapper.billingCountryCode);
        selector.addPrimaryCustomerTypeToSet(proposalHeaderWrapper.primaryCustomerType);
        selector.addCustomerSpendToSet(proposalHeaderWrapper.customerSpend);
        selector.addCurrencyIsoCodeToSet(proposalHeaderWrapper.currencyIsoCode);
        selector.addInstrumentCreditToSet(proposalHeaderWrapper.instrumentCredit);
        selector.addDateValueToSet(proposalHeaderWrapper.quotePricingDate);
        selector.addAllDiscountGridGroupToSet(proposalHeaderWrapper.discountGridGroupSet);
        
        List<Discount_Guidance__c> guidanceList = selector.fetchDiscountGuidanceRecordsForLineItems();
        
        ilib_LogEvent.info('guidanceList : '+guidanceList);
        ilib_LogEvent.pop();
        
        return guidanceList;
    }
    
    /**
     * Method fill map for Country and Price List Type wise Discount Guidance record.
     **/
    private void fillCategoryTypeWiseDiscountGuidanceMap(List<Discount_Guidance__c> discountGuidanceList, Map<String, Discount_Guidance__c> countryWiseDiscountGuidanceMap, Map<String, Discount_Guidance__c> priceListTypeWiseDiscountGuidanceMap) {
        
        for(Integer index = 0; index < discountGuidanceList.size(); index++) {
            Discount_Guidance__c discountGuidance = discountGuidanceList.get(index);
            
            // Country Specific Discount Guidance Record
            if(discountGuidance.Discount_Guidance_Level__c == Label.UI_Label_Country && countryWiseDiscountGuidanceMap.get(discountGuidance.Discount_Grid_Group__c) == null) {
                countryWiseDiscountGuidanceMap.put(discountGuidance.Discount_Grid_Group__c, discountGuidance);
            }
            
            // Country Specific Discount Guidance Record
            else if(discountGuidance.Discount_Guidance_Level__c == Label.Price_List_Type && priceListTypeWiseDiscountGuidanceMap.get(discountGuidance.Discount_Grid_Group__c) == null) {
                priceListTypeWiseDiscountGuidanceMap.put(discountGuidance.Discount_Grid_Group__c, discountGuidance);
            }
        }   
    }
    
    /**
     * Method to set Discount Guidance recommendation on given list of line items from the fetched result.
     **/
    private void setDiscountGuidanceOnLineItems(List<Apttus_Config2__LineItem__c> lineItemList, Map<String, Discount_Guidance__c> countryWiseDiscountGuidanceMap, Map<String, Discount_Guidance__c> priceListTypeWiseDiscountGuidanceMap) {
        
        for(Apttus_Config2__LineItem__c lineItem : lineItemList) {     
            Discount_Guidance__c guidanceRecord = null;
            String discountGridGroup = lineItem.Discount_Grid_Group__c;
            
            // Check for Country type Record
            if(countryWiseDiscountGuidanceMap.containsKey(discountGridGroup)){
                guidanceRecord = countryWiseDiscountGuidanceMap.get(discountGridGroup);
            }
            
            // Check for Price List Type Record
            else if(priceListTypeWiseDiscountGuidanceMap.containsKey(discountGridGroup)){
                guidanceRecord = priceListTypeWiseDiscountGuidanceMap.get(discountGridGroup);
            }
            
            lineItem.Discount_Guidance__c = guidanceRecord == null ? null : guidanceRecord.Id;
            lineItem.Max_Discount_Guidance__c = guidanceRecord == null ? null : guidanceRecord.Max_Discount__c;
            lineItem.Median_Discount_Guidance__c = guidanceRecord == null ? null : guidanceRecord.Median_Discount__c;
        }
    }
    
    
    
    
    /**
     * Method to get Distribution Channel based on code on given agreement line item.
     **/
    private String getDistributionChannelBasedOnCode(Apttus_Config2__ProductConfiguration__c configSO) {
        if(configSO.Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c == Label.DirectDistributionChannelCode) {
            return Label.DistributionChannelDirect;
        } else if(configSO.Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c == Label.IndirectDistributionChannelCode) {
            return Label.DistributionChannelIndirect;
        }
        return null;
    }
    
    /**
     * Method to get Distribution Channel based on code on given agreement line item.
     **/
    private Account getAccountBasedOnDistributionChannel(Apttus_Config2__ProductConfiguration__c configSO) {
        
        // Sold To Account for Direct Channel
        if(configSO.Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c == Label.DirectDistributionChannelCode) {
            return (Account) (configSO.getSObject('Apttus_QPConfig__Proposald__r').getSObject('Apttus_Proposal__Account__r'));
        }
        
        // Ultimate Consignee for Indirect Channel
        else if(configSO.Apttus_QPConfig__Proposald__r.Sold_To_Distribution_Channel__c == Label.IndirectDistributionChannelCode) {
            return (Account) (configSO.getSObject('Apttus_QPConfig__Proposald__r').getSObject('Ultimate_Consignee__r'));
        }
        
        return null;
    }
    
    /**
     * Method to get set of Material Numbers from given list of line items.
     **/
    private Set<String> getSetOfMaterialNumbers(List<Apttus_Config2__LineItem__c> lineItemList) {
        Set<String> materialNumberSet = new Set<String>();
        
        for(Apttus_Config2__LineItem__c lineItem : lineItemList) {
            materialNumberSet.add(lineItem.Product_Code__c);
        }
        
        return materialNumberSet;
    }
    
    /**
     * Method to get map of Discount Grid Groups from the given list of line items.
     **/
    private Set<String> getDiscountGridGroupSet(List<Apttus_Config2__LineItem__c> lineItemList) {
        Set<String> discountGridGroupSet = new Set<String>();
        
        for(Apttus_Config2__LineItem__c lineItem : lineItemList) {
            
            if(String.isNotBlank(lineItem.Discount_Grid_Group__c)) {
                discountGridGroupSet.add(lineItem.Discount_Grid_Group__c);
            }
        }
        
        return discountGridGroupSet;
    }
    
    /**
     * Method to get string value of given object in lower case. If blankForNull is TRUE, it will return empty string for null object.
     **/
    private String toStringLowerCase(Object obj, Boolean blankForNull) {
        return obj == null ? (blankForNull ? '' : null) : String.valueOf(obj).toLowerCase();
    }
    
    
    
    /*************
     * Wrapper class to contain header field values from Configuration / Proposal.
     *************/
    public class ConfigAndProposalFieldValueWrapper {
        
        String configId {get; private set;}
        String proposalId {get; private set;}
        
        String priceListType {get; private set;}
        String distributionChannel {get; private set;}
        String distributionChannelCode {get; private set;} 
        String currencyIsoCode {get; private set;}
        String erpCustomerId {get; private set;}
        String accountRegion {get; private set;}
        String billingCountry {get; private set;}
        String billingCountryCode {get; private set;}
        String nationalGroupNumber {get; private set;}
        String primaryCustomerType {get; private set;}
        Set<String> discountGridGroupSet {get; private set;}
        
        Decimal customerSpend {get; private set;}
        Decimal instrumentCredit {get; private set;}
        Date quotePricingDate {get; private set;}
        Boolean quoteForOpenOfferCustomer {get; private set;}
    }
}