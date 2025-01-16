/* @ author      : Dushyant Srivastava
* @ date         : 2nd December 2021
* @ Description  : TestUpdateProductPricingController is the test class for UpdateProductPricingController
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Ashwin Kumar                   31-Mar-2021         DCP-52339 Remove TestTAPS.setupDeferredObjectData
*         Jitesh Lakhwani                20-Sept-2022        @88% Class : UpdateProductPricingController Test Coverage 
*    ---------------------------------------------------------------------------------------------------------------------------
*/
@isTest
public with sharing class TestUpdateProductPricingController {
    
    public static string salesOppName = 'Sales Opp';

    /**
	*  @author Dushyant Srivastava
	*  @description Test Data Setup
	**/
	@testSetup
    static void setupData(){
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
        OpportunityLineItem objOpportunityLineItem = TestDataMaster.createOpportunityProduct(opp.Id, pbe1.Id, true);
        OpportunityLineItem objOppLineItem = TestDataMaster.createOpportunityProduct(opp.Id, pbe2.Id, true);
        
        System.debug('OLIs Id : ' + objOpportunityLineItem.id + objOppLineItem.id);
    }
     /**
	*  @author Dushyant Srivastava
	*  @description Test Method
	**/
    @isTest
    static void testUpdatePricings(){
        Opportunity objOpportunity = [Select id from Opportunity Limit 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHTTPCalloutCustomerSpecificPricing());
        UpdateProductPricingController.checkRecordAccess(objOpportunity.Id);
        Test.stopTest();
        System.assertEquals(UpdatePricingOLIController.STRSUCCESS,'success');
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

    /** @Author Jitesh Lakhwani
     * @Description - test exception */
    @isTest
    public static void testUpdateProductPricingControllerException()
    {
        OpportunityLineItem objOpportunityLI = [Select id from OpportunityLineItem Limit 1];
        Boolean exceptionBool = false;

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHTTPCalloutCustomerSpecificPricing());
        try {
            UpdateProductPricingController.checkRecordAccess(objOpportunityLI.Id);
        } catch (Exception e) {
            
            exceptionBool = true;
        }
        System.assert(exceptionBool, 'Exception Occured');
        Test.stopTest();
    }
}