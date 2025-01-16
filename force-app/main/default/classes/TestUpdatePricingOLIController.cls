/**
*    @author Rishab
*    @date   2021-June-03
*    @description    DCP-46927: Quote Optimization (Add Products to Opportunity Controller Test Class)
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rishab                        03-06-2021          Initial Version
*         Ashwin Kumar                  31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*    ---------------------------------------------------------------------------------------------------------------------------
**/
@isTest
public class TestUpdatePricingOLIController {

    public static string salesOppName = 'Sales Opp';

    @testSetup
    static void initializeTestData()
    {
        Account acc = TestDataAccount.getAccount('Test 1');
        String recordtypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.AccountRecordTypeIndirectPartner).getRecordTypeId();
        acc.RecordTypeId = recordtypeid;
        Account accDistributor = TestDataAccount.getAccount('Distributor Partner');
        accDistributor.Account_Group__c = 'Distributor';
        accDistributor.RecordTypeId = recordtypeid;
        Account acc1 = TestDataAccount.getAccount('DistributorAffiliateAccount');
        acc1.Account_Group__c = 'Distributor';
        acc1.Channel_Partner_Type__c = 'Affiliate';
        acc1.RecordTypeId = recordtypeid;
        Account acc2 = TestDataAccount.getAccount('Test 2');
        acc2.RecordTypeId = recordtypeid;
        acc2.Clinical_Type__c = 'Clinical';
        acc2.Market_Segment__c = null;
        insert new List<Account>{acc,accDistributor,acc1,acc2};

        Contact con1 = TestDataPerson.initContact(acc.Id);
        Contact con2 = TestDataPerson.initContact(acc.Id);
        Contact con3 = TestDataPerson.initContact(accDistributor.Id);
        insert new List<Contact> { con1, con2, con3 };

        Opportunity opp = TestDataOpportunity.initOpportunity(acc);
		opp.Name = salesOppName;

        Pricebook2 standardPricebook = TestDataOpportunity.getStandardPriceBook();
        opp.Pricebook2Id = standardPricebook.Id;
        Partner_Association__c objAssociatedDistributor = new Partner_Association__c(Associated_Channel_Partner__c = acc1.Id,Parent_Channel_Partner__c = accDistributor.Id);
        insert objAssociatedDistributor;

        insert opp;  
		
        List<String> productGroupValues = getProductGroupValues();
        Integer intValueCount = productGroupValues.size();
        Integer intTwo = 2;
        if (intValueCount < intTwo) { return; }
        String group1 = productGroupValues.get(0);
        String group2 = productGroupValues.get(intValueCount - 1);

        Product2 objProduct1 = TestDataMaster.initProduct('Cookie');
        Product2 objProduct2 = TestDataMaster.initProduct('Brownie');
        objProduct1.ProductCode = '20020084';
        objProduct2.ProductCode = '20020085';
        objProduct1.Product_Group__c = group1;
        objProduct2.Product_Group__c = group2;
        insert new List<Product2> { objProduct1, objProduct2 };
        PricebookEntry pbe1 = TestDataMaster.getNewStandardPrice(objProduct1.Id, 200);
        PricebookEntry pbe2 = TestDataMaster.getNewStandardPrice(objProduct2.Id, 200);
        OpportunityLineItem oli1 = TestDataMaster.createOpportunityProduct(opp.Id, pbe1.Id, true);
        OpportunityLineItem oli2 = TestDataMaster.createOpportunityProduct(opp.Id, pbe2.Id, true);

        System.debug('OLIs Id : ' + oli1.id + oli2.id);
    }
    
    /*Description - Checks access for user method  */
    public static testmethod void checkAccessMethod()
    {
        Opportunity opp = [SELECT Id,Name FROM Opportunity WHERE Name = : salesOppName];
        test.startTest();
        String boolResult = UpdatePricingOLIController.checkRecordAccess(opp.Id);
        test.stopTest();
        System.assertEquals(UpdatePricingOLIController.STRSUCCESS,boolResult,'User has access');
    }
    
    /*Description - Get data from SAP method check */
    public static testmethod void getPricingMethod()
    {
        Opportunity opp = [SELECT Id,Name FROM Opportunity WHERE Name =: salesOppName];
        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHTTPCalloutCustomerSpecificPricing());
        String boolResult = UpdatePricingOLIController.getPricingDetails(opp.Id);
        test.stopTest();
        System.assertEquals(UpdatePricingOLIController.STRSUCCESS,boolResult,'SAP Pricing Updated');
    }
    
    /*Description - Checks access negative scenario  */
    public static testmethod void checkAccessNegativeScenario()
    {
        Opportunity opp = [SELECT Id,Name FROM Opportunity WHERE Name = : salesOppName];
        User salesUser = TestDataUser.findUserInProfile(TestDataUser.PROFILE_SALES_REP);
        test.startTest();
        String boolResult;
        System.runAs(salesUser)
        {
        	boolResult = UpdatePricingOLIController.checkRecordAccess(opp.Id);
        }
        test.stopTest();
        System.assertEquals(UpdatePricingOLIController.STRERROR,boolResult,'User has no access.');
    }

    /*Description - get group values */
    public static List<String> getProductGroupValues()
    {
        List<String> values = new List<String>();
        List<Schema.PicklistEntry> entries = Product2.Product_Group__c.getDescribe().getPicklistValues();
        for (Schema.PicklistEntry entry : entries){
            if (entry.isActive()){
                values.add(entry.getLabel());
            }
        }
        System.debug(values);
        return values;
    }
    
}