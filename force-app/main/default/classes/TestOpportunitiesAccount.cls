/**
*    @author Saurabh Brahmankar
*    @date   2023-10-18
*    @description    Opportunities.cls Account tests.
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                       Description
*             Satya Swain                   26-Oct-2018             Adding checkPopulateCompanyCodeAddress for DCP-11696
*             Satya Swain                   10-Sep-2019             Adding clearOpportunityCache for INC0225110
*             Satya Swain                   26-Sep-2019             DCP-30062: SonarQube Fixes
*             KD                            16-June-2021            DCP-46224: Set Relocation Type field
*             Satya Swain                   09 Dec 2022             Added Codescan fix for Variable Naming Convention
*             Saurabh Brahmankar            18-Oct-2023             Update the TestOpportunity class from improvements
*             Gerardo Garcia                02-Jan-2024             Refactor Tests.
*    ----------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class TestOpportunitiesAccount {

    private static final String TEST1 = 'Test 1';
    private static final String DISTRIBUTOR_PARTNER = 'Distributor Partner';
    private static final String TERRITORY_ACCOUNT = 'Territory Account';
    private static final String TERRITORY_ACCOUNT_2 = 'Territory Account 2';
    private static final String TERRITORY_ACCOUNT_3 = 'Territory Account 3';
    private static final String ULTIMATE_CONSIGNEE = 'Ultimate Consignee';
    private static final String ANOTHER_ADMIN_FNAME = 'Chester';
    private static final String ANOTHER_ADMIN_LNAME = 'Testos';

    @testSetup
    static void initializeTestData()
    {
        Map<String, Account > accounts = setupAccounts();

       	Account acc = accounts.get(TEST1);
        Account accDistributor = accounts.get(DISTRIBUTOR_PARTNER);

        Contact con1 = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        Contact con3 = TestDataPerson.initContact(accDistributor.Id);
        insert new List<Contact> { con1, con2, con3 };

        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());    

        System.debug('Total Number of SOQL Queries allowed in this apex code context: ' + Limits.getLimitQueries());
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());    
    }

    private static Map<String, Account> setupAccounts() {
        String indirectPartnerRecordTypeId = TestDataAccount.getIndirectPartnerTypeId();
        String customerRecordTypeId = TestDataAccount.getCustomerTypeId();

        Account acc = TestDataAccount.getAccount(TEST1);
        acc.Territory_Region__c = 'Region1';
        acc.BillingCountryCode = 'US';
        acc.BillingStateCode = 'AK';
        acc.RecordTypeId = indirectPartnerRecordTypeId;

        Account accDistributor = TestDataAccount.getAccount(DISTRIBUTOR_PARTNER);
        accDistributor.Account_Group__c = 'Distributor';
        accDistributor.RecordTypeId = indirectPartnerRecordTypeId;

        Account accUltimateConsignee = TestDataAccount.getAccount(ULTIMATE_CONSIGNEE);
        accUltimateConsignee.Account_Group__c = 'Ultimate Consignee';
        accUltimateConsignee.RecordTypeId = customerRecordTypeId;

        Account acTerritory = TestDataAccount.getAccount(TERRITORY_ACCOUNT);
        acTerritory.Territory_Region__c = 'China';
        acTerritory.ERP_Customer_Id__c = '123456';

        Account acTerritory2 = TestDataAccount.getAccount(TERRITORY_ACCOUNT_2);
        acTerritory2.Territory_Region__c = 'Region2';
        acTerritory2.BillingCountryCode = 'US';
        acTerritory2.BillingStateCode = 'AK';
        acTerritory2.ERP_Customer_Id__c = '123457';

        Account acTerritory3 = TestDataAccount.getAccount(TERRITORY_ACCOUNT_3);
        acTerritory3.Territory_Region__c = 'Region1';
        acTerritory3.BillingCountryCode = 'GB';
        acTerritory3.BillingStateCode = 'AL';

        List<Account> accounts = new List<Account>{acc, accDistributor, accUltimateConsignee, acTerritory, acTerritory2, acTerritory3};
        insert accounts;

        return (Map<String, Account>) UtilsCollection.getMapOfStringToSObject(accounts, 'Name', Map<String, Account>.class);
    }

    
    /**
    *    @author Satya Swain
    *    @date   2019-02-21
    *    @description Method for retrieving Territory
    */
    public static Territory2 getTerritory(){
        List<Territory2Model> lstModels = [SELECT ID,Name,(SELECT ID,Name FROM Territory2s) 
                                           FROM Territory2Model WHERE State='Active'];
        System.debug('lstModels: ' + lstModels);
        Assert.isTrue(!lstModels.isEmpty(), 'Territory Model needs to be set up first and activated!');
        Territory2Model objTerritoryModel = lstModels.get(0);
        Assert.isTrue(!objTerritoryModel.Territory2s.isEmpty(), 'Territory needs to be set up first!');
        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);
        System.debug('objTerritory: ' + objTerritory);
        return objTerritory;
    }

    private static Account getAccountByName(String name) {
        return getAccountsByName(new List<String> {name}).get(name);
    }

    private static Map<String, Account> getAccountsByName(List<String> names) {
        return (Map<String, Account>) UtilsCollection.getMapOfStringToSObject([SELECT ID, Name, Territory_Region__c, ERP_Customer_Id__c, OwnerId
            FROM Account WHERE Name IN :names], 'Name', Map<String, Account>.class);
    }

    /**
    *    @author Akshay Mohan
    *    @date   2019-01-15
    *    @description check Territory defaulting
    */
    @isTest
    static void checkTerritoryDefaulting(){

        Map<String, Account> accMap = getAccountsByName(new List<String> {TERRITORY_ACCOUNT, TERRITORY_ACCOUNT_2});

        Account acc5 = accMap.get(TERRITORY_ACCOUNT);
        Account acc6 = accMap.get(TERRITORY_ACCOUNT_2);

        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc5);
        opp1.Ultimate_Consignee__c = acc5.Id;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc5);
        opp2.Ultimate_Consignee__c = acc6.Id;

        Test.startTest();
        insert new List<Opportunity>{opp1, opp2};
        Test.stopTest();

        Set<Id> setOppIds = new Set<Id>{opp1.Id, opp2.Id};
        Map<ID, Opportunity> opps = new Map<Id, Opportunity>([SELECT ID, Name, Sold_To_Account_Region__c, Ultimate_Consignee_Region__c
                                    FROM Opportunity WHERE ID IN :setOppIds ORDER BY ID DESC]);

        Assert.areEqual(acc5.Territory_Region__c, opps.get(opp1.id).Sold_To_Account_Region__c, 'opp1 Sold To Region not set');
        Assert.areEqual(acc5.Territory_Region__c, opps.get(opp1.id).Ultimate_Consignee_Region__c, 'opp1 UC Region not set');

        Assert.areEqual(acc5.Territory_Region__c, opps.get(opp2.id).Sold_To_Account_Region__c, 'opp2 Sold To Region not set');
        Assert.areEqual(acc6.Territory_Region__c, opps.get(opp2.id).Ultimate_Consignee_Region__c, 'opp2 UC Region not set');
    }
    
    /**
     * @author Tapas
     * @date   18 Sep 2020
     * @description    DCP-40024  Automatically add primary contact role for partner when the indirect opportunity is created by a partner
    **/ 
    @isTest
    static void testOCRonOppCreatedByPartner(){
        Account accountDistruitor = getAccountByName(DISTRIBUTOR_PARTNER);
        Account ultimateConsignee = getAccountByName(ULTIMATE_CONSIGNEE);

        Contact contactDistribuitor = [SELECT id, accountId 
            FROM Contact 
            WHERE AccountId = :accountDistruitor.id LIMIT 1];

        Territory2 territory = getTerritory();
        ObjectTerritory2Association assignDist2Territory = TestDataObjectTerritory2Association.getObjectAssociation(territory.Id, accountDistruitor.Id);
        ObjectTerritory2Association assignUC2Territory = TestDataObjectTerritory2Association.getObjectAssociation(territory.Id, ultimateConsignee.Id);
        insert new List<ObjectTerritory2Association> {assignDist2Territory, assignUC2Territory};

        User otherAdminUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>{UserInfo.getUserId()});
        TestDataUser.allowUserCreation(otherAdminUser.Id); 

        User channelUser1 ;
        System.runAs(otherAdminUser){
            Id channelPartnerProfileId = [SELECT Id FROM Profile WHERE Name = :TestDataUser.PROFILE_CHANNEL].Id;

            channelUser1 = TestDataUser.initPartnerUser(channelPartnerProfileId, contactDistribuitor.Id);
            insert channelUser1;

            UserTerritory2Association assignCPToDist = TestDataUserTerritory2Association.getUserAssociation(territory.Id, channelUser1.Id);
            insert assignCPToDist;
        }

        Opportunity objOpp;

        Test.StartTest();
            System.runAs(channelUser1){
                objOpp = TestDataOpportunity.initOpportunity(accountDistruitor, Label.OpportunityRTIndirectStandard);
                objOpp.Distributor__c = accountDistruitor.Id;
                objOpp.Ultimate_Consignee__c = ultimateConsignee.Id;
                objOpp.Direct_Sale_to_Ultimate_Consignee__c = false;
                insert objOpp;
            }
        Test.StopTest();

        Assert.areEqual(1, [SELECT id FROM OpportunityContactRole WHERE OpportunityId =: objOpp.Id].size(), 'At least 1 contact roles should exist for new added opportunity');
        Assert.areEqual(contactDistribuitor.Id, [SELECT Primary_Contact__c FROM Opportunity WHERE id = :objOpp.Id].Primary_Contact__c, 'The main contact from opportunity should match with Distruitor\'s contact');
    } 
    
    /**
     * @author KD
     * @date   16-June-2020
     * @description   DCP-46224 : test method to test relocation Type
    **/ 
    @isTest
    static void testRelocationTypeUpdate(){
        List<String> names = new List<String> {TEST1, TERRITORY_ACCOUNT_2, TERRITORY_ACCOUNT_3};
        Map<String, Account> accountMap  = getAccountsByName(names);
        
        Account acc7 = accountMap.get(TEST1);
        Account acc8 = accountMap.get(TERRITORY_ACCOUNT_2);
        Account acc9 = accountMap.get(TERRITORY_ACCOUNT_3);
        
        Opportunity opp1 = TestDataOpportunity.initOpportunity(acc7);
        opp1.Name = 'Test Opp 1';
        opp1.Ultimate_Consignee__c = acc7.Id;
        opp1.Current_Ultimate_Consignee__c = acc7.Id;

        Opportunity opp2 = TestDataOpportunity.initOpportunity(acc7);
        opp2.Name = 'Test Opp 2';
        opp2.Ultimate_Consignee__c = acc8.Id;
        opp2.Current_Ultimate_Consignee__c = acc7.Id;

        Test.startTest();
        insert new List<Opportunity>{opp1,opp2};

        Map<String, Opportunity> opps = (Map<String, Opportunity>) UtilsCollection.getMapOfStringToSObject([SELECT id, Name, Relocation_Type__c, Ultimate_Consignee__r.Territory_Region__c, 
        Current_Ultimate_Consignee__r.Territory_Region__c, Ultimate_Consignee__r.BillingCountryCode, Current_Ultimate_Consignee__r.BillingCountryCode 
        FROM Opportunity WHERE Name IN ('Test Opp 1','Test Opp 2')], 'Name',  Map<String, Opportunity>.class);
        System.debug('opps'+ JSON.serializePretty(opps));

        Opportunity testOpp1 = opps.get('Test Opp 1');
        System.debug('testOpp1 UC-->' + testOpp1.Ultimate_Consignee__r.Territory_Region__c);
        System.debug('testOpp1 CUC-->' + testOpp1.Current_Ultimate_Consignee__r.Territory_Region__c);
        System.debug('testOpp1 CUC Country-->' + testOpp1.Current_Ultimate_Consignee__r.BillingCountryCode);
        System.debug('testOpp1 UC Country-->' + testOpp1.Ultimate_Consignee__r.BillingCountryCode);
        System.debug('testOpp1 -->' + testOpp1.Relocation_Type__c);
        
        Opportunity testOpp2 = opps.get('Test Opp 2');
        System.debug('testOpp2 UC-->' + testOpp2.Ultimate_Consignee__r.Territory_Region__c);
        System.debug('testOpp2 CUC-->' + testOpp2.Current_Ultimate_Consignee__r.Territory_Region__c);
        System.debug('testOpp2  CUC Country-->' + testOpp2.Current_Ultimate_Consignee__r.BillingCountryCode);
        System.debug('testOpp2 UC Country-->' + testOpp2.Ultimate_Consignee__r.BillingCountryCode);
        System.debug('testOpp2 -->' + testOpp2.Relocation_Type__c);

        Assert.areEqual(Label.OpportunityRelocationStandard, testOpp1.Relocation_Type__c, 'Relocation Type Standard not set correctly');
        Assert.areEqual(Label.OpportunityRelocationTransRegion, testOpp2.Relocation_Type__c, 'Relocation Type Trans-Region not set correctly');

        testOpp1.Current_Ultimate_Consignee__c = acc9.id;
        update testOpp1;

        Opportunity oppUpdate = [SELECT id, Relocation_Type__c FROM Opportunity WHERE id = :testOpp1.id];
        Assert.areEqual(Label.OpportunityRelocationTransBorder, oppUpdate.Relocation_Type__c, 'Relocation Type Trans-border not set correctly');

        testOpp1.Current_Ultimate_Consignee__c = null;
        update testOpp1;

        Opportunity oppUpdate1 = [SELECT id,Relocation_Type__c FROM Opportunity WHERE id =: testOpp1.id];
        Assert.isTrue(String.isBlank(oppUpdate1.Relocation_Type__c), 'Relocation Type not reset');
        Test.stopTest();
    }

    /**
    *    @author Maruthi B
    *    @date   2020-14-09
    *    @description IP2-51 -Testing RenewOppQueueable on closing of existing opp
    */
    @isTest
    static void renewOppQueuableTest()
    {
        Account acc = getAccountByName(TERRITORY_ACCOUNT_2);

        Opportunity opp = TestDataOpportunity.initOpportunity(acc, Label.OpportunityRTDirectStandard);
        opp.Name = 'opp1';
        opp.Ultimate_Consignee__c = acc.Id; 
        insert opp;

        Territory2 terr = getTerritory();

        ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(terr.Id, acc.Id);
        insert objTerritoryAssociation;

        User isrUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN, new Set<Id>{UserInfo.getUserId()});
        UserTerritory2Association isrToTerritory = TestDataUserTerritory2Association.getUserAssociationwithRole(
            terr.Id, 
            isrUser.Id, 
            Label.ISR_Role
        );

        User salesUser = TestDataUser.findUserInProfile('Sales User');
        UserTerritory2Association salesUserToTerritory = TestDataUserTerritory2Association.getUserAssociationwithRole(
            terr.Id, 
            salesUser.Id, 
            Label.TAM_Role
        );

        System.runAs(isrUser) {
            insert new List<UserTerritory2Association> {isrToTerritory, salesUserToTerritory};
        }

        fillOpportunity(opp);

        Test.startTest();

        opp.StageName = 'Closed Won';
        opp.Informatics_Opportunity__c = true;
        opp.Competitor_Presence__c = 'No Competitor'; //Added by SB
        update opp;

        Test.stopTest();
        Opportunity renewOpp = [SELECT Id, Name, Related_Opportunity__c, StageName FROM Opportunity WHERE Name LIKE 'Informatics Auto Renewal%' ORDER BY Name LIMIT 1];
        System.assertEquals(opp.id, renewOpp.Related_Opportunity__c, 'Related Opportunity Field on Renewed Opportunity is not populated correctly!');
    }



    private static void fillOpportunity(Opportunity opp) {
        User currentUser = [SELECT id FROM User WHERE id=:UserInfo.getUserId() LIMIT 1];
        User anotherAdmin;
        System.runAs(currentUser) {
            anotherAdmin = TestDataUser.initAdminUser();
            anotherAdmin.FirstName = ANOTHER_ADMIN_FNAME;
            anotherAdmin.LastName = ANOTHER_ADMIN_LNAME;
            insert anotherAdmin;

            cs_Apex_Settings__c cs = new cs_Apex_Settings__c();
            cs.Bypass_All_Validations__c = true;
            cs.Bypass_All_Triggers__c = true;
            cs.SetupOwnerId = anotherAdmin.Id;
            insert cs;
        }

        System.runAs(anotherAdmin) {

            Product2 prod = TestDataMaster.createProduct(false);
            prod.End_Of_Sale_Date__c = Date.today() + 15; // Added for DCP-26583
            prod.Product_Specific_Terms__c = 'Test Specific Term'; // Added for 29812
            prod.Material_Group_1_Code__c = 'AIM';
            prod.Informatics_Family__c = 'IAP_BB';
            insert prod;
            
            Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
            insert objPriceList;

            Apttus_Config2__PriceListItem__c lstPriceListItemId = TestDataAgreement.initPriceListItem(prod, objPriceList);
            insert lstPriceListItemId;

            PricebookEntry pbe = TestDataMaster.getNewStandardPrice(prod.Id, 200);

            Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(opp.AccountId, opp.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
            objProposal.Apttus_QPConfig__PricingDate__c = System.today()+1;
            objProposal.Apttus_Proposal__Proposal_Name__c = 'Test Proposal';
            objProposal.Promotion_JSON__c='[{"PromoCode":"NEWBEE","PromoChannel":null},{"PromoCode":"ICT-000021","PromoChannel":null},{"PromoCode":"ICT-000022","PromoChannel":null}] ';
            insert objProposal;

            Apttus_Proposal__Proposal_Line_Item__c qLI = TestDataProposal.initProposalLineItem(objProposal, prod);
            qLI.Apttus_QPConfig__PriceListItemId__c = lstPriceListItemId.id;
            insert qLI;

            OpportunityLineItem oli = new OpportunityLineItem(
                Quantity = 1,
                OpportunityId = opp.id,
                Shipping_In_Close_Quarter__c = 1,
                UnitPrice = 1,
                Product2Id = prod.id,
                Quote_Line_Item__c = qLI.Id,
                PriceBookEntryId = pbe.Id
            );
            System.debug('Before insert oli '); 
            insert oli;

            System.debug('After insert oli ');
            System.debug('oppLineItem' + oli.id);
            System.debug('Prod' + prod.id);

            Apttus_Config2__Order__c aptusOrder = new Apttus_Config2__Order__c(
                Apttus_QPConfig__ProposalId__c = objProposal.id,
                Apttus_Config2__PrimaryContactId__c = objProposal.Apttus_Proposal__Primary_Contact__c,
                Apttus_Config2__RelatedOpportunityId__c = opp.id 
            );
            insert aptusOrder;

            Apttus_Config2__OrderLineItem__c orderLine = new Apttus_Config2__OrderLineItem__c(
                Apttus_Config2__OrderId__c = aptusOrder.id,
                Apttus_Config2__LineNumber__c = 0,
                Apttus_Config2__ItemSequence__c = 0,
                Apttus_Config2__ProductId__c = prod.id,
                Apttus_QPConfig__ProposalLineItemId__c = qLI.id,
                Apttus_Config2__Quantity__c = 1);
            insert orderLine;

            qLI.Apttus_QPConfig__StartDate__c = Date.today() - 10;
            qLI.Apttus_QPConfig__EndDate__c = date.newinstance(2999, 31, 12);
            update qLI;

            oli.Quote_Line_Item__c = qLI.id;
            update oli;
        }
    }

    /**
    *    @author Enrique Reyes
    *    @date   09-22-2023
    *    @description Test Opportunity: Populate Territory Id After Insert Flow   
    */
    @isTest
    static void testOpportunityPopulateTerritoryIdAfterInsertFlow()
    {
        Account soldToAccount = getAccountByName(TEST1);
        Account ultimateConsigneeAccount = getAccountByName(ULTIMATE_CONSIGNEE);

        List<Territory2Model> lstModels =
            [SELECT Id, Name, (SELECT Id, Name FROM Territory2s WHERE Territory2Type.DeveloperName = 'Territory')
             FROM Territory2Model
             WHERE State = 'Active'];

        Territory2Model objTerritoryModel = lstModels.get(0);

        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);

        //Insert Object2TerritoryAssociation
        ObjectTerritory2Association objTerritoryAssociation = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,ultimateConsigneeAccount.id);
        insert objTerritoryAssociation;

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for(Integer i = 0; i<50; i++){
            Opportunity newOpportunity = TestDataOpportunity.initOpportunity(soldToAccount,Label.OpportunityRTIndirectStandard);
            newOpportunity.Name = 'Flow Account '+i;
            newOpportunity.Ultimate_Consignee__c = ultimateConsigneeAccount.Id;
            opportunitiesToInsert.add(newOpportunity);
        }

        Test.startTest();
        Database.SaveResult[] insertResults = Database.insert(opportunitiesToInsert, false);
        Test.stopTest();
        Boolean insertError = false;
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                insertError = true;
            }
        }

        Assert.isFalse(insertError, 'All Opportunities should have been inserted successfully');
    }

    /**
    *    @author Enrique Reyes
    *    @date   09-22-2023
    *    @description Test Opportunity: Populate Territory Id After Update Flow   
    */
    @isTest
    static void testOpportunityPopulateTerritoryIdAfterUpdateFlow()
    {
        Account soldToAccount = getAccountByName(TEST1);
        Account ultimateConsigneeAccount1 = getAccountByName(DISTRIBUTOR_PARTNER);
        Account ultimateConsigneeAccount2 = getAccountByName(ULTIMATE_CONSIGNEE);

        List<Territory2Model> lstModels =
            [SELECT Id, Name, (SELECT Id, Name FROM Territory2s WHERE Territory2Type.DeveloperName = 'Territory')
             FROM Territory2Model
             WHERE State = 'Active'];

        Territory2Model objTerritoryModel = lstModels.get(0);

        Territory2 objTerritory = objTerritoryModel.Territory2s.get(0);
        Territory2 objTerritory2 = objTerritoryModel.Territory2s.get(1);

        //Insert Object2TerritoryAssociation
        ObjectTerritory2Association objTerritoryAssociation1 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory.Id,ultimateConsigneeAccount1.id);
        ObjectTerritory2Association objTerritoryAssociation2 = TestDataObjectTerritory2Association.getObjectAssociation(objTerritory2.Id,ultimateConsigneeAccount2.id);
        insert new List<ObjectTerritory2Association>{objTerritoryAssociation1, objTerritoryAssociation2};

        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        for(Integer i = 0; i<50; i++){
            Opportunity newOpportunity = TestDataOpportunity.initOpportunity(soldToAccount,Label.OpportunityRTIndirectStandard);
            newOpportunity.Name = 'Flow Account '+i;
            newOpportunity.Ultimate_Consignee__c = ultimateConsigneeAccount1.Id;
            opportunitiesToInsert.add(newOpportunity);
        }

        Database.SaveResult[] insertResults = Database.insert(opportunitiesToInsert, false);
        Boolean insertError = false;
        for (Database.SaveResult result : insertResults) {
            if (!result.isSuccess()) {
                insertError = true;
            }
        }

        Assert.isFalse(insertError, 'All Opportunities should have been inserted successfully');

        List<Opportunity> insertedOpportunities =
            [SELECT Id, Ultimate_Consignee__c
             FROM Opportunity
             WHERE AccountId =: soldToAccount.Id
             AND Ultimate_Consignee__c =: ultimateConsigneeAccount1.Id
             ORDER BY Name];

        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for(Opportunity opp : insertedOpportunities){
            //Assign other Ultimate Consignee
            opp.Ultimate_Consignee__c = ultimateConsigneeAccount2.Id;
            opportunitiesToUpdate.add(opp);
        }

        Test.startTest();
        Database.SaveResult[] updateResults = Database.update(opportunitiesToUpdate, false);
        Test.stopTest();
        Boolean updateError = false;
        for (Database.SaveResult result : updateResults) {
            if (!result.isSuccess()) {
                updateError = true;
            }
        }

        Assert.isFalse(updateError, 'All Opportunities should have been updated successfully');
    }

}