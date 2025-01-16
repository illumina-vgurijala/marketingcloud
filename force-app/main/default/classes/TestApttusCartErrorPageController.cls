/*@ author       : 
* @ date         : 
* @ Description  : TestApttusCartErrorPageController Test class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Parthasarathy D      10-Oct-2022                                 Codescan Fix- Added Header comments.
* Satya Swain          09 Dec 2022                                 Added Codescan fix for Variable Naming Convention
* 
*/
@isTest(isParallel=true)
public with sharing class TestApttusCartErrorPageController {
	
	public static final Integer INTEGER_QUANTITY = 2;
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 1;
	
	@testSetup
    static void setupData(){
    	Account objAcc = TestDataAccount.getNewAccount();
        TestDataPerson.getNewContact(objAcc.Id);
        Apttus_Config2__PriceList__c objPriceList = TestDataProposal.initPriceList('AMR-USD-US-01');
        insert objPriceList;
        
        Opportunity objOpportunity = TestDataOpportunity.getNewOpportunity(objAcc);
        objOpportunity.Ultimate_Consignee__c = objAcc.Id;
        objOpportunity.Sold_to_Distribution_Channel__c = 'Direct';
        objOpportunity.Price_List__c = objPriceList.Name;
        update objOpportunity; 

        Apttus_Proposal__Proposal__c objProposal = TestDataProposal.initProposal(objAcc.id, objOpportunity.id, 'Test Proposal', objPriceList.id, true, 'Draft', 'None');
        insert objProposal;

        TestDataMaster.createProduct(true); 

        TestDataProposal.getNewCart(objProposal);

    }

    @isTest
    static void testCheckCartErrors(){
    	
        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        objProductConfig.SAP_errors__c = 'Test Error';
        update objProductConfig;

        Test.startTest();
        
        Test.setCurrentPageReference(new PageReference('Page.ApttusCartErrorPage')); 
        System.currentPageReference().getParameters().put('id', objProductConfig.Id);

        ApttusCartErrorPageController pageController = new ApttusCartErrorPageController();

        Test.stopTest();
        System.assertEquals('Test Error',pageController.strErrors,'Incorrect value copied in Error List');
    }
}