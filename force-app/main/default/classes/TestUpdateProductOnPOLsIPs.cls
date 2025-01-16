/*
* Test class for UpdateProductOnPOLsIPs
*/
@isTest(SeeAllData = true)	
public class TestUpdateProductOnPOLsIPs {

    /*
    * Test Method for Update Installed products functionality
    */	
    @isTest
    public static void testUpdateProds(){
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');

        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
        
        SVMXC__RMA_Shipment_Order__c partOrder;
        partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.ERP_Sales_Order_Number__c = '28189';
        partOrder.SVMXC__Order_Status__c = 'Open';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.SVMXC__Order_Type__c = 'Return';
        insert partOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(partOrder.Id);
        objPartsOrderLine.ERP_Sales_Order_Item__c = '01910';// + '199842';
        objPartsOrderLine.Product_Code1__c = 'aaaaawwwwwcc';
        insert objPartsOrderLine;

        // Insert a Missing_Product__c record CMCM-2846 sart
        Missing_Product__c missingProduct = new Missing_Product__c(Product_External_Id__c = 'aaaaawwwwwcc');
        insert missingProduct;

        // Get the initial count of Missing_Product__c records
        Integer initialCount = [SELECT COUNT() FROM Missing_Product__c LIMIT 199];//CMCM-2846

        // Setup Product2 and run business logic
        Product2 p = new Product2(Name = 'TestProductUpdated', ProductCode = 'aaaaawwwwwcc', Material_Number__c = 'aaaaawwwwwcc');
        insert p;
        
        UpdateProductOnPOLsIPs.doBusinessLogic(new List<Id>{p.Id});
        
        // Get the count after the business logic execution
        Integer finalCount = [SELECT COUNT() FROM Missing_Product__c LIMIT 199];//CMCM-2846

        // Assert the Missing_Product__c record count decreases by 1
        System.assertEquals(initialCount - 1, finalCount, 'One Missing product record should be deleted after logic execution.');//CMCM-2846

        // Validate that the Product2 is correctly linked to the RMA Shipment Line
        SVMXC__RMA_Shipment_Line__c updatedPartsOrderLine = [SELECT SVMXC__Product__c FROM SVMXC__RMA_Shipment_Line__c WHERE Id =: objPartsOrderLine.Id];
        System.assertEquals(p.Id, updatedPartsOrderLine.SVMXC__Product__c, 'The product should be linked to the parts order line.');
    }
}
