/**
*    @author Illumina
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Arif,Dalali                    28-Nov-2022         POL-57: Update APJ and EMEA References to AMEA and Europe respectively
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
private class TestTAPS_ApttusApprovalRequest {

    // NOTE: TestTAPS covers scenarios like new user, new territory, territory move
    // this is just to make sure we have coverage of the specific object trigger

    public final static String GROUP_CONTRACT_ADMIN_QUEUE = 'Contract Admin Queue';
    public static final string AMEA_USD_01 = '01-AMEA-USD'; //POL-57
    public static final string TEST_TXDR = 'Test TXDR';
    //Added for SonarQube Fixes
    public static final string COUNTRY_HK = 'Hong Kong';
    public final static String PROFILE_COMMERCIAL_REVENUE_OPERATIONS = 'Commercial and Revenue Operations';

    @testSetup static void setupEtmData()
    {
        setupTerritoryData();        
    }
    static void setupTerritoryData()
    {
        User objUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_ADMIN,new Set<Id>{UserInfo.getUserId()});
        System.runAs(objUser){
            TestTAPS.setupTerritoryData();
        }
    }

    // these methods do most of the object-specific work, modify all of them

    private static TAPS_ComposedBase mshareClass;
    private static TAPS_ComposedBase getShareClass()
    {
        if (mshareClass == null) mshareClass = new TAPS_ApttusApprovalRequest();
        return mshareClass;
    }

    private static void reparentRecord(Id recordId, Id newParentId)
    {
        // opportunity was created in this transaction, clear query cache for update
        OpportunitySelector.clearOpportunityCache();
        // Rahul: Added UC parameter to the below line for DCP-25384
        update new Opportunity(Id = recordId, AccountId = newParentId, Ultimate_Consignee__c = newParentId);
    }

    private static void createShareRecords(Id recordId, List<Id> userIds)
    {
        TAPS_ComposedBase shareClass = getShareClass();

        List<Apttus_Approval__Approval_Request__Share> shareRecords = new List<Apttus_Approval__Approval_Request__Share>();
        for (Id i : userIds)
            shareRecords.add((Apttus_Approval__Approval_Request__Share)shareClass.createSharingRecord(recordId, i));

        insert shareRecords;
    }

    @isTest static void objectType()
    {
        System.assertEquals(Apttus_Approval__Approval_Request__c.sObjectType, getShareClass().getObjectType());
    }

    // these methods are the tests, only the object creation need to be altered by class

    // inserting a record on an account associated to TERRITORY1
    // should add shares to the associated users
    @isTest static void createRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Approval__Approval_Request__c rec1;

        Test.startTest();
        {
            rec1 = TestDataProposal.getNewApprovalRequest(quote1.Id);
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));

        // also check record id conversion method
        Set<Id> recordIds = getShareClass().getRecordIdsFromAccountIdsCustom(new Set<Id>(accountIds));
        System.assert(recordIds.contains(rec1.Id), 'idsFromAccountIds: Did not successfully convert from account IDs to record IDs');
    }

    // moving a record from one account to another (and therefore from one territory to another)
    // should result in the old shares deleted and new shares added
    @isTest static void changeRecordParent()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Approval__Approval_Request__c rec1 = TestDataProposal.getNewApprovalRequest(quote1.Id);

        // get associated users
        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
        List<Id> usersOnA1 = new List<Id> { associatedUserIds.get(0), associatedUserIds.get(1) };
        List<Id> usersOnA2 = new List<Id> { associatedUserIds.get(2) };

        // manually create initial shares since since the trigger won't run the batch
        createShareRecords(rec1.Id, usersOnA1);

        // validate we start with shares to users aligned with a1
        System.assertEquals(2, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2));

        Test.startTest();
        {
            System.debug('hasRunTaps'+Opportunities.hasRunTaps);
            Opportunities.hasRunTaps = false;
            reparentRecord(o1.Id, accountIds.get(1));
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares now belong to users on a2
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA1));
        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, usersOnA2));
    }

    private static User getCommercialOpsUser(List<Id> exceptForIds)
    {
        List<User> recs = [SELECT Id, Name FROM User
            WHERE IsActive = true
            AND ProfileId IN :Profiles.getCommercialOpsQuotingUserProfileId()
            AND Id NOT IN :exceptForIds
            LIMIT 1
        ];
        return recs.get(0);
    }

    // moving a record from one owner to another will retrigger sharing via the platform event
    @isTest static void changeRecordOwner()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Approval__Approval_Request__c rec1 = TestDataProposal.getNewApprovalRequest(quote1.Id);

        // get associated users
        List<Id> associatedUserIds = TestTAPS.getAssociatedUserIds();
        Id userNotInTerritory = getCommercialOpsUser(associatedUserIds).Id;

        // validate we start with usersOnA2 out of the picture
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<Id> {userNotInTerritory}, new List<String> {'Approver'}));

        Test.startTest();
        {
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
System.debug('TTNz: old owner = ' + [SELECT Id, OwnerId FROM Apttus_Approval__Approval_Request__c WHERE Id = :rec1.Id]);
System.debug('TTNz: new owner = ' + userNotInTerritory);
            rec1.OwnerId = userNotInTerritory;
            update rec1;
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate new share created for usersOnA2
List<Apttus_Approval__Approval_Request__Share> shares = [SELECT Id, RowCause, UserOrGroupId FROM Apttus_Approval__Approval_Request__Share WHERE ParentId = :rec1.Id];
System.debug('TTNz: share count ' + shares.size());
for (Apttus_Approval__Approval_Request__Share s : shares)
    System.debug('TTNz: share' + s);
//        System.assertEquals(1, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id, new List<Id> {userNotInTerritory}, new List<String> {'Approver'}));
    }

    // inserting a record with no account, shouldn't bomb
    @isTest static void createOrphanRecord()
    {
        // parent records
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;

        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        // add record
        Apttus_Approval__Approval_Request__c rec1;

        Test.startTest();
        {
            rec1 = TestDataProposal.initApprovalRequest(quote1.Id);
            rec1.Apttus_QPApprov__ProposalId__c = null;
            insert rec1;
            // Added by Satya as part of PRB0042764 
            TestTAPS.objectBeingTested = getShareClass().getObjectType();
            Test.getEventBus().deliver();
        }
        Test.stopTest();

        // validate shares were added by batch
        System.assertEquals(0, TestTAPS.getShareRecordCount(getShareClass(), rec1.Id));
    }

    /**
    *  @author Satya Swain
    *  @description test creation of parent quotation shares on Creation of Approval Request for INC0253701
    *  @param none
    *  @return void
    **/
    @isTest
    static void testCreateParentQuotationShares(){
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        Apttus_Approval__Approval_Request__c rec1,rec2;

        User objUser = getCommercialOpsUser(new List<Id>());
        Group objGroup = [Select Id from Group where Name = :GROUP_CONTRACT_ADMIN_QUEUE];

        Test.startTest();
        
        rec1 = TestDataProposal.initApprovalRequest(quote1.Id);
        rec1.Apttus_Approval__Assigned_To_Id__c = objUser.Id;
        rec1.Apttus_Approval__Assigned_To_Name__c = objUser.Name;
        rec1.Apttus_Approval__ObjectRefId__c = quote1.Id;
        rec1.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_USER;
        rec1.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_QUOTATION;

        rec2 = TestDataProposal.initApprovalRequest(quote1.Id);
        rec2.Apttus_Approval__Assigned_To_Id__c = objGroup.Id;
        rec2.Apttus_Approval__Assigned_To_Name__c = GROUP_CONTRACT_ADMIN_QUEUE;
        rec2.Apttus_Approval__ObjectRefId__c = quote1.Id;
        rec2.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_QUEUE;
        rec2.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_QUOTATION;
        
        insert new List<Apttus_Approval__Approval_Request__c>{rec1,rec2};
        Test.getEventBus().deliver();
        
        Test.stopTest();
        
        List<Apttus_Proposal__Proposal__Share> lstProposalShare = [Select Id, ParentId, UserOrGroupId,RowCause from Apttus_Proposal__Proposal__Share where ParentId = :quote1.Id AND (UserOrGroupId = :objUser.Id OR UserOrGroupId = :objGroup.Id)];
        for(Apttus_Proposal__Proposal__Share objShare : lstProposalShare)
        {
            System.assertEquals(Schema.Apttus_Proposal__Proposal__Share.RowCause.Approver__c,objShare.RowCause); //Indicating that parent share got created having new Manual Sharing Reason
        }    
        System.assertEquals(1,lstProposalShare.size());
    }

    /**
    *  @author Satya Swain
    *  @description test deletion of parent quotation shares on deletion of Approval Request for INC0253701
    *  @param none
    *  @return void
    **/
    @isTest
    static void testDeleteParentQuotationShares(){
        List<Id> accountIds = TestTAPS.createParentAccounts();
        Opportunity o1 = TestDataOpportunity.getNewOpportunity2(accountIds.get(0));
        Apttus_Config2__PriceList__c priceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert priceList;
        Apttus_Proposal__Proposal__c quote1 = TestDataProposal.initProposal(accountIds.get(0), o1.Id, 'Test Proposal', priceList.Id, true, 'Draft', 'None');
        insert quote1;

        Apttus_Approval__Approval_Request__c rec1,rec2;

        User objUser = TestDataUser.findUserInProfile(PROFILE_COMMERCIAL_REVENUE_OPERATIONS);
        Group objGroup = [Select Id from Group where Name = :GROUP_CONTRACT_ADMIN_QUEUE];
        
        rec1 = TestDataProposal.initApprovalRequest(quote1.Id);
        rec1.Apttus_Approval__Assigned_To_Id__c = objUser.Id;
        rec1.Apttus_Approval__Assigned_To_Name__c = objUser.Name;
        rec1.Apttus_Approval__ObjectRefId__c = quote1.Id;
        rec1.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_USER;
        rec1.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_QUOTATION;

        rec2 = TestDataProposal.initApprovalRequest(quote1.Id);
        rec2.Apttus_Approval__Assigned_To_Id__c = objGroup.Id;
        rec2.Apttus_Approval__Assigned_To_Name__c = GROUP_CONTRACT_ADMIN_QUEUE;
        rec2.Apttus_Approval__ObjectRefId__c = quote1.Id;
        rec2.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_QUEUE;
        rec2.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_QUOTATION;

        insert new List<Apttus_Approval__Approval_Request__c>{rec1,rec2};
        Test.getEventBus().deliver();

        Test.startTest();
        delete rec1;
        Test.getEventBus().deliver();
        Test.stopTest();

        List<Apttus_Proposal__Proposal__Share> lstProposalShare2 = [Select Id, ParentId, UserOrGroupId,RowCause from Apttus_Proposal__Proposal__Share where ParentId = :quote1.Id AND (UserOrGroupId = :objUser.Id OR UserOrGroupId = :objGroup.Id) AND RowCause=:Schema.Apttus_Proposal__Proposal__Share.RowCause.Approver__c];
        System.assertEquals(true, lstProposalShare2.isEmpty()); //indicating that parent quotation share also got deleted upon Approval Request deletion
    }

    /**
    *  @author Satya Swain
    *  @description test creation of parent agreement shares on Creation of Approval Request for INC0253701
    *  @param none
    *  @return void
    **/
    @isTest
    static void testCreateParentAgreementShares()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BillingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        acc2.BillingCountryCode='HK' ;
        insert new List<Account> { acc, acc2 };
        
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
    
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c=COUNTRY_HK,Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c=COUNTRY_HK,Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
    
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c=Test_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';
    
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = 'TXDR';
        acc2SalesArea.Sales_Organization__c='AU01';
        acc2SalesArea.Price_Group_Description__c=Test_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';
    
        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = 'TXDR';
        acc3SalesArea.Sales_Organization__c='HK01';
        acc3SalesArea.Price_Group_Description__c=Test_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';
    
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea  };
    
        Id userId = UserInfo.getProfileId();
        
        insert new CLM_ProfileValidation__c(
            SetupOwnerId = userId,
            Channel_Partner_Agreement__c = true,
            Master_Customer_Agreement__c = true,
            Master_Service_Agreement__c = true,
            Negotiated_Terms_and_Conditions__c = true,
            Standing_Quote__c = true,
            Tender__c = true);
    
        Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
    
        Apttus__APTS_Agreement__c objAgreement = new Apttus__APTS_Agreement__c(
            Name = 'Test Agreement',
            Apttus__Account__c  = acc.Id,
            Apttus__Contract_Start_Date__c = system.today(),
            Apttus__Auto_Renewal__c=True, 
            Sales_Org__c ='HK01',
            RecordTypeId = recTypeChannelPartner
        );

        Apttus_Approval__Approval_Request__c rec1, rec2;
        
        User objUser = getCommercialOpsUser(new List<Id>());
        Group objGroup = [Select Id from Group where Name = :GROUP_CONTRACT_ADMIN_QUEUE];

        Test.startTest();
        rec1 = TestDataProposal.initApprovalRequest(objAgreement.Id);
        rec1.Apttus_Approval__Assigned_To_Id__c = objUser.Id;
        rec1.Apttus_Approval__Assigned_To_Name__c = objUser.Name;
        rec1.Apttus_Approval__ObjectRefId__c = objAgreement.Id;
        rec1.Apttus_QPApprov__ProposalId__c = NULL;
        rec1.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_USER;
        rec1.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_AGREEMENT;

        rec2 = TestDataProposal.initApprovalRequest(objAgreement.Id);
        rec2.Apttus_Approval__Assigned_To_Id__c = objGroup.Id;
        rec2.Apttus_Approval__Assigned_To_Name__c = GROUP_CONTRACT_ADMIN_QUEUE;
        rec2.Apttus_Approval__ObjectRefId__c = objAgreement.Id;
        rec2.Apttus_QPApprov__ProposalId__c = NULL;
        rec2.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_QUEUE;
        rec2.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_AGREEMENT;
        
        insert new List<Apttus_Approval__Approval_Request__c>{rec1,rec2};
        //Test.getEventBus().deliver();
        Test.stopTest();
        
        List<Apttus__APTS_Agreement__Share> lstAgreementShare = [Select Id, ParentId, UserOrGroupId, RowCause from Apttus__APTS_Agreement__Share where ParentId = :objAgreement.Id AND (UserOrGroupId = :objUser.Id OR UserOrGroupId = :objGroup.Id)];
        for(Apttus__APTS_Agreement__Share objShare : lstAgreementShare)
        {
            System.assertEquals(Schema.Apttus__APTS_Agreement__Share.RowCause.Approver__c,objShare.RowCause); //Indicating that parent share got created having new Manual Sharing Reason
        }
    }

    /**
    *  @author Satya Swain
    *  @description test deletion of parent agreement shares on deletion of Approval Request for INC0253701
    *  @param none
    *  @return void
    **/
    @isTest
    static void testDeleteParentAgreementShares()
    {
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';
        acc.Name = 'distributor Account';
        acc.BillingCountryCode='HK';
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '234567';
        acc2.BillingCountryCode='HK' ;
        insert new List<Account> { acc, acc2 };
        
        Contact con = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        insert new List<Contact> { con, con2 };
    
        Customer_Master_Data__c objCMD1 = new Customer_Master_Data__c(Name='CMD1',Country__c=COUNTRY_HK,Country_Code__c='HK'),
                                objCMD2 = new Customer_Master_Data__c(Name='CMD2',Country__c=COUNTRY_HK,Country_Code__c='HK');
        objCMD1.ERP_Customer_Id__c = '123456';
        objCMD2.ERP_Customer_Id__c = '234567';
        insert new List<Customer_Master_Data__c> {objCMD1, objCMD2};
    
        Account_Sales_Area__c acc1SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '01', '178', '00', false);
        acc1SalesArea.Account__c = acc.Id;
        acc1SalesArea.Price_List_Type__c = '06';
        acc1SalesArea.CurrencyIsoCode = 'USD';
        acc1SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc1SalesArea.Contract_Number__c = '123456_HK010100';
        acc1SalesArea.Price_Group__c = 'TXDR';
        acc1SalesArea.Sales_Organization__c='HK01';
        acc1SalesArea.Price_Group_Description__c=Test_TXDR;
        acc1SalesArea.Distribution_Channel__c='01';
    
        Account_Sales_Area__c acc2SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc2SalesArea.Account__c = acc2.Id;
        acc2SalesArea.Price_List_Type__c = '06';
        acc2SalesArea.CurrencyIsoCode = 'USD';
        acc2SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc2SalesArea.Contract_Number__c ='567890_US010100';
        acc2SalesArea.Price_Group__c = 'TXDR';
        acc2SalesArea.Sales_Organization__c='AU01';
        acc2SalesArea.Price_Group_Description__c=Test_TXDR;
        acc2SalesArea.Distribution_Channel__c='01';
    
        Account_Sales_Area__c acc3SalesArea = TestDataAccountSalesArea.getAccountSalesArea('HK01', '02', '179', '00', false);
        acc3SalesArea.Account__c = acc2.Id;
        acc3SalesArea.Price_List_Type__c = '06';
        acc3SalesArea.CurrencyIsoCode = 'USD';
        acc3SalesArea.Price_List__c = AMEA_USD_01; //POL-57
        acc3SalesArea.Contract_Number__c ='67890_HK010100';
        acc3SalesArea.Price_Group__c = 'TXDR';
        acc3SalesArea.Sales_Organization__c='HK01';
        acc3SalesArea.Price_Group_Description__c=Test_TXDR;
        acc3SalesArea.Distribution_Channel__c='01';
        acc3SalesArea.ERP_Account_Sales_Area_Id__c='67890_HK010100';
    
        insert new List<Account_Sales_Area__c>{ acc1SalesArea, acc2SalesArea,acc3SalesArea  };
    
        Id userId = UserInfo.getProfileId();
        
        insert new CLM_ProfileValidation__c(
            SetupOwnerId = userId,
            Channel_Partner_Agreement__c = true,
            Master_Customer_Agreement__c = true,
            Master_Service_Agreement__c = true,
            Negotiated_Terms_and_Conditions__c = true,
            Standing_Quote__c = true,
            Tender__c = true);
    
        Id recTypeChannelPartner = Schema.SObjectType.Apttus__APTS_Agreement__c.getRecordTypeInfosByName().get('Channel Partner Agreement').getRecordTypeId();
    
        Apttus__APTS_Agreement__c objAgreement = new Apttus__APTS_Agreement__c(
            Name = 'Test Agreement',
            Apttus__Account__c  = acc.Id,
            Apttus__Contract_Start_Date__c = system.today(),
            Apttus__Auto_Renewal__c=True, 
            Sales_Org__c ='HK01',
            RecordTypeId = recTypeChannelPartner
        );
        insert objAgreement;

        Apttus_Approval__Approval_Request__c rec1, rec2;
        
        User objUser = TestDataUser.findUserInProfile(PROFILE_COMMERCIAL_REVENUE_OPERATIONS);
        Group objGroup = [Select Id from Group where Name = :GROUP_CONTRACT_ADMIN_QUEUE];

        rec1 = TestDataProposal.initApprovalRequest(objAgreement.Id);
        rec1.Apttus_Approval__Assigned_To_Id__c = objUser.Id;
        rec1.Apttus_Approval__Assigned_To_Name__c = objUser.Name;
        rec1.Apttus_Approval__ObjectRefId__c = objAgreement.Id;
        rec1.Apttus_QPApprov__ProposalId__c = NULL;
        rec1.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_USER;
        rec1.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_AGREEMENT;

        rec2 = TestDataProposal.initApprovalRequest(objAgreement.Id);
        rec2.Apttus_Approval__Assigned_To_Id__c = objGroup.Id;
        rec2.Apttus_Approval__Assigned_To_Name__c = GROUP_CONTRACT_ADMIN_QUEUE;
        rec2.Apttus_Approval__ObjectRefId__c = objAgreement.Id;
        rec2.Apttus_QPApprov__ProposalId__c = NULL;
        rec2.Apttus_Approval__Assigned_To_Type__c = ApttusApprovalRequests.ASSIGNED_TO_TYPE_QUEUE;
        rec2.Apttus_Approval__Object_Type__c = ApttusApprovalRequests.OBJECT_TYPE_AGREEMENT;

        insert new List<Apttus_Approval__Approval_Request__c>{rec1,rec2};
        Test.getEventBus().deliver();

        Test.startTest();
        
        delete rec1;
        Test.getEventBus().deliver();
        
        Test.stopTest();

        List<Apttus__APTS_Agreement__Share> lstAgreementShare2 = [Select Id, ParentId, UserOrGroupId, RowCause from Apttus__APTS_Agreement__Share where ParentId = :objAgreement.Id AND (UserOrGroupId = :objUser.Id OR UserOrGroupId = :objGroup.Id) AND RowCause=:Schema.Apttus__APTS_Agreement__Share.RowCause.Approver__c];
        System.assertEquals(true, lstAgreementShare2.isEmpty()); //indicating that parent agreement share also got deleted upon Approval Request deletion
    }

}