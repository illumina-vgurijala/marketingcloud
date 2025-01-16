/***************************************************************************************************************************************
* NAME         : TestWorkOrderWrapper
* DESCRIPTION  : Test class for WorkOrderWrapper.
*                    
* @AUTHOR      : Naomi
* @DATE        : 19-Jul-2019  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Pooja                    23-09-2022          CodeScanFixes
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@IsTest
public class TestWorkOrderWrapper {
    
    @IsTest
    static void callConstructorForWO() {
        Account objAccount = TestDataAccount.getNewAccount();
        system.assertNotEquals(null,objAccount.id);
        Account objAccupdate=[select id,Account_Group__c from Account where id=:objAccount.id];
        objAccupdate.Account_Group__c='Distributor';
        update objAccupdate;
        
        Contact objContact = TestDataContact.getNewContact(objAccount);
        system.assertNotEquals(null,objContact.id);
        Test.startTest();
        Product2 objProduct = new Product2(
            Name = 'Test Product VM', 
            Service_Product_Type__c = 'Consumable',
            Material_Class__c = 'Consumables');
        insert objProduct;
        system.assertNotEquals(null,objProduct.id);
         cs_Apex_Settings__c apexSettings = new cs_Apex_Settings__c(
            Bypass_Triggers_By_Object_1__c = 'Case',
            Bypass_Triggers_By_Object_3__c = 'SVMXC__Installed_Product__c',
            Bypass_Triggers_By_Object_4__c = 'SVMXC__Service_Order__c',
            Bypass_Triggers_By_Object_5__c = 'SVMXC__Service_Order_Line__c'
        );
        insert apexSettings;
        SVMXC__Service_Contract__c objServiceContract = TestDataFieldService.createServiceContract(objAccount.Id);
        objServiceContract.Consumables_Included__c=false;
        objServiceContract.Status__c = 'Active';
        insert objServiceContract;
        system.assertNotEquals(null,objServiceContract.id);
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP VM', 'USD', 'New');
        objInstalledProduct.SVMXC__Company__c = objAccount.Id;
        insert objInstalledProduct;
        system.assertNotEquals(null,objInstalledProduct.id);
        
        Case objCase = TestDataCase.initServiceRequestCase(objContact);
        objCase.SVMXC__Component__c = objInstalledProduct.Id;
        insert objCase;
        system.assertNotEquals(null,objCase.id);
        
        SVMXC__Service_Order__c workOrder = TestDataFieldService.createWorkOrder('Field Service', objCase.Id, 'Initiated');
        workOrder.SVMXC__Company__c = objAccount.id;
        workOrder.SVMXC__Component__c = objInstalledProduct.Id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Is_Auto_Created__c=true;
        insert workOrder;
        system.assertNotEquals(null,workOrder.id);
        
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        insert objOrderDetail;
        system.assertNotEquals(null,objOrderDetail.id);

        Applied_Contract__c objEntitlement = TestDataFieldService.createEntitlement(objCase.Id, workOrder.Id, objServiceContract.Id);
        insert objEntitlement;
        system.assertNotEquals(null,objEntitlement.id);
        
        Test.stopTest();
        WorkOrderWrapper.ServiceOrder objWOWrapperNoParam=new WorkOrderWrapper.ServiceOrder();
        WorkOrderWrapper.ServiceOrder objWOWrapperWOId=new WorkOrderWrapper.ServiceOrder(workOrder);
        WorkOrderWrapper.ServiceOrderLine objWDWrapperNoParam=new WorkOrderWrapper.ServiceOrderLine();
        WorkOrderWrapper.ServiceOrderLine objWDWrapperWDId=new WorkOrderWrapper.ServiceOrderLine(objOrderDetail);
        WorkOrderWrapper.ServiceContracts objContWrapperNoParam=new WorkOrderWrapper.ServiceContracts();
        WorkOrderWrapper.ServiceContracts objContWrapperAppConId=new WorkOrderWrapper.ServiceContracts(objEntitlement);
      
    }
}