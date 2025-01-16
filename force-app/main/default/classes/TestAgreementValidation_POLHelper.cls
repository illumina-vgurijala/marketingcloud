/**
* @author Shivani Jain
* @date 29 Nov 2021
*
* @description DCP-42926 Test class for ProcessItemsBeforeDelete_POLHelper

MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Sagar Madkaikar        06-Jun-2022         DCP-51199 : Modified testvalidateIfDCIRAgreementIsGeneratedNoError() method 
 *                                                  to create Agreement and Attachment Test Record
 *                                                  Added new method testvalidateIfCOFDAgreementIsGenerated() to test COFD Validation.

****************************************************************************************************************************************/ 
 
@IsTest(SeeAllData=True)
private class TestAgreementValidation_POLHelper {

    static final String STRING_SHIPPING_TYPE_TRUNK = 'Trunk';
    static final String STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT = 'Service Support';
    static final String STRING_WORK_ORDER_STATUS_INITIATED ='Initiated';
    static final String STRING_WORK_ORDER_TYPE_INSTALLATION = 'Installation';

    static SVMXC__RMA_Shipment_Order__c objPartsOrder;

    /*******************************************************************************************************
    * @description setup data
    */
    static void testDataCreation() {
        List<SVMXC__Site__c> lstlocation =new List<SVMXC__Site__c>();
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(fromLocation);

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(toLocation);
        insert lstlocation;
        
        System.assertNotEquals(null, fromLocation.Id);
        System.assertNotEquals(null, toLocation.Id);

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=FromLocation.id;
        objPartsOrder.SVMXC__Source_Location__c=FromLocation.id;
        objPartsOrder.SVMXC__Destination_Location__c=toLocation.id;
        insert objPartsOrder;
        System.assertNotEquals(null, objPartsOrder.Id);
    }

    /*******************************************************************************************************
    * @description test validateIfLoanergreementIsGenerated method throwing error
    */
    static testmethod void testAgreementValidationThrowError() {
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileID());
        cp.Is_Channel_Partner__c= false;
        upsert cp;

        Boolean expectedExceptionThrown = false;  // Initialize variable
        testDataCreation();  // Ensure your test data is created properly
        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;
        System.assertNotEquals(null, objPartsOrderLine.Id);

