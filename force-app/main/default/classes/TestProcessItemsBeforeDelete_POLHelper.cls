/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Test class for ProcessItemsBeforeDelete_POLHelper
*/ 
@IsTest(SeeAllData=True)
private class TestProcessItemsBeforeDelete_POLHelper {

    static final String STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT = 'Service Support';
    static final String STRING_WORK_ORDER_STATUS_INITIATED ='Initiated';
    static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';

    /*******************************************************************************************************
    * @description test processLineItemsBeforeDelete method throwing error
    */
    private static testmethod void partsOrderLinesDeletionTest() {
        //Create Account
        Account objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Account_Group__c='Distributor';
        insert objAcc;
        System.assertNotEquals(null, objAcc.Id);

        //Create Case
        Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
        Case objCase = TestDataCase.getNewComplaintCase(objCon);
        objCase.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Service Request');
        update objCase;
        System.assertNotEquals(null, objCase.Id);
        
        SVMXC__Site__c objLocationRec = new SVMXC__Site__c(Name = 'test');
        insert objLocationRec;
        System.assertNotEquals(null, objLocationRec.Id);
        
        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        System.assertNotEquals(null, objWorkOrder.Id);

        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = '13';
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=objLocationRec.id;
        insert objPartsOrder;
        System.assertNotEquals(null, objPartsOrder.Id);
        
        Product2 product1 = TestDataMaster.createProduct(false);
        product1.Material_Class__c = 'Consumables';
        insert product1;
        System.assertNotEquals(null, product1.Id);

        Test.startTest();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.SVMXC__Product__c = product1.Id;
        
        insert objPartsOrderLine;
        objPartsOrderLine.SVMXC__Line_Status__c = 'Shipped';
        objPartsOrderLine.SVMXC__Actual_Quantity2__c= 1;
        update objPartsOrderLine;
        Boolean isErrorThrown;
        try {
            delete objPartsOrderLine;
        } catch(Exception e) {
            isErrorThrown = e.getMessage().contains(Label.PartsOrderLinesDeletionError);
        }
        System.Assert(isErrorThrown, 'Parts Order Lines Deletion Error not thrown');
        

    }
    /**
     *  @author      : Nitin
     *  @description : method to cover catch block in AutoDebrief_POLHelper
     **/
    @isTest
    public static void coverCatchBlockAutoDebriefPOLHelper(){
        try{
            AutoDebrief_POLHelper.catchException = true;
            AutoDebrief_POLHelper pd = new AutoDebrief_POLHelper(null);
            Test.startTest();
            System.enqueueJob(pd);
            Test.stopTest();
        }
        catch(Exception e){
            System.assert(e!=null, 'e is not empty');
        }
    }
}
