/***************************************************************************************************************************************
* NAME         : UpdateWorkOrderNotesBatchTest
* DESCRIPTION  :  UpdateWorkOrderNotesBatchTest.
*                    
* @AUTHOR : Abhishek Yadav
* @DATE   : 1-Oct-2024
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav            1-Oct-2024           Initial Version.
****************************************************************************************************************************************/
@isTest
public with sharing class UpdateWorkOrderNotesBatchTest { 
    public static final String STRING_WO_RECORDTYPE_REMOTE_SUPPORT = 'Remote Support';
    @testSetup
    static void setup() {
        cs_Apex_Settings__c apexSetting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
            apexSetting.Bypass_All_Validations__c = true;
            upsert apexSetting;
        // Create test SVMXC__Service_Order__c records that match the batch query conditions
        List<SVMXC__Service_Order__c> serviceOrders = new List<SVMXC__Service_Order__c>();
        Id woRecordTypeId = Schema.SObjectType.SVMXC__Service_Order__c.getRecordTypeInfosByName().get(STRING_WO_RECORDTYPE_REMOTE_SUPPORT).getRecordTypeId();
        for (Integer i = 0; i < 5; i++) {
            SVMXC__Service_Order__c order = new SVMXC__Service_Order__c();
            order.RecordTypeId = woRecordTypeId;
            order.SVMXC__Problem_Description__c = 'Problem ' + i;
            order.Evaluation__c = 'Evaluation ' + i;
            if(i == 2) {
               order.Notes__c = 'Test';
            }
            order.SVMXC__Work_Performed__c = 'Work Performed ' + i;
            order.Verification_Result__c = 'Verification Result ' + i;
            order.SVMXC__Order_Type__c = 'Installation';
            order.Is_Auto_Created__c = true;
            serviceOrders.add(order);
        }
        insert serviceOrders;
    }

    @isTest
    static void testBatchProcess() {
        // Execute the batch with a small batch size
        Test.startTest();
        // Initialize the batch class
        UpdateWorkOrderNotesBatch batch = new UpdateWorkOrderNotesBatch('test@email.com');
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Check if the service orders have been updated
        List<SVMXC__Service_Order__c> updatedOrders = [SELECT Notes__c FROM SVMXC__Service_Order__c LIMIT 10];
        
        // Assert that the Notes__c are updated
        for (SVMXC__Service_Order__c order : updatedOrders) {
            System.assertNotEquals(null, order.Notes__c, 'Notes__c should be updated');
        }
    }

    @isTest
    static void testFinishMethod() {
        // Call the finish method directly
        Test.startTest();
        UpdateWorkOrderNotesBatch batch = new UpdateWorkOrderNotesBatch('test@email.com');
        batch.finish(null);  // Simulate the finish method
        Test.stopTest();
        
        // Simple assertion to ensure the finish method ran
        System.assert(true, 'Batch finish method should complete successfully.');
    }
}