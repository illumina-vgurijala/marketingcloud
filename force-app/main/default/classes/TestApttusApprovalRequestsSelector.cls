/*
    * @author      : Gerardo Garcia
    * @date        : 02-06-2024.
    * @description : This class provides coverage for class - ApttusApprovalRequestsSelector
*    ------------------------------------------
*    Developer Name                     Date                Description
*    Gerardo Garcia                     02-06-24            Initial commit CMCM-5761
*    ------------------------------------------------------------------------------------------------------------------
**/
@IsTest
private class TestApttusApprovalRequestsSelector {

    private static final String IN_REVIEW = 'In Review';
    private static final String NONE = 'None';
    private static final String PRICELIST_01_AMEA_USD = '01-AMEA-USD';
    private static final String HK01 = 'HK01';
    private static final String TEST_TXDR = 'Test TXDR';

    @TestSetup
    static void makeData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BIllingCountryCode='HK';

        insert new List<Account> { acc};

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea(HK01, '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = PRICELIST_01_AMEA_USD;
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';        
        acc1SalesArea.Sales_Organization__c = HK01;
        acc1SalesArea.Price_Group_Description__c = TEST_TXDR;
        acc1SalesArea.Distribution_Channel__c = '01';

        insert new List<Account_Sales_Area__c>{ acc1SalesArea };

        CLM_ProfileValidation__c profilevalidation = new CLM_ProfileValidation__c(
            SetupOwnerId=userinfo.getProfileId(),
            Channel_Partner_Agreement__c = true,
            Master_Customer_Agreement__c = true,
            Master_Service_Agreement__c = true,
            Negotiated_Terms_and_Conditions__c = true,
            Standing_Quote__c = true,
            Tender__c = true);
        insert profilevalidation;

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Pricebook2Id = standardPricebook.Id;
        opp.Price_List__c = '01-AMR-USD';
        insert opp;

        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Apttus_Proposal__Proposal__c oProposal = TestDataProposal.initProposal(acc.Id, opp.Id, 'Test Proposal', priceList.Id, true, IN_REVIEW, NONE);
        insert oProposal;

        Id recTypeMasterAgreement = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();

        Apttus__APTS_Agreement__c oAgreement = TestDataAgreement.initAgreements('Test Agreement - No Price Group', acc.id);
        oAgreement.RecordTypeId = recTypeMasterAgreement;
        oAgreement.Apttus__Contract_Start_Date__c = System.today();
        oAgreement.Apttus__Contract_End_Date__c = System.today() + 750;
        oAgreement.Sales_Org__c = HK01;
        insert new List<Apttus__APTS_Agreement__c> {oAgreement};

        Apttus_Approval__Approval_Request__c objAppReq = new Apttus_Approval__Approval_Request__c(
            Apttus_Approval__Related_Agreement__c = oAgreement.id,
            Apttus_QPApprov__ProposalId__c = oProposal.id,
            Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_USER,
            Apttus_Approval__Assigned_To_Id__c = UserInfo.getUserId(),
            Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_QUOTATION,
            Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved
        );
        insert objAppReq;
    }

    @IsTest
    private static void selectByQuoteId(){
        Apttus_Proposal__Proposal__c objProposal = [SELECT Id FROM Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector().selectByQuoteId(new Set<Id> {objProposal.id});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

    @IsTest
    private static void selectByAccounts(){
        Account account = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector().selectByAccounts(new Set<Id> {account.id});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

    @IsTest
    private static void selectByApprovalRequestId(){
        Apttus_Approval__Approval_Request__c requestApprovalSample = [SELECT Id FROM Apttus_Approval__Approval_Request__c LIMIT 1];

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector().selectByApprovalRequestId(new Set<Id> {requestApprovalSample.id});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

    @IsTest
    private static void selectByAgreementId(){
        Apttus__APTS_Agreement__c agreementSample = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector().selectByAgreementId(new Set<Id> {agreementSample.id});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

    @IsTest
    private static void selectAppReqByAgreementId(){
        Apttus__APTS_Agreement__c agreementSample = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        agreementSample.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        agreementSample.Approval_Request_Present__c = false;
        update agreementSample;

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector().selectAppReqByAgreementId(new Set<Id> {agreementSample.id});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

    
    @IsTest
    private static void getApprovalRequestByLoggedInUser(){
        Apttus__APTS_Agreement__c agreementSample = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        agreementSample.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        update agreementSample;

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector()
            .getApprovalRequestByLoggedInUser(ApttusApprovalRequests.OBJECT_TYPE_QUOTATION, 
            UserInfo.getUserId(), 
            new Set<String> {Label.AgreementApprovalStatusApproved});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

    
    @IsTest
    private static void selectByParentandUserId(){
        Apttus__APTS_Agreement__c agreementSample = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];

        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector().selectByParentandUserId(new Set<Id> {agreementSample.id}, new Set<Id> {UserInfo.getUserId()});
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }


    @IsTest
    private static void selectByParentandUserIdByUsersAndStatusAndApprovalStage(){

        Apttus__APTS_Agreement__c agreementSample = [SELECT Id FROM Apttus__APTS_Agreement__c LIMIT 1];
        agreementSample.Apttus_Approval__Approval_Status__c = Label.AgreementApprovalStatusApproved;
        update agreementSample;

        List<User> users = [SELECT id FROM User WHERE id = :UserInfo.getUserId()];
        Test.startTest();
        List<Apttus_Approval__Approval_Request__c> res = new ApttusApprovalRequestsSelector()
            .selectByParentandUserId(users, new List<String> {Label.AgreementApprovalStatusApproved}, IN_REVIEW);
        Test.stopTest();
        Assert.areEqual(1, res.size(), 'It should get 1 approval request!');
    }

}