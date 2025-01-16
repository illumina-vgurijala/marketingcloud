/**
*    @author Todd Newman
*    @date   2021-08-19
*    @description    DCP-48131: Test class for overall approvals flow
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-08-19           Initial Version
*         Satya Swain                 2021-10-27           CodeScan Fixes
*         Arif,Dalali                 28-Nov-2022          POL-57: Update APJ and EMEA References to AMEA and EUR respectively
*
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest private class TestApprovalsFramework {
    private static final String STRING_MESSAGE_PRIORITY_LOGIC = 'Priority combination logic did not work';

    @istest static void generatePriorityKey()
    {
        Account soldTo = new Account(
            Territory_Region__c = 'EUR', //POL-57
            BillingCountryCode = 'DK'
        );
        Account uc = new Account(
            Territory_Region__c = 'EUR', //POL-57
            BillingCountryCode = 'IT'
        );

        Opportunity opp1 = new Opportunity(
            RecordType = new RecordType(Name = 'Direct Standard')
        );
        Opportunity opp2 = new Opportunity(
            RecordType = new RecordType(Name = 'Indirect Standard')
        );

        Apttus_Proposal__Proposal__c quote1 = new Apttus_Proposal__Proposal__c(
            Apttus_Proposal__Account__r = soldTo,
            Ultimate_Consignee__r = soldTo,
            Apttus_Proposal__Opportunity__r = opp1,
            Sold_To_Sales_Organization__c = 'DK01'
        );
        Apttus_Proposal__Proposal__c quote2 = new Apttus_Proposal__Proposal__c(
            Apttus_Proposal__Account__r = soldTo,
            Ultimate_Consignee__r = uc,
            Apttus_Proposal__Opportunity__r = opp2,
            Sold_To_Sales_Organization__c = 'IT01'
        );

        Apttus_Proposal__Proposal_Line_Item__c quoteLine2 = new Apttus_Proposal__Proposal_Line_Item__c(
            CurrencyIsoCode = 'EUR'
        );

        Custom_Approval_Matrix__c matrixRecord2 = new Custom_Approval_Matrix__c(
            Region__c = 'EUR', //POL-57
            Distribution_Channel__c = 'Direct',
            Sales_Organization__c = 'IT01',
            Country__c = 'IT',
            Currency__c = 'EUR'
        );
        Custom_Approval_Matrix__c matrixRecord3 = new Custom_Approval_Matrix__c(
            Region__c = '',
            Distribution_Channel__c = '',
            Sales_Organization__c = '',
            Country__c = '',
            Currency__c = ''
        );

        Approvals.SupportData data = new Approvals.SupportData(
                                        new Map<Id, Apttus_Proposal__Proposal__c> {quote1.Id => quote1, quote2.Id => quote2},
                                        new Map<Id, Product2>(),
                                        new Map<Id, Apttus_Config2__Incentive__c>(),
                                        new Approvals.ApprovalMatricesWrapper(),
                                        new Map<Id, Approval_Hierarchy__c>(),
                                        new Map<Id, User>(),
                                        new Map<String, Integer>(),
                                        new Map<Id, Set<String>>()
                                    );

        ApprovalsQuoteLineStepBase approvalBase = new ApprovalsQuoteLineStepBase(Approvals.StepName.PROMOTION_1, data);

        Test.startTest();

        String res2 = approvalBase.generatePriorityKey(quoteLine2, matrixRecord2, false);
        String res3 = approvalBase.generatePriorityKey(quoteLine2, matrixRecord3, false);
        Test.stopTest();

        // 1: matrix sales org matches quote/line sales org
        // 2: matrix region matches account region (account could be UC, distributor or sold to)
        // 4: matrix dist channel matches opportunity record type
        // 5: matrix currency matches quote line
        System.assertEquals('true_true_false_true_true_false_false_false_false_false', res2,STRING_MESSAGE_PRIORITY_LOGIC);

        // 6: matrix sales org is blank
        // 7: matrix region is blank
        // 8: matrix dist channel is blank
        // 9: matrix country is blank
        // 10: matrix currency is blank
        System.assertEquals('false_false_false_false_false_true_true_true_true_true', res3,STRING_MESSAGE_PRIORITY_LOGIC);
    }

    @istest static void buildMatrixWrapper()
    {
        Custom_Approval_Matrix__c matrixRecord = new Custom_Approval_Matrix__c(
            Approval_Hierarchy_Type__c = 'Custom',
            Min_Discount_Amount__c = 300,
            Min_Discount__c = 10,
            Discount_Amount_Level_1__c = 500,
            Discount_Amount_Level_2__c = 600,
            Discount_Amount_Level_3__c = 700,
            Discount_Level_1__c = 10,
            Discount_Level_2__c = 12,
            Discount_Level_3__c = 14
        );

        ApprovalsQuoteLineStepBase psuedoStep = new ApprovalsQuoteLineStepBase(Approvals.StepName.CPQ_MATERIAL_NUMBER, null);

        Test.startTest();
        Approvals.MatrixWrapper res = psuedoStep.buildMatrixWrapper(matrixRecord, 450, 11, UserInfo.getUserId(),5,'Custom');
        Test.stopTest();

        System.assertEquals(1, res.approvalLevel, 'Approval level should be 1');
        System.assert(!res.isDiscountUnderLevel1,'Discount should not be under level 1');
        System.assertEquals(matrixRecord.Min_Discount_Amount__c, res.record.Min_Discount_Amount__c, 'Minimum discount Amount value did not match');
        System.assertEquals(UserInfo.getUserId(), res.ownerId, 'Owner Id did not match');
    }

    @istest static void getIsDiscountUnderLevel1()
    {
        Custom_Approval_Matrix__c matrixRecord = new Custom_Approval_Matrix__c(
            Approval_Hierarchy_Type__c = 'Custom',
            Min_Discount_Amount__c = 500,
            Min_Discount__c = 10
        );

        ApprovalsQuoteLineStepBase psuedoStep = new ApprovalsQuoteLineStepBase(Approvals.StepName.CPQ_MATERIAL_NUMBER, null);

        Test.startTest();
        Boolean res1 = psuedoStep.getIsDiscountUnderLevel1(matrixRecord, 100, 2);
        Boolean res2 = psuedoStep.getIsDiscountUnderLevel1(matrixRecord, 600, 9);
        Boolean res3 = psuedoStep.getIsDiscountUnderLevel1(matrixRecord, 400, 11);
        Boolean res4 = psuedoStep.getIsDiscountUnderLevel1(matrixRecord, 600, 11);
        Test.stopTest();

        System.assert(res1, '100/2 should have been < level 1');
        System.assert(res2, '600/9 should have been < level 1');
        System.assert(res3, '400/11 should have been < level 1');
        System.assert(!res4, '600/11 should not have been < level 1');
    }

    @istest static void getApprovalLevelFromMatrix()
    {
        Custom_Approval_Matrix__c matrixRecord = new Custom_Approval_Matrix__c(
            Approval_Hierarchy_Type__c = 'Custom',
            Min_Discount_Amount__c = 500,
            Min_Discount__c = 10,
            Discount_Amount_Level_1__c = 500,
            Discount_Amount_Level_2__c = 600,
            Discount_Amount_Level_3__c = 700,
            Discount_Level_1__c = 10,
            Discount_Level_2__c = 12,
            Discount_Level_3__c = 14
        );

        ApprovalsQuoteLineStepBase psuedoStep = new ApprovalsQuoteLineStepBase(Approvals.StepName.CPQ_MATERIAL_NUMBER, null);

        Test.startTest();
        Integer res1 = psuedoStep.getApprovalLevelFromMatrix(false, matrixRecord, 550, 11,3, 'Custom');
        Integer res2 = psuedoStep.getApprovalLevelFromMatrix(false, matrixRecord, 650, 13,4,'Custom');
        Integer res3 = psuedoStep.getApprovalLevelFromMatrix(false, matrixRecord, 550, 25,5,'Custom');
        Integer res4 = psuedoStep.getApprovalLevelFromMatrix(false, matrixRecord, 250, 11,1,'Custom');
        Test.stopTest();

        System.assertEquals(2,res1,'550/11 should have been level 2');
        System.assertEquals(3,res2,'650/13 should have been level 3');
        System.assertEquals(2,res3,'550/25 should have been level 2');
        System.assertEquals(1,res4,'250/1 should have been level 1');
    }

    @istest static void expandProductNumbers()
    {
        Set<String> combinedProductNumbers = new Set<String>{
            'ABC;XYZ',
            'QQQ'
        };


        Test.startTest();
        List<String> res = ApprovalsUtils.expandProductNumbers(combinedProductNumbers);
        Test.stopTest();

        System.assertEquals(3, res.size(), 'Number of Products generated did not match');
    }

    @istest static void getPriorityResult()
    {
        Approval_Hierarchy__c objHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');

        Id recTypeId = Schema.SObjectType.Custom_Approval_Matrix__c.getRecordTypeInfosByName().get('CPQ Discount').getRecordTypeId();
        Custom_Approval_Matrix__c matrix1 = new Custom_Approval_Matrix__c(
            Name = 'Matrix1',
            RecordTypeId = recTypeId,
            Region__c = null,
            Currency__c = null,
            Distribution_Channel__c = 'Direct',
            Approval_Hierarchy__r = objHeirarchy,
            Approval_Hierarchy_Type__c = 'Record Owner;Custom'
        );
        Custom_Approval_Matrix__c matrix2 = new Custom_Approval_Matrix__c(
            Name = 'Matrix2',
            RecordTypeId = recTypeId,
            Region__c = null,
            Currency__c = null,
            Distribution_Channel__c = 'Direct',
            Approval_Hierarchy__r = objHeirarchy,
            Approval_Hierarchy_Type__c = 'Record Owner;Custom'
        );

        Approvals.CandidateMatrix candidateMatrix = new Approvals.CandidateMatrix(false, matrix1, 1, Datetime.now() - 1);
        Approvals.CandidateMatrix bestSoFarMatrix = new Approvals.CandidateMatrix(false, matrix2, 2, Datetime.now() - 1);

        Test.startTest();
        Approvals.CandidateMatrix result = ApprovalsUtils.getPriorityResult(candidateMatrix, bestSoFarMatrix);
        Test.stopTest();

        System.assertEquals(candidateMatrix, result, 'candidate matrix did not match after priority result determination');
    }
}