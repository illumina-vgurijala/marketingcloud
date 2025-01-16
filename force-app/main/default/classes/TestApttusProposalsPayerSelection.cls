/**
* 
*
* @desc TestApttusProposalsPayerSelection [CodeScan Fix]
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy              11-Jan-2023         Codescan Fix for Removing Unused Methods
*    ---------------------------------------------------------------------------------------------------------------------------
**/

@isTest(isParallel=true)
private class TestApttusProposalsPayerSelection {

    private static final String SOLD_TO_NAME = 'Sold To Account 1';
    private static final String BILL_TO_NAME_1 = 'Bill To Account 1';
    private static final String BILL_TO_NAME_2 = 'Bill To Account 2';
    private static final String BILL_TO_NAME_3 = 'Bill To Account 3';

    private static final String SALES_ORG = 'BR01';
    private static final String CURRENCY_CODE = 'BRL';
    private static final String COUNTRY_CODE = 'BR';
    // price list type/name for BR01
    private static final String PRICELIST_NAME = '10-BRL-BRL';

    @testSetup
    /**
    * 
    *
    * @desc setupData [CodeScan Fix]
    */
    public static void setupData()
    {
        List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = new List<TestBundleCustomersStructure.CustomerDefinition> {
            new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_SOLD_TO, CURRENCY_CODE, COUNTRY_CODE),
            new TestBundleCustomersStructure.CustomerDefinition(CustomerMasterDatas.GROUP_BILL_TO, CURRENCY_CODE, COUNTRY_CODE),
            new TestBundleCustomersStructure.CustomerDefinition(CustomerMasterDatas.GROUP_BILL_TO, CURRENCY_CODE, COUNTRY_CODE),
            new TestBundleCustomersStructure.CustomerDefinition(CustomerMasterDatas.GROUP_BILL_TO, CURRENCY_CODE, COUNTRY_CODE)
        };
        
        List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs = new List<TestBundleCustomersStructure.SalesAreaDefinition> {
            new TestBundleCustomersStructure.SalesAreaDefinition(SALES_ORG, '01', '00')
        };

        List<TestBundleCustomersStructure.ExtraRelationshipDefinition> extraRels = new List<TestBundleCustomersStructure.ExtraRelationshipDefinition> {
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {SALES_ORG}, CustomerMasterDatas.GROUP_BILL_TO, false),
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {SALES_ORG}, CustomerMasterDatas.GROUP_PAYER, false),
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(3, 1, new Set<String> {SALES_ORG}, CustomerMasterDatas.GROUP_BILL_TO, false),
            new TestBundleCustomersStructure.ExtraRelationshipDefinition(3, 1, new Set<String> {SALES_ORG}, CustomerMasterDatas.GROUP_PAYER, false)
        };

        TestBundleCustomers bundleMaker = new TestBundleCustomers(customerDefinitions, salesAreaDefs, extraRels);
        Map<String, List<SObject>> customerBundle = bundleMaker.getBundle();

        // set names for easy finding
        customerBundle.get('Account').get(0).put('Name', SOLD_TO_NAME);
        customerBundle.get('Customer_Master_Data__c').get(0).put('Name', SOLD_TO_NAME);
        customerBundle.get('Customer_Master_Data__c').get(1).put('Name', BILL_TO_NAME_1);
        customerBundle.get('Customer_Master_Data__c').get(2).put('Name', BILL_TO_NAME_2);
        customerBundle.get('Customer_Master_Data__c').get(3).put('Name', BILL_TO_NAME_3);

        bundleMaker.insertBundle(customerBundle);

        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList(PRICELIST_NAME);
        insert objPriceList;
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

    private static Account getSoldTo1()
    {
        return getAccountByName(SOLD_TO_NAME);
    }

    private static List<Customer_Master_Data__c> allCMDs;
    private static List<Customer_Master_Data__c> getCMDs()
    {
        if (allCMDs == null)
        {
            allCMDs = [SELECT Id, Name, ERP_Customer_Id__c FROM Customer_Master_Data__c];
        }

        return allCMDs;
    }

    private static Customer_Master_Data__c getCMDByName(String n)
    {
        for (Customer_Master_Data__c rec : getCMDs())
        {
            if (rec.Name == n) return rec;
        }

        return null;
    }

    private static Customer_Master_Data__c getSoldToCMD1()
    {
        return getCMDByName(SOLD_TO_NAME);
    }

    private static Customer_Master_Data__c getBillToCMD1()
    {
        return getCMDByName(BILL_TO_NAME_1);
    }

    private static Customer_Master_Data__c getBillToCMD2()
    {
        return getCMDByName(BILL_TO_NAME_2);
    }

    private static Apttus_Proposal__Proposal__c generateQuote(Account soldTo)
    {
        Apttus_Config2__PriceList__c objPriceList = [SELECT Id, Name FROM Apttus_Config2__PriceList__c WHERE Name = :PRICELIST_NAME];

        Opportunity objOpp = TestDataOpportunity.initOpportunity(soldTo);
        objOpp.Price_List__c = PRICELIST_NAME;
        insert objOpp;

        Apttus_Proposal__Proposal__c objQuote = TestDataProposal.initProposal(
            objOpp.AccountId, objOpp.id, 'Test Proposal 1', objPriceList.Id, true, 'Draft', 'None'
        );
        objQuote.Is_Updated_By_System__c = false;

        return objQuote;
    }

    private static void selectBillTo(Apttus_Proposal__Proposal__c objQuote, String selectedErpKey)
    {
        // user selects the sold to as the bill to
        String strJSON = CustomerMasterDataSelectionController.loadPage(objQuote.Id, Label.AccountRelationshipBillTo);

        List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper> lstDirect = (List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>)
            JSON.deserialize(UtilsObject.getJSONPart(strJSON, '{"lstDirect": ', ',"mapLabels": '),
            List<CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper>.class
        );

        // find the selection
        Integer selectedIndex = 0;
        for (Integer i = 0; i < lstDirect.size(); i++)
        {
            CustomerMasterDataSelectionController.CustomerMasterDataSelectionWrapper customerChoice = lstDirect.get(i);
            if (customerChoice.strERP == selectedErpKey)
                selectedIndex = i;
        }

        String strSalesArea = (String)JSON.deserialize(UtilsObject.getJSONPart(strJSON, ',"strSalesArea": ', '}'), String.class);

        strJSON = CustomerMasterDataSelectionController.saveSelection(JSON.serialize(objQuote), JSON.serialize(lstDirect[selectedIndex]),JSON.serialize(lstDirect[selectedIndex]), Label.AccountRelationshipBillTo, true, strSalesArea);
        System.assertEquals('Success', strJSON);
    }

    // Convert the sold to account to a distributor account
    // this requires updates to 3 records
    private static void soldToNowDistributor()
    {
        // first account
        Account soldTo = getSoldTo1();
        soldTo.Account_Group__c = Accounts.GROUP_DISTRIBUTOR;
        update soldTo;

        // first CMD
        Customer_Master_Data__c soldToCMD = getSoldToCMD1();
        soldToCMD.Account_Group__c = Accounts.GROUP_DISTRIBUTOR;
        update soldToCMD;

        // first (and only) self-relationship
        Account_Relationship__c rel = [
            SELECT Id, Relationship__c, ERP_Account_Relationship_Id__c
            FROM Account_Relationship__c
            WHERE Relationship__c = :Accounts.GROUP_SOLD_TO
        ].get(0);
        rel.Relationship__c = Accounts.GROUP_DISTRIBUTOR;
        rel.ERP_Account_Relationship_Id__c = rel.ERP_Account_Relationship_Id__c.replace(Accounts.GROUP_SOLD_TO, Accounts.GROUP_DISTRIBUTOR);
        update rel;
    }

    /**
    * 
    *
    * @desc billToAndPayerOnlyFromDistributor [CodeScan Fix]
    */
    @isTest
    public static void billToAndPayerOnlyFromDistributor()
    {
        soldToNowDistributor();

        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c soldToCMD = getSoldToCMD1();

        // invalidate relationships for this test
        // all bill to/payer except the sold to
        List<Account_Relationship__c> rels = [
            SELECT Id, IsInactive__c, Default_Partner__c, ERP_Customer_Id__c, Related_ERP_Customer_Id__c, Relationship__c
            FROM Account_Relationship__c
            WHERE Relationship__c IN (:CustomerMasterDatas.GROUP_BILL_TO, :CustomerMasterDatas.GROUP_PAYER)
        ];
        for (Account_Relationship__c r : rels)
        {
            if (r.ERP_Customer_Id__c == soldToCMD.ERP_Customer_Id__c
             && r.Related_ERP_Customer_Id__c != soldToCMD.ERP_Customer_Id__c
            ) {
                r.IsInactive__c = true;
            }
        }
        update rels;

        Test.startTest();
        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;
        Test.stopTest();

        // validate sold to auto-selected as bill to/payer since it's the only bill to
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(soldToCMD.Id, objInsertedQuote.Bill_To__c);
        System.assertEquals(soldToCMD.Id, objInsertedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc userSelectsDistributor1 [CodeScan Fix]
    */
    @isTest
    public static void userSelectsDistributor1()
    {
        soldToNowDistributor();

        // retrieve data from setup
        Account distributor = getSoldTo1();
        Customer_Master_Data__c distributorCMD = getSoldToCMD1();

        // invalidate relationships for this test
        // all payers except the sold to
        List<Account_Relationship__c> rels = [
            SELECT Id, IsInactive__c, Default_Partner__c, ERP_Customer_Id__c, Related_ERP_Customer_Id__c, Relationship__c
            FROM Account_Relationship__c
            WHERE Relationship__c IN (:CustomerMasterDatas.GROUP_PAYER)
        ];
        for (Account_Relationship__c r : rels)
        {
            if (r.ERP_Customer_Id__c == distributorCMD.ERP_Customer_Id__c
             && r.Related_ERP_Customer_Id__c != distributorCMD.ERP_Customer_Id__c
            ) {
                r.IsInactive__c = true;
            }
        }
        update rels;

        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(distributor);
        insert objQuote;

        // validate no bill to/payer were auto-selected because there are 3 bill tos
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(distributor.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(null, objInsertedQuote.Bill_To__c);
        System.assertEquals(null, objInsertedQuote.Payer__c);

        Test.startTest();
        selectBillTo(objQuote, distributorCMD.ERP_Customer_Id__c);
        Test.stopTest();

        // confirm the bill to selection also populates the payer
        Apttus_Proposal__Proposal__c objUpdatedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(distributor.Id, objUpdatedQuote.Apttus_Proposal__Account__c);
        // no assert on bill to, that gets set by the user's click which we didn't simulate
        System.assertEquals(distributorCMD.Id, objUpdatedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc billToAndPayerOnlyFromSoldTo [CodeScan Fix]
    */
    @isTest
    public static void billToAndPayerOnlyFromSoldTo()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c soldToCMD = getSoldToCMD1();

        // invalidate relationships for this test
        // all bill to/payer except the sold to
        List<Account_Relationship__c> rels = [
            SELECT Id, IsInactive__c, Default_Partner__c, ERP_Customer_Id__c, Related_ERP_Customer_Id__c, Relationship__c
            FROM Account_Relationship__c
            WHERE Relationship__c IN (:CustomerMasterDatas.GROUP_BILL_TO, :CustomerMasterDatas.GROUP_PAYER)
        ];
        for (Account_Relationship__c r : rels)
        {
            if (r.ERP_Customer_Id__c == soldToCMD.ERP_Customer_Id__c
             && r.Related_ERP_Customer_Id__c != soldToCMD.ERP_Customer_Id__c
            ) {
                r.IsInactive__c = true;
            }
        }
        update rels;

        Test.startTest();
        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;
        Test.stopTest();

        // validate sold to auto-selected as bill to/payer since it's the only bill to
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(soldToCMD.Id, objInsertedQuote.Bill_To__c);
        System.assertEquals(soldToCMD.Id, objInsertedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc userSelectsSoldTo1 [CodeScan Fix]
    */
    @isTest
    public static void userSelectsSoldTo1()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c soldToCMD = getSoldToCMD1();

        // invalidate relationships for this test
        // all payers except the sold to
        List<Account_Relationship__c> rels = [
            SELECT Id, IsInactive__c, Default_Partner__c, ERP_Customer_Id__c, Related_ERP_Customer_Id__c, Relationship__c
            FROM Account_Relationship__c
            WHERE Relationship__c IN (:CustomerMasterDatas.GROUP_PAYER)
        ];
        for (Account_Relationship__c r : rels)
        {
            if (r.ERP_Customer_Id__c == soldToCMD.ERP_Customer_Id__c
             && r.Related_ERP_Customer_Id__c != soldToCMD.ERP_Customer_Id__c
            ) {
                r.IsInactive__c = true;
            }
        }
        update rels;

        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;

        // validate no bill to/payer were auto-selected because there are 3 bill tos
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(null, objInsertedQuote.Bill_To__c);
        System.assertEquals(null, objInsertedQuote.Payer__c);

        Test.startTest();
        selectBillTo(objQuote, soldToCMD.ERP_Customer_Id__c);
        Test.stopTest();

        // confirm the bill to selection also populates the payer
        Apttus_Proposal__Proposal__c objUpdatedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objUpdatedQuote.Apttus_Proposal__Account__c);
        // no assert on bill to, that gets set by the user's click which we didn't simulate
        System.assertEquals(soldToCMD.Id, objUpdatedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc soldToIsDefaultBillTo [CodeScan Fix]
    */
    @isTest
    public static void soldToIsDefaultBillTo()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c soldToCMD = getSoldToCMD1();

        // update relationships for this test
        // make bill to rel the default (the one itself the sold to)
        List<Account_Relationship__c> rels = [
            SELECT Id, IsInactive__c, Default_Partner__c, ERP_Customer_Id__c, Related_ERP_Customer_Id__c, Relationship__c
            FROM Account_Relationship__c
            WHERE Relationship__c IN (:CustomerMasterDatas.GROUP_BILL_TO)
        ];
        for (Account_Relationship__c r : rels)
        {
            if (r.ERP_Customer_Id__c == r.Related_ERP_Customer_Id__c
             && r.Related_ERP_Customer_Id__c == soldToCMD.ERP_Customer_Id__c)
            {
                r.Default_Partner__c = true;
            }
        }
        update rels;

        Test.startTest();
        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;
        Test.stopTest();

        // validate sold to auto-selected as bill to/payer since it's the default
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);

        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(soldToCMD.Id, objInsertedQuote.Bill_To__c);
        System.assertEquals(soldToCMD.Id, objInsertedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc defaultBillToSet [CodeScan Fix]
    */
    @isTest
    public static void defaultBillToSet()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c billToCMD1 = getBillToCMD1();

        // update relationships for this test
        // make a bill to rel the default (not sold to, a different bill to)
        List<Account_Relationship__c> rels = [
            SELECT Id, IsInactive__c, Default_Partner__c, ERP_Customer_Id__c, Related_ERP_Customer_Id__c, Relationship__c
            FROM Account_Relationship__c
            WHERE Relationship__c IN (:CustomerMasterDatas.GROUP_BILL_TO)
        ];
        for (Account_Relationship__c r : rels)
        {
            if (r.ERP_Customer_Id__c != r.Related_ERP_Customer_Id__c
             && r.Related_ERP_Customer_Id__c == billToCMD1.ERP_Customer_Id__c
            ) {
                r.Default_Partner__c = true;
            }
        }
        update rels;

        Test.startTest();
        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;
        Test.stopTest();

        // validate default bill to auto-selected as bill to/payer
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(billToCMD1.Id, objInsertedQuote.Bill_To__c);
        System.assertEquals(billToCMD1.Id, objInsertedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc userSelectsSoldTo2 [CodeScan Fix]
    */
    @isTest
    public static void userSelectsSoldTo2()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c soldToCMD = getSoldToCMD1();

        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;

        // validate no bill to/payer were auto-selected because there are 3 bill tos
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(null, objInsertedQuote.Bill_To__c);
        System.assertEquals(null, objInsertedQuote.Payer__c);

        Test.startTest();
        selectBillTo(objQuote, soldToCMD.ERP_Customer_Id__c);
        Test.stopTest();

        // confirm the bill to selection also populates the payer
        Apttus_Proposal__Proposal__c objUpdatedQuote =
            [SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objUpdatedQuote.Apttus_Proposal__Account__c);
        // no assert on bill to, that gets set by the user's click which we didn't simulate
        System.assertEquals(soldToCMD.Id, objUpdatedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc userSelectsBillTo [CodeScan Fix]
    */
    @isTest
    public static void userSelectsBillTo()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c billToCMD2 = getBillToCMD2();

        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;

        // validate no bill to/payer were auto-selected because there are 3 bill tos
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(null, objInsertedQuote.Bill_To__c);
        System.assertEquals(null, objInsertedQuote.Payer__c);

        Test.startTest();
        selectBillTo(objQuote, billToCMD2.ERP_Customer_Id__c);
        Test.stopTest();

        // confirm the bill to selection also populates the payer
        Apttus_Proposal__Proposal__c objUpdatedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objUpdatedQuote.Apttus_Proposal__Account__c);
        // no assert on bill to, that gets set by the user's click which we didn't simulate
        System.assertEquals(billToCMD2.Id, objUpdatedQuote.Payer__c);
    }

    /**
    * 
    *
    * @desc userSelectsUnrelatedBillTo [CodeScan Fix]
    */
    @isTest
    public static void userSelectsUnrelatedBillTo()
    {
        // retrieve data from setup
        Account soldTo = getSoldTo1();
        Customer_Master_Data__c getBillToCMD3 = getSoldToCMD1();

        // create oppt/quote
        Apttus_Proposal__Proposal__c objQuote = generateQuote(soldTo);
        insert objQuote;

        // validate no bill to/payer were auto-selected because there are 3 bill tos
        Apttus_Proposal__Proposal__c objInsertedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objInsertedQuote.Apttus_Proposal__Account__c);
        System.assertEquals(null, objInsertedQuote.Bill_To__c);
        System.assertEquals(null, objInsertedQuote.Payer__c);

        Test.startTest();
        selectBillTo(objQuote, getBillToCMD3.ERP_Customer_Id__c);
        Test.stopTest();

        // confirm the bill to selection also populates the payer
        Apttus_Proposal__Proposal__c objUpdatedQuote = [
            SELECT Id, Apttus_Proposal__Account__c, Bill_To__c, Ship_To__c, Payer__c
            FROM Apttus_Proposal__Proposal__c
            WHERE Id = :objQuote.Id
        ].get(0);
        System.assertEquals(soldTo.Id, objUpdatedQuote.Apttus_Proposal__Account__c);
        // no assert on bill to, that gets set by the user's click which we didn't simulate
        System.assertEquals(getBillToCMD3.Id, objUpdatedQuote.Payer__c);
    }

}