/*@ author       : Digvijay Singh
* @ date         : 09-04-2019
* @ Description  : Test class for WorkOrderDetailForTemplate class
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Digvijay SIngh          9-04-2019                US-DCP-24630            Initial version
* 
*/
@IsTest(SeeAllData=false)
global with sharing class TestWorkOrderDetailForTemplate {
    public static final string STRING_INSTALLED_PRODUCT_NAME = 'Test IP VM';
    public static final string STRING_CURRENCY = 'USD';
    public static final string STRING_INSTALLED_PRODUCT_STATUS = 'New';
    
    @IsTest
		/*Test Data*/
    public static void testgetWorkDetails(){
        Account objAccount = TestDataAccount.getNewAccount();
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        Contact objContact = TestDataContact.getNewContact(objAccount);
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        insert objCase;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct(STRING_INSTALLED_PRODUCT_NAME, STRING_CURRENCY, STRING_INSTALLED_PRODUCT_STATUS);
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
         SVMXC__Service_Order__c workOrder;
        workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        insert objOrderDetail;
         Test.startTest();
         
         WorkOrderDetailForTemplate obj=new WorkOrderDetailForTemplate();
         obj.workOrderId = workOrder.id;
         
        List<SVMXC__Service_Order_Line__c> lstworkDetails= obj.getlistworkDetails();
        System.assertEquals(1,lstworkDetails.size());
         
         Test.stopTest();
        
        
        }
        
  }