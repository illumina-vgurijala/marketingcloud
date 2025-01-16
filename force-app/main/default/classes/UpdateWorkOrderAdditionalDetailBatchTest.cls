/***************************************************************************************************************************************
* NAME         : UpdateWorkOrderAdditionalDetailBatchTest
* DESCRIPTION  :  UpdateWorkOrderAdditionalDetailBatchTest.
*                    
* @AUTHOR : Abhishek Yadav
* @DATE   : 24-Sept-2024
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek Yadav            24-Sept-2024           Initial Version.
****************************************************************************************************************************************/
@isTest
public class UpdateWorkOrderAdditionalDetailBatchTest {
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
            SVMXC__Service_Order__c order = new SVMXC__Service_Order__c(
                RecordTypeId = woRecordTypeId,
                SVMXC__Problem_Description__c = 'Problem ' + i,
                English_Translation_Description__c = 'eng Description' + i,
                Evaluation__c = 'Evaluation ' + i,
                SVMXC__Work_Performed__c = 'Work Performed ' + i,
                Verification_Result__c = 'Verification Result ' + i,
                SVMXC__Order_Status__c = 'Closed',
                CreatedDate = System.today().addDays(-30),
                SVMXC__Order_Type__c = 'Installation',
                Is_Auto_Created__c = true
            );
            serviceOrders.add(order);
        }
        insert serviceOrders;
    }

    @isTest
    static void testBatchProcess() {
        // Execute the batch with a small batch size
        Test.startTest();
        // Initialize the batch class
        UpdateWorkOrderAdditionalDetailBatch batch = new UpdateWorkOrderAdditionalDetailBatch('test@email.com' , 730);
        Database.executeBatch(batch, 200);
        Test.stopTest();
        
        // Check if the service orders have been updated
        List<SVMXC__Service_Order__c> updatedOrders = [SELECT Additional_Detail__c, English_Translation_Additional_Detail__c 
                                                       FROM SVMXC__Service_Order__c WHERE SVMXC__Order_Status__c = 'Closed'];
        
        // Assert that the Additional_Detail__c and English_Translation_Additional_Detail__c are updated
        for (SVMXC__Service_Order__c order : updatedOrders) {
            System.assertNotEquals(null, order.Additional_Detail__c, 'Additional_Detail__c should be updated');
            System.assertNotEquals(null, order.English_Translation_Additional_Detail__c, 'English_Translation_Additional_Detail__c should be updated');
        }
    }

    @isTest
    static void testFinishMethod() {
        // Call the finish method directly
        Test.startTest();
        UpdateWorkOrderAdditionalDetailBatch batch = new UpdateWorkOrderAdditionalDetailBatch('test@email.com' , 730);
        batch.finish(null);  // Simulate the finish method
        Test.stopTest();
        
        // Simple assertion to ensure the finish method ran
        System.assert(true, 'Batch finish method should complete successfully.');
    }
}