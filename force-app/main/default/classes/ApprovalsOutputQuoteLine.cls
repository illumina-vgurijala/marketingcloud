/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: Class to stamp output values on fields of record after output is calculated
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27           Initial Version
*         Satya Swain                 2021-07-28           Added New Fields
*         Kushal Shah                 2021-09-28           DCP-49429: Added logic for MFN Aprovals
*         Satya Swain                 2021-10-27           Added CodeScan fixes
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsOutputQuoteLine implements IApprovalsOutputProcessor {

    private Map<Id, User> idToAccountOwner;

    // NOTE: interface brings no value now, but i think will be needed when we support agreement lines, etc
    /*
    *   @description:
    *   constructor    
    */
    public ApprovalsOutputQuoteLine(Map<Id, User> idToAccountOwner)
    {
        this.idToAccountOwner = idToAccountOwner;
    }

    /*
    *   @description:
    *   stamps values on line level after output is calculated for entire pipeline        
    */
    public void stampValues(Object record, Approvals.Outputs outputs)
    {
        Apttus_Proposal__Proposal_Line_Item__c quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)record;

        // promo values
        quoteLine.Approval_Hierarchy_Promotion__c = outputs.approvalsResults.promo1.hierarchy;
        quoteLine.Approval_Level_Promotion__c = outputs.approvalsResults.promo1.level;
        quoteLine.Approval_Hierarchy_Promotion_2__c = outputs.approvalsResults.promo2.hierarchy;
        quoteLine.Approval_Level_Promotion_2__c = outputs.approvalsResults.promo2.level;
        quoteLine.Approval_Hierarchy_Promotion_3__c = outputs.approvalsResults.promo3.hierarchy;
        quoteLine.Approval_Level_Promotion_3__c = outputs.approvalsResults.promo3.level;
        quoteLine.Approval_Hierarchy_Promotion_4__c = outputs.approvalsResults.promo4.hierarchy;
        quoteLine.Approval_Level_Promotion_4__c = outputs.approvalsResults.promo4.level;
        quoteLine.Approval_Hierarchy_Promotion_5__c = outputs.approvalsResults.promo5.hierarchy;
        quoteLine.Approval_Level_Promotion_5__c = outputs.approvalsResults.promo5.level;

        // custom approvals
        quoteLine.Approval_Hierarchy_Discount__c = outputs.approvalsResults.customDiscount.hierarchy;
        quoteLine.Approval_Level_Discount__c = outputs.approvalsResults.customDiscount.level;
        quoteLine.Approval_Hierarchy_Product__c = outputs.approvalsResults.customMaterialNumber.hierarchy;
        quoteLine.Approval_Level_Product__c = outputs.approvalsResults.customMaterialNumber.level;
        quoteLine.Approval_Hierarchy_Product_Group__c = outputs.approvalsResults.customMaterialGroup.hierarchy;
        quoteLine.Approval_Level_Product_Group__c = outputs.approvalsResults.customMaterialGroup.level;

        // standard approvals
        quoteLine.Approval_Hierarchy_Record_Owner__c = outputs.approvalsResults.discount.hierarchy; // mapQuoteIdToROHierarchy
        quoteLine.Approval_Level_Record_Owner__c = outputs.approvalsResults.discount.level;
        quoteLine.Approval_Hierarchy_UC_Discount__c = outputs.approvalsResults.discountUC.hierarchy; // mapQuoteIdToUCHierarchy
        quoteLine.Approval_Level_UC_Discount__c = outputs.approvalsResults.discountUC.level;

        // category and status
        quoteLine.Apttus_QPApprov__Approval_Status__c = outputs.approvalsResults.approvalStatus;
        quoteLine.Is_MFN_Line_Item__c = outputs.approvalsResults.isMFNApprovalLine; //DCP-49429
        quoteLine.Approval_Category__c = String.join(new List<String>(outputs.approvalsResults.approvalCategories), ';');

        if (!(String.isBlank(quoteLine.Line_Description__c))) {
            quoteLine.Apttus_Proposal__Description__c = quoteLine.Line_Description__c;
        }

        ilib_LogEvent.message('Quote Line ' + quoteLine.Id + ' Values\n' +
            'categories = ' + quoteLine.Approval_Category__c + '\n' +
            'status = ' + quoteLine.Apttus_QPApprov__Approval_Status__c + '\n' +
            'discount = ' + quoteLine.Approval_Hierarchy_Discount__c + '/' + quoteLine.Approval_Level_Record_Owner__c + '\n' +
            'UC discount = ' + quoteLine.Approval_Hierarchy_UC_Discount__c + '/' + quoteLine.Approval_Level_UC_Discount__c + '\n' +
            'custom material = ' + quoteLine.Approval_Hierarchy_Product__c + '/' + quoteLine.Approval_Level_Discount__c + '\n' +
            'custom group = ' + quoteLine.Approval_Hierarchy_Product__c + '/' + quoteLine.Approval_Level_Product__c + '\n' +
            'custom discount = ' + quoteLine.Approval_Hierarchy_Product_Group__c + '/' + quoteLine.Approval_Level_Product_Group__c + '\n' +
            'promo1 = ' + quoteLine.Approval_Hierarchy_Promotion__c + '/' + quoteLine.Approval_Level_Promotion__c + '\n' +
            'promo2 = ' + quoteLine.Approval_Hierarchy_Promotion_2__c + '/' + quoteLine.Approval_Level_Promotion_2__c + '\n' +
            'promo3 = ' + quoteLine.Approval_Hierarchy_Promotion_3__c + '/' + quoteLine.Approval_Level_Promotion_3__c + '\n' +
            'promo4 = ' + quoteLine.Approval_Hierarchy_Promotion_4__c + '/' + quoteLine.Approval_Level_Promotion_4__c + '\n' +
            'promo5 = ' + quoteLine.Approval_Hierarchy_Promotion_5__c + '/' + quoteLine.Approval_Level_Promotion_5__c
        );
    }

    /*
    *   @description:
    *   stamps values on header level after output is calculated for entire pipeline        
    */
    public void addHeaderOutputValues(Object record, Approvals.Outputs outputs, IApprovalsParentRecordUpdates headerUpdates)
    {
        System.debug('inside addHeaderOutputValues');
        
        Apttus_Proposal__Proposal_Line_Item__c quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)record;
        Approvals.QuoteHeaderUpdates quoteHeaderUpdates = (Approvals.QuoteHeaderUpdates)headerUpdates;

        Id quoteId = quoteLine.Apttus_Proposal__Proposal__c;
        
        System.debug('outputs => '+JSON.serialize(outputs));
        System.debug('outputs.approvalsResults.discount.hierarchy ::: '+outputs.approvalsResults.discount.hierarchy);
        System.debug('outputs.approvalsResults.discountUC.hierarchy ::: '+outputs.approvalsResults.discountUC.hierarchy);

        quoteHeaderUpdates.setApprovalError(quoteId, null);
        if(outputs.approvalsResults.discount.hierarchy != null)
        {
            quoteHeaderUpdates.setHierarchyOwner(quoteId, outputs.approvalsResults.discount.hierarchy);
        }
        if(outputs.approvalsResults.discountUC.hierarchy != null)
        {
            quoteHeaderUpdates.setTransborderHierarchyOwner(quoteId, outputs.approvalsResults.discountUC.hierarchy);
        }        
        approvalErrorHandling(outputs, quoteHeaderUpdates);
    }

    /*
    *   @description:
    *   main method for handling errors generated during approvals pipeline execution   
    */
    private void approvalErrorHandling(Approvals.Outputs outputs, Approvals.QuoteHeaderUpdates quoteHeaderUpdates)
    {
        Set<Id> quoteIdsWithError = new Set<Id>(outputs.erroredQuoteIdToOwnerIds.keySet());
        quoteIdsWithError.addAll(outputs.erroredQuoteIdToAccount.keySet());
        quoteIdsWithError.addAll(outputs.quotesWithMatrixError);
            
        for (Id quoteId : quoteIdsWithError)
        {
            // NOTE: moved these inside the loop so errors wouldn't carry between quotes, verify ok
            String hierarchyErrorMessage = '';
            String territoryErrorMessage = '';
            String matrixErrorMessage = '';

            Set<Id> quoteAccountOwnerIds = outputs.erroredQuoteIdToOwnerIds.get(quoteId);

            if (quoteAccountOwnerIds != null && !quoteAccountOwnerIds.isEmpty()) {
                hierarchyErrorMessage = addHierarchyErrorString(quoteAccountOwnerIds, hierarchyErrorMessage);
            }

            if (outputs.erroredQuoteIdToAccount.keySet().contains(quoteId))
            {
                territoryErrorMessage = addTerritoryErrorString(outputs.erroredQuoteIdToAccount.get(quoteId), territoryErrorMessage);
            }

            if (outputs.quotesWithMatrixError.contains(quoteId)) {
                matrixErrorMessage = Label.UI_Error_ApprovalMatrixNotFound + '\n';
            }

            quoteHeaderUpdates.setApprovalError(quoteId, hierarchyErrorMessage + territoryErrorMessage + matrixErrorMessage);
        }
    }

    /*
    *   @description:
    *   calculates error message to display if approval hierarchy is missing   
    */
    private String addHierarchyErrorString(Set<Id> quoteAccountOwnerIds, String hierarchyErrorMessage)
    {
        // Added strErrorMessage as part of codescan fix
        String strErrorMessage = hierarchyErrorMessage;
        for (Id ownerId : quoteAccountOwnerIds)
        {
            if (!idToAccountOwner.containsKey(ownerId)) { continue; }

            String ownerName = idToAccountOwner.get(ownerId).Name;
            if (String.isBlank(strErrorMessage)) {
                strErrorMessage = Label.UI_Error_ApprovalHierarchyNotInPlace + ' ' + ownerName + '.';
            } else {
                strErrorMessage += ', ' + ownerName;
            }
        }

        if (String.isNotBlank(strErrorMessage)) {
            strErrorMessage += ' ' + Label.UI_Error_ContactQuoteTeam + '\n';
        }

       return strErrorMessage;
    }
    
    /*
    *   @description:
    *   calculates error message if territory is missing on Account     
    */
    private String addTerritoryErrorString(String missingTerritoryAccountDetail, String territoryErrorMessage)
    {
        // Added strErrorMessage as part of codescan fix
        String strErrorMessage = territoryErrorMessage;
        if (String.isBlank(strErrorMessage)) {
            strErrorMessage = Label.UI_Error_AccountTerritoryNotInPlace + ' ' + missingTerritoryAccountDetail + '.';
        } else {
            strErrorMessage += ', ' + missingTerritoryAccountDetail;
        }

        if (String.isNotBlank(strErrorMessage)) {
            strErrorMessage += ' ' + Label.UI_Error_ContactRegionalSalesOps + '\n';    
        }

        return strErrorMessage;
    }

}