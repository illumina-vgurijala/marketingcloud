/**
 * @author Satya Swain 
 * @date   30-Oct-2018
 * @description   Test class to check Non Renew Functionality of Asset Line Item for DCP-736
 * Modification Log:
 *  --------------------------------------------------------------------------------------------------
 *   Developer                Date                Description                                                  
 *   Satya Swain            30-Oct-2018         Original Version
 *   Jitesh Lakhwani        21-Feb-2023         COdescan - Fix naming convention
 * ---------------------------------------------------------------------------------------------------
 **/
@isTest(isParallel=true)
public class TestApttusTerminateAssetRenewals {

    public static final Integer INTEGER_QUANTITY = 2;
    public static final Integer INTEGER_SHIPPING_IN_CLOSE_QUARTER = 1;

    @testSetup
    static void setupData()
    {
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

		Product2 objProduct = TestDataMaster.createProduct(true); 

        Apttus_Config2__ProductConfiguration__c testCart = TestDataProposal.getNewCart(objProposal);

        Apttus_Config2__AssetLineItem__c objAssetLineItem = TestDataProposal.initAssetLineItem(objAcc.Id, objProduct.Id, objProposal.Id);
        Apttus_Config2__AssetLineItem__c objAssetLineItem2 = TestDataProposal.initAssetLineItem(objAcc.Id, objProduct.Id, objProposal.Id);
        insert new List<Apttus_Config2__AssetLineItem__c>{objAssetLineItem,objAssetLineItem2};
        
        Apttus_Config2__LineItem__c objLineItem = TestDataProposal.getNewLineItem(testCart.Id,objProduct.Id,INTEGER_QUANTITY,INTEGER_SHIPPING_IN_CLOSE_QUARTER);
        Apttus_Config2__LineItem__c objLineItem2 = TestDataProposal.getNewLineItem(testCart.Id,objProduct.Id,INTEGER_QUANTITY,INTEGER_SHIPPING_IN_CLOSE_QUARTER);
		objLineItem2.Apttus_Config2__AssetLineItemId__c = objAssetLineItem2.Id;
        insert new List<Apttus_Config2__LineItem__c>{objLineItem,objLineItem2};       
        
    }
    /**
    *    @author Satya Swain
    *    @date   2018-10-30       
    *    @description test method for indicating non renewal of asset line item functionality
    */ 
    @isTest
    static void testIndicateNonRenewalAssets(){
        Opportunity objOpportunity = [Select id From Opportunity LIMIT 1];
        Apttus_Proposal__Proposal__c objProposal = [Select id From Apttus_Proposal__Proposal__c WHERE Apttus_Proposal__Opportunity__c =: objOpportunity.Id and Apttus_Proposal__Proposal_Name__c = 'Test Proposal'];
        
        Apttus_Config2__ProductConfiguration__c objProductConfig = [SELECT Id from Apttus_Config2__ProductConfiguration__c LIMIT 1];  
        objProductConfig.Apttus_Config2__Status__c = System.Label.ConfigurationStatusFinalized;
        update objProductConfig;
		List<Apttus_Config2__AssetLineItem__c> lstAssetLineItem = [SELECT Id,Apttus_Config2__AccountId__c,Ultimate_Consignee__c,Apttus_Config2__ProductId__c,Apttus_Config2__PriceType__c from Apttus_Config2__AssetLineItem__c];

        List<Apttus_Config2__LineItem__c> lstLineItem = [SELECT Id,Apttus_Config2__AssetLineItemId__c from Apttus_Config2__LineItem__c];
        System.debug('@@@@ test lstlineitem: '+lstLineItem);
        System.debug('@@@@ test lstLineItem AssetLineItemIds' +lstLineItem.get(0).Apttus_Config2__AssetLineItemId__c + '   '+ lstLineItem.get(1).Apttus_Config2__AssetLineItemId__c );
        
        Test.setCurrentPageReference(new PageReference('Page.ApttusTerminateAssetRenewals')); 
        System.currentPageReference().getParameters().put('businessObjectId', objProposal.Id);
        System.currentPageReference().getParameters().put('id', objProductConfig.Id);
        System.currentPageReference().getParameters().put('flow','NGDefault');
        Test.startTest();
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstAssetLineItem);
        stdSetController.setSelected(lstAssetLineItem);
        ApttusTerminateAssetRenewalController objTerminateAssetRenewalController = new ApttusTerminateAssetRenewalController();
        List<Apttus_Config2__AssetLineItem__c> lstAssetLineItemRecords = objTerminateAssetRenewalController.getAssetLineItems();
        System.debug('@@@@ lstAssetLineItems:'+lstAssetLineItem+'\n');
        System.debug('@@@@ test2 lstAssetLineItemRecords: '+lstAssetLineItemRecords);
        System.debug('@@@@ test2 lstlineitem: '+lstLineItem);
        System.debug('@@@@ test2 lstLineItem AssetLineItemIds' +lstLineItem.get(0).Apttus_Config2__AssetLineItemId__c + '   '+ lstLineItem.get(1).Apttus_Config2__AssetLineItemId__c );
        lstAssetLineItemRecords.get(0).Is_Customer_Not_Renewing__c = true;
        lstAssetLineItemRecords.get(0).Reason_Not_Renewing__c = NULL;
        update lstAssetLineItemRecords;
        objTerminateAssetRenewalController.next();
        objTerminateAssetRenewalController.previous();
        objTerminateAssetRenewalController.lastPage();
        objTerminateAssetRenewalController.firstPage();
        objTerminateAssetRenewalController.saveAssets();
        lstAssetLineItemRecords.get(0).Is_Customer_Not_Renewing__c = false;
        lstAssetLineItemRecords.get(0).Reason_Not_Renewing__c = 'test reason';
        update lstAssetLineItemRecords;
        objTerminateAssetRenewalController.next();
        objTerminateAssetRenewalController.previous();
        objTerminateAssetRenewalController.lastPage();
        objTerminateAssetRenewalController.firstPage();
        objTerminateAssetRenewalController.saveAssets();
        System.assertEquals(NULL,lstAssetLineItemRecords.get(0).Reason_Not_Renewing__c,'Reason Field Not Blanked Out');
        System.assertEquals(false,stdSetController.gethasNext(),'Error In Next Page Functionality');
        System.assertEquals(false,stdSetController.gethasPrevious(),'Error In Previous Page Functionality');  
        
        objTerminateAssetRenewalController.cancel();
        Test.stopTest();       
    }
    
}