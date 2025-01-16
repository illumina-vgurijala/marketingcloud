/**
*    @author Todd Newman
*    @date   2021-12-13
*    @description    DCP-50961: This class contains logic for handling methods that can be called by all agreementi line flows
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-12-13            Initial Version
*         Sudarshan Kataria           2024-06-06            Changes for DGP 302
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsAgreementLineStepBase implements IApprovalsDomainStep {

    // context data for this transaction mapped into useful collections
    protected Approvals.SupportData data;
    // name of the step, used for logging and sometimes business logic
    protected Approvals.StepName stepName;

    // each step in the pipeline builds these values over the course of the step
    protected Approvals.StepResults stepResults;
    // the output which is built over multiple steps
    // StepResults are merged into this variable at the end of the step
    protected Approvals.Outputs outputs;
    public static final String RECORD_OWNER = 'Record Owner';
    public static final String CUSTOM = 'Custom';

    /*
        constructor
    */
    public ApprovalsAgreementLineStepBase(Approvals.StepName stepName, Approvals.SupportData data)
    {
        initSupportData(stepName, data);
    }

    private void initSupportData(Approvals.StepName stepName, Approvals.SupportData data)
    {
        this.stepName = stepName;
        this.data = data;
    }

    /* initialize results and outputs */
    public void initStepData(Approvals.StepResults stepResults, Approvals.Outputs outputs)
    {
        this.stepResults = stepResults;
        this.outputs = outputs;
    }

    /*
        @description: 
        Method to copy hierarchy and level to output wrapper which will later be stamped on the line item
    */
    public void copyHierarchyAndLevel()
    {
        // copy hierarchy found boolean
        if(stepName == Approvals.StepName.CLM_MATERIAL_NUMBER) {
            outputs.approvalsResults.isHierarchyFound.materialNumber = stepResults.approvalFound;
        } else if(stepName == Approvals.StepName.CLM_MATERIAL_GROUP_1) {
            outputs.approvalsResults.isHierarchyFound.materialGroup = stepResults.approvalFound;
        } else if(stepName == Approvals.StepName.CLM_DISCOUNT) {
            outputs.approvalsResults.isHierarchyFound.discount = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CLM_MATERIAL_NUMBER_CUSTOM) {
            outputs.approvalsResults.isHierarchyFound.customMaterialNumber = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CLM_MATERIAL_GROUP_CUSTOM) {
            outputs.approvalsResults.isHierarchyFound.customMaterialGroup = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CLM_DISCOUNT_CUSTOM) {
            outputs.approvalsResults.isHierarchyFound.customDiscount = stepResults.approvalFound;
        }

        // copy hierarchy/level
        if (stepName == Approvals.StepName.CLM_MATERIAL_NUMBER || stepName == Approvals.StepName.CLM_MATERIAL_GROUP_1 || stepName == Approvals.StepName.CLM_DISCOUNT) {
            outputs.approvalsResults.discount = stepResults.discount;
        } else if (stepName == Approvals.StepName.CLM_MATERIAL_NUMBER_CUSTOM) {
            outputs.approvalsResults.customMaterialNumber = stepResults.discount;
        } else if (stepName == Approvals.StepName.CLM_MATERIAL_GROUP_CUSTOM) {
            outputs.approvalsResults.customMaterialGroup = stepResults.discount;
        } else if (stepName == Approvals.StepName.CLM_DISCOUNT_CUSTOM) {
            outputs.approvalsResults.customDiscount = stepResults.discount;
        } else if (stepName == Approvals.StepName.CLM_MFN) {
            outputs.approvalsResults.isMFNApprovalLine = stepResults.isMFNApprovalLine;
        }
    }

    /*  
    *   @description:
    *   after execution of a particular step, any errors found during execution are copied to output wrapper for stamping on record later
    */
    public void copyErrorInformation()
    {
        // copy error record association
        outputs.agreementstoRevert.addAll(stepResults.agreementstoRevert);
        outputs.agreementsWithMatrixError.addAll(stepResults.agreementsWithMatrixError);
        outputs.agreementsWithHierarchyError.addAll(stepResults.agreementsWithHierarchyError);
        outputs.agreementstoRemoveFromMatrixError.addAll(stepResults.agreementstoRemoveFromMatrixError);
    }

    /*  
    *   @description:
    *   called in every step execution
    *   determines the highest priority matrix based on input data and type of Approval
    */
    public Approvals.MatrixWrapper findHighestPriorityMatrix(SObject line, String strApprovalType, Boolean isTransborder, String hierarchyType)
    {
        Apttus__AgreementLineItem__c agreementLine = (Apttus__AgreementLineItem__c)line;

        Account account = getAccountForPriceGroup(agreementLine);
        Decimal lineDiscountPercent =  agreementLine.Discount_In_Percent__c == null ? 0 : agreementLine.Discount_In_Percent__c;

        // create default result, look for best result in the loop
        // defaulted the owner Id field to take the value as follows
        // OwnerId = AgrLineItem->Agreement->Account->OwnerId
        Approvals.MatrixWrapper result = new Approvals.MatrixWrapper(data.idToAccount.get(data.idToAgreement.get(agreementLine.Apttus__AgreementId__c).Apttus__Account__c).ownerId);

        List<Custom_Approval_Matrix__c> allCandidateMatrices = getAppropriateCustomApprovalMatrixRecords(this.stepName);

        System.debug('Length of approval matrix-->' + allCandidateMatrices.size());
        System.debug('lineDiscountPercent-->' + lineDiscountPercent);

        if (allCandidateMatrices.isEmpty()) { return result; }

        // create a dummy best so far
        Approvals.CandidateMatrix bestSoFarMatrix = new Approvals.CandidateMatrix();
        
        // loop through the candidate matrices to find the actual best        
        for (Custom_Approval_Matrix__c matrixRecord : allCandidateMatrices)
        {
            Approvals.CandidateMatrix candidateMatrix = buildCandidateMatrix(matrixRecord, agreementLine, strApprovalType, account);
            System.debug('CandidateMatrix for '+strApprovalType+' ::: '+JSON.serialize(candidateMatrix));

            // compare best so far with candidate, winner is (new) best so far
            bestSoFarMatrix = ApprovalsUtils.getPriorityResult(candidateMatrix, bestSoFarMatrix);

            // if an appropriate matrix was found, build the output based on it
            if (bestSoFarMatrix.isApprovalMatrixFound)
            {
                result = buildMatrixWrapper(bestSoFarMatrix.record, lineDiscountPercent, result.ownerId, hierarchyType);
            }
        }
        System.debug('Highest priority matrix returned for '+ strApprovalType +'type approval scenario ::: ' + JSON.serialize(result));
        return result;
    }

    private List<Custom_Approval_Matrix__c> getAppropriateCustomApprovalMatrixRecords(Approvals.StepName stepName)
    {
        List<Custom_Approval_Matrix__c> selectedMatrixRecords = null;
        switch on stepName {
            when CLM_MATERIAL_NUMBER {		
                selectedMatrixRecords = data.approvalMatricesWrapper.materialNumberMatrices;
            }
            when CLM_MATERIAL_GROUP_1 {		
                selectedMatrixRecords = data.approvalMatricesWrapper.materialGroupMatrices;
            }
            when CLM_DISCOUNT {		
                selectedMatrixRecords = data.approvalMatricesWrapper.discountMatrices;
            }
            when CLM_MATERIAL_NUMBER_CUSTOM {		
                selectedMatrixRecords = data.approvalMatricesWrapper.customMaterialNumberMatrices;
            }
            when CLM_MATERIAL_GROUP_CUSTOM {                
                selectedMatrixRecords = data.approvalMatricesWrapper.customMaterialGroupMatrices;
            }
            when CLM_DISCOUNT_CUSTOM {		
                selectedMatrixRecords = data.approvalMatricesWrapper.customDiscountMatrices;
            }
            when else {
                selectedMatrixRecords = new List<Custom_Approval_Matrix__c>();
            }
        } 

        return selectedMatrixRecords;
    }

    // TODO: agreement service method?
    private String calculateChannel(Apttus__AgreementLineItem__c agreementLine)
    {
        // Can remove this if check as Distribution Channel is required
        if(agreementLine.Distribution_Channel__c == null) { return null; }
        
        if(agreementLine.Distribution_Channel__c == System.Label.AgreementLineItemDistributionChannelIndirect){
            return System.Label.DistributionChannelIndirect;
        }else if(agreementLine.Distribution_Channel__c == System.Label.AgreementLineItemDistributionChannelDirect){
            return System.Label.DistributionChannelDirect;   
        }
        else{
            return null;
        }
    }

    // @PureFunction
    @TestVisible
    private Approvals.MatrixWrapper buildMatrixWrapper(Custom_Approval_Matrix__c bestSoFarMatrix, Decimal lineDiscountPercent, Id ownerId, String hierarchyType)
    {
        Boolean isDiscountUnderLevel1 = getIsDiscountUnderLevel1(bestSoFarMatrix, lineDiscountPercent);

        Integer approvalLevel = getApprovalLevelFromMatrix(isDiscountUnderLevel1, bestSoFarMatrix, lineDiscountPercent, hierarchyType);

        System.debug('Approval Level = --> ' + approvalLevel);

        return new Approvals.MatrixWrapper(bestSoFarMatrix, isDiscountUnderLevel1, approvalLevel, ownerId);
    }

    // @PureFunction
    @TestVisible
    private Boolean getIsDiscountUnderLevel1(Custom_Approval_Matrix__c matrixRecord, Decimal lineDiscountPercent)
    {
        List<String> lstAppHierarchyTypes = matrixRecord.Approval_Hierarchy_Type__c.split(';');

        //Decimal matrixMinimumPercent = lstAppHierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM) && matrixRecord.Min_Discount__c!=null?matrixRecord.Min_Discount__c: matrixRecord.Agreement_Minimum_Discount__c == null ? 0 : matrixRecord.Agreement_Minimum_Discount__c; -- Commented for DGP-821
        Decimal matrixMinimumPercent = matrixRecord.Min_Discount__c != null ? matrixRecord.Min_Discount__c : 0;

        return lineDiscountPercent <= matrixMinimumPercent;
    }

    // @PureFunction
    @TestVisible
    private Integer getApprovalLevelFromMatrix(Boolean isDiscountUnderLevel1, Custom_Approval_Matrix__c matrixRecord, Decimal lineDiscountPercent, String hierarchyType) {
        
        // DGP-821:Approval Level For Record Owner is determined in "ApprovalsOutputAgreementLine" Class
        if (isDiscountUnderLevel1 || hierarchyType == RECORD_OWNER) { return 1;}

        Integer approvalLevel = null;
        for (Integer loopLevel = 1; loopLevel <= Approvals.MAX_APPROVAL_LEVEL; loopLevel++) {
            Decimal matrixPercentForLevel = (Decimal) matrixRecord.get('Discount_Level_' + loopLevel + '__c');

            if (matrixPercentForLevel != null && lineDiscountPercent <= matrixPercentForLevel) {
                approvalLevel = loopLevel;
                break;
            }
        }

        return approvalLevel;
    }


    private Approvals.CandidateMatrix buildCandidateMatrix(Custom_Approval_Matrix__c matrixRecord, Apttus__AgreementLineItem__c agreementLine, String strApprovalType, Account account)
    {
        Integer candidatePriority = null;
        Datetime candidateLastModified = null;

        Id productId = agreementLine.Apttus__ProductId__c;

        if (strApprovalType == Approvals.APPROVAL_TYPE_MATNUM && data.matrixIdToProductNumbers.containsKey(matrixRecord.Id))
        {
            List<String> lstProductNumbers = ApprovalsUtils.expandProductNumbers(data.matrixIdToProductNumbers.get(matrixRecord.Id));

            if (productId != null && lstProductNumbers.contains(data.idToProduct.get(productId).Material_Number__c))
            {
                candidatePriority = getPriorityFromKey(agreementLine, matrixRecord, account);
                candidateLastModified = matrixRecord.LastModifiedDate;
            }
        }
        else if (strApprovalType == Approvals.APPROVAL_TYPE_MATGRP && data.approvalMatricesWrapper.idToMaterialGroups.containsKey(matrixRecord.Id))
        {
            List<String> lstProductGroups = ApprovalsUtils.expandProductNumbers(data.approvalMatricesWrapper.idToMaterialGroups.get(matrixRecord.Id));

            if (productId != null && lstProductGroups.contains(data.idToProduct.get(productId).Material_Group_1_Code__c)
                || lstProductGroups.contains(agreementLine.Material_Group_1__c))
            {
                candidatePriority = getPriorityFromKey(agreementLine, matrixRecord, account);
                candidateLastModified = matrixRecord.LastModifiedDate;
            }
        }
        else if (strApprovalType == Approvals.APPROVAL_TYPE_DISCOUNT)
        {
            candidatePriority = getPriorityFromKey(agreementLine, matrixRecord, account);
            candidateLastModified = matrixRecord.LastModifiedDate;
        }

        return new Approvals.CandidateMatrix(false, matrixRecord, candidatePriority, candidateLastModified);
    }

    private Integer getPriorityFromKey(Apttus__AgreementLineItem__c agreementLine, Custom_Approval_Matrix__c matrixRecord, Account account)
    {
        String conditionKey = generatePriorityKey(agreementLine, matrixRecord, account);
        Integer intPriority = null;
        if (data.approvalKeyToPriority.containsKey(conditionKey)) {
            intPriority = data.approvalKeyToPriority.get(conditionKey);
        }
        System.debug('Priority returned for this combination ::: '+intPriority);
        return intPriority;
    }

    // @PureFunction
    // generates a string key based on several boolean checks against the agreement line and its related records
    // used as a key against records from Approval_Priority_Combination__mdt
    @TestVisible
    private String generatePriorityKey(Apttus__AgreementLineItem__c agreementLine, Custom_Approval_Matrix__c matrixRecord, Account account)
    {
        String strDistributionChannel = calculateChannel(agreementLine);
        String strRegion = matrixRecord.Region__c;
        String strDistChannel = matrixRecord.Distribution_Channel__c;
        // String strSalesOrg = matrixRecord.Sales_Organization__c;
        String strCountry = matrixRecord.Country__c;
        String strCurrency = matrixRecord.Currency__c;
        String strPriceListType = matrixRecord.Price_List_Type__c; // DGP-52
        String accountPriceListType = getAccountPriceListTypeForAgreementLine(agreementLine, account); // DGP-52
        
        
        System.debug('Matrix details : => ID | Region | Distribution Channel | Sales Org | Country | Currency'); // System.debug added instead of ilib_LogEvent.message as this method will get called for all lines and all relevant matrices
        System.debug(matrixRecord.Id + '_' + strDistributionChannel + '_' + strRegion + '_' + strDistChannel + '_' + strPriceListType + '_' +strCountry + '_' + strCurrency);

        Approvals.AccountData accountData = new Approvals.AccountData(account.Territory_Region__c, account.BillingCountryCode, account.OwnerId);

        // Boolean boolSalesOrg = (String.isBlank(strSalesOrg) ? false : strSalesOrg.contains(agreementLine.Sales_Org__c));
        Boolean boolRegionCheck = String.isNotBlank(strRegion) && String.isNotBlank(accountData.region) && strRegion.contains(accountData.region);
        Boolean boolPriceListTypeCheck = String.isNotBlank(strPriceListType) && String.isNotBlank(accountPriceListType) && strPriceListType.contains(accountPriceListType); // DGP-52
        Boolean boolCountryConditionCheck = String.isNotBlank(strCountry) && String.isNotBlank(accountData.country) && strCountry.contains(accountData.country);
        Boolean boolDistributionChannelCheck = String.isNotBlank(strDistChannel) && String.isNotBlank(strDistributionChannel) && strDistChannel.contains(strDistributionChannel);
        Boolean boolCurrencyCheck = String.isNotBlank(strCurrency) && String.isNotBlank(agreementLine.CurrencyIsoCode) && strCurrency.contains(agreementLine.CurrencyIsoCode);

        // Boolean boolSalesOrgBlank = String.isBlank(strSalesOrg);
        Boolean boolRegionBlank = String.isBlank(strRegion);
        Boolean boolPriceListTypeBlank = String.isBlank(strPriceListType); // DGP-52
        Boolean boolDistChannelBlank = String.isBlank(strDistChannel);
        Boolean boolCountryBlank = String.isBlank(strCountry);
        Boolean boolCurrencyBlank = String.isBlank(strCurrency);
        
        // DGP-52 - INVALID if Region is not found/matched
        if(!boolRegionCheck) {
            return null;
        }
        
        String strCondition = 
            boolPriceListTypeCheck                  // matrix Price List Type matches account Price List Type
            + '_' + boolRegionCheck                 // matrix region matches account region (account could be UC, distributor or sold to)
            + '_' + boolCountryConditionCheck       // matrix country matches account country (account could be UC, distributor or sold to)
            + '_' + boolDistributionChannelCheck    // matrix dist channel matches opportunity record type
            + '_' + boolCurrencyCheck               // matrix currency matches quote line
            + '_' + boolPriceListTypeBlank          // matrix Price List Type is blank
            + '_' + boolRegionBlank                 // matrix region is blank
            + '_' + boolDistChannelBlank            // matrix dist channel is blank
            + '_' + boolCountryBlank                // matrix country is blank
            + '_' + boolCurrencyBlank;              // matrix currency is blank
        
        System.debug('condition generated for this matrix: '+strCondition);
        return strCondition;
    }
    
    /**
     * Method to get Price List Type from Account Sales Area records of given Account.
     **/
    private String getAccountPriceListTypeForAgreementLine(Apttus__AgreementLineItem__c agreementLine, Account account) {
        if(account.Account_Sales_Areas__r == null || account.Account_Sales_Areas__r.size() == 0) {
            return null;
        }
        
        String priceListType = null;
        
        for(Account_Sales_Area__c salesArea : account.Account_Sales_Areas__r) {
            if(salesArea.Sales_Organization__c == agreementLine.Sales_Org__c
               		&& salesArea.Distribution_Channel__c == agreementLine.Distribution_Channel__c) {
                priceListType = salesArea.Price_List_Type__c;
                break;
            }
        }
        
        return priceListType;
    }

    private Account getAccountForPriceGroup(Apttus__AgreementLineItem__c agreementLine)
    {
        Account account = null;
        Apttus__APTS_Agreement__c agreement = data.idToAgreement.get(agreementLine.Apttus__AgreementId__c);

        if(Approvals.lineTypeForApprovals.contains(agreementLine.Line_Type__c) || Approvals.lineTypeForApprovals.contains(agreementLine.Line_Type_1__c))
        {
            if(data.idToAccount.containskey(agreement.Apttus__Account__c))
            {
                account = data.idToAccount.get(agreement.Apttus__Account__c);
            }
        }
        else
        {
            if(data.customerERPToAccount.containskey(agreementLine.Customer_ERP_Number__c))
            {
                account = data.customerERPToAccount.get(agreementLine.Customer_ERP_Number__c);
            }
        }
        return account;
    }

}