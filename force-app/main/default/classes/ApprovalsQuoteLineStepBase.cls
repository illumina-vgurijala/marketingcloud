/**
*    @author Todd Newman
*    @date   2021-12-13
*    @description    DCP-50961: This class contains logic for handling methods that can be called by all quote line flows
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-12-13            Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsQuoteLineStepBase implements IApprovalsDomainStep {

    public static final String RECORD_OWNER = 'Record Owner';
    public static final String CUSTOM = 'Custom';
    public static final String CPQ_MAT_NUMBER='CPQ_Material_Number';
    public static final String CPQ_MAT_GROUP_1='CPQ_Material_Group_1';
    public static final String CPQ_DISC= 'CPQ_Discount';
    public static final String BLANK='';
    

    // context data for this transaction mapped into useful collections
    protected Approvals.SupportData data;
    // name of the step, used for logging and sometimes business logic
    protected Approvals.StepName stepName;

    // each step in the pipeline builds these values over the course of the step
    protected Approvals.StepResults stepResults;
    // the output which is built over multiple steps
    // StepResults are merged into this variable at the end of the step
    protected Approvals.Outputs outputs;

    /* constructor */
    public ApprovalsQuoteLineStepBase(Approvals.StepName stepName, Approvals.SupportData data)
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
        if (stepName == Approvals.StepName.PROMOTION_1 || stepName == Approvals.StepName.PROMOTION_2 || stepName == Approvals.StepName.PROMOTION_3 || stepName == Approvals.StepName.PROMOTION_4 || stepName == Approvals.StepName.PROMOTION_5) {
            // promotion found value is cuumulative for all 5
            outputs.approvalsResults.isHierarchyFound.promotion = outputs.approvalsResults.isHierarchyFound.promotion || stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CPQ_MATERIAL_NUMBER) {
            outputs.approvalsResults.isHierarchyFound.materialNumber = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CPQ_MATERIAL_GROUP_1) {
            outputs.approvalsResults.isHierarchyFound.materialGroup = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CPQ_DISCOUNT) {
            outputs.approvalsResults.isHierarchyFound.discount = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CPQ_MATERIAL_NUMBER_CUSTOM) {
            outputs.approvalsResults.isHierarchyFound.customMaterialNumber = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CPQ_MATERIAL_GROUP_CUSTOM) {
            outputs.approvalsResults.isHierarchyFound.customMaterialGroup = stepResults.approvalFound;
        } else if (stepName == Approvals.StepName.CPQ_DISCOUNT_CUSTOM) {
            outputs.approvalsResults.isHierarchyFound.customDiscount = stepResults.approvalFound;
        }

        // copy hierarchy/level
        if (stepName == Approvals.StepName.CPQ_MATERIAL_NUMBER || stepName == Approvals.StepName.CPQ_MATERIAL_GROUP_1 || stepName == Approvals.StepName.CPQ_DISCOUNT) {
            outputs.approvalsResults.discount = stepResults.discount;
            outputs.approvalsResults.discountUC = stepResults.discountUC;
        } else if (stepName == Approvals.StepName.PROMOTION_1) {
            outputs.approvalsResults.promo1 = stepResults.discount;
        } else if (stepName == Approvals.StepName.PROMOTION_2) {
            outputs.approvalsResults.promo2 = stepResults.discount;
        } else if (stepName == Approvals.StepName.PROMOTION_3) {
            outputs.approvalsResults.promo3 = stepResults.discount;
        } else if (stepName == Approvals.StepName.PROMOTION_4) {
            outputs.approvalsResults.promo4 = stepResults.discount;
        } else if (stepName == Approvals.StepName.PROMOTION_5) {
            outputs.approvalsResults.promo5 = stepResults.discount;
        } else if (stepName == Approvals.StepName.CPQ_MATERIAL_NUMBER_CUSTOM) {
            outputs.approvalsResults.customMaterialNumber = stepResults.discount;
        } else if (stepName == Approvals.StepName.CPQ_MATERIAL_GROUP_CUSTOM) {
            outputs.approvalsResults.customMaterialGroup = stepResults.discount;
        } else if (stepName == Approvals.StepName.CPQ_DISCOUNT_CUSTOM) {
            outputs.approvalsResults.customDiscount = stepResults.discount;
        } 
    }

    /*  
    *   @description:
    *   after execution of a particular step, any errors found during execution are copied to output wrapper for stamping on record later
    */
    public void copyErrorInformation()
    {
        // copy error record association
        // no values for for custom approvals, china, grail, or promos
        // which won't hurt anything
        outputs.quotesWithMatrixError.addAll(stepResults.quotesWithMatrixError);

        for (Id quoteId : stepResults.erroredQuoteIdToAccount.keySet()) {
            outputs.erroredQuoteIdToAccount.put(quoteId, stepResults.erroredQuoteIdToAccount.get(quoteId));
        }

        for (Id quoteId : stepResults.erroredQuoteIdToOwnerIds.keySet()) {
            if (!outputs.erroredQuoteIdToOwnerIds.containsKey(quoteId)) { outputs.erroredQuoteIdToOwnerIds.put(quoteId, new Set<Id>()); }
            outputs.erroredQuoteIdToOwnerIds.get(quoteId).addAll(stepResults.erroredQuoteIdToOwnerIds.get(quoteId));
        }
    }

    /*  
    *   @description:
    *   called in every step execution
    *   determines the highest priority matrix based on input data and type of Approval
    */
    public Approvals.MatrixWrapper findHighestPriorityMatrix(SObject line, String strApprovalType, Boolean isTransborder, String hierarchyType)
    {
        Apttus_Proposal__Proposal_Line_Item__c quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)line;

        Apttus_Proposal__Proposal__c quote = data.idToQuote.get(quoteLine.Apttus_Proposal__Proposal__c);
        Decimal lineDiscountPercent = (quoteLine.Applied_Discount_Percentage__c == null ? 0 : quoteLine.Applied_Discount_Percentage__c);
        Decimal lineDiscountAmount = (quoteLine.Applied_Discount_Amount__c == null ? 0 : quoteLine.Applied_Discount_Amount__c);
        Decimal lineDiscountBeforeApproval = (quoteLine.Sales_Approval_Threshold__c == null ? 0 : quoteLine.Sales_Approval_Threshold__c);
        Id lineApprovalMatrixRecordOwner = quoteLine.Approval_Matrix_Record_Owner__c;
        Id lineApprovalMatrixCustom = quoteLine.Approval_Matrix_Custom__c;
        Id accountOwnerId = getAccountData(quote, isTransborder).ownerId;

        // create default result, look for best result in the loop
        Approvals.MatrixWrapper result = new Approvals.MatrixWrapper(accountOwnerId);

        List<Custom_Approval_Matrix__c> allCandidateMatrices = getAppropriateCustomApprovalMatrixRecords(this.stepName);

        // QUESTIONS: could allCandidateMatrices be empty?
        if (allCandidateMatrices.isEmpty() || lineDiscountPercent == 0)
        {
            return result;
        }
        // create a dummy best so far
        Approvals.CandidateMatrix bestSoFarMatrix = new Approvals.CandidateMatrix();
        if(!test.isRunningTest() && ((lineApprovalMatrixRecordOwner != null && hierarchyType == RECORD_OWNER ) || (lineApprovalMatrixCustom != null && hierarchyType == CUSTOM)))
        {
            Id customAppMatrix = idCustomApprovalMatrix(hierarchyType, lineApprovalMatrixRecordOwner,lineApprovalMatrixCustom );

            Custom_Approval_Matrix__c matrixRecord = data.approvalMatricesWrapper.idToMatrix.get(customAppMatrix);
            System.debug('strApprovalType '+strApprovalType);

            String camStepName;
            switch on this.stepName {
                when CPQ_MATERIAL_NUMBER {		
                    camStepName=CPQ_MAT_NUMBER;
                }            
                when CPQ_MATERIAL_GROUP_1 {
                    camStepName=CPQ_MAT_GROUP_1;
                }            
                when CPQ_DISCOUNT {		
                    camStepName=CPQ_DISC;
                }
                when CPQ_MATERIAL_NUMBER_CUSTOM {		
                    camStepName=CPQ_MAT_NUMBER;
                }
                when CPQ_MATERIAL_GROUP_CUSTOM {                
                    camStepName=CPQ_MAT_GROUP_1;
                }
                when CPQ_DISCOUNT_CUSTOM {		
                    camStepName=CPQ_DISC;
                }
                when else {
                    camStepName=BLANK;
                }
            }
            
                String matRecType = matrixRecord.RecordType.DeveloperName;
                System.debug('Hierarchy Type '+hierarchyType+' possible record type '+camStepName+' Selected RecordType  '+matRecType);
            if(camStepName == matRecType ){
                         result = buildMatrixWrapper(matrixRecord, lineDiscountAmount, lineDiscountPercent, result.ownerId,lineDiscountBeforeApproval,hierarchyType);
            }
        
        }
        
        else
        {
            // loop through the candidate matrices to find the actual best        
            for (Custom_Approval_Matrix__c matrixRecord : allCandidateMatrices)
            {
                Approvals.CandidateMatrix candidateMatrix = buildCandidateMatrix(matrixRecord, quoteLine, strApprovalType, isTransborder);
                 System.debug('CandidateMatrix for '+strApprovalType+' with Transborder scenario as '+ isTransborder + ' ::: '+JSON.serialize(candidateMatrix));
                System.debug('MatrixRecord    '+matrixRecord);
                // compare best so far with candidate, winner is (new) best so far
                bestSoFarMatrix = ApprovalsUtils.getPriorityResult(candidateMatrix, bestSoFarMatrix);
            
                // if an appropriate matrix was found, build the output based on it
                if (bestSoFarMatrix.isApprovalMatrixFound)
                {
                    system.debug('bestSoFarMatrix  '+bestSoFarMatrix);
                    result = buildMatrixWrapper(bestSoFarMatrix.record, lineDiscountAmount, lineDiscountPercent, result.ownerId,lineDiscountBeforeApproval,hierarchyType);
                }
            }
        }
        System.debug('Highest priority matrix returned for '+ strApprovalType +'type approval scenario ::: ' + JSON.serialize(result));
        return result;
    }

    // ID for Custom Approval Matrix
    private ID idCustomApprovalMatrix(String hierarchyType, ID lineApprovalMatrixRecordOwner, ID lineApprovalMatrixCustom){
        ID customAppMatrix;
            if(hierarchyType == RECORD_OWNER) customAppMatrix=lineApprovalMatrixRecordOwner;
            
            else if(hierarchyType == CUSTOM) customAppMatrix=lineApprovalMatrixCustom;
        
            return customAppMatrix;

    }
    private List<Custom_Approval_Matrix__c> getAppropriateCustomApprovalMatrixRecords(Approvals.StepName stepName)
    {
        List<Custom_Approval_Matrix__c> selectedMatrixRecords = null;
        switch on stepName {
            when CPQ_MATERIAL_NUMBER {		
                selectedMatrixRecords = data.approvalMatricesWrapper.materialNumberMatrices;
            }            
            when CPQ_MATERIAL_GROUP_1 {
                selectedMatrixRecords = data.approvalMatricesWrapper.materialGroupMatrices;
            }            
            when CPQ_DISCOUNT {		
                selectedMatrixRecords = data.approvalMatricesWrapper.discountMatrices;
            }
            when CPQ_MATERIAL_NUMBER_CUSTOM {		
                selectedMatrixRecords = data.approvalMatricesWrapper.customMaterialNumberMatrices;
            }
            when CPQ_MATERIAL_GROUP_CUSTOM {                
                selectedMatrixRecords = data.approvalMatricesWrapper.customMaterialGroupMatrices;
            }
            when CPQ_DISCOUNT_CUSTOM {		
                selectedMatrixRecords = data.approvalMatricesWrapper.customDiscountMatrices;
            }
            when else {
                selectedMatrixRecords = new List<Custom_Approval_Matrix__c>();
            }
        } 

        return selectedMatrixRecords;
    }

    // TODO: quote service method?
    private String calculateChannel(Apttus_Proposal__Proposal__c quote)
    {
        if (quote.Quote_Type__c != null && quote.Quote_Type__c.startsWith('Indirect')) {
            return System.Label.DistributionChannelIndirect;
        } else {
            return System.Label.DistributionChannelDirect;
        }
    }

    // @PureFunction
    @TestVisible
    private Approvals.MatrixWrapper buildMatrixWrapper(Custom_Approval_Matrix__c bestSoFarMatrix, Decimal lineDiscountAmount, Decimal lineDiscountPercent, Id ownerId, Decimal lineDiscountBeforeApproval, String hierarchyType)
    {
        Boolean isDiscountUnderLevel1 = getIsDiscountUnderLevel1(bestSoFarMatrix, lineDiscountAmount, lineDiscountPercent);

        Integer approvalLevel = getApprovalLevelFromMatrix(isDiscountUnderLevel1, bestSoFarMatrix, lineDiscountAmount, lineDiscountPercent, lineDiscountBeforeApproval,hierarchyType);

        return new Approvals.MatrixWrapper(bestSoFarMatrix, isDiscountUnderLevel1, approvalLevel, ownerId);
    }

    // @PureFunction
    @TestVisible
    private Boolean getIsDiscountUnderLevel1(Custom_Approval_Matrix__c matrixRecord, Decimal lineDiscountAmount, Decimal lineDiscountPercent)
    {
        List<String> lstAppHierarchyTypes = matrixRecord.Approval_Hierarchy_Type__c.split(';');

        Decimal matrixMinimumDiscount = lstAppHierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM) && matrixRecord.Min_Discount_Amount__c != null
            ? matrixRecord.Min_Discount_Amount__c : 0;
        Decimal matrixMinimumPercent = lstAppHierarchyTypes.contains(Approvals.HIERARCHY_CUSTOM) && matrixRecord.Min_Discount__c != null
            ? matrixRecord.Min_Discount__c : 0;

        return lineDiscountAmount <= matrixMinimumDiscount || lineDiscountPercent <= matrixMinimumPercent;
    }

    // @PureFunction
    @TestVisible
    private Integer getApprovalLevelFromMatrix(Boolean isDiscountUnderLevel1, Custom_Approval_Matrix__c matrixRecord, Decimal lineDiscountAmount, Decimal lineDiscountPercent, DecimaL lineDiscountBeforeApproval, String hierarchyType)
    {
        if (isDiscountUnderLevel1) { return null;}

        Integer approvalLevel = null;
        Integer approvalLevelBasedOnPercent = null;
        Integer approvalLevelBasedOnAmount = null;
        for (Integer loopLevel = 1; loopLevel <= Approvals.MAX_APPROVAL_LEVEL; loopLevel++)
        {
            Decimal matrixAmountForLevel = (Decimal)matrixRecord.get('Discount_Amount_Level_' + loopLevel + '__c');
            Decimal matrixPercentForLevel = (Decimal)matrixRecord.get('Discount_Level_' + loopLevel + '__c');
            if (matrixAmountForLevel != null && matrixPercentForLevel != null)
            { 
                if(hierarchyType == CUSTOM){
                    
                        approvalLevel=loopLevel;
                        system.debug('Approval Level count  '+approvalLevel);
                        // if line levels do not exceed loop level counter, we have found the appropriate approval level
                        if (lineDiscountAmount <= matrixAmountForLevel || lineDiscountPercent <= matrixPercentForLevel)
                        { break; }
                    

                }
                else if (hierarchyType == RECORD_OWNER ) {
                    Decimal discountDifference = lineDiscountPercent - lineDiscountBeforeApproval;
                    approvalLevel=loopLevel;
                    system.debug('Approval Level count  '+approvalLevel);
   
                    // if line levels do not exceed loop level counter, we have found the appropriate approval level
                    if (lineDiscountAmount <= matrixAmountForLevel || discountDifference <= matrixPercentForLevel)
                        { break; }
                }
            }
        }

        return approvalLevel;
    }

    //pure function

    private Approvals.CandidateMatrix buildCandidateMatrix(Custom_Approval_Matrix__c matrixRecord, Apttus_Proposal__Proposal_Line_Item__c quoteLine, String strApprovalType, Boolean isTransborder)
    {
        Integer candidatePriority = null;
        Datetime candidateLastModified = null;

        Id productId = (quoteLine.Apttus_QPConfig__OptionId__c == null) ? quoteLine.Apttus_Proposal__Product__c : quoteLine.Apttus_QPConfig__OptionId__c;        

        if (strApprovalType == Approvals.APPROVAL_TYPE_MATNUM && data.matrixIdToProductNumbers.containsKey(matrixRecord.Id))
        {
            List<String> lstProductNumbers = ApprovalsUtils.expandProductNumbers(data.matrixIdToProductNumbers.get(matrixRecord.Id));

            if (lstProductNumbers.contains(data.idToProduct.get(productId).Material_Number__c))
            {
                candidatePriority = getPriorityFromKey(quoteLine, matrixRecord, isTransborder);
                candidateLastModified = matrixRecord.LastModifiedDate;
            }
        }
        else if (strApprovalType == Approvals.APPROVAL_TYPE_MATGRP && data.approvalMatricesWrapper.idToMaterialGroups.containsKey(matrixRecord.Id))
        {
            List<String> lstProductGroups = ApprovalsUtils.expandProductNumbers(data.approvalMatricesWrapper.idToMaterialGroups.get(matrixRecord.Id));

            if (lstProductGroups.contains(data.idToProduct.get(productId).Material_Group_1_Code__c))
            {
                candidatePriority = getPriorityFromKey(quoteLine, matrixRecord, isTransborder);
                candidateLastModified = matrixRecord.LastModifiedDate;
            }
        }
        else if (strApprovalType == Approvals.APPROVAL_TYPE_DISCOUNT)
        {
            candidatePriority = getPriorityFromKey(quoteLine, matrixRecord, isTransborder);
            candidateLastModified = matrixRecord.LastModifiedDate;
        }

        return new Approvals.CandidateMatrix(false, matrixRecord, candidatePriority, candidateLastModified);
    }

    private Integer getPriorityFromKey(Apttus_Proposal__Proposal_Line_Item__c quoteLine, Custom_Approval_Matrix__c matrixRecord, Boolean isTransborder)
    {
        String conditionKey = generatePriorityKey(quoteLine, matrixRecord, isTransborder);
        Integer intPriority = null;
        if (data.approvalKeyToPriority.containsKey(conditionKey)) {
            intPriority = data.approvalKeyToPriority.get(conditionKey);
        }
        System.debug('Priority returned for this combination ::: '+intPriority);
        return intPriority;
    }

    // @PureFunction
    // generates a string key based on several boolean checks against the quote line and its related records
    // used as a key against records from Approval_Priority_Combination__mdt
    @TestVisible
    private String generatePriorityKey(Apttus_Proposal__Proposal_Line_Item__c quoteLine, Custom_Approval_Matrix__c matrixRecord, Boolean isTransborder)
    {
        Apttus_Proposal__Proposal__c quote = data.idToQuote.get(quoteLine.Apttus_Proposal__Proposal__c);
        String strDistributionChannel = calculateChannel(quote);
        String strRegion = matrixRecord.Region__c;
        String strDistChannel = matrixRecord.Distribution_Channel__c;
        String strSalesOrg = matrixRecord.Sales_Organization__c;
        String strCountry = matrixRecord.Country__c;
        String strCurrency = matrixRecord.Currency__c;

        System.debug('Matrix details : => ID | Region | Distribution Channel | Sales Org | Country | Currency'); // System.debug added instead of ilib_LogEvent.message as this method will get called for all lines and all relevant matrices
        System.debug(matrixRecord.Id + '_' + strDistributionChannel + '_' + strRegion + '_' + strDistChannel + '_'+ strSalesOrg + '_' +strCountry + '_' + strCurrency);

        Approvals.AccountData accountData = getAccountData(quote, isTransborder);

        Boolean boolSalesOrg = (String.isBlank(strSalesOrg) ? false : strSalesOrg.contains(quote.Sold_To_Sales_Organization__c)); // same as quote line sales org
        Boolean boolRegionCheck = (String.isBlank(strRegion) ? false : strRegion.contains(accountData.region));  
        
        Boolean boolCountryConditionCheck = String.isBlank(strCountry) ? false : strCountry.contains(accountData.country);
        Boolean boolDistributionChannelCheck = String.isBlank(strDistChannel) ? false : strDistChannel.contains(strDistributionChannel);
        Boolean boolCurrencyCheck = String.isBlank(strCurrency) ? false : strCurrency.contains(quoteLine.CurrencyIsoCode);

        Boolean boolSalesOrgBlank = String.isBlank(strSalesOrg);
        Boolean boolRegionBlank = String.isBlank(strRegion);
        Boolean boolDistChannelBlank = String.isBlank(strDistChannel);
        Boolean boolCountryBlank = String.isBlank(strCountry);
        Boolean boolCurrencyBlank = String.isBlank(strCurrency);

        String strCondition = 
            boolSalesOrg                            // matrix sales org matches quote/line sales org
            + '_' + boolRegionCheck                 // matrix region matches account region (account could be UC, distributor or sold to)
            + '_' + boolCountryConditionCheck       // matrix country matches account country (account could be UC, distributor or sold to)
            + '_' + boolDistributionChannelCheck    // matrix dist channel matches opportunity record type
            + '_' + boolCurrencyCheck               // matrix currency matches quote line
            + '_' + boolSalesOrgBlank               // matrix sales org is blank
            + '_' + boolRegionBlank                 // matrix region is blank
            + '_' + boolDistChannelBlank            // matrix dist channel is blank
            + '_' + boolCountryBlank                // matrix country is blank
            + '_' + boolCurrencyBlank;              // matrix currency is blank
        
        System.debug('condition generated for this matrix: '+strCondition);
        return strCondition;
    }

    // get the account country, region, and owner from a quote
    // use the Sold To, UC, or Distributor depending on the kind of quote
    // store an error if the region can't be determined
    // @PureFunction
    @TestVisible
    private Approvals.AccountData getAccountData(Apttus_Proposal__Proposal__c quote, Boolean isTransborder)
    {
        String strDistributionChannel = calculateChannel(quote);
        // if (Test.isRunningTest()) { strDistributionChannel = calculateChannelTestContext(quote); }

        Account mostImportantAccount;

        if (isTransborder)
        {
            if (strDistributionChannel == System.Label.DistributionChannelIndirect) {
                mostImportantAccount = quote.Distributor__r;
            } else {
                mostImportantAccount = quote.Ultimate_Consignee__r;
            }
        } else {
            if (strDistributionChannel == System.Label.DistributionChannelIndirect) {
                mostImportantAccount = quote.Ultimate_Consignee__r;
            } else {
                mostImportantAccount = quote.Apttus_Proposal__Account__r;
            }
        }

        if (String.isBlank(mostImportantAccount.Territory_Region__c)) {
            stepResults.erroredQuoteIdToAccount.put(quote.Id, mostImportantAccount.Name);
        }

        return new Approvals.AccountData(mostImportantAccount.Territory_Region__c, mostImportantAccount.BillingCountryCode, mostImportantAccount.OwnerId);
    }

}