/**
*    @author Satya Swain
*    @date   2021-07-27
*    @description    DCP-48131: Class to prepare the collections of Support Data for Quotation Approvals
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Satya Swain                 2021-07-27           Initial Version
*         Satya Swain                 2021-10-28           Created prepareMatrixSupportData as part of Codescan Fixes For NPath Complexity
*    -------------------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsSupportDataQuoteLine {

    /*
    *   @description:
    *   public method that returns the wrapper containing support data details for quotation line items   
    */
    public Approvals.SupportData prepareSupportData(Approvals.QuoteLineInputs inputs)
    {
        Approvals.ApprovalMatricesWrapper approvalMatricesWrapper = getApprovalMatricesWrapper();

        Set<Id> productIds = getProductIds(inputs.quoteLines);
        Set<Id> promoIds = getPromoIds(inputs.quoteLines);

        Map<Id, Product2> idToProduct = new Map<Id,Product2>(new ProductsSelector().selectProducts(productIds));

        List<Custom_Approval_Matrix_Products__c> matrixProducts = new CustomApprovalMatrixProductSelector().selectbyCustomApprMatrixId(approvalMatricesWrapper.materialNumberMatrixIds);

        Map<Id, Set<String>> matrixIdToProductNumbers = getMatrixIdToProductNumbers(matrixProducts);

        // DCP-25340, Map of Incentive Id to Incentives
		Map<Id, Apttus_Config2__Incentive__c> idToPromo = new Map<Id,Apttus_Config2__Incentive__c>(new ApttusIncentivesPromotionsSelector().getPromotionsById(promoIds));

        Map<Id, Approval_Hierarchy__c> userIdToApprovalHierarcy = getUserIdToApprovalHierarcy(inputs);
        Map<Id, User> idToAccountOwner = queryAccountOwners(inputs);

        Map<String, Integer> approvalKeyToPriority = ApprovalsUtils.retrieveApprovalKeyToPriority();

        ilib_LogEvent.push('Approvals-prepare for quote line processing');
        ilib_LogEvent.message('Key Support Data\n' +
            'quotes = ' + inputs.idToQuote.keySet() + '\n' +
            'products = ' + idToProduct.keySet() + '\n' +
            'promos = ' + idToPromo.keySet() + '\n' +
            'approvalMatrices = ' + approvalMatricesWrapper.idToMatrix.keySet() + '\n' +
            'users with approvals = ' + userIdToApprovalHierarcy.keySet()
        );
        ilib_LogEvent.pop();
 
        return new Approvals.SupportData(
            inputs.idToQuote,
            idToProduct,
            idToPromo,
            approvalMatricesWrapper,
            userIdToApprovalHierarcy,
            idToAccountOwner,
            approvalKeyToPriority,
            matrixIdToProductNumbers
        );
    }

    private static Map<Id, Approval_Hierarchy__c> getUserIdToApprovalHierarcy(Approvals.QuoteLineInputs inputs)
    {
        Map<Id, Approval_Hierarchy__c> userIdToApprovalHierarcy = new Map<Id, Approval_Hierarchy__c>();        

        Set<Id> accountOwnerIds = getAccountOwnerIds(inputs);

        if (accountOwnerIds.isEmpty()) { return userIdToApprovalHierarcy; }

        List<Approval_Hierarchy__c> approvalHierarchies = new ApprovalHierarchiesSelector().selectByAccountOwner(Approvals.Category.CPQ_Sales_Hierarchy.name(), accountOwnerIds);
        // TODO: could make a generic method in UtilsCollection
        for (Approval_Hierarchy__c approvalHierarchy : approvalHierarchies) {
            userIdToApprovalHierarcy.put(approvalHierarchy.Approver_Level_1__c, approvalHierarchy);
        }

        return userIdToApprovalHierarcy;
    }

    private static Map<Id, User> queryAccountOwners(Approvals.QuoteLineInputs inputs)
    {
        Set<Id> accountOwnerIds = getAccountOwnerIds(inputs);

        if (accountOwnerIds.isEmpty())
        {
            return new Map<Id, User>();
        }
        else
        {
            return new Map<Id, User>(new UsersSelector().selectByUserId(accountOwnerIds));
        }
    }

    private static Set<Id> getAccountOwnerIds(Approvals.QuoteLineInputs inputs)
    {
        Set<Id> accountOwnerIds = new Set<Id>();
        for (Apttus_Proposal__Proposal_Line_Item__c quoteLine : inputs.quoteLines)
        {
            Apttus_Proposal__Proposal__c quote = inputs.idToQuote.get(quoteLine.Apttus_Proposal__Proposal__c);
            if (quote != null)
            {
                if (quote.Apttus_Proposal__Account__r.OwnerId != null) { accountOwnerIds.add(quote.Apttus_Proposal__Account__r.OwnerId); }
                if (quote.Ultimate_Consignee__r.OwnerId != null) { accountOwnerIds.add(quote.Ultimate_Consignee__r.OwnerId); }
                if (quote.Distributor__r.OwnerId != null) { accountOwnerIds.add(quote.Distributor__r.OwnerId); }
            }
        }

        return accountOwnerIds;
    }

    private static Map<Id, Set<String>> getMatrixIdToProductNumbers(List<Custom_Approval_Matrix_Products__c> matrixProducts)
    {
        Map<Id, Set<String>> matrixIdToProductNumbers = new Map<Id, Set<String>>();

        // TODO: could make a generic method in UtilsCollection
        for (Custom_Approval_Matrix_Products__c matrixProduct : matrixProducts)
        {
            Id matrixId = matrixProduct.Custom_Approval_Matrix__c;

            if (!matrixIdToProductNumbers.containsKey(matrixId))
                { matrixIdToProductNumbers.put(matrixId, new Set<String>()); }
            matrixIdToProductNumbers.get(matrixId).add(matrixProduct.Product__r.Material_Number__c);
        }

        return matrixIdToProductNumbers;
    }

    private Set<Id> getProductIds(List<Apttus_Proposal__Proposal_Line_Item__c> quoteLines)
    {
        Set<Id> productIds = new Set<Id>();
        for (Apttus_Proposal__Proposal_Line_Item__c qli : quoteLines)
        {
            productIds.add(qli.Apttus_Proposal__Product__c);
            if (qli.Apttus_QPConfig__OptionId__c != null)
            {
                productIds.add(qli.Apttus_QPConfig__OptionId__c);
            }
        }

        return productIds;
    }

    private Set<Id> getPromoIds(List<Apttus_Proposal__Proposal_Line_Item__c> quoteLines)
    {
        Set<Id> promoIds = new Set<Id>();
        for (Apttus_Proposal__Proposal_Line_Item__c qli : quoteLines)
        {
            if (qli.Promotion_1__c != null) {  //DCP-25340 Adding incentives from qli to the set of incentive Ids <--- Start
                promoIds.add(qli.Promotion_1__c);
            }
            if (qli.Promotion_2__c != null) {
                promoIds.add(qli.Promotion_2__c);
            }
            if (qli.Promotion_3__c != null) {
                promoIds.add(qli.Promotion_3__c);
            }
            if (qli.Promotion_4__c != null) {
                promoIds.add(qli.Promotion_4__c);
            }
            if (qli.Promotion_5__c != null) {
                promoIds.add(qli.Promotion_5__c); //DCP-25340 End --->
            }
        }

        return promoIds;
    }

    private Approvals.ApprovalMatricesWrapper getApprovalMatricesWrapper()
    {
        Approvals.ApprovalMatricesWrapper wrapper = new Approvals.ApprovalMatricesWrapper();

        for (Custom_Approval_Matrix__c cam : new CustomApprovalMatrixSelector().selectActive())
        {
            prepareMatrixSupportData(cam, wrapper);            
        }

        return wrapper;
    }

    private void prepareMatrixSupportData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper)
    {
        wrapper.idToMatrix.put(matrix.Id, matrix);
        
        preparePromotionMatrixData(matrix, wrapper);

        if (matrix.Approval_Hierarchy_Type__c == null) { return; }

        List<String> hierarchyTypes = matrix.Approval_Hierarchy_Type__c.split(';');

        prepareMaterialNumberMatrixData(matrix,wrapper,hierarchyTypes);
        prepareMaterialGroupMatrixData(matrix,wrapper,hierarchyTypes);
        prepareDiscountMatrixData(matrix,wrapper,hierarchyTypes);
    }

    private void preparePromotionMatrixData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper)
    {   
        if (matrix.RecordType.DeveloperName == Approvals.Category.PROMOTION.Name())
        {
            if (!wrapper.promoCodeToMatrices.containsKey(matrix.Promo_Code__c))
            { 
                wrapper.promoCodeToMatrices.put(matrix.Promo_Code__c, new List<Custom_Approval_Matrix__c>()); 
            } //DCP-25340, Get Map of protion code and approval matrix
            wrapper.promoCodeToMatrices.get(matrix.Promo_Code__c).add(matrix);
        }
    }

    private void prepareMaterialNumberMatrixData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper,List<String> hierarchyTypes)
    {
        if (matrix.RecordType.DeveloperName == Approvals.Category.CPQ_MATERIAL_NUMBER.Name())
        {
            if(hierarchyTypes.contains(Approvals.HIERARCHY_TYPE_RECORD_OWNER)) 
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
        if (matrix.RecordType.DeveloperName == Approvals.Category.CPQ_MATERIAL_GROUP_1.Name()) 
        {
            if(hierarchyTypes.contains(Approvals.HIERARCHY_TYPE_RECORD_OWNER))
            {
                if (wrapper.idToMaterialGroups.containsKey(matrix.Id))
                {
                    Set<String> setMatGrp = wrapper.idToMaterialGroups.get(matrix.Id);
                    setMatGrp.add(matrix.Material_Group_1__c);
                    wrapper.idToMaterialGroups.put(matrix.Id, setMatGrp);
                }
                else
                {
                    wrapper.idToMaterialGroups.put(matrix.Id, new Set<String> { matrix.Material_Group_1__c });
                }                
                wrapper.materialGroupMatrices.add(matrix);
            }
            if (hierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM))
            {
                if (wrapper.idToCustomMaterialGroups.containsKey(matrix.Id))
                {
                    Set<String> setMatGrp = wrapper.idToCustomMaterialGroups.get(matrix.Id);
                    setMatGrp.add(matrix.Material_Group_1__c);
                    wrapper.idToCustomMaterialGroups.put(matrix.Id, setMatGrp);
                }
                else
                {
                    wrapper.idToCustomMaterialGroups.put(matrix.Id, new Set<String> { matrix.Material_Group_1__c });
                }                
                wrapper.customMaterialGroupMatrices.add(matrix);
            }
        }
    }

    private void prepareDiscountMatrixData(Custom_Approval_Matrix__c matrix, Approvals.ApprovalMatricesWrapper wrapper,List<String> hierarchyTypes)
    {
        if (matrix.RecordType.DeveloperName == Approvals.Category.CPQ_DISCOUNT.Name())
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