        Test.startTest();
        try {
            // Set Loaner Agreement Signed field and attempt to update
            objPartsOrderLine.Loaner_Agreement_Signed__c = true;
            update objPartsOrderLine;
        } catch (Exception ex) {
            // Check if the exception message contains the expected error message label
            expectedExceptionThrown = ex.getMessage().contains(Label.POLLoanerAgreementCheckError);
        }
        Test.stopTest();
        // Assert that the exception was thrown with the expected message
        System.assert(expectedExceptionThrown, 'Expected exception was not thrown or the message did not match');
    }    

    /*******************************************************************************************************
    * @description test validateIfLoanergreementIsGenerated method not throwing error
    */
    static testmethod void testAgreementValidationNotThrowError() {
        testDataCreation();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;
        System.assertNotEquals(null, objPartsOrderLine.Id);

        //create ContentDocumentLink  record 
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Limit 1];
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objPartsOrderLine.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';

        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = 'Testagreement';
        agreement.echosign_dev1__Status__c = 'Signed';   
        agreement.Parts_Order_Line__c=objPartsOrderLine.Id;
        insert cdl; 
        System.assertNotEquals(null, cdl.Id);

        insert agreement;  
        System.assertNotEquals(null, agreement.Id);

        Test.startTest();
        
        objPartsOrderLine.Loaner_Agreement_Signed__c=true;
        update objPartsOrderLine;
        
        Test.stopTest();
        
    }

    /*******************************************************************************************************
    * @description test validateIfDCIRAgreementIsGenerated method throwing error
    */
    static testmethod void testvalidateIfDCIRAgreementIsGenerated() {
        List<SVMXC__Site__c> lstlocation =new List<SVMXC__Site__c>();
        SVMXC__Site__c fromLocation = new SVMXC__Site__c(Name = 'test',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(fromLocation);

        SVMXC__Site__c toLocation = new SVMXC__Site__c(Name = 'test1',SVMXC__Stocking_Location__c=true,Type__c=STRING_SHIPPING_TYPE_TRUNK);
        lstlocation.add(toLocation);

        insert lstlocation;

        SVMXC__Service_Order__c objWorkOrder = TestDataFieldService.createWorkOrderWithoutCase(STRING_WORK_ORDER_RECORD_TYPE_SERVICE_SUPPORT,STRING_WORK_ORDER_STATUS_INITIATED, STRING_WORK_ORDER_TYPE_INSTALLATION);
        SVMXC__RMA_Shipment_Order__c objPartsOrder = TestDataFieldService.createPartsOrderForInstallationWO(objWorkOrder.Id);
        objPartsOrder.SVMXC__Order_Status__c = 'Open';
        objPartsOrder.ERP_Sales_Order_Number__c = String.valueOf(Math.random());
        objPartsOrder.Contact_Name__c='Test';
        objPartsOrder.Contact_Phone__c='Test';
        objPartsOrder.Shipping_Location__c=FromLocation.id;
        objPartsOrder.SVMXC__Source_Location__c=FromLocation.id;
        objPartsOrder.SVMXC__Destination_Location__c=toLocation.id;
        insert objPartsOrder;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        objPartsOrderLine.Is_DCIR_Filled__c = false;
        objPartsOrderLine.Enable_DCIR__c = false;
        insert objPartsOrderLine;
        
        test.startTest();
        
        try{
            objPartsOrderLine.Is_DCIR_Filled__c=true;
            objPartsOrderLine.Enable_DCIR__c = true;
            update objPartsOrderLine;
        }Catch(Exception ex){
            system.assert(ex.getMessage().contains(Label.POLDCIRCheckError));
        }
        
        test.stopTest();
    }

    /*******************************************************************************************************
    * @description test validateIfDCIRAgreementIsGenerated method not throwing error
    */
    static testmethod void testvalidateIfDCIRAgreementIsGeneratedNoError() {
        testDataCreation();

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;
        System.assertNotEquals(null, objPartsOrderLine.Id);

        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument Limit 1];
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = objPartsOrderLine.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        System.assertNotEquals(null, cdl.Id);

        //DCP-51199 : Creating Test Agreement Record having Name containing DCIR word.
        echosign_dev1__SIGN_Agreement__c agreement = new echosign_dev1__SIGN_Agreement__c();
        agreement.Name = 'DCIR Form';
        agreement.echosign_dev1__Status__c = 'Signed';   
        agreement.Parts_Order_Line__c=objPartsOrderLine.Id;
        insert agreement;  
        System.assertNotEquals(null, agreement.Id,'Agreement record creation failed');

        //DCP-51199 : Creating Test Attachment Record having Name containing DCIR word.
        Blob body = Blob.valueOf('Test DCIR');
    	Attachment attachment = new Attachment();
    	attachment.ParentId = objPartsOrderLine.Id;
    	attachment.Name = 'Test DCIR Form';
    	attachment.Body = body;
    	insert attachment;

        Test.startTest();
        
        objPartsOrderLine.Is_DCIR_Filled__c=true;
        update objPartsOrderLine;
        
        Test.stopTest();

    }
    /*******************************************************************************************************
    * @description : DCP-51199 :test testvalidateIfCOFDAgreementIsGenerated method throwing error
    */
    static testmethod void testvalidateIfCOFDAgreementIsGenerated() {
        testDataCreation();
        Boolean expectedExceptionThrown;

        SVMXC__RMA_Shipment_Line__c objPartsOrderLine = TestDataFieldService.createPartsOrderLines(objPartsOrder.Id);
        insert objPartsOrderLine;
        System.assertNotEquals(null, objPartsOrderLine.Id,'Parts Order creation failed');

        Test.startTest();
        
        try {
            objPartsOrderLine.Is_CofD_Filled__c=true;
            update objPartsOrderLine;
        } catch(Exception ex){
            expectedExceptionThrown = ex.getMessage().contains(Label.POLCOFDCheckError) ? true : false;
        }
        system.assert(expectedExceptionThrown, 'testvalidateIfCOFDAgreementIsGenerated method failed');
        
        Test.stopTest();

    }

}
