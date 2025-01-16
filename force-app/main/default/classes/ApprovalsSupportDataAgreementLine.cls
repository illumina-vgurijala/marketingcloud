/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: Class to prepare the collections of Support Data for AgreementLine Approvals
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varna               2021-12-07           Initial Version
*    -------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsSupportDataAgreementLine {

    /*
    *   @description:
    *   public method that returns the wrapper containing support data details for agreement line items   
    */
    public Approvals.SupportData prepareSupportData(Approvals.AgreementLineInputs inputs) {

        Set<Id> productIds = getProductIds(inputs.agreementLines);

        Map<Id, Product2> idToProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(productIds));

        Set<Id> agreementLinesUpdated = getUpdatedAgreementLines(inputs.agreementLines);

        Approvals.ApprovalMatricesWrapper approvalMatricesWrapper = getApprovalMatricesWrapper(); //Done
        ilib_LogEvent.message('@@@@ approvalMatricesWrapper' + approvalMatricesWrapper);

        Map<String, Account> customerERPToAccount = getCustomerERPToAccount(inputs);
        ilib_LogEvent.message('^&^ customerERPToAccount'+ customerERPToAccount);

        // TTN - this collection (setAccountIds) isn't used elsewhere so i moved it from instance variable to here
        Set<Id> setAccountIds = UtilsCollection.getSetOfIds(inputs.idToAgreement.values(), 'Apttus__Account__c');
        Map<Id,Account> idToAccount = new Map<Id,Account>(new AccountsSelector().selectAccountsAndRelatedSalesArea(setAccountIds)); // Support Data (Added new field)


        if(approvalMatricesWrapper.idToMatrix.values().isEmpty())
        {
            // TTN: since this is an expected path, made smaller constructor part of the API
            return new Approvals.SupportData(
                inputs.idToAgreement, 
                idToProduct,
                approvalMatricesWrapper,
                agreementLinesUpdated,
                customerERPToAccount,
                idToAccount
            );
        }

        List<Custom_Approval_Matrix_Products__c> matrixProducts = new CustomApprovalMatrixProductSelector().selectbyCustomApprMatrixId(approvalMatricesWrapper.materialNumberMatrixIds);
        Map<Id, Set<String>> matrixIdToProductNumbers = ApprovalsUtils.getMatrixIdToProductNumbers(matrixProducts); //Done
        ilib_LogEvent.message('@@@@ matrixIdToProductNumbers' + matrixIdToProductNumbers);

        Set<String> materialNumbers = getMaterialNumbers(matrixIdToProductNumbers);

        List<Account_Sales_Area__c> lstAccSalesArea = getLstAccSalesArea(inputs.agreementLines, inputs.idToAgreement);

        Map<String,Account_Sales_Area__c> aliToAccountSalesArea = getMapAliToAccountSalesArea(inputs, lstAccSalesArea);

        List<Apttus_Config2__PriceListItem__c> priceListItems = getPriceListItems(lstAccSalesArea, productIds);
        ilib_LogEvent.message('@@@ List of PLI - '+ priceListItems);

        Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>> productIdToPriceListItem = getProductIdToPriceListItem(priceListItems);

        Map<String, Integer> approvalKeyToPriority = ApprovalsUtils.retrieveApprovalKeyToPriority(); // Support Data
        
        Map<id, Approval_Hierarchy__c> userIdToApprovalHierarcy = getApprovalHierarchyByAccountOwner(inputs.idToAgreement); // SupportData

        ilib_LogEvent.push('Approvals-prepare for agreement line processing');
        ilib_LogEvent.message('Key Support Data\n' +
            'agreements = ' + inputs.idToAgreement.keySet() + '\n' +
            'products = ' + idToProduct.keySet() + '\n' +
            'approvalMatrices = ' + approvalMatricesWrapper.idToMatrix.keySet() + '\n' +
            'users with approvals = ' + userIdToApprovalHierarcy.keySet()
        );
        ilib_LogEvent.pop();

        return new Approvals.SupportData( 
            inputs.idToAgreement, 
            idToProduct, 
            approvalMatricesWrapper, 
            userIdToApprovalHierarcy, 
            idToAccount, 
            approvalKeyToPriority, 
            matrixIdToProductNumbers,
            materialNumbers,
            customerERPToAccount,
            aliToAccountSalesArea,
            priceListItems,
            productIdToPriceListItem,
            agreementLinesUpdated
        );

    }

    // TTN: created this method so prepareSupportData() doesn't include intermediary steps towards its goal
    private List<Account_Sales_Area__c> getLstAccSalesArea(List<Apttus__AgreementLineItem__c> agreementLines, Map<Id, Apttus__APTS_Agreement__c> idToAgreement)
    {
        // TTN - this collection (setCustomerERP) isn't used elsewhere so i moved it along with the selector that uses it to their own method
        //Getting lists of Customer ERP ids
        Set<String> setCustomerERP = new Set<String>();
        for (Apttus__AgreementLineItem__c ali : agreementLines) {
            setCustomerERP.add(generateStrCustomerErpID(ali, idToAgreement));
        }

        return new AccountSalesAreaSelector().selectAccountSaleaAreaByERP(setCustomerERP);
    }

    private Set<Id> getUpdatedAgreementLines(List<Apttus__AgreementLineItem__c> agreementLines)
    {
        Set<Id> agreementLinesUpdated = new Set<Id>();
        for(Apttus__AgreementLineItem__c agreementLine : agreementLines)
        {
            if(String.isNotBlank(agreementLine.Id)){
				agreementLinesUpdated.add(agreementLine.Id);
			}
        }

        return agreementLinesUpdated;
    }

    private Set<String> getMaterialNumbers(Map<Id, Set<String>> matrixIdToProductNumbers)
    {
        Set<String> materialNumbers = new Set<String>();
        if(!matrixIdToProductNumbers.isEmpty())
        {
            for(Set<String> productNumbers : matrixIdToProductNumbers.values())
            {
                materialNumbers.addAll(productNumbers);
            }
        }

        return materialNumbers;
    }

    private Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>> getProductIdToPriceListItem(List<Apttus_Config2__PriceListItem__c> priceListItems) {
        Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>> mapProductPricelist= new Map<String,Map<String,List<Apttus_Config2__PriceListItem__c>>>();

        for(Apttus_Config2__PriceListItem__c objPricelistItem : priceListItems){
            if(mapProductPricelist.containskey(objPricelistItem.Apttus_Config2__ProductId__c))
            {
                if(mapProductPricelist.get(objPricelistItem.Apttus_Config2__ProductId__c).containskey(objPricelistItem.Apttus_Config2__PriceListId__r.Name)) {  
                    mapProductPricelist.get(objPricelistItem.Apttus_Config2__ProductId__c).get(objPricelistItem.Apttus_Config2__PriceListId__r.Name).add(objPricelistItem);
                }else {
                    mapProductPricelist.get(objPricelistItem.Apttus_Config2__ProductId__c).put(objPricelistItem.Apttus_Config2__PriceListId__r.Name,new List<Apttus_Config2__PriceListItem__c>{objPricelistItem});
                }
            }else {
                Map<String,List<Apttus_Config2__PriceListItem__c>> pricelistToItem=new Map<String,List<Apttus_Config2__PriceListItem__c>>();
                pricelistToItem.put(objPricelistItem.Apttus_Config2__PriceListId__r.Name,new List<Apttus_Config2__PriceListItem__c>{objPricelistItem});
                mapProductPricelist.put(objPricelistItem.Apttus_Config2__ProductId__c,pricelistToItem);
            }

        }

        return mapProductPricelist;
    }

    private List<Apttus_Config2__PriceListItem__c> getPriceListItems(List<Account_Sales_Area__c> lstAccSalesArea, Set<Id> productIds) {
        Set<String> priceListNames = new Set<String>();
        if(!lstAccSalesArea.isEmpty())
        {
            priceListNames = getPriceListNames(lstAccSalesArea); // temp
            // strpriceList = lstAccSalesArea.get(0).Price_List__c; // temp - probably not even useful - check codebase
        }
        return new PriceListItemsSelector().selectByProductIdsAndPriceList(productIds,priceListNames); // Support Data (Added new field)
    }

    private Map<String, Account> getCustomerERPToAccount(Approvals.AgreementLineInputs inputs) {
        Set<String> setCustomerERPFromAgreement = new Set<String>();
        Map<String, Account> customerERPToAccount = new Map<String, Account>();

        for(Apttus__AgreementLineItem__c ali : inputs.agreementLines)
        {
            setCustomerERPFromAgreement.add(ali.Customer_ERP_Number__c);
        }

        List<Account> lstAccounts = new AccountsSelector().selectAccountsAndRelatedSalesAreaForERPCustomerIds(setCustomerERPFromAgreement);
        for(Account objAcc : lstAccounts)
        {
            customerERPToAccount.put(objacc.ERP_Customer_Id__c,objacc); // Support Data (Added new field)
        }

        return customerERPToAccount;
    }

    private Map<id, Approval_Hierarchy__c> getApprovalHierarchyByAccountOwner(Map<Id, Apttus__APTS_Agreement__c> idToAgreement)
    {
        // TTN - this collection (setAccountOwnerIds) isn't used elsewhere so i moved it from instance variable to here
        Set<Id> setAccountOwnerIds = UtilsCollection.getSetOfIds(idToAgreement.values(), 'Apttus__Account__r.OwnerId');

        Map<id, Approval_Hierarchy__c> ownerToApporovalHierarchy = new Map<id, Approval_Hierarchy__c>();

        if (!setAccountOwnerIds.isEmpty()){
            List<Approval_Hierarchy__c> lstApprovalHierarchy = new ApprovalHierarchiesSelector().selectByAccountOwner(Approvals.Category.CLM_SALES_HIERARCHY.name(), setAccountOwnerIds);
            for(Approval_Hierarchy__c objApprovalHierarchy: lstApprovalHierarchy){
                ownerToApporovalHierarchy.put(objApprovalHierarchy.Approver_Level_1__c, objApprovalHierarchy);
            }
        }
        return ownerToApporovalHierarchy;
    }

    private Set<String> getPriceListNames (List<Account_Sales_Area__c> lstAccSalesArea){
        Set<String> priceListNames = new Set<String>();
        for( Account_Sales_Area__c oAccSalesArea:lstAccSalesArea)
        {
            priceListNames.add(oAccSalesArea.Price_List__c);
        }
        return priceListNames;
    }

    private Map<String,Account_Sales_Area__c> getMapAliToAccountSalesArea (Approvals.AgreementLineInputs inputs, List<Account_Sales_Area__c> lstAccSalesArea){
        // TTN - this collection (setAccountOwnerIds) isn't used elsewhere so i moved it from a passed-in variable to here
        Map<String, String> mapAliToERPSalesId = new Map<String, String>();
        for(Apttus__AgreementLineItem__c ali : inputs.agreementLines)
        {
            String strCustomerERPSalesId = generateStrCustomerErpID(ali,inputs.idToAgreement);
            String keyAliToErpSalesId = String.valueOf(ali.Line_Type__c)+String.valueOf(ali.Discount_Type__c)+String.valueOf(ali.RecordTypeId)+strCustomerERPSalesId;
            mapAliToERPSalesId.put(keyAliToErpSalesId, strCustomerERPSalesId);
        }
        ilib_LogEvent.message('@@@@ mapAliToERPSalesId' + mapAliToERPSalesId);

        Map<String,Account_Sales_Area__c> mapAliToAccountSalesArea = new Map<String,Account_Sales_Area__c>();

        for(Apttus__AgreementLineItem__c ali : inputs.agreementLines)
        {   
            String strCustomerERPSalesIdForAli = generateStrCustomerErpID(ali,inputs.idToAgreement);
            String keyAliToErpSalesId = String.valueOf(ali.Line_Type__c)+String.valueOf(ali.Discount_Type__c)+String.valueOf(ali.RecordTypeId)+strCustomerERPSalesIdForAli;
            if(mapAliToERPSalesId.containskey(keyAliToErpSalesId))
            {
                for(Account_Sales_Area__c oAccSalesArea:lstAccSalesArea)
                {   
                    if(oAccSalesArea.ERP_Account_Sales_Area_Id__c == mapAliToERPSalesId.get(keyAliToErpSalesId))
                    {
                        mapAliToAccountSalesArea.put(keyAliToErpSalesId,oAccSalesArea);
                    }                
                }
            }
        }

        return mapAliToAccountSalesArea;
    }

    private Set<Id> getProductIds(List<Apttus__AgreementLineItem__c> agreementLines)
    {
        Set<Id> productIds = new Set<Id>();
        for(Apttus__AgreementLineItem__c ali: agreementLines)
        {
            if(ali.Apttus__ProductId__c != null) 
            {
                productIds.add(ali.Apttus__ProductId__c);
            }
        }
        return productIds;
    }

    private static String generateStrCustomerErpID(Apttus__AgreementLineItem__c agreementLineItem, Map<Id,Apttus__APTS_Agreement__c> mapIdToAgreement)
    {
        String strCustomerERPSalesId = null;
        // TODO: Move this from Agreement line items to Approvals framework
        if(Approvals.lineTypeForApprovals.contains(agreementLineItem.Line_Type__c) || Approvals.lineTypeForApprovals.contains(agreementLineItem.Line_Type_1__c) && mapIdToAgreement.containskey(agreementLineItem.Apttus__AgreementId__c)) 
        {
            ilib_LogEvent.message('Map contains Agreement Id for Price Group Check ');
            strCustomerERPSalesId =  mapIdToAgreement.get(agreementLineItem.Apttus__AgreementId__c).Account_ERP_Number__c +'_' + agreementLineItem.Sales_Org__c + agreementLineItem.Distribution_Channel__c + System.Label.AccountSalesAreaDivision; // (00 to be put in label - division value)
        }
        else
        {
            strCustomerERPSalesId = agreementLineItem.Customer_ERP_Number__c +'_' + agreementLineItem.Sales_Org__c + agreementLineItem.Distribution_Channel__c + System.Label.AccountSalesAreaDivision; // (00 to be put in label - division value)
        }
        return strCustomerERPSalesId;
    }

    private Approvals.ApprovalMatricesWrapper getApprovalMatricesWrapper() {

        Approvals.ApprovalMatricesWrapper wrapper = new Approvals.ApprovalMatricesWrapper();

        for (Custom_Approval_Matrix__c matrix : new CustomApprovalMatrixSelector().selectActive())
        {
            // TTN: split this up like we did in quote line so the methods are shorter
            prepareMatrixSupportData(matrix, wrapper);            
        }

        return wrapper;
    }

    private void prepareMatrixSupportData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper)
    {
        wrapper.idToMatrix.put(matrix.Id, matrix);

        if (matrix.Approval_Hierarchy_Type__c == null) { return; }

        List<String> hierarchyTypes = matrix.Approval_Hierarchy_Type__c.split(';');

        prepareMaterialNumberMatrixData(matrix, wrapper, hierarchyTypes);
        prepareMaterialGroupMatrixData(matrix, wrapper, hierarchyTypes);
        prepareDiscountMatrixData(matrix, wrapper, hierarchyTypes);
    }

    private void prepareMaterialNumberMatrixData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper, List<String> hierarchyTypes)
    {
        if (matrix.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixMaterialNumber)
        {
            if (hierarchyTypes.contains(Approvals.HIERARCHY_TYPE_RECORD_OWNER))
            {
                wrapper.materialNumberMatrices.add(matrix);
                wrapper.materialNumberMatrixIds.add(matrix.Id);
            }
            if (hierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM)) 
            {
                wrapper.customMaterialNumberMatrices.add(matrix);
                wrapper.materialNumberMatrixIds.add(matrix.Id);
            }
        } 
    }

    private void prepareMaterialGroupMatrixData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper,List<String> hierarchyTypes)
    {
        if (matrix.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixMaterialGroup) 
        {
            if(hierarchyTypes.contains(Approvals.HIERARCHY_TYPE_RECORD_OWNER))
            {
                if (!wrapper.idToMaterialGroups.containsKey(matrix.Id))
                {
                    wrapper.idToMaterialGroups.put(matrix.Id, new Set<String>());
                }
                wrapper.idToMaterialGroups.get(matrix.Id).add(matrix.Material_Group_1__c);
                wrapper.materialGroupMatrices.add(matrix);
            }
            if (hierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM))
            {
                if (!wrapper.idToCustomMaterialGroups.containsKey(matrix.Id))
                {
                    wrapper.idToCustomMaterialGroups.put(matrix.Id, new Set<String>());
                }
                wrapper.idToCustomMaterialGroups.get(matrix.Id).add(matrix.Material_Group_1__c);
                wrapper.customMaterialGroupMatrices.add(matrix);
            }
        }
    }

    private void prepareDiscountMatrixData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper,List<String> hierarchyTypes)
    {
        if (matrix.RecordType.DeveloperName == System.Label.RecordTypeCustomApprovalMatrixDiscount)
        {
            if(hierarchyTypes.contains(Approvals.HIERARCHY_TYPE_RECORD_OWNER))
            {
                wrapper.discountMatrices.add(matrix);
            }
            if(hierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM))
            {
                wrapper.customDiscountMatrices.add(matrix);
            }
        }  
    }

}