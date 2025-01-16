/**
* 
*
* @description TestBundleCustomers [CodeScan Fix]
*/
public with sharing class TestBundleCustomers {

    public static final String LOG_TITLE = 'TESTBUNDLE Customer';
    public static final String SALES_ORG_ACCOUNT = 'Account';
    public static final String SALES_ORG_CMDATA = 'Customer_Master_Data__c';
    public static final String SALES_ORG_ACCSALESAREA = 'Account_Sales_Area__c';
    public static final String SALES_ORG_ACCRELATIONSHIP = 'Account_Relationship__c';
    public static final String SALES_ILIBMESSAGE = 'Generated ';

/*
INSTRUCTIONS

See the example script below to construct your request.  For now you'll need to make two method calls to get your bundle.
(We could add a single method that covers it all if the sugar is worth it)

First the constructor requires all the parameters which will be used to create the bundle.
Then getBundle() instantiates all of the objects in memory.
Finally, insertBundle() persists all the objects.  The lookups are populated in this method as IDs of parent objects become available.

INPUTS
List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = the list of customers that will be created.  These customers will be created as accounts and/or customer master data as appropriate
String currencyCode = the currency used for the transaction
List<SalesAreaDefinition> salesAreaDefs = which sales areas will be created for (all of the) customers
List<ExtraRelationshipDefinition> extraRels = relationships between the different customers.  Relationships for each single customer will be created automatically

OUTPUTS
The output is a map with the structure Map<String, List<SObject>>
The string is one of these four values: Account, Customer_Master_Data__c, Account_Sales_Area__c. and Account_Relationship__c
The lists will be in the order of accountGroups and salesAreaDefs
- For instance for accounts, there will be one account for each accountGroups which requires an account (i.e. yes for Sold To but not for Bill To)
- For CMD, there will be one CMD for each accountGroups
- When it comes to sales areas, there will be one of each salesAreaDefs for each CMD
- And for relationships, there will be the standard appropriate relationships auto-generated followed by the extraRels passed in

If the above bullets are confusing it's probably easiest to run the example script below and search the output for 'TESTBUNDLE Customer'
The last hit on that string will show you the output
*/

/*
//EXAMPLE CLIENT SCRIPT

List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions = new List<TestBundleCustomersStructure.CustomerDefinition> {
    new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_SOLD_TO, 'USD', 'US'),
    new TestBundleCustomersStructure.CustomerDefinition(CustomerMasterDatas.GROUP_BILL_TO, 'USD', 'US'),
    new TestBundleCustomersStructure.CustomerDefinition(Accounts.GROUP_ULTIMATE_CONSIGNEE, 'USD', 'US')
};

List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs = new List<TestBundleCustomersStructure.SalesAreaDefinition> {
    new TestBundleCustomersStructure.SalesAreaDefinition('US01', '01', '00')
};

List<TestBundleCustomersStructure.ExtraRelationshipDefinition> extraRels = new List<TestBundleCustomersStructure.ExtraRelationshipDefinition> {
    new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {'US01'}, CustomerMasterDatas.GROUP_BILL_TO, true),
    new TestBundleCustomersStructure.ExtraRelationshipDefinition(2, 1, new Set<String> {'US01'}, CustomerMasterDatas.GROUP_PAYER, true),
    new TestBundleCustomersStructure.ExtraRelationshipDefinition(3, 1, new Set<String> {'US01'}, Accounts.GROUP_ULTIMATE_CONSIGNEE, false)
};

TestBundleCustomers bundleMaker = new TestBundleCustomers(customerDefinitions, salesAreaDefs, extraRels);
Map<String, List<SObject>> customerBundle = bundleMaker.getBundle();
// NOTE: set your own values here... ex:
customerBundle.get('Account').get(0).put('Name', 'Acct 1');
customerBundle.get('Account').get(1).put('Name', 'Acct 2');
bundleMaker.insertBundle(customerBundle);

// if you are testing this out, delete what you have created
delete customerBundle.get('Account_Relationship__c');
delete customerBundle.get('Account_Sales_Area__c');
delete customerBundle.get('Account');
delete customerBundle.get('Customer_Master_Data__c');

*/

    public final Set<String> ACCEPTABLE_ACCOUNT_GROUPS = new Set<String> {
        Accounts.GROUP_SOLD_TO, Accounts.GROUP_DISTRIBUTOR, Accounts.GROUP_ULTIMATE_CONSIGNEE, Accounts.GROUP_PROSPECT
    };

    public final Set<String> ACCEPTABLE_CMD_GROUPS = new Set<String> {
        Accounts.GROUP_SOLD_TO, Accounts.GROUP_DISTRIBUTOR, Accounts.GROUP_ULTIMATE_CONSIGNEE, CustomerMasterDatas.GROUP_SHIP_TO, CustomerMasterDatas.GROUP_BILL_TO, CustomerMasterDatas.GROUP_PAYER
    };

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Constructors
    //
    // NOTE: compiler won't let me call one constructor from the other, don't know why
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // inputs
    private List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions;
    private List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs;
    private List<TestBundleCustomersStructure.ExtraRelationshipDefinition> extraRelationshipDefinitions;

    // class which contains logic to generate intelligent random values for customer fields
    // NOTE: in future we could have multiple implementing classes which cover situations like transborder, transregion
    TestBundleCustomersValues valueGenerator;

    /**
    * 
    *
    * @description TestBundleCustomers Constructor [CodeScan Fix]
    */
    
    public TestBundleCustomers(List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions)
    {
        commonConstructorLogic();

        this.customerDefinitions = customerDefinitions;

        // pick a random sakes org and build the definition structure with it
        // NOTE: two potential improvements for randomly-generated orgs
        // 1) we are only adding direct (01)
        // 2) we are only adding one sales org
        String randomSalesOrg = valueGenerator.getRandomSalesOrg();

        this.salesAreaDefs = new List<TestBundleCustomersStructure.SalesAreaDefinition> {
            new TestBundleCustomersStructure.SalesAreaDefinition(randomSalesOrg, '01', '00')
        };

        this.extraRelationshipDefinitions = new List<TestBundleCustomersStructure.ExtraRelationshipDefinition>();
    }

    /**
    * 
    *
    * @description TestBundleCustomers Constructor [CodeScan Fix]
    */

    public TestBundleCustomers(List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions, List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs)
    {
        commonConstructorLogic();

        this.customerDefinitions = customerDefinitions;
        this.salesAreaDefs = salesAreaDefs;
        this.extraRelationshipDefinitions = new List<TestBundleCustomersStructure.ExtraRelationshipDefinition>();
    }

    /**
    * 
    *
    * @description TestBundleCustomers Constructor [CodeScan Fix]
    */

    public TestBundleCustomers(List<TestBundleCustomersStructure.CustomerDefinition> customerDefinitions,
                               List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs,
                               List<TestBundleCustomersStructure.ExtraRelationshipDefinition> extraRelationshipDefs)
    {
        commonConstructorLogic();

        this.customerDefinitions = customerDefinitions;
        this.salesAreaDefs = salesAreaDefs;
        this.extraRelationshipDefinitions = extraRelationshipDefs;
    }

    private void commonConstructorLogic()
    {
        ilib_LogEvent.rootTitle = LOG_TITLE;
        valueGenerator = new TestBundleCustomersValues();
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // getBundle() generates all the object rows that represent the customers
    // (account, customer master data, account sales area, account relationship)
    // only the objects relevant to the account group will be created (ex: no account record for a Bill To)
    // 
    // the relationships between objects won't be established until the call to insertBundle()
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * 
    *
    * @description getBundle [CodeScan Fix]
    */
    public Map<String, List<SObject>> getBundle()
    {
        ilib_LogEvent.push(LOG_TITLE + '.getBundle()');

        Map<String, List<SObject>> dataBundle = new Map<String, List<SObject>>();

        for (TestBundleCustomersStructure.CustomerDefinition customerDefinition : customerDefinitions)
        {
            // tell the value generator class which customer values have been specified
            valueGenerator.specifyCustomerDef(customerDefinition, salesAreaDefs);

            Account a = initAccount(customerDefinition.accountGroup);
            dataBundle.put(SALES_ORG_ACCOUNT, TestBundles.addRecordToList(dataBundle.get(SALES_ORG_ACCOUNT), a));

            Customer_Master_Data__c cmd = initCustomerMasterData(customerDefinition.accountGroup, a);
            dataBundle.put(SALES_ORG_CMDATA, TestBundles.addRecordToList(dataBundle.get(SALES_ORG_CMDATA), cmd));

            // no cmd means prospect so the below objects don't apply
            if (cmd == null) continue;

            List<Account_Sales_Area__c> sas = initSalesAreas(cmd, salesAreaDefs);
            dataBundle.put(SALES_ORG_ACCSALESAREA, TestBundles.addRecordsToList(dataBundle.get(SALES_ORG_ACCSALESAREA), sas));

            List<Account_Relationship__c> rels = initRelationships(cmd, sas);
            dataBundle.put(SALES_ORG_ACCRELATIONSHIP, TestBundles.addRecordsToList(dataBundle.get(SALES_ORG_ACCRELATIONSHIP), rels));
        }

        for (String objType : dataBundle.keySet())
        {
            ilib_LogEvent.message(SALES_ILIBMESSAGE + objType + ' count = ' + dataBundle.get(objType).size());
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return dataBundle;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // insertBundle() and its support methods persist all the object rows to the database
    // the relationships are set as the parent objects are inserted
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * 
    *
    * @description insertBundle [CodeScan Fix]
    */
    public void insertBundle(Map<String, List<SObject>> dataBundle)
    {
        ilib_LogEvent.push(LOG_TITLE + '.insertBundle()');

        TestBundles.insertSingleObjectRows(dataBundle, SALES_ORG_ACCOUNT);
        TestBundles.insertSingleObjectRows(dataBundle, SALES_ORG_CMDATA);

        resolveSalesAreaLookups(dataBundle);
        TestBundles.insertSingleObjectRows(dataBundle, SALES_ORG_ACCSALESAREA);

        resolveRelationshipLookups(dataBundle);
        // extra relationships are user-specified links between SAP customers
        createExtraRelationships(dataBundle);
        TestBundles.insertSingleObjectRows(dataBundle, SALES_ORG_ACCRELATIONSHIP);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

    private void resolveSalesAreaLookups(Map<String, List<SObject>> dataBundle)
    {
        Integer salesAreaCount = salesAreaDefs.size();
        if (salesAreaCount == 0) return;

        List<SObject> accounts = dataBundle.get(SALES_ORG_ACCOUNT);
        List<Customer_Master_Data__c> cmds = (List<Customer_Master_Data__c>)dataBundle.get(SALES_ORG_CMDATA);
        List<Account_Sales_Area__c> sas = (List<Account_Sales_Area__c>)dataBundle.get(SALES_ORG_ACCSALESAREA);
        if (sas == null) return;

        Integer loopCounter = 1;
        Integer cmdCounter = 0;
        Integer accountCounter = 0;

        List<String> accountGroups = new List<String>();
        for (TestBundleCustomersStructure.CustomerDefinition customerDefinition : customerDefinitions)
            accountGroups.add(customerDefinition.accountGroup);

        for (Account_Sales_Area__c sa : sas)
        {
            // if we have assigned salesAreaCount - 1 references, move to the next one after this run through the loop
            Boolean changeLookups = Math.mod(loopCounter, salesAreaCount) == 0;

            // only set account reference if the account group is one that has account records in addition to CMD records
            if (ACCEPTABLE_ACCOUNT_GROUPS.contains(accountGroups.get(cmdCounter)))
            {
                // set reference to the current account lookup
                sa.Account__c = accounts.get(accountCounter).Id;

                // if we have assigned salesAreaCount references to this Account, move to the next one
                if (changeLookups)
                {
                    accountCounter = accountCounter + 1;
                }
            }

            // always have a CMD lookup, set reference to the current one
            sa.Customer_Master_Data__c = cmds.get(cmdCounter).Id;

            // if we have assigned salesAreaCount references to this CMD, move to the next one
            if (changeLookups)
                cmdCounter = cmdCounter + 1;

            loopCounter = loopCounter + 1;
        }
    }

    private void resolveRelationshipLookups(Map<String, List<SObject>> dataBundle)
    {
        Integer salesAreaCount = salesAreaDefs.size();
        if (salesAreaCount == 0) return;

        List<Account_Sales_Area__c> sas = (List<Account_Sales_Area__c>)dataBundle.get(SALES_ORG_ACCSALESAREA);
        List<Account_Relationship__c> rels = (List<Account_Relationship__c>)dataBundle.get(SALES_ORG_ACCRELATIONSHIP);
        if (rels == null) return;

        // "multiply" account groups by sales areas
        // because if we have one sold to but two sales areas then we have to map all the relationship for both sales areas
        // i.e. the first 5 relationships to sales area #1 and the next 5 relationships to sales area #2
        List<String> accountGroupsTimesSalesAreas = new List<String>();
        for (TestBundleCustomersStructure.CustomerDefinition customerDefinition : customerDefinitions)
        {   
            for (TestBundleCustomersStructure.SalesAreaDefinition sa : salesAreaDefs) {
                List<TestBundleCustomersStructure.SalesAreaDefinition> lstSalesAreaDefinition=new List<TestBundleCustomersStructure.SalesAreaDefinition>();
                lstSalesAreaDefinition.add(sa);
                accountGroupsTimesSalesAreas.add(customerDefinition.accountGroup);
            }
                
        }

        Integer relsInSaCounter = 1;
        Integer saCounter = 0;

        for (Account_Relationship__c rel : rels)
        {
            Integer relationshipListSize = getRelationshipListForAccountGroup(accountGroupsTimesSalesAreas.get(saCounter)).size();

            // always have an ASA lookup, set reference to the current one
            rel.Account_Sales_Area__c = sas.get(saCounter).Id;

            // if we have linked relationshipListSize relationships to the current sales area, move to the next sales area
            Boolean changeLookups = Math.mod(relsInSaCounter, relationshipListSize) == 0;
            if (changeLookups)
            {
                saCounter = saCounter + 1;
                relsInSaCounter = 0;
            }

            relsInSaCounter = relsInSaCounter + 1;
        }
    }

    private void createExtraRelationships(Map<String, List<SObject>> dataBundle)
    {
        List<Account_Relationship__c> rels = (List<Account_Relationship__c>)dataBundle.get(SALES_ORG_ACCRELATIONSHIP);

        for (TestBundleCustomersStructure.ExtraRelationshipDefinition extraRel : extraRelationshipDefinitions)
        {
            Customer_Master_Data__c parentCmd = (Customer_Master_Data__c)dataBundle.get(SALES_ORG_CMDATA).get(extraRel.parentCustomer - 1);
            Customer_Master_Data__c childCmd = (Customer_Master_Data__c)dataBundle.get(SALES_ORG_CMDATA).get(extraRel.childCustomer - 1);

            for (Integer saCount = 0; saCount < salesAreaDefs.size(); saCount++)
            {
                if (!extraRel.parentSalesAreas.contains(salesAreaDefs.get(saCount).salesOrg))
                    continue;

                Integer parentSaIndex = (extraRel.parentCustomer - 1) * salesAreaDefs.size() + saCount;
                Account_Sales_Area__c parentAsa = (Account_Sales_Area__c)dataBundle.get(SALES_ORG_ACCSALESAREA).get(parentSaIndex);
    
                Account_Relationship__c rel = initRelationship(parentCmd.ERP_Customer_Id__c, childCmd.ERP_Customer_Id__c, parentAsa.ERP_Account_Sales_Area_Id__c, extraRel.relationshipType, extraRel.isDefault);
                rel.Account_Sales_Area__c = parentAsa.Id;
                rels.add(rel);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // contact utility methods
    // don't have a good home for these yet so dropping them here
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * 
    *
    * @description initContact [CodeScan Fix]
    */
    public static Contact initContact(Account a)
    {
        Contact rec = new Contact(
            FirstName = TestBundles.getRandom(),
            LastName = TestBundles.getRandom(),
            AccountId = a.Id,
            Email = TestBundles.getRandom() + '@' + a.Name + '.com',
            Phone = TestBundles.getRandomNumeric(),
            MailingCountryCode = a.BillingCountryCode
        );
        return rec;
    }

    /**
    * 
    *
    * @description initContacts [CodeScan Fix]
    */
    public static List<Contact> initContacts(List<Account> accounts)
    {
        List<Contact> recs = new List<Contact>();
        for (Account a : accounts)
        {
            recs.add(initContact(a));
        }
        return recs;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // init methods create a single row in-memory
    //
    // would be nice to integrate this with the other TestData* classes
    // but those aren't advanced enough yet
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * 
    *
    * @description initAccount [CodeScan Fix]
    */
    public Account initAccount(String accountGroup)
    {
        if (!ACCEPTABLE_ACCOUNT_GROUPS.contains(accountGroup))
            return null;

        Id rtId = Accounts.getNameToRecordType().get('Prospect').getRecordTypeId();
        if (accountGroup != Accounts.GROUP_PROSPECT)
            rtId = Accounts.getNameToRecordType().get('Customer').getRecordTypeId();

        // TODO: figure out the code/description mismatches
        Account rec = new Account(
            Name = TestBundles.getRandom(),
            ERP_Customer_Id__c = TestBundles.getRandomNumeric(10),
            CurrencyIsoCode = valueGenerator.getRandomCurrency(),
            BillingStreet = TestBundles.getRandom(),
            BillingCity = TestBundles.getRandom(),
            BillingPostalCode = TestBundles.getRandom(),
            //BillingStateCode = valueGenerator.getRandomState(),
            BillingState = valueGenerator.getRandomStateDesc(),
            BillingCountryCode = valueGenerator.getRandomCountry(),
            //BillingCountry = valueGenerator.getRandomCountryDesc(),
            Clinical_Type__c = valueGenerator.getRandomClinicalType(),
            Customer_Sub_Type__c = valueGenerator.getRandomCustomerSubType(),
            Customer_Type__c = valueGenerator.getRandomCustomerType(),
            Market_Segment__c = valueGenerator.getRandomMarketSegment(),
            Tier__c = valueGenerator.getRandomTier(),
            Account_Group__c = accountGroup,
            RecordTypeId = rtId
        );

        // distributors have a few extra values
        if (accountGroup == Accounts.GROUP_DISTRIBUTOR)
        {
            rec.Channel_Partner_Type__c = 'Affiliate';
            rec.Product_Group__c = 'All';
            rec.Regulatory_Type__c = 'All';
        }

        ilib_LogEvent.message(SALES_ILIBMESSAGE + rec);

        return rec;
    }
    
    /**
    * 
    *
    * @description initCustomerMasterData [CodeScan Fix]
    */

    public Customer_Master_Data__c initCustomerMasterData(String accountGroup, Account a)
    {
        if (accountGroup == Accounts.GROUP_PROSPECT)
            return null;

        if (ACCEPTABLE_ACCOUNT_GROUPS.contains(accountGroup) && a == null)
            return null;

        if (!ACCEPTABLE_CMD_GROUPS.contains(accountGroup))
            return null;

        Customer_Master_Data__c rec;
        if (a == null)
        {
            rec = new Customer_Master_Data__c(
                ERP_Customer_Id__c = TestBundles.getRandomNumeric(10),
                Country__c = valueGenerator.getRandomCountryDesc(),
                Country_Code__c = valueGenerator.getRandomCountry(),
                Name = TestBundles.getRandom(),
                Account_Group__c = accountGroup
            );
        }
        else
        {
            rec = new Customer_Master_Data__c(
                ERP_Customer_Id__c = a.ERP_Customer_Id__c,
                Country__c = a.BillingCountry,
                Country_Code__c = a.BillingCountryCode,
                Name = a.Name,
                Account_Group__c = accountGroup
            );
        }
        ilib_LogEvent.message(SALES_ILIBMESSAGE + rec);

        return rec;
    }

    /**
    * 
    *
    * @description initSalesAreas [CodeScan Fix]
    */
    public List<Account_Sales_Area__c> initSalesAreas(Customer_Master_Data__c cmd, List<TestBundleCustomersStructure.SalesAreaDefinition> salesAreaDefs)
    {
        List<Account_Sales_Area__c> recs = new List<Account_Sales_Area__c>();

        for (TestBundleCustomersStructure.SalesAreaDefinition salesAreaDef : salesAreaDefs)
        {
            valueGenerator.specifySalesAreaDef(salesAreaDef);
            recs.add(initSalesArea(cmd, salesAreaDef));
        }

        return recs;
    }

    /**
    * 
    *
    * @description initSalesArea [CodeScan Fix]
    */
    public Account_Sales_Area__c initSalesArea(Customer_Master_Data__c cmd, TestBundleCustomersStructure.SalesAreaDefinition salesAreaDef)
    {
        String contractNumber = cmd.ERP_Customer_Id__c + '_' + salesAreaDef.salesOrg + salesAreaDef.distChannel + salesAreaDef.division;
        String priceListType = valueGenerator.getRandomPriceListType(salesAreaDef.salesOrg);
        String currencyValue = valueGenerator.getRandomCurrency();

        Account_Sales_Area__c rec = new Account_Sales_Area__c(
            CurrencyIsoCode = currencyValue,
            Sales_Organization__c = salesAreaDef.salesOrg,
            Distribution_Channel__c = salesAreaDef.distChannel,
            Division__c = salesAreaDef.division,
            Company_Code__c = salesAreaDef.salesOrg,
            ERP_Account_Sales_Area_Id__c = contractNumber,
            Contract_Number__c = contractNumber,
            IsInactive__c = false,
            Price_List_Type__c = priceListType,
            Price_List__c = valueGenerator.getPriceListPrefix(priceListType) + currencyValue,
            Term_Of_Payment__c = valueGenerator.getRandomPaymentTerm(),
            Inco_Term_1__c = valueGenerator.getRandomIncoterm()
        );
        ilib_LogEvent.message(SALES_ILIBMESSAGE + rec);

        return rec;
    }

    /**
    * 
    *
    * @description initRelationships [CodeScan Fix]
    */
    public List<Account_Relationship__c> initRelationships(Customer_Master_Data__c cmd, List<Account_Sales_Area__c> asas)
    {
        List<String> accountGroups = getRelationshipListForAccountGroup(cmd.Account_Group__c);

        List<Account_Relationship__c> recs = new List<Account_Relationship__c>();
        for (Account_Sales_Area__c asa : asas)
        {
            for (String accountGroup : accountGroups)
            {
                recs.add(initRelationship(cmd.ERP_Customer_Id__c, cmd.ERP_Customer_Id__c, asa.ERP_Account_Sales_Area_Id__c, accountGroup, false));
            }
        }

        return recs;
    }

    /**
    * 
    *
    * @description initRelationship [CodeScan Fix]
    */
    private Account_Relationship__c initRelationship(String erpId, String relatedErpId, String asaErpId, String accountGroup, Boolean isDefault)
    {
        Account_Relationship__c rec = new Account_Relationship__c(
            ERP_Customer_Id__c = erpId,
            Related_ERP_Customer_Id__c = relatedErpId,
            Relationship__c = accountGroup,
            ERP_Account_Relationship_Id__c = relatedErpId + '_' + accountGroup + '_' + asaErpId,
            IsInactive__c = false,
            Default_Partner__c = isDefault
        );
        ilib_LogEvent.message(SALES_ILIBMESSAGE + rec);

        return rec;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // utility methods
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /**
    * 
    *
    * @description getRelationshipListForAccountGroup [CodeScan Fix]
    */
    public List<String> getRelationshipListForAccountGroup(String accountGroup)
    {
        List<String> accountGroups = new List<String>();

        if (accountGroup == Accounts.GROUP_SOLD_TO)
        {
            accountGroups = new List<String> {Accounts.GROUP_SOLD_TO, Accounts.GROUP_ULTIMATE_CONSIGNEE, CustomerMasterDatas.GROUP_SHIP_TO, CustomerMasterDatas.GROUP_BILL_TO, CustomerMasterDatas.GROUP_PAYER};
        }
        if (accountGroup == Accounts.GROUP_DISTRIBUTOR)
        {
            accountGroups = new List<String> {Accounts.GROUP_DISTRIBUTOR, Accounts.GROUP_ULTIMATE_CONSIGNEE, CustomerMasterDatas.GROUP_SHIP_TO, CustomerMasterDatas.GROUP_BILL_TO, CustomerMasterDatas.GROUP_PAYER};
        }
        if (accountGroup == Accounts.GROUP_ULTIMATE_CONSIGNEE)
        {
            accountGroups = new List<String> {Accounts.GROUP_ULTIMATE_CONSIGNEE};
        }
        if (accountGroup == CustomerMasterDatas.GROUP_SHIP_TO)
        {
            accountGroups = new List<String> {CustomerMasterDatas.GROUP_SHIP_TO};
        }
        if (accountGroup == CustomerMasterDatas.GROUP_BILL_TO)
        {
            accountGroups = new List<String> {CustomerMasterDatas.GROUP_BILL_TO, CustomerMasterDatas.GROUP_PAYER};
        }
        if (accountGroup == CustomerMasterDatas.GROUP_PAYER)
        {
            accountGroups = new List<String> {CustomerMasterDatas.GROUP_PAYER};
        }

        return accountGroups;
    }

}