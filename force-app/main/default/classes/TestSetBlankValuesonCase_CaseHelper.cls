/***************************************************************************************************************************************
 * NAME   : TestSetBlankValuesonCase_CaseHelper
 * DESCRIPTION  : TestClass for SetBlankValuesonCase_CaseHelper
 *    
 * @AUTHOR : Vishal
 * @DATE   : 25-Oct-2024  
 * ****************************************************************************************************************************************/ 
@isTest
public with sharing class TestSetBlankValuesonCase_CaseHelper {
    public static final string CASE_RECORDTYPE_SERVICE_REQUEST = 'Service Request';
    public static final string CASE_STATUS_INITIATED = 'Initiated';
    public static final string CASE_ORIGIN_PHONE = 'Phone - CS';
    public static final string RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_CONFIRMED = 'Customer Confirmed Receipt of Notification and Understands its Content';
    public static final string RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_NOT_RESPONDED = 'Customer has not responded';
    public static final string MODE_OF_CONFIRMATION_VERBAL = 'Verbal';
    public static final string RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED = 'Recall Actions Postponed';
    public static final string RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED = 'Recall Actions Declined';
    public static final string RECALL_ACTIVITY_RECALL_ACTIONS_ACKNOWLEDGED = 'Recall Actions Acknowledged & Completed';
    public static final string REASON_RECALL_ACTIVITY_POSTPONED_OTHER = 'Other';
    public static final string REASON_RECALL_ACTIVITY_DECLINED_OTHER = 'Other';
    public static final string PRODUCT_RETURN_STATUS_RETURNED_STATUS_RETURNED_TO_ILLUMINA = 'Product Returned to Illumina';
    public static final string PRODUCT_RETURN_STATUS_RETURNED_THROUGH_ANOTHER_WO = 'Returned through another Work Order';
    public static final string TEST_STRING = 'Test';

    static testMethod void testBlankvaluesOnRecallFields() {
        //Insert case
        Case objCase = TestDataCase.initNewCase(CASE_RECORDTYPE_SERVICE_REQUEST, CASE_STATUS_INITIATED, CASE_ORIGIN_PHONE);
        objCase.Recall__c = true;
        objCase.Recall_Acknowledgement_Status__c = RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_CONFIRMED;   
        objCase.Mode_of_Confirmation__c = MODE_OF_CONFIRMATION_VERBAL;
        objCase.Date_of_Customer_Confirmation__c = date.today();
        objCase.Recall_Activity__c = RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED;
        objCase.Reason_Recall_Activity_Postpone__c = REASON_RECALL_ACTIVITY_POSTPONED_OTHER;
        objCase.Reason_Recall_Postponed_Declined_Other__c = TEST_STRING;
        objCase.Product_Returned_Status__c = REASON_RECALL_ACTIVITY_POSTPONED_OTHER;
        objCase.Product_Return_Status_Other__c = TEST_STRING;
        insert objCase;

        Test.startTest();
        objCase.Recall_Acknowledgement_Status__c = RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_NOT_RESPONDED;
        objCase.Recall_Activity__c = RECALL_ACTIVITY_RECALL_ACTIONS_ACKNOWLEDGED;
        objCase.Product_Returned_Status__c = PRODUCT_RETURN_STATUS_RETURNED_STATUS_RETURNED_TO_ILLUMINA;
        update objCase;
        Test.stopTest();

        Case updatedCase = [SELECT Mode_of_Confirmation__c, Date_of_Customer_Confirmation__c, Reason_Recall_Activity_Postpone__c, 
                                   Reason_Recall_Postponed_Declined_Other__c, Product_Return_Status_Other__c
                            FROM Case 
                            WHERE Id = :objCase.Id];
        
        // Assertions for the first case
        System.assertEquals(null, updatedCase.Mode_of_Confirmation__c, 'Mode of Confirmation should be cleared.');
        System.assertEquals(null, updatedCase.Date_of_Customer_Confirmation__c, 'Date of Customer Confirmation should be cleared.');
        System.assertEquals(null, updatedCase.Reason_Recall_Activity_Postpone__c, 'Reason Recall Activity Postponed should be cleared.');
        System.assertEquals(null, updatedCase.Reason_Recall_Postponed_Declined_Other__c, 'Reason Recall Postponed/Declined - Other should be cleared.');
        System.assertEquals(null, updatedCase.Product_Return_Status_Other__c, 'Product Return Status - Other should be cleared.');
        
        //Insert Case
        Case objCase2 = TestDataCase.initNewCase(CASE_RECORDTYPE_SERVICE_REQUEST, CASE_STATUS_INITIATED, CASE_ORIGIN_PHONE);
        objCase2.Recall__c = true;
        objCase2.Recall_Acknowledgement_Status__c = RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_CONFIRMED;   
        objCase2.Mode_of_Confirmation__c = MODE_OF_CONFIRMATION_VERBAL;
        objCase2.Date_of_Customer_Confirmation__c = date.today();
        objCase2.Recall_Activity__c = RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED;
        objCase2.Reason_Recall_Activity_Declined__c = REASON_RECALL_ACTIVITY_DECLINED_OTHER;
        objCase2.Reason_Recall_Postponed_Declined_Other__c = TEST_STRING;
        objCase2.Product_Returned_Status__c = PRODUCT_RETURN_STATUS_RETURNED_THROUGH_ANOTHER_WO;
        insert objCase2;

        objCase2.Recall_Activity__c = RECALL_ACTIVITY_RECALL_ACTIONS_ACKNOWLEDGED;
        objCase.Product_Returned_Status__c = PRODUCT_RETURN_STATUS_RETURNED_STATUS_RETURNED_TO_ILLUMINA;
        update objCase2;
        Case updatedCase2 = [SELECT Mode_of_Confirmation__c, Date_of_Customer_Confirmation__c, Reason_Recall_Activity_Declined__c, 
                                    Reason_Recall_Postponed_Declined_Other__c 
                             FROM Case 
                             WHERE Id = :objCase2.Id];

        // Assertions for the second case
        System.assertEquals(null, updatedCase2.Reason_Recall_Activity_Declined__c, 'Reason Recall Activity Declined should be cleared.');
        System.assertEquals(null, updatedCase2.Reason_Recall_Postponed_Declined_Other__c, 'Reason Recall Postponed/Declined - Other should be cleared.');
    }
}