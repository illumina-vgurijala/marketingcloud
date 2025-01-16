/**
*    @author Saurabh Brahmankar
*    @date   2023-10-18
*    @description    Opportunities.cls tests.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                21 May 2018            Opportunities test class
*             Govind Dubey                31 May 2018            Added Negative test case scenario for DCP-2988
*             Akash Kumar                 04 Jul 2018            Added method for comparing Other Segment and Primary 
*                                                                Segment comparison
*             Akash Kumar                 05 Jul 2018            Added positive scenario for update trigger for DCP-2138
*             Akash Kumar                 05 Jul 2018            Added negative scenario for insert trigger for DCP-2138
*             Akash Kumar                 05 Jul 2018            Added positive scenario for insert trigger for DCP-2138
*             Roopal Verma                01 Aug 2018            Added positive and negative scenario for insert trigger for DCP-4498
*             Rahul Sharma                07 Aug 2018            Added method for insert and update for direct pricelist DCP-8330
*             Roopal Verma                26 Sep 2018            Renamed Post pricing message on quotation to Post_Pricing_Message_List__c
*             Rahul Sharma                07 Oct 2018            Added method for insert and update for indirect pricelist DCP-12478 
*             Rahul Sharma                24 Oct 2018            Added method for insert and update for Sales Org Override DCP-14235
*             Satya Swain                 26-Oct-2018            Adding checkPopulateCompanyCodeAddress for DCP-11696
*             Vishnu Priya Duggineni      02-Oct-2018            Added methos for before insert check for Account Territory valdiation for DCP 8615
*             Rahul Sharma                06 Dec 2018            Changes for DCP-12852 and added lines to Reduce Queries
*             Satya Swain                 10-Sep-2019            Adding clearOpportunityCache for INC0225110
*             Joshith K                   28-Nov-2019            updated Assert statement as per INC0235038
*             Rahul Bishnoi               05-Dec-2019            DCP-30367: cover RenewOppQueueable
*             Satya Swain                 26-Sep-2019            DCP-30062: SonarQube Fixes
//SonarQube Issue Fix 10/12/2019
*             Rishab                      25-Mar-2021            DCP-45454 Opp Improvements
*             KD                          16-June-2021           DCP-46224: Set Relocation Type field
*             Ashwin Kumar                31-Mar-2022            DCP-52339 Remove TestTAPS.setupDeferredObjectData
*             Nishan                      10-Oct-2022            CodeScanFix [Method name should not start with Capital].
*             Adyasha Satapathy           28-Nov-2022            POL-54: Update region references to AMEA and EUR
*             Adithi Acharya              10-Jan-2023            CodescanFix [Avoid assignments in operands]
*             Satya Swain                 09 Dec 2022            Added Codescan fix for Variable Naming Convention
*             Prem Ranjan                 21-Feb-2023            Codescan fix (APEX) Unit Test Method should include System.Assert
*             Deep Diwakar                July-11-2023           DCP-60098: Updated test waterfall method for new changes
*			  Saurabh Brahmankar		  18-Oct-2023			 Update the TestOpportunity class from improvements
*             Gerardo Garcia              02-Jan-2024            CMCM-4368 Refactor Tests
*             Arquimidez Mora             20-Aug-2024            Set Forecast Category and Opportunity Forecast to "Closed" for closed Opportunities  
*            Sai Pasumarthy               Dec-04-2024            CMCM-11292 TI- Opportunity: Update Backwards Movement in Pipeline
*    ----------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestOpportunity {

    private static final String STRING_FINALIZE = 'finalize';
    private static final String TEST1 = 'Test 1';
    private static final String DISTRIBUTOR_PARTNER = 'Distributor Partner';
    private static final String DISTRIBUTOR_AGGREGATOR = 'DistributorAggregatorAccount';
    private static final String DISTRIBUTOR_AFFILIATE = 'DistributorAffiliateAccount';
    private static final String COMPLIANCE_OPP = 'ComplianceTest';
    private static final String SALES_OPP = 'Sales Opp';
    private static final String SERVICE_OPP = 'Service Opp';
    private static final String OP_NAME = 'Opp to be tested';
    private static final String DEAL_REJECT_OPP = 'Deal Reject Opp';
    private static final String STRING_OPPORTUNITY_ABANDON_REASON = 'Deal Registration Rejected'; // CMCM-11235
    private static final String STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED = 'Closed Abandoned'; // CMCM-11235
    private static final User AUTOMATED_USER = TestDataUser.getAutomatedUser();
    private static final User SYS_ADMIN = TestDataUser.findUserInProfile('System Administrator');

    @testSetup
    static void initializeTestData()
    {
        Map<String, Account > accounts = setupAccounts();
        Account acc = accounts.get(TEST1);
        Account accDistributorPartner = accounts.get(DISTRIBUTOR_PARTNER);
        Account accDistributorAffiliate = accounts.get(DISTRIBUTOR_AFFILIATE);

        Partner_Association__c objAssociatedDistributor = new Partner_Association__c(Associated_Channel_Partner__c = accDistributorAffiliate.Id, 
            Parent_Channel_Partner__c = accDistributorPartner.Id);
        insert objAssociatedDistributor;

        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());

        Contact con1 = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        Contact con3 = TestDataPerson.initContact(accDistributorPartner.Id);
        insert new List<Contact> { con1, con2, con3 };

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Name = SALES_OPP;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        Opportunity opp3 = TestDataOpportunity.initOpportunity(acc, Opportunities.RT_STANDARD_INDIRECT);
        Opportunity sOpp = TestDataOpportunity.initOpportunity(acc);
        sOpp.Name = SERVICE_OPP;
        sOpp.Primary_Contact__c = con1.Id;

        insert new List<Opportunity>{ opp, opp2, sOpp, opp3};

        OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, opp.Id);
        OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, opp.Id);
        OpportunityContactRole ocr3 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, opp2.Id);
        OpportunityContactRole ocr4 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con2.Id, opp2.Id);
        OpportunityContactRole ocr5 = TestDataOpportunity.getNewOpportunityPrimaryContactRole('Power Sponsor', con2.Id, opp2.Id, true);
        insert new List<OpportunityContactRole> { ocr1, ocr2, ocr3, ocr4, ocr5 };

        SVMXC__Service_Group__c serviceTeam = TestDataFieldService.createServiceTeam ('Test', 'country');
        insert serviceTeam;

        User fieldServiceUser = [SELECT Id
            FROM User 
            WHERE Profile.Name =: System.label.Field_Service
            LIMIT 1];
        SVMXC__Service_Group_Members__c technicianFAS = TestDataFieldService.createTechnician(fieldServiceUser.Id, 'Test Technician', serviceTeam.Id);
        technicianFAS.SVMXC__Email__c='b@b.com';
        insert technicianFAS;

        TestDataOpportunity.getStandardPriceBook();

        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());    
    }

    private static Map<String, Account> setupAccounts() {
        String indirectPartnerRecordTypeId = TestDataAccount.getIndirectPartnerTypeId();

        Account acc = TestDataAccount.getAccount(TEST1);
        acc.RecordTypeId = indirectPartnerRecordTypeId;
        acc.BillingCountryCode = 'US';
        acc.BillingStateCode = 'AK';
        acc.ERP_Customer_Id__c = '123456';

        Account accDistributor = TestDataAccount.getAccount(DISTRIBUTOR_PARTNER);
        accDistributor.Account_Group__c = 'Distributor';
        accDistributor.RecordTypeId = indirectPartnerRecordTypeId;
        accDistributor.BillingCountryCode = 'US';
        accDistributor.BillingStateCode = 'AK';
        accDistributor.ERP_Customer_Id__c = '567890';

        Account accDistAffiliate = TestDataAccount.getAccount(DISTRIBUTOR_AFFILIATE);
        accDistAffiliate.Account_Group__c = 'Distributor';
        accDistAffiliate.Channel_Partner_Type__c = 'Affiliate';
        accDistAffiliate.RecordTypeId = indirectPartnerRecordTypeId;
        accDistAffiliate.BillingCountryCode = 'CA';
        accDistAffiliate.BillingStateCode ='AB';
        accDistAffiliate.ERP_Customer_Id__c = '654321';

        Account accDistAggregator = TestDataAccount.getAccount(DISTRIBUTOR_AGGREGATOR);
        accDistAggregator.Account_Group__c = 'Distributor';
        accDistAggregator.Channel_Partner_Type__c = 'Aggregator';
        accDistAggregator.BillingCountryCode = 'CA';
        accDistAggregator.BillingStateCode ='AB';
        accDistAggregator.ERP_Customer_Id__c = '987650';

        List<Account> accounts = new List<Account>{acc
            ,accDistributor
            ,accDistAffiliate
            ,accDistAggregator
        };
        insert accounts;

        return (Map<String, Account>) UtilsCollection.getMapOfStringToSObject(accounts, 'Name', Map<String, Account>.class);
    }

    private static Account getAccountByName(String name) {
        return getAccountsByName(new List<String> {name}).get(name);
    }

    private static Map<String, Account> getAccountsByName(List<String> names) {
        return (Map<String, Account>) UtilsCollection.getMapOfStringToSObject([SELECT 
            ID, Name, BillingCountryCode, BillingStateCode, Territory_Region__c, Account_Group__c, ERP_Customer_Id__c, OwnerId
            FROM Account WHERE Name IN :names], 'Name', Map<String, Account>.class);
    }

    private static Opportunity getOppComplianceSetupData() {
        Account acc = getAccountByName(TEST1);

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
        opp.Name = COMPLIANCE_OPP;
        return opp;
    }

    private static Opportunity getOpportunity(String name) {
        Opportunity opp = [SELECT Id,Compliance_Last_Modified_Date__c,StageName, Amount_USD__c,Rev_Rec_Terms__c,Product_Type__c,LastModifiedDate,CloseDate,Non_Compliance_Reason__c FROM Opportunity WHERE Name = :name LIMIT 1];
        return opp;
    }

    /**
    *    @author Govind Dubey
    *    @date   2018-05-21
    *    @description    Testing Is contact role identified scenario when Opportunity has OpportunityContactRole.
    */
    @isTest
    static void opportunityWithMultipleContactRoles()
    {
        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE Name NOT IN (:SERVICE_OPP, 'Indirect Standard Opty Test')];
        for (Opportunity opp : oppList)
        {
            opp.StageName = 'Qualify';
        }

        Test.startTest();
        update oppList;
        Test.stopTest();

        oppList = [SELECT id,Is_Contact_Role_Identified__c FROM Opportunity WHERE Id IN: oppList];
        System.debug(JSON.serializePretty(oppList));
        Assert.isTrue(oppList.get(0).Is_Contact_Role_Identified__c, 'Contact Role is not identified for first opportunity..');
        Assert.isTrue(oppList.get(1).Is_Contact_Role_Identified__c, 'Contact Role is not identified for second opportunity..');
    }

    /**
    *    @author Govind Dubey
    *    @date   2018-05-21
    *    @description    Testing Is contact role not identified scenario when Opportunity has no OpportunityConatctRole.
    */    
    @isTest
    static void opportunityWithoutContactRoles()
    {
        String strErrorMessage;
        List<Opportunity> oppList = [SELECT Id, StageName FROM Opportunity WHERE Name NOT IN (:SERVICE_OPP, 'Indirect Standard Opty Test')];
        System.debug('oppList: ' + oppList);

        User objUser = TestDataUser.findUserInProfile('Sales User');
        System.debug('objUser: ' + objUser);

        for (Opportunity opp : oppList) {
            opp.OwnerId = objUser.Id;
        }
        update oppList;

        List<OpportunityContactRole> ocrList = [SELECT Id FROM OpportunityContactRole WHERE OpportunityId IN :oppList];
        try {
            delete ocrList;
        } catch(Exception e) {
            System.debug('@@@Catch'+e.getMessage());
            strErrorMessage = e.getMessage();
        }

        Opportunities.lstOpportunityContactRole = null;

        for (Opportunity opp : oppList) {
            opp.StageName = 'Qualify';
        }

        Test.startTest();
        System.runAs(objUser){
            try {
                update oppList;
            } catch(Exception e) {
                System.debug('@@@Catch'+e.getMessage());
                strErrorMessage = e.getMessage();
            }
        }
        Test.stopTest();
        
        System.debug('@@@@opportunityWithoutContactRoles error '+ strErrorMessage);
        Assert.isTrue(String.isNotBlank(strErrorMessage) 
            && strErrorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),
        'Validation rule is not fired as expected.');
    }

    /**
    *    @author Govind Dubey
    *    @date   22 Oct 2018
    *    @description Testing populateDistributorAccount while inserting Opportunity.
    */
    
    @isTest
    static void testpopulateDistributorAccount(){

        Account distAffiliate = [SELECT Id FROM Account WHERE NAME = :DISTRIBUTOR_AFFILIATE LIMIT 1]; 
        Account distAggregator = [SELECT ID, Name, Account_Group__c, Channel_Partner_Type__c FROM Account WHERE Name = :DISTRIBUTOR_AGGREGATOR LIMIT 1];
        Account distPartner = [SELECT Id FROM Account WHERE Name = :DISTRIBUTOR_PARTNER LIMIT 1];

        String indirectStandardOppName = 'Indirect Standard Opty Test';
        Opportunity indirectStandardOpp = TestDataOpportunity.initOpportunity(distAffiliate, 'Create', Date.today() + 30,10000,
            'Indirect_Standard', 10, 'Clinical', 'Description Test', 'Applied Lab', 'Forensics', 'Services', 'Standard Sale', '$10,000 - $25,000', 
            'Internal Budget: In Process', 'Poor Data Quality', '0-3 Months', false);
        indirectStandardOpp.Name = indirectStandardOppName;

        String indirectStandardOppAggregatorName = 'Indirect Standard Opty';
        Opportunity indirectStandardOppAggregator = TestDataOpportunity.initOpportunity(distAggregator, 'Create',Date.today() + 30,10000, 
            'Indirect_Standard', 10, 'Clinical', 'Description Test', 'Applied Lab', 'Forensics', 'Services', 'Standard Sale', 
            '$10,000 - $25,000', 'Internal Budget: In Process', 'Poor Data Quality', '0-3 Months', false);
        indirectStandardOppAggregator.Name = indirectStandardOppAggregatorName;

        Test.startTest();
        
        insert indirectStandardOpp;

        indirectStandardOpp = [SELECT Id, StageName,Distributor__c FROM Opportunity WHERE Name = :indirectStandardOppName LIMIT 1];
        Assert.areEqual(distPartner.Id, indirectStandardOpp.Distributor__c, 'Different Distributor is populated for Affiliate Sold To (Distributor).');
        indirectStandardOpp.Distributor__c = null;

        String strErrorMessage ;
        try {
            update indirectStandardOpp;
        } catch(Exception e) {
            System.debug('@@@Catch'+ e.getMessage());
            strErrorMessage = e.getMessage();
        }

        insert indirectStandardOppAggregator;

        Test.stopTest();
        Assert.isTrue(String.isBlank(strErrorMessage));

        Opportunity updatedIndirectOpty = [SELECT Id, StageName,Distributor__c FROM Opportunity WHERE Name = 'Indirect Standard Opty'];
        Assert.areEqual(distAggregator.Id, updatedIndirectOpty.Distributor__c, 'Different Distributor is populated for Aggregator Sold To (Distributor).');
    }
    
     /**
    *    @author Roopal Verma
    *    @date   2018-08-01
    *    @description Testing insert scenario for opportunity where opportunity is not an active member of related consortium account.
    */
    
    @isTest
    static void opportunityInsertWithInactiveConsortiumAccount()
    {
        Consortium__c con = TestDataConsortium.initConsortium('Closed');
        insert con;
        System.debug('---con.id---'+con.id);

        Account acc1 = getAccountByName(TEST1);
        Account acc2 = getAccountByName(DISTRIBUTOR_PARTNER);

        Consortium_Account__c conAcc1 = TestDataConsortiumAccount.initConsortiumAccount(con,acc1,true);
        insert conAcc1;
        Consortium_Account__c conAcc2 = TestDataConsortiumAccount.initConsortiumAccount(con,acc2,false);
        insert conAcc2;
        System.debug('---conAcc2.Consortia__c---'+conAcc2.Consortia__c);

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1);
        opp1.Consortium__c = con.Id;
        opp1.Type = 'Consortium';

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc2);
        opp2.Consortium__c = con.Id;
        opp2.Type = 'Consortium';
        opp2.Product_Interest__c = 'Consumables';

        Test.startTest();
        String strErrorMessage;
        try {
            insert opp1;
        } catch(Exception e) {
            System.debug('--Error--'+ e.getMessage());
            strErrorMessage = e.getMessage();
        }

        insert opp2;
        Test.stopTest();
        
        Assert.isTrue(strErrorMessage.contains('Sold-To Account is not an active member of this Closed Consortium'));
        Assert.areEqual(con.id, opp2.Consortium__c, 'Consortium__c value is incorrect');
    }

    /**
    *    @author Indra Ganesan
    *    @date   2018-08-03
    *    @description  Test Opportunity with Primary Contact Role.
    */
    @isTest
    static void opportunityWithPrimaryContactRoles()
    {
        List<Opportunity> lstOpp = [SELECT Id, StageName FROM Opportunity WHERE StageName Not In :Opportunities.CLOSED_STATUSES ];
        User objUser1 = TestDataUser.findUserInProfile('Sales User');
        for (Opportunity opp : lstOpp)
        {
            opp.StageName = STRING_FINALIZE;
            opp.Manual_Quote_Number__c = '9090';
            opp.Manual_Quote_Reason__c = 'test reason';
            opp.Proposal_Sent_On__c =  Date.newInstance(2018, 12, 9);
            opp.Competitor_Presence__c = 'No Competitor'; //opp.Competitor_Name__c = 'No Competitor'; Added by SB
            opp.Summarize_Buying_Vision__c = 'buyingvision';
            opp.Win_Strategy__c = 'Performance';
            opp.Customer_Confirmed_Solution_Fit_On__c = Date.newInstance(2018, 12, 9);
            opp.Customer_Approval_Received_On__c = Date.newInstance(2018, 12, 9);
            opp.Customer_s_Next_Step__c = 'test';
            opp.Are_Products_Added__c = true;
            opp.Primary_Field_Application_Scientist__c = objUser1.Id;
            opp.Primary_Field_Service_Engineer__c = objUser1.Id;
            opp.Field_Application_Manager__c = objUser1.Id;
            opp.Field_Service_Manager__c = objUser1.Id;
            opp.CloseDate = system.TODAY() + 1;
            opp.Customer_Account_Creation_Requested_On__c = system.TODAY();
        }

        Test.startTest();
        update lstOpp;
        Test.stopTest();

        lstOpp = [SELECT id, Primary_Contact__c FROM Opportunity WHERE Id IN :lstOpp];
        //due to OpportunityContactRoles.cls method->opportunityWithPrimaryContactRoles first contact becomes primary if primary not selected by user
        Assert.isNotNull(lstOpp.get(0).Primary_Contact__c, 'Primary Contact does not exist');
    }

    /**
    *    @author Rahul Sharma
    *    @date   2018-08-01
    *    @description Testing insert scenario for direct and indirect pricelist
    */
    
    @isTest
    static void opportunityPopulatePriceListFieldsOnInsert()
    {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1, DISTRIBUTOR_PARTNER});

        Account acc5 = accMap.get(TEST1);
        Account acc6 = accMap.get(DISTRIBUTOR_PARTNER);

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc5.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc6.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};
            
        System.debug('acc1SalesArea: ' + acc1SalesArea);
        System.debug('acc2SalesArea: ' + acc2SalesArea);

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc5.Id;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc5.Id;
        opp2.Distributor__c = acc6.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;

        Test.startTest();
        insert new List<Opportunity> {opp1, opp2};
        Test.stopTest();

        List<Opportunity> lstOpp = [SELECT id, Name, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c,
            Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,
            Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,
            Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c 
            FROM Opportunity WHERE Name LIKE'opp%'];

        for(Opportunity opp:lstOpp){
            System.debug('opp: '+opp);
            if(opp.Name == 'opp1'){
                Assert.areEqual('123456_US010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('123456_US010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual(acc1SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
                Assert.areEqual(acc1SalesArea.Contract_Number__c,opp.Contract_Number__c,'Contract Number Incorrect');
                Assert.areEqual(acc1SalesArea.Sales_Organization__c,opp.Sold_to_Sales_Organization__c,'Sold To Sales Organization Incorrect');
                Assert.areEqual(acc1SalesArea.Distribution_Channel__c,opp.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel Incorrect');
                Assert.areEqual(acc1SalesArea.Division__c,opp.Sold_to_Division__c,'Sold To Division Incorrect');
            }
            if(opp.Name == 'opp2'){
                Assert.areEqual('123456_US010200',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('123456_US010200',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual('567890_US010200',opp.Sales_Area_Distributor__c,'Distributor Sales Area Incorrect');
                Assert.areEqual(acc2SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
                Assert.areEqual(acc2SalesArea.Contract_Number__c,opp.Contract_Number__c,'Contract Number Incorrect');
                Assert.areEqual(acc2SalesArea.Sales_Organization__c,opp.Sold_to_Sales_Organization__c,'Distributor Sales Organization Incorrect');
                Assert.areEqual('02',opp.Sold_to_Distribution_Channel__c,'Distributor Distribution Channel Incorrect');
                Assert.areEqual(acc2SalesArea.Division__c,opp.Sold_to_Division__c,'Distributor Division Incorrect');
            }
        }
    }
    
    /**
    *    @author Rahul Sharma
    *    @date   2018-10-08
    *    @description Testing update scenario for direct and indirect pricelist
    */
    @isTest
    static void opportunityPopulatePriceListFieldsOnUpdate()
    {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1, DISTRIBUTOR_PARTNER, DISTRIBUTOR_AFFILIATE, DISTRIBUTOR_AGGREGATOR});
        Account acc5 = accMap.get(TEST1);
        Account acc6 = accMap.get(DISTRIBUTOR_PARTNER);
        Account acc7 = accMap.get(DISTRIBUTOR_AFFILIATE);
        Account acc8 = accMap.get(DISTRIBUTOR_AGGREGATOR);

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc7.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'CAD';
        acc1SalesArea.Price_List__c = '01-AMR-CAD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('CA01','02','179','00',false);
        acc2SalesArea.Account__c = acc8.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'CAD';
        acc2SalesArea.Price_List__c = '01-AMR-CAD';
        acc2SalesArea.Contract_Number__c = '987650_CA010200';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};

        Test.startTest();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc5.Id;
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc5.Id;
        opp2.Distributor__c = acc6.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;

        insert new List<Opportunity> {opp1, opp2};

        opp1.AccountId = acc7.Id;
        opp2.Ultimate_Consignee__c = acc7.Id;
        opp2.Distributor__c = acc8.Id;

        update new List<Opportunity> {opp1, opp2};
        Test.stopTest();

        List<Opportunity> lstUpdatedOpp = [SELECT id,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c,Sold_to_Sales_Organization__c,Sold_to_Distribution_Channel__c,Sold_to_Division__c,Direct_Sale_to_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp%'];

        for(Opportunity opp:lstUpdatedOpp){
            if(opp.Name == 'opp1'){
                Assert.areEqual('654321_US010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('123456_US010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual(acc1SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
                Assert.areEqual(acc1SalesArea.Contract_Number__c,opp.Contract_Number__c,'Contract Number Incorrect');
                Assert.areEqual(acc1SalesArea.Sales_Organization__c,opp.Sold_to_Sales_Organization__c,'Sold To Sales Organization Incorrect');
                Assert.areEqual(acc1SalesArea.Distribution_Channel__c,opp.Sold_to_Distribution_Channel__c,'Sold To Distribution Channel Incorrect');
                Assert.areEqual(acc1SalesArea.Division__c,opp.Sold_to_Division__c,'Sold To Division Incorrect');
            }
            if(opp.Name == 'opp2'){
                Assert.areEqual('123456_CA010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('654321_CA010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual('987650_CA010200',opp.Sales_Area_Distributor__c,'Distributor Sales Area Incorrect');
                Assert.areEqual(acc2SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
                Assert.areEqual(acc2SalesArea.Contract_Number__c,opp.Contract_Number__c,'Contract Number Incorrect');
                Assert.areEqual(acc2SalesArea.Sales_Organization__c,opp.Sold_to_Sales_Organization__c,'Distributor Sales Organization Incorrect');
                Assert.areEqual('01',opp.Sold_to_Distribution_Channel__c,'Distributor Distribution Channel Incorrect');
                Assert.areEqual(acc2SalesArea.Division__c,opp.Sold_to_Division__c,'Distributor Division Incorrect');
            }
        }
    }
   
    /**
    *    @author Rahul Sharma
    *    @date   2018-10-24
    *    @description Testing insert scenario for Sales Org Override
    */
    @isTest
    static void opportunitySalesOrgOverrideOnInsert()
    {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1, DISTRIBUTOR_PARTNER, DISTRIBUTOR_AFFILIATE, DISTRIBUTOR_AGGREGATOR});
        Account acc5 = accMap.get(TEST1);
        Account acc6 = accMap.get(DISTRIBUTOR_PARTNER);

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('SG01','01','178','00',false);
        acc1SalesArea.Account__c = acc5.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('SG01','02','179','00',false);
        acc2SalesArea.Account__c = acc6.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';

        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};    

        System.debug('acc1SalesArea: '+acc1SalesArea);
        System.debug('acc2SalesArea: '+acc2SalesArea);

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc5.Id;
        opp1.Sales_Org_Override__c = 'SG01';
        opp1.Reason_For_Default_Sales_Org_Override__c = 'Override Test';

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc5.Id;
        opp2.Distributor__c = acc6.Id;
        opp2.Sales_Org_Override__c = 'SG01';
        opp2.Reason_For_Default_Sales_Org_Override__c = 'Override Test';
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;

        Test.startTest();
        insert new List<Opportunity> {opp1, opp2};
        Test.stopTest();

        List<Opportunity> lstOpp = [SELECT id,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c FROM Opportunity WHERE Name LIKE'opp%'];

        for(Opportunity opp:lstOpp){
            System.debug('opp: '+opp);
            if(opp.Name == 'opp1'){
                Assert.areEqual('123456_SG010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('123456_SG010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual(acc1SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
            }
            if(opp.Name == 'opp2'){
                Assert.areEqual('123456_SG010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('123456_SG010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual('567890_SG010200',opp.Sales_Area_Distributor__c,'Distributor Sales Area Incorrect');
                Assert.areEqual(acc2SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
            }
        }
    }
    
    /**
    *    @author Rahul Sharma
    *    @date   2018-10-24
    *    @description Testing update scenario for Sales Org Override
    */
    @isTest
    static void opportunitySalesOrgOverrideOnUpdate()
    {

        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1, DISTRIBUTOR_PARTNER, DISTRIBUTOR_AFFILIATE, DISTRIBUTOR_AGGREGATOR});
        Account acc5 = accMap.get(TEST1);
        Account acc6 = accMap.get(DISTRIBUTOR_PARTNER);
        Account acc7 = accMap.get(DISTRIBUTOR_AFFILIATE);
        Account acc8 = accMap.get(DISTRIBUTOR_AGGREGATOR);

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('SG01','01','178','00',false);
        acc1SalesArea.Account__c = acc7.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'CAD';
        acc1SalesArea.Price_List__c = '01-AMR-CAD';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('SG01','02','179','00',false);
        acc2SalesArea.Account__c = acc8.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'CAD';
        acc2SalesArea.Price_List__c = '01-AMR-CAD';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea}; 
        

        Test.startTest();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc5.Id;
        opp1.Sales_Org_Override__c = 'HK01';
        opp1.Reason_For_Default_Sales_Org_Override__c = 'Override Test';

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc5.Id;
        opp2.Distributor__c = acc6.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp1.Sales_Org_Override__c = 'HK01';
        opp1.Reason_For_Default_Sales_Org_Override__c = 'Override Test';

        insert new List<Opportunity> {opp1, opp2};

        opp1.AccountId = acc7.Id;
        opp1.Sales_Org_Override__c = 'SG01';
        opp1.Reason_For_Default_Sales_Org_Override__c = 'Override Test';

        opp2.Ultimate_Consignee__c = acc7.Id;
        opp2.Distributor__c = acc8.Id;
        opp2.Sales_Org_Override__c = 'SG01';
        opp2.Reason_For_Default_Sales_Org_Override__c = 'Override Test';

        update new List<Opportunity> {opp1, opp2};
        Test.stopTest(); 

        List<Opportunity> lstUpdatedOpp = [SELECT id,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c,Price_List_Type__c,Price_List__c,Sales_Area_Distributor__c,CurrencyIsoCode,Contract_Number__c FROM Opportunity WHERE Name LIKE'opp%'];

        for(Opportunity opp:lstUpdatedOpp){
            if(opp.Name == 'opp1'){
                Assert.areEqual('654321_SG010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('123456_SG010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Not Overriden');
                Assert.areEqual(acc1SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc1SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
                Assert.areEqual(acc1SalesArea.Contract_Number__c,opp.Contract_Number__c,'Contract Number Incorrect');
            }
            if(opp.Name == 'opp2'){
                Assert.areEqual('123456_SG010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
                Assert.areEqual('654321_SG010100',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
                Assert.areEqual('987650_SG010200',opp.Sales_Area_Distributor__c,'Distributor Sales Area Not Overriden');
                Assert.areEqual(acc2SalesArea.CurrencyIsoCode,opp.CurrencyIsoCode,'Currency Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List_Type__c,opp.Price_List_Type__c,'Price List Type Incorrect');
                Assert.areEqual(acc2SalesArea.Price_List__c,opp.Price_List__c,'Price List Incorrect');
                Assert.areEqual(acc2SalesArea.Contract_Number__c,opp.Contract_Number__c,'Contract Number Incorrect');
            }
        }
    }

    
    /**
    *    @author Rahul Sharma
    *    @date   2018-12-03
    *    @description Testing update scenario for Sales Org Override
    *    Method to increase the coverage and asserts for sales area already available in above methods
    */    
    @isTest
        static void opportunityIndirectSoldToSalesAreaOnUpdate()
    {
   
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1, DISTRIBUTOR_PARTNER, DISTRIBUTOR_AFFILIATE, DISTRIBUTOR_AGGREGATOR});
        Account acc5 = accMap.get(TEST1);
        Account acc6 = accMap.get(DISTRIBUTOR_PARTNER);
        Account acc7 = accMap.get(DISTRIBUTOR_AFFILIATE);

        Test.startTest();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc5.Id;
        opp1.Direct_Sale_to_Ultimate_Consignee__c = true;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc5.Id;
        opp2.Distributor__c = acc6.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;

        insert new List<Opportunity> {opp1, opp2};

        opp1.AccountId = acc7.Id;
        opp2.Ultimate_Consignee__c = acc7.Id;

        update new List<Opportunity> {opp1, opp2};
        Test.stopTest();
        
        //Added by Rahul 08-Jul-2019: Asserts for checkmarxp
        List<Opportunity> lstUpdatedOpp = [SELECT id,Name,Sales_Area_Sold_To__c,Sales_Area_Ultimate_Consignee__c FROM Opportunity WHERE Name LIKE'opp%'];

        for(Opportunity opp:lstUpdatedOpp){
            if(opp.Name == 'opp1'){
                System.assertEquals('654321_US010100',opp.Sales_Area_Sold_To__c,'Sold To Sales Area Incorrect');
            }
            if(opp.Name == 'opp2'){
                System.assertEquals('654321_CA010200',opp.Sales_Area_Ultimate_Consignee__c,'Ultimate Consignee Sales Area Incorrect');
            }
        }
    }
    
    /**
    *    @author        : Sravan
    *    @date          : 2018-08-30
    *    @description   : Testing auto creation of work orders with work details
    */
    @isTest
    static void autoCreateWOOrWDRecords(){

        Account accOpp = [SELECT Id, Account_Group__c FROM Account LIMIT 1];
        accOpp.Account_Group__c = 'Sold To';
        update accOpp;

        // Contact con =[SELECT id FROM contact LIMIT 1];

        // Pricebook2 stdPricebook = [SELECT Id FROM Pricebook2 LIMIT 1];
        List<Opportunity> oppList = [SELECT Id,AccountId,Primary_Contact__c, StageName 
            FROM Opportunity WHERE Name = :SERVICE_OPP LIMIT 1];

        for (Opportunity opp : oppList)
        {
            opp.StageName = 'Closed Won';
            opp.ForecastCategoryName = 'Closed';
            opp.Opportunity_Forecast_Category__c = 'Closed';
            opp.Customer_Confirmed_Solution_Fit_On__c = system.today();
            opp.Customer_Account_Creation_Requested_On__c = system.today();
            opp.Customer_s_Next_Step__c = 'test';
            opp.Customer_Approval_Received_On__c = system.today();
            opp.Win_Strategy__c = 'Performance';
            opp.Summarize_Buying_Vision__c = 'test';
            opp.Probability = 0.99;
            opp.Manual_Quote_Number__c = '9090';
            opp.Manual_Quote_Reason__c = 'test reason';
            opp.Proposal_Sent_On__c =  Date.newInstance(2018, 12, 9);
            opp.CloseDate = system.Today();
            opp.Is_Updated_By_System__c=true;
        }
        Test.startTest();

        try{
            update oppList;
        }catch(exception ex){
            //Added as part of DCP-30062
            System.debug('Exception occured, details: '+ex);
        }


        //SVMXC__Service_Order__c objWO = [Select id from SVMXC__Service_Order__c where SVMXC__Order_Type__c = 'Installation' AND ]
        Test.stopTest();
    }

    
    /**
    *    @author Akash Kumar
    *    @date   2018-09-28
    *    @description Insert Scenarios for Populate field service fields
    */
    @isTest
    static void opportunityUpdateFieldServiceFieldsonInsert() {

        SVMXC__Service_Group__c serviceTeam = [SELECT id FROM SVMXC__Service_Group__c LIMIT 1];

        System.debug('serviceTeam' + serviceTeam);

        SVMXC__Service_Group_Members__c technicianFAS = [SELECT id FROM SVMXC__Service_Group_Members__c LIMIT 1];
        technicianFAS.SVMXC__Active__c = true;
        update technicianFAS;

        Account acc1 = getAccountByName(DISTRIBUTOR_PARTNER);

        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Application Scientist');

        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Application Manager');

        Account_to_Field_Support__c afs3 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Service Engineer');

        Account_to_Field_Support__c afs4 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Service Manager');

        insert new list<Account_to_Field_Support__c> {afs1, afs2, afs3, afs4};

        Test.startTest();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc1.Id;
        opp1.Distributor__c=acc1.Id;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.IndirectFieldServices);
        opp2.Name = 'opp2';
        opp2.Distributor__c = acc1.Id;
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        opp2.Are_Products_Added_by_Channel_Partner__c = true;
        opp2.Type = 'Billable Services';
        opp2.StageName = 'Develop';
        opp2.Product_Interest__c = 'Break Fix';

        insert new List<Opportunity> {opp1, opp2};
        Test.stopTest();
        User fieldServiceUser = [SELECT Id FROM User WHERE Profile.Name = :System.label.Field_Service LIMIT 1];

        Opportunity objOpp = [SELECT id, Primary_Field_Service_Engineer__c FROM Opportunity WHERE Name = 'opp1'];
        System.debug('Primary_Field_Service_Engineer__c:' + objOpp.Primary_Field_Service_Engineer__c + ' fieldServiceUser:' + fieldServiceUser);
        Assert.areNotEqual(fieldServiceUser, objOpp.Primary_Field_Service_Engineer__c, 'Primary_Field_Service_Engineer__c value is incorrect');
    }

    
      /**
    *    @author Akash Kumar
    *    @date   2018-09-28
    *    @description Update Scenarios for Populate field service fields
    */
    @isTest
    static void opportunityUpdateFieldServiceFieldsonUpdate() {

        SVMXC__Service_Group__c serviceTeam = [SELECT id FROM SVMXC__Service_Group__c LIMIT 10];

        System.debug('serviceTeam' +serviceTeam);

        SVMXC__Service_Group_Members__c technicianFAS = [SELECT id FROM SVMXC__Service_Group_Members__c LIMIT 10];
        technicianFAS.SVMXC__Active__c = true;
        update technicianFAS;

        Account acc1 = getAccountByName(DISTRIBUTOR_PARTNER);

        Account acc2 = getAccountByName(DISTRIBUTOR_AFFILIATE);

        Account_to_Field_Support__c afs1 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc2.Id,User_Role__c = 'Primary Field Application Scientist');

        Account_to_Field_Support__c afs2 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc2.Id,User_Role__c = 'Field Application Manager');

        Account_to_Field_Support__c afs3 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Primary Field Service Engineer');

        Account_to_Field_Support__c afs4 = new Account_to_Field_Support__c(User__c = technicianFAS.Id,
                                                                         Account__c = acc1.Id,User_Role__c = 'Field Service Manager');

        insert new List<Account_to_Field_Support__c> {afs1, afs2, afs3, afs4};

        Test.startTest();
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c=acc1.Id;
        opp1.Distributor__c=acc1.Id;
        opp1.Are_Products_Added_by_Channel_Partner__c = true;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Distributor__c = acc2.Id;
        opp2.Ultimate_Consignee__c = acc1.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
        opp2.Are_Products_Added_by_Channel_Partner__c = true;

        insert new List<Opportunity> {opp1, opp2};

        opp1.Ultimate_Consignee__c = acc2.Id;
        opp2.Distributor__c = acc2.Id;

        update new List<Opportunity> {opp1, opp2};
        Test.stopTest();

        Opportunity objOpp = [SELECT id,Primary_Field_Application_Scientist__c FROM Opportunity WHERE Name = 'Opp1'];
        User fieldServiceUser = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service LIMIT 1];
        System.debug('Primary_Field_Application_Scientist__c:' + objOpp.Primary_Field_Application_Scientist__c + ' fieldServiceUser:' + fieldServiceUser);
        Assert.areNotEqual(fieldServiceUser.Id, objOpp.Primary_Field_Application_Scientist__c, 'Primary_Field_Application_Scientist__c value is incorrect');
    }

    
    /**
    *    @author Pankaj Singla
    *    @date   2018-10-26
    *    @description test method for processClosedOpportunities
    */
    @IsTest
    static void testprocessClosedOpportunities(){

        Account acc = TestDataAccount.getAccount('Test X');
        Contact con1 = TestDataPerson.getNewContact(acc.Id);
        Con1.Marketing_Contact_Status__c='Open Opportunity';
        update Con1;

        Opportunity opp = [SELECT id, stagename FROM Opportunity LIMIT 1];
        if(opp.stagename != 'Closed Won'){
            OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, opp.Id);
            insert new List<OpportunityContactRole> { ocr1 };
        }    

        Test.StartTest();
            opp.StageName = 'Closed Won';
            opp.ForecastCategoryName = 'Closed';
            opp.Opportunity_Forecast_Category__c = 'Closed';
            opp.Customer_Confirmed_Solution_Fit_On__c = system.today();
            opp.Customer_Account_Creation_Requested_On__c = system.today();
            opp.Customer_s_Next_Step__c = 'test';
            opp.Customer_Approval_Received_On__c = system.today();
            opp.Win_Strategy__c = 'Performance';
            opp.Summarize_Buying_Vision__c = 'test';
            opp.Competitor_Presence__c = 'No Competitor'; //opp.Competitor_Name__c = 'No Competitor'; Added by SB
            opp.Probability = 0.99;
            opp.Manual_Quote_Number__c = '9090';
            opp.Manual_Quote_Reason__c = 'test reason';
            opp.Proposal_Sent_On__c =  Date.newInstance(2018, 12, 9);
            opp.CloseDate = system.Today();
            opp.Is_Updated_By_System__c=true;
            update opp;
        Test.StopTest();

        Contact con=[SELECT id, Marketing_Contact_Status__c FROM contact WHERE id = :con1.id];
        Assert.areEqual('Recycled', con.Marketing_Contact_Status__c, 'The value should be Recycled');
    }
    
    /**
    *    @author Satya Swain
    *    @date   2018-10-26
    *    @description test method for populateCountryCodeAddress
    */
    @isTest
    static void checkpopulateCountryCodeAddress(){
       
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1, DISTRIBUTOR_PARTNER});

        Account acc5 = accMap.get(TEST1);
        Account acc6 = accMap.get(DISTRIBUTOR_PARTNER);

        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','01','178','00',false);
        acc1SalesArea.Account__c = acc5.Id;
        acc1SalesArea.Price_List_Type__c='01';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = '01-AMR-USD';
        acc1SalesArea.Contract_Number__c = '123456_US010100';
        acc1SalesArea.Company_Code__c = 'GB01';

        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('US01','02','179','00',false);
        acc2SalesArea.Account__c = acc6.Id;
        acc2SalesArea.Price_List_Type__c='01';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = '01-AMR-USD';
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Company_Code__c = 'US01';
        insert new List<Account_Sales_Area__c>{acc1SalesArea,acc2SalesArea};    
                 
        System.debug('acc1SalesArea: '+acc1SalesArea);
        System.debug('acc2SalesArea: '+acc2SalesArea);

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTDirectStandard);
        opp1.Name = 'opp1';
        opp1.Ultimate_Consignee__c = acc5.Id;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5,Label.OpportunityRTIndirectStandard);
        opp2.Name = 'opp2';
        opp2.Ultimate_Consignee__c = acc5.Id;
        opp2.Distributor__c = acc6.Id;
        opp2.Direct_Sale_to_Ultimate_Consignee__c = true;
        opp2.Are_Products_Added_by_Channel_Partner__c = true;

        Test.startTest();
        insert new List<Opportunity> {opp1, opp2};
        Test.stopTest();

        List<Opportunity> lstOpp = [SELECT id, Name, Sales_Area_Sold_To__c, Sales_Area_Ultimate_Consignee__c, Price_List_Type__c,
            Price_List__c,Sales_Area_Distributor__c, CurrencyIsoCode, Contract_Number__c, Company_Code__c, Company_Code_Address__c,
            Company_Name__c, Address_Line_1__c, Address_Line_2__c, Address_Line_3__c, Address_Line_4__c, Address_Line_5__c,
            Address_Line_6__c, Footer_City__c, Footer_Full_Street__c 
            FROM Opportunity 
            WHERE Name LIKE'opp%'];

        List<Company_Code_Address__mdt> lstCompanyCodeAddress = [SELECT City__c,Company_Code__c,
            Company_Name__c, Country__c, Currency__c, PO_Box__c, Postal_Code__c, Street__c, Address_Line_1__c,
            Address_Line_2__c, Address_Line_3__c, Address_Line_4__c, Address_Line_5__c, Address_Line_6__c, 
            Footer_City__c, Footer_Full_Street__c 
            FROM Company_Code_Address__mdt WHERE Company_Code__c IN('SE01','US01')];

        for(Opportunity objOpp : lstOpp){
            for (Company_Code_Address__mdt objCompanyCodeAddress : lstCompanyCodeAddress){
                if(objOpp.Name == 'opp1' && objCompanyCodeAddress.Company_Code__c == 'GB01'){
                    Assert.areEqual(acc1SalesArea.Company_Code__c, objOpp.Company_Code__c,'Company Code Incorrect');
                    Assert.isTrue(objOpp.Company_Name__c.contains(objCompanyCodeAddress.Company_Name__c), 'Company Name incorrect');
                    Assert.isTrue(objOpp.Address_Line_1__c.contains(objCompanyCodeAddress.Address_Line_1__c), 'Address Line 1 incorrect');
                    Assert.isTrue(objOpp.Address_Line_2__c.contains(objCompanyCodeAddress.Address_Line_2__c), 'Address Line 2 incorrect');
                    Assert.isTrue(objOpp.Address_Line_3__c.contains(objCompanyCodeAddress.Address_Line_3__c), 'Address Line 3 incorrect');
                }
                 if(objOpp.Name == 'opp2' && objCompanyCodeAddress.Company_Code__c == 'US01'){
                    Assert.areEqual(acc2SalesArea.Company_Code__c,objOpp.Company_Code__c,'Company Code Incorrect');
                    Assert.isTrue(objOpp.Company_Name__c.contains(objCompanyCodeAddress.Company_Name__c), 'Company Name incorrect');
                    Assert.isTrue(objOpp.Address_Line_1__c.contains(objCompanyCodeAddress.Address_Line_1__c), 'Address Line 1 incorrect');
                    Assert.isTrue(objOpp.Address_Line_2__c.contains(objCompanyCodeAddress.Address_Line_2__c), 'Address Line 2 incorrect');
                    Assert.isTrue(objOpp.Address_Line_3__c.contains(objCompanyCodeAddress.Address_Line_3__c), 'Address Line 3 incorrect');
                }
            }
        }
    }

    
    /*Method Description - DCP-45454 Check If First Proposal sent is set to true */   
    @isTest
    static void checkIsFirstProposalSentOnUpdate()
    {
        Opportunity opp = [SELECT Id,Name FROM Opportunity WHERE Name = 'Sales Opp'];
        Test.startTest();
        opp.stageName = 'Develop';
        opp.Is_First_Proposal_Sent__c = false;
        opp.Proposal_Sent_On__c = System.today() + 5 ;
        update opp;
        Test.stopTest();
        Opportunity updatedOpp = [SELECT Id,Is_First_Proposal_Sent__c,Name FROM Opportunity WHERE Id =: opp.Id];
        System.assertEquals(true,updatedOpp.Is_First_Proposal_Sent__c);
    }

    @isTest
    static void testWaterFall(){
        Account acc = TestDataMarketing.getAccount('test123');
        Contact con1 = TestDataPerson.getNewContact(acc.Id);
        Contact con2 = TestDataPerson.getNewContact(acc.Id);
        con1.Last_Responded_Campaign_Date__c=Datetime.Now();
    
        update con1; 
        con2.Marketing_Contact_Status__c='Open Opportunity';
        update con2;
        Opportunity sOpp = TestDataOpportunity.initOpportunity(acc);
        sOpp.LeadSource='Funnel Marketing';
        sOpp.StageName='Create';
        sOpp.Competitor_Presence__c = 'No Competitor'; //Added by SB
        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc);
        opp2.LeadSource='Funnel Marketing';
        opp2.StageName='Create';
        opp2.Competitor_Presence__c = 'No Competitor'; //Added by SB
        insert new List<Opportunity>{opp2,sOpp};
  
        OpportunityContactRole ocr1 = TestDataOpportunity.getNewOpportunityContactRole('Power Sponsor', con1.Id, sOpp.Id);
        OpportunityContactRole ocr2 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, opp2.Id);
        OpportunityContactRole ocr3 = TestDataOpportunity.getNewOpportunityContactRole('Sponsor', con2.Id, sOpp.Id);
        insert new List<OpportunityContactRole> { ocr1, ocr2,ocr3};
        sOpp.StageName='Develop';        
        opp2.StageName='Closed Won';
        opp2.ForecastCategoryName = 'Closed';
        opp2.Opportunity_Forecast_Category__c = 'Closed';

        //DCP-60098: Updated for this story
        Test.startTest();
        update (new List<Opportunity>{opp2,sOpp});   
        // fire platform event
        Test.getEventBus().deliver();
        Test.stopTest();

        List<OpportunityContactRole> lstOcrResultCW = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c
                                                        FROM OpportunityContactRole WHERE OpportunityId =: opp2.Id];
        List<OpportunityContactRole> lstOcrResultOpen = [SELECT Id, Contact.Marketing_Contact_Status__c, Contact.Waterfall_Stage__c, Contact.Waterfall_Closed_Won_Date__c
                                                        FROM OpportunityContactRole WHERE OpportunityId =: sOpp.Id];

        System.assertEquals('Closed Won',opp2.StageName,'Stage is not closed won');
        Assert.isNotNull(lstOcrResultCW.get(0).Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data did not set correctly');
        Assert.isNull(lstOcrResultOpen.get(0).Contact.Waterfall_Closed_Won_Date__c, 'Waterfall Closed Won data incorrectly set');

   }

    @IsTest
    private static void populateComplianceLastModifiedDateWithHumanUserOnInsert() {
        Opportunity opp = getOppComplianceSetupData();
        System.debug('Compliance_Last_Modified_Date__c' + opp.Compliance_Last_Modified_Date__c);// null
        System.runAs(SYS_ADMIN) {
            insert opp;
        }

        opp = getOpportunity(COMPLIANCE_OPP);
        Assert.isNotNull(opp.Compliance_Last_Modified_Date__c, 'Compliance Last Modified Date should not be null');
    }

    //CMCM-11235
    @IsTest
    private static void oppStageChangeOnDealRejectOnInsert() {
        Feature.setMockFeatureFlag('WF_Opp_Update_Stage_To_Close_Abandoned', true);
        Account acc = TestDataAccount.getAccount(TEST1);
        Opportunity opp = TestDataOpportunity.initOpportunity(acc, Opportunities.RT_STANDARD_INDIRECT);
        System.debug('Deal_Registration_Status__c ' + opp.Deal_Registration_Status__c);
        System.runAs(SYS_ADMIN) {
            opp.Deal_Registration_Status__c = 'Rejected';
            opp.Name = DEAL_REJECT_OPP;
            insert opp;
        }
        opp = [SELECT Id, Abandon_Reason__c, StageName, Deal_Registration_Status__c FROM Opportunity WHERE Id =: opp.Id];
        Assert.areEqual(STRING_OPPORTUNITY_ABANDON_REASON, opp.Abandon_Reason__c, 'Should be the same date since it is inserted with Rejected Deal');
        Assert.areEqual(STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED, opp.StageName, 'Should be the same date since it is updated with Rejected Deal');    
    }

    //CMCM-11235 
    @IsTest
    private static void oppStageChangeOnDealRejectOnUpdate() {
        Feature.setMockFeatureFlag('WF_Opp_Update_Stage_To_Close_Abandoned', true);
        Opportunity opp = [SELECT Id, Abandon_Reason__c, StageName, Deal_Registration_Status__c FROM Opportunity WHERE RecordType.DeveloperName =: Opportunities.RT_STANDARD_INDIRECT LIMIT 1];
        System.runAs(SYS_ADMIN) {
            Test.startTest();
                opp.Deal_Registration_Status__c = 'Rejected';
                update opp;
            Test.stopTest();
        }

        Opportunity updatedOpp = [SELECT Id, Abandon_Reason__c, StageName, Deal_Registration_Status__c FROM Opportunity WHERE Id =: opp.Id];
        Assert.areEqual(STRING_OPPORTUNITY_ABANDON_REASON, updatedOpp.Abandon_Reason__c, 'Should be the same date since it is inserted with Rejected Deal');
        Assert.areEqual(STRING_OPPORTUNITY_STAGE_CLOSED_ABANDONED, updatedOpp.StageName, 'Should be the same date since it is updated with Rejected Deal');    
    }
     //CMCM-11292
     @IsTest
     private static void oppStageChangeBackwardMovementUpdateNonStandard() {
 
         Feature.setMockFeatureFlag('WF_Opp_Backward_Movement', true);
         Account acc1 = getAccountByName(DISTRIBUTOR_PARTNER);
         
         Opportunity opp2 = TestDataOpportunity.initOpportunity(acc1,Label.IndirectFieldServices);
         opp2.Name = 'opp2';
         opp2.Distributor__c = acc1.Id;
         opp2.Ultimate_Consignee__c = acc1.Id;
         opp2.Direct_Sale_to_Ultimate_Consignee__c = false;
         opp2.Are_Products_Added_by_Channel_Partner__c = true;
         opp2.Type = 'Billable Services';
         opp2.StageName = Label.OpportunityStageDevelop;
         opp2.Product_Interest__c = 'Break Fix';
         Opportunity updtOpps;
         System.runAs(SYS_ADMIN) {
             Test.startTest();
             insert opp2;
             updtOpps = [SELECT Id, Backward_Movement_in_Pipeline__c, StageName, Name FROM Opportunity WHERE Id =: opp2.Id];
             updtOpps.StageName = Label.OpportunityStageQualify;
             update updtOpps;
             Test.stopTest();
         }
         Opportunity updtedOpps = [SELECT Id, Backward_Movement_in_Pipeline__c, StageName FROM Opportunity WHERE Id =: updtOpps.Id];
         Boolean backwardMovementUpdate = updtedOpps.Backward_Movement_in_Pipeline__c;
         System.debug('backwardMovementUpdate: ' + backwardMovementUpdate);
         Assert.areEqual(true, backwardMovementUpdate, 'Should be same');
     }
    
    //CMCM-11292
    @IsTest
    private static void oppStageChangeBackwardMovementUpdateDirectStandard() {

        Feature.setMockFeatureFlag('WF_Opp_Backward_Movement', true);
        Opportunity opp = [SELECT Id, Backward_Movement_in_Pipeline__c, StageName FROM Opportunity WHERE RecordType.DeveloperName =: Opportunities.RT_STANDARD_INDIRECT LIMIT 1];
         System.runAs(SYS_ADMIN) {
            Test.startTest();
                opp.StageName = Label.OpportunityStageDevelop;
                update opp;
                opp.StageName = Label.OpportunityStageQualify;
                update opp;
            Test.stopTest();
        }

        Opportunity updatedOpp = [SELECT Id, Backward_Movement_in_Pipeline__c, StageName FROM Opportunity WHERE Id =: opp.Id];
        Assert.areEqual(true, updatedOpp.Backward_Movement_in_Pipeline__c, 'Should be the same');
    }

    @IsTest
    private static void populateComplianceLastModifiedDateWithHumanUserOnUpdate() {
        Opportunity opp;
        Datetime oldComplianceLastModifiedDate;
        System.runAs(SYS_ADMIN) {

            opp = getOpportunity(SALES_OPP);
            oldComplianceLastModifiedDate = opp.Compliance_Last_Modified_Date__c;
            System.debug('oldComplianceLastModifiedDate:' + oldComplianceLastModifiedDate);

            Test.startTest();
                opp.StageName = 'Develop';
                update opp;
            Test.stopTest();
        }

        Opportunity updatedOpp = getOpportunity(SALES_OPP);
        Datetime newComplianceLastModifiedDate = updatedOpp.Compliance_Last_Modified_Date__c;
        System.debug('newComplianceLastModifiedDate:' + newComplianceLastModifiedDate);

        Assert.areNotEqual(oldComplianceLastModifiedDate, newComplianceLastModifiedDate, 'Should not be the same date since it is updated the record with a human user');
    }

    @IsTest
    private static void populateComplianceLastModifiedDateWithAutomatedUserOnInsert() {
        Opportunity opp = getOppComplianceSetupData();
        System.debug('Compliance_Last_Modified_Date__c' + opp.Compliance_Last_Modified_Date__c);// null
        System.runAs(AUTOMATED_USER) {
            insert opp;
        }

        opp = getOpportunity(COMPLIANCE_OPP);
        Assert.isNotNull(opp.Compliance_Last_Modified_Date__c, 'Compliance Last Modified Date should not be null');
    }

    @IsTest
    private static void populateComplianceLastModifiedDateWithAutomatedUserOnUpdate() {

        Opportunity opp;
        Datetime oldComplianceLastModifiedDate;
        System.runAs(AUTOMATED_USER) {
            opp = getOpportunity(SALES_OPP);
            oldComplianceLastModifiedDate = opp.Compliance_Last_Modified_Date__c;
            System.debug('oldComplianceLastModifiedDate:' + oldComplianceLastModifiedDate);

            opp.StageName = 'Develop';
            update opp;
        }

        Opportunity updatedOpp = getOpportunity(SALES_OPP);
        Datetime newComplianceLastModifiedDate = updatedOpp.Compliance_Last_Modified_Date__c;
        System.debug('newComplianceLastModifiedDate:' + newComplianceLastModifiedDate);

        Assert.areEqual(oldComplianceLastModifiedDate, newComplianceLastModifiedDate, 'Should be the same date since it is updated with an automated process');
    }

    @IsTest
    private static void updateIsUpdatedBySystemAndReasonBackwardsAsFuture() {
        Test.startTest();
        insertOpportunityFuture();
        Test.stopTest();
        Opportunity opportunity = [SELECT id, Is_Updated_By_System__c, Reason_for_Moving_Backwards__c, ByPass_LockSentProposalDate__c, ByPass_Change_Record_Type_To_Standard__c FROM Opportunity WHERE name = :OP_NAME];
        Assert.isFalse(opportunity.Is_Updated_By_System__c, 'Is_Updated_By_System__c should be updated to false!');
        Assert.isNull(opportunity.Reason_for_Moving_Backwards__c, 'Reason_for_Moving_Backwards__c should be null');
        Assert.isFalse(opportunity.ByPass_LockSentProposalDate__c, 'ByPass_LockSentProposalDate__c should be updated to false!');
        Assert.isFalse(opportunity.ByPass_Change_Record_Type_To_Standard__c, 'ByPass_Change_Record_Type_To_Standard__c should be updated to false!');
    }

    @IsTest
    private static void setProbabilityStageCreateNotForecasted10percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Create';
        opp2insert.ForecastCategoryName = 'Not Forecasted';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Create';
        opp2update.ForecastCategoryName = 'Not Forecasted';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(10, results[0].Probability, 'it should be 10 as probability!');
        Assert.areEqual(10, results[1].Probability, 'it should be 10 as probability!');
    }

    @IsTest
    private static void setProbabilityStageCreateNotForecasted20percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Qualify';
        opp2insert.ForecastCategoryName = 'Not Forecasted';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Qualify';
        opp2update.ForecastCategoryName = 'Not Forecasted';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(20, results[0].Probability, 'it should be 20 as probability!');
        Assert.areEqual(20, results[1].Probability, 'it should be 20 as probability!');
    }

    @IsTest
    private static void setProbabilityStageProveNotForecasted40percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Prove';
        opp2insert.ForecastCategoryName = 'Not Forecasted';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Prove';
        opp2update.ForecastCategoryName = 'Not Forecasted';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(40, results[0].Probability, 'it should be 40 as probability!');
        Assert.areEqual(40, results[1].Probability, 'it should be 40 as probability!');
    }

    @IsTest
    private static void setProbabilityOppClosedAndFCUpside60percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Develop';
        opp2insert.ForecastCategoryName = 'Upside';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Develop';
        opp2update.ForecastCategoryName = 'Upside';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(60, results[0].Probability, 'it should be 60 as probability!');
        Assert.areEqual(60, results[1].Probability, 'it should be 60 as probability!');
    }

    @IsTest
    private static void setProbabilityOppClosedAndFCCommitAtRisk70percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Develop';
        opp2insert.ForecastCategoryName = 'Commit-At Risk';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Develop';
        opp2update.ForecastCategoryName = 'Commit-At Risk';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(70, results[0].Probability, 'it should be 70 as probability!');
        Assert.areEqual(70, results[1].Probability, 'it should be 70 as probability!');
    }

    @IsTest
    private static void setProbabilityStageProveFCCommit80percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Prove';
        opp2insert.ForecastCategoryName = 'Commit';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Prove';
        opp2update.ForecastCategoryName = 'Commit';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(80, results[0].Probability, 'it should be 80 as probability!');
        Assert.areEqual(80, results[1].Probability, 'it should be 80 as probability!');
    }

    @IsTest
    private static void setProbabilityStageFinalizeFCCommit90percent() {
        Map<String, Account> accMap = getAccountsByName(new List<String> {TEST1});
        Account acc = accMap.get(TEST1);

        Opportunity opp2insert = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp2insert.Name = 'opp1';
        opp2insert.Ultimate_Consignee__c = acc.Id;
        opp2insert.StageName = 'Finalize';
        opp2insert.ForecastCategoryName = 'Commit';
        
        Opportunity opp2update = getOpportunity(SALES_OPP);
        opp2update.StageName = 'Finalize';
        opp2update.ForecastCategoryName = 'Commit';

        Test.startTest();
        insert opp2insert;
        update opp2update;
        Test.stopTest();

        List<Opportunity> results = [SELECT id, Name, Probability FROM Opportunity WHERE Name IN ('opp1', :SALES_OPP) ORDER BY Name ASC];
        System.debug('results:' + JSON.serializePretty(results));

        Assert.areEqual(90, results[0].Probability, 'it should be 90 as probability!');
        Assert.areEqual(90, results[1].Probability, 'it should be 90 as probability!');
    }

    /**Dummy future method */
    @future
    public static void insertOpportunityFuture() {
        Account a = getAccountByName(TEST1);
        Opportunity op = TestDataOpportunity.initOpportunity(a);
        op.Name = OP_NAME;
        op.Is_Updated_By_System__c = true;
        insert op;
    }

}