/**
*    @author Indra Ganesan
*    @date  2018-05-25
*    @description  Test Class for Opportunity Selector
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Indra Ganesan                  2018-05-25         Initial Version
*    Aman Tyagi                     2022-12-12         CodeScan Fixes
*    Gerardo Garcia                 2024-06-05         CMCM-5579: fixes uat tests.
*    ------------------------------------------------------------------------------------                  
*/
@isTest
private class TestOpportunitySelector {

    /////////////////////////////////////////////////////////////////////
    // unit test methods
    /////////////////////////////////////////////////////////////////////

    @isTest
    private static void queryWithFeatureFlagOff()
    {
        // config environment to disable query logs
        Feature.setMockFeatureFlag('SalesQueryLogs', false);
        setThreshholdsToZero();

        // query using a single opp ID, returns one opp
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectOpportunities(getSimpleOppId()); //Added by KD
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        // test results returned and no query logging occurred
        System.assertEquals(1, opps.size());
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'OpportunitySelector.selectOpportunities';//Added by KD
        System.assertEquals(0, [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle]);
    }

    @isTest
    private static void queryWithFeatureFlagOn()
    {
        // config environment to enable query logs
        Feature.setMockFeatureFlag('SalesQueryLogs', true);
        setThreshholdsToZero();

        // query using a single opp ID, returns one opp
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectOpportunities(getSimpleOppId()); //Added by KD
        ilib_LogEvent.emit();
        Test.getEventBus().deliver();
        Test.stopTest();

        // query logging occurred
        String slowQueryTitle = ilib_LogEvent.SLOW_QUERY_LOG_TITLE_PREFIX + 'OpportunitySelector.selectOpportunities'; //Added by KD
        Integer numLogs = [SELECT count() FROM ILMN_Debug_Log__c WHERE Title__c LIKE :slowQueryTitle];
        Assert.isTrue(numLogs > 0, 'It should generate Logs!');
    }

    @isTest
    private static void selectOpportunities()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectOpportunities(getSimpleOppId());
        OpportunitySelector.clearOpportunityCache();
        Test.stopTest();

        // test results returned, check a field specified in this method
        System.assertEquals(1, opps.size());
        System.assertEquals(CURRENCY_CODE, opps.get(0).CurrencyIsoCode);
    }

    @isTest
    private static void selectConsortiumOpp()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);

        Consortium__c consortium = getConsortium();

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectConsortiumOpp(new Set<Id>{consortium.Id});
        Test.stopTest();

        // test results returned, just CONSORTIUM_OPP
        System.assertEquals(1, opps.size());
        System.assertEquals(consortium.Id, opps.get(0).Consortium__c);
    }

    @isTest
    private static void selectByAccountIds()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);

        Id soldToId = getSoldTo().Id;

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectByAccountIds(new Set<Id> {soldToId});
        Test.stopTest();

        // test results returned, all 5 have the same sold to
        System.assertEquals(5, opps.size());
        System.assertEquals(soldToId, opps.get(0).AccountId);
    }

    @isTest
    private static void selectByAccountOrUCIds()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);

        Id ucId = getUc().Id;

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectByAccountOrUCIds(new Set<Id> {ucId});
        Test.stopTest();

        // test results returned, only OPP_WITH_UC
        System.assertEquals(1, opps.size());
        System.assertEquals(ucId, opps.get(0).Ultimate_Consignee__c);
    }

    @isTest
    private static void selectRelatedOpenOpportunities()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);

        Id soldToId = getSoldTo().Id;

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectRelatedOpenOpportunities(new Set<Id> {soldToId});
        Test.stopTest();

        // test results returned
        // skipped will be OPP_WITH_UC (because query criteria checks UC, not Sold To) and CLOSED_OPP
        System.assertEquals(3, opps.size());
    }

    @isTest
    private static void selectRelatedClosedOpportunities()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);

        Id soldToId = getSoldTo().Id;

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectRelatedClosedOpportunities(new Set<Id> {soldToId});
        Test.stopTest();

        // test results returned, only CLOSED_OPP
        System.assertEquals(1, opps.size());
    }

    @isTest
    private static void selectOpportunitiesByAgreementIdsAccIdsClosedates()
    {
        // config environment to enable query logs for the coverage, feature tested elsewhere
        Feature.setMockFeatureFlag('SalesQueryLogs', true);
        List<Period> lstPeriod = [SELECT Id, StartDate, EndDate FROM Period WHERE Type = 'Quarter' AND EndDate >= :Date.today() ORDER BY EndDate];

        Id soldToId = getSoldTo().Id;
        Id agreementId = getAgreement().Id;

        // query
        Test.startTest();
        List<Opportunity> opps = new OpportunitySelector().selectOpportunitiesByAgreementIdsAccIdsClosedates(new Set<Id> {agreementId}, new Set<Id> {soldToId}, new Set<Date> {lstPeriod[0].EndDate}, new Set<Id>());
        Test.stopTest();

        // test results returned
        System.assertEquals(1, opps.size());
    }


    /////////////////////////////////////////////////////////////////////
    // environment and test data methods
    /////////////////////////////////////////////////////////////////////

    private static final String SOLD_TO_NAME = 'Sold To Account';
    private static final String UC_NAME = 'UC Account';
    private static final String SALES_ORG = 'BR01';
    private static final String CURRENCY_CODE = 'BRL';
    private static final String COUNTRY_CODE = 'BR';
    // price list type/name for BR01
    private static final String PRICELIST_NAME = '10-BRL-BRL';

    private static final String SIMPLE_OPP = 'simple';
    private static final String CONSORTIUM_OPP = 'cons';
    private static final String OPP_WITH_UC = 'with uc';
    private static final String CLOSED_OPP = 'closed';
    private static final String OPP_WITH_AGREEMENT = 'agreeement values';

    private static void setThreshholdsToZero()
    {
        PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
        settings.Slow_Query_Threshold__c = 0.0;
        settings.Slow_Transaction_Threshold__c = 0.0;
        settings.Disable_All_Log_Persistence__c = false;
        settings.Disable_Slow_Query_Publish__c = false;
        settings.Disable_Slow_Transaction_Publish__c = false;
        //CMSI-2 Pause_Publishes_Until__c moved to code params metadata

        ilib_LogSettings.unitTestSettingsRecord = settings;
    }
    /*
    *@author: Indra Ganesan
    *@Desc: Method for data setup
    */
    @testSetup
    public static void setupData()
    {
        TestDataAgreement.addHierarchyPermission();

        List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = new List<TestBundleCustomersStructure.CustomerDefinition> {
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_SOLD_TO, CURRENCY_CODE, COUNTRY_CODE),
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_ULTIMATE_CONSIGNEE, CURRENCY_CODE, COUNTRY_CODE)
        };
        
        List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs = new List<TestBundleCustomersStructure.SalesAreaDefinition> {
            new TestBundleCustomersStructure.SalesAreaDefinition(SALES_ORG, '01', '00')
        };

        List<TestBundleCustomersStructure.ExtraRelationshipDefinition> extraRels = new List<TestBundleCustomersStructure.ExtraRelationshipDefinition> {
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {SALES_ORG}, Accounts.GROUP_ULTIMATE_CONSIGNEE, false)
        };

        TestBundleCustomers bundleMaker = new TestBundleCustomers(customerDefinitions, salesAreaDefs, extraRels);
        Map<String, List<SObject>> customerBundle = bundleMaker.getBundle();

        // set names for easy finding
        Account soldTo = (Account)customerBundle.get('Account').get(0);
        Account uc = (Account)customerBundle.get('Account').get(1);
        soldTo.put('Name', SOLD_TO_NAME);
        uc.put('Name', UC_NAME);

        bundleMaker.insertBundle(customerBundle);

        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST_NAME);
        insert objPriceList;

        Consortium__c consortium = TestDataConsortium.getNewConsortium();
        TestDataConsortium.getNewConsortiumAccount(soldTo.Id, consortium.Id);

        Apttus__APTS_Agreement__c agreement = TestDataAgreement.initAgreements('Test Agreement', soldTo.Id);
        agreement.Justification_for_No_Agreement_Value__c = 'Comparison Customer';
        agreement.Freight_Charge__c = 'Standard';
        insert agreement;
        List<Period> lstPeriod = [SELECT Id, StartDate, EndDate FROM Period WHERE Type = 'Quarter' AND EndDate >= :Date.today() ORDER BY EndDate];

        //by opp id
        Opportunity simpleOpp = TestDataOpportunity.initOpportunity(soldTo);
        simpleOpp.Name = SIMPLE_OPP;
        simpleOpp.Price_List__c = PRICELIST_NAME;
        // by consortium id
        Opportunity consortiumOpp = TestDataOpportunity.initOpportunity(soldTo);
        consortiumOpp.Name = CONSORTIUM_OPP;
        consortiumOpp.Price_List__c = PRICELIST_NAME;
        consortiumOpp.Consortium__c = consortium.Id;
        // by sold to id
        // by sold to/UC id
        Opportunity oppWithUc = TestDataOpportunity.initOpportunity(soldTo);
        oppWithUc.Name = OPP_WITH_UC;
        oppWithUc.Price_List__c = PRICELIST_NAME;
        oppWithUc.Ultimate_Consignee__c = uc.Id;
        // by sold to and open
        // by sold to and closed
        Opportunity closedOpp = TestDataOpportunity.initOpportunity(soldTo);
        closedOpp.Name = CLOSED_OPP;
        closedOpp.Price_List__c = PRICELIST_NAME;
        closedOpp.StageName = Opportunities.STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED;
        // by sold to with agreement and close_date
        Opportunity oppWithAgreement = TestDataOpportunity.initOpportunity(soldTo);
        oppWithAgreement.Name = OPP_WITH_AGREEMENT;
        oppWithAgreement.Price_List__c = PRICELIST_NAME;
        oppWithAgreement.Related_Agreement__c = agreement.Id;
        oppWithAgreement.Last_Date_of_Quarter__c = lstPeriod.get(0).EndDate;

        insert new List<Opportunity> {simpleOpp, consortiumOpp, oppWithUc, closedOpp, oppWithAgreement};
    }

    private static List<Account> allAccounts;
    private static List<Account> getAccounts()
    {
        if (allAccounts == null)
        {
            allAccounts = [SELECT Id, Name, ERP_Customer_Id__c FROM Account];
        }

        return allAccounts;
    }

    private static Account getAccountByName(String n)
    {
        for (Account rec : getAccounts())
        {
            if (rec.Name == n) return rec;
        }

        return null;
    }

    private static Account getSoldTo()
    {
        return getAccountByName(SOLD_TO_NAME);
    }

    private static Account getUC()
    {
        return getAccountByName(UC_NAME);
    }

    private static Set<Id> getSimpleOppId()
    {
        return UtilsCollection.getSetOfIds([SELECT Id FROM Opportunity WHERE Name = :SIMPLE_OPP]);
    }

    private static Consortium__c getConsortium()
    {
        return [SELECT Id FROM Consortium__c];
    }

    private static Apttus__APTS_Agreement__c getAgreement()
    {
        return [SELECT Id FROM Apttus__APTS_Agreement__c];
    }

}