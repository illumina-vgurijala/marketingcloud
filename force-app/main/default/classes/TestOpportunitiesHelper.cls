/**
*    @author Gerardo Garcia
*    @date   12/20/23
*    @description    OpportunitiesHelper tests
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Claudiu Avram                2023-20-06            Initial Commit
*             Gerardo Garcia               2024-02-02            CMCM-4368 Refactor Tests
**/
@IsTest
private class TestOpportunitiesHelper {

    private static final String TERRITORY_NAME = 'Territory Account';
    private static final String DISTRIBUTOR_PARTNER = 'Distribuitor Account';
    private static final String OPP_NAME = 'opp';
    private static final String ULTIMATE_CONSIGNEE = 'Ultimate Consignee';

    @TestSetup
    private static void makeData(){
        Account acc = TestDataAccount.getAccount(TERRITORY_NAME);
        acc.Territory_Region__c = 'China';
        acc.ERP_Customer_Id__c = '123456';
        acc.OwnerId = UserInfo.getUserId();

        Account accDistributor = TestDataAccount.getAccount(DISTRIBUTOR_PARTNER);
        accDistributor.Account_Group__c = 'Distributor';

        Account accUltimateConsignee = TestDataAccount.getAccount(ULTIMATE_CONSIGNEE);
        accUltimateConsignee.Account_Group__c = 'Ultimate Consignee';
        accUltimateConsignee.RecordTypeId = TestDataAccount.getCustomerTypeId();
        accUltimateConsignee.Clinical_Type__c = 'Clinical';
        accUltimateConsignee.Market_Segment__c = null;

        insert new List<Account> {acc, accDistributor, accUltimateConsignee};

        Opportunity newOppWOUC = TestDataOpportunity.initOpportunity(acc);
        newOppWOUC.Name = 'Opp Without UC';
        newOppWOUC.Ultimate_Consignee__c = null;
        insert newOppWOUC;
    }

    private static Account getAccount(String name) {
        return [SELECT id, Territory_Region__c, ERP_Customer_Id__c, Owner.Id FROM Account WHERE Name = :name LIMIT 1];
    }

    private static Opportunity getOpportunity() {
        return [SELECT id, Transborder_Flag__c, Ultimate_Consignee__r.Owner.id, Distributor__r.Owner.id, Account.Owner.id, RecordType.DeveloperName FROM Opportunity WHERE Name = :OPP_NAME LIMIT 1];
    }

    /**
    *    @author Claudiu Avram
    *    @date   2023-20-06
    *    @description Testing OpportunitiesHelper.getAccountHierarchy    
    */
    @isTest
    static void getAccountHierarchyCorrectly()
    {
        Test.startTest();
        Approval_Hierarchy__c ah = new Approval_Hierarchy__c();
        ah.Approver_Level_1__c = UserInfo.getUserId();
        ah.Approval_Hierarchy_Type__c = Label.CPQ_Sales_Hierarchy;
        insert ah;
        
        Id appOwnerId = OpportunitiesHelper.getAccountHierarchy(UserInfo.getUserId());
        
        Test.stopTest();
        Assert.areEqual(ah.Id, appOwnerId,'Account owner not correctly selected!');
    }

    /**
    *    @author Claudiu Avram
    *    @date   2023-20-06
    *    @description Testing OpportunitiesHelper.getAccountIdBasedOnProposal first case    
    */    
    @isTest
    static void getAccountOwnerIdTransborderIndirect()
    {
        Account acc = getAccount(TERRITORY_NAME);
        Account dist = getAccount(DISTRIBUTOR_PARTNER);

        Opportunity opp = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTIndirectStandard);
        opp.Name = 'opp';
        opp.Transborder_Flag__c = true;
        opp.Distributor__c = dist.id;
        insert opp;

        Test.startTest();
        Id accountOwnerId = OpportunitiesHelper.getAccountOwnerId(getOpportunity(), new Apttus_Proposal__Proposal__c());
        Test.stopTest();

        Assert.areEqual(acc.Owner.Id, accountOwnerId, 'Account owner not correctly selected!');
    }

    /**
    *    @author Claudiu Avram
    *    @date   2023-20-06
    *    @description Testing OpportunitiesHelper.getAccountIdBasedOnProposal second case    
    */    
    @isTest
    static void getAccountOwnerIdTransborderDirect()
    {
        Account acc = getAccount(TERRITORY_NAME);

        Opportunity opp = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp.Name = 'opp';
        opp.Transborder_Flag__c = true;
        opp.Ultimate_Consignee__c = acc.id; 
        insert opp;

        Test.startTest();
        Id accountOwnerId = OpportunitiesHelper.getAccountOwnerId(getOpportunity(), new Apttus_Proposal__Proposal__c());
        Test.stopTest();

        Assert.areEqual(acc.Owner.Id, accountOwnerId, 'Account owner not correctly selected!');
    }

    /**
    *    @author Claudiu Avram
    *    @date   2023-20-06
    *    @description Testing OpportunitiesHelper.getAccountIdBasedOnProposal third case    
    */    
    @isTest
    static void getAccountOwnerIdInternalIndirect()
    {
        Account acc = getAccount(TERRITORY_NAME);

        Opportunity opp = TestDataOpportunity.initOpportunity(acc, Label.IndirectReOrder);
        opp.Name = 'opp';
        opp.Transborder_Flag__c = false;
        opp.Ultimate_Consignee__c = acc.id; 
        insert opp;

        Test.startTest();
        Id accountOwnerId = OpportunitiesHelper.getAccountOwnerId(getOpportunity(), new Apttus_Proposal__Proposal__c());
        Test.stopTest();  
        Assert.areEqual(acc.Owner.Id, accountOwnerId, 'Account owner not correctly selected!');
    }

    /**
    *    @author Claudiu Avram
    *    @date   2023-20-06
    *    @description Testing OpportunitiesHelper.getAccountIdBasedOnProposal fourth case    
    */    
    @isTest
    static void getAccountOwnerIdInternalDirect()
    {
        Account acc = getAccount(TERRITORY_NAME);

        Opportunity opp = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp.Name = 'opp';
        opp.Transborder_Flag__c = false;
        opp.Account = acc; 
        insert opp;

        Test.startTest();
        Id accountOwnerId = OpportunitiesHelper.getAccountOwnerId(getOpportunity(), new Apttus_Proposal__Proposal__c());
        Test.stopTest();
        Assert.areEqual(acc.Owner.Id, accountOwnerId, 'Account owner not correctly selected!');
    }

    /*Method to cover - OpportunitiesHelper Class - DCP-45454*/
    @isTest
    static void checkOpportunitiesHelper()
    {
        Account ultimateConsignee = getAccount(ULTIMATE_CONSIGNEE);
        Opportunity opp = [SELECT Id, Name, recordTypeId, Ultimate_Consignee__c, AccountId, Clinical_Type__c, Market_Segment__c FROM Opportunity WHERE Name = 'Opp Without UC'];
        Test.startTest();
        opp.Ultimate_Consignee__c = ultimateConsignee.Id;
        opp.Clinical_Type__c = '';
        opp.Market_Segment__c = '';
        OpportunitiesHelper.updateOpportunityFromUltimateConsignee(new list<Opportunity> {opp});
        Test.stopTest();
        Assert.isTrue(String.isNotBlank(opp.Clinical_Type__c));
    }
}