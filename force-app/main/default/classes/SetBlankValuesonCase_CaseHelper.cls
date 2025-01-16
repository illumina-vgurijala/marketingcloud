/****************************************************************************************************************************************
* NAME         : SetBlankValuesonCase_CaseHelper
* DESCRIPTION  : Helper class for Case
*                    
* @AUTHOR : Vishal
* @DATE   : 10-Oct-2024  
* @testclasses : TestSetBlankValuesonCase_CaseHelper
****************************************************************************************************************************************/ 
public with sharing class SetBlankValuesonCase_CaseHelper {
    
    public static final String RECORD_TYPE_SERVICE_REQUEST = 'Service Request';
    public static final String RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_CONFIRMED = 'Customer Confirmed Receipt of Notification and Understands its Content';
    public static final String RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED = 'Recall Actions postponed';
    public static final String RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED = 'Recall Actions Declined';
    public static final String REASON_RECALL_ACTIVITY_POSTPONED_OTHER = 'Other';
    public static final String REASON_RECALL_ACTIVITY_DECLINED_OTHER = 'Other';
    public static final String PRODUCT_RETURN_STATUS_OTHER = 'Other';
    public static final String PRODUCT_RETURN_STATUS_RETURNED_THROUGH_ANOTHER_WO = 'Returned through another Work Order';
    
    /**
    *  @author Vishal
    *  @description - Set blank values in recall fields.    
    *  @PARAM :  List<Case> newCases, Map<Id, Case> oldCaseMap
    *  @RETURN:  void
    */ 
    public static void setBlankValueOnRecallFields(List<Case> newCases, Map<Id, Case> oldCaseMap) {
        for (Case newCase : newCases) {
            Case oldCase = oldCaseMap.get(newCase.Id);

            // Early exit for non-Service Request or non-recall cases
            if (newCase.Record_Type__c != RECORD_TYPE_SERVICE_REQUEST || !newCase.Recall__c) {
                continue;
            }

            // Nullify fields based on specific changes
            clearRecallAcknowledgementFields(newCase, oldCase);
            clearRecallActivityFields(newCase, oldCase);
            clearProductReturnFields(newCase, oldCase);
        }
    }
    
    /**
    *  @author Vishal
    *  @description - Set blank values in Recall Acknowledgement Field.    
    *  @PARAM :  List<Case> newCases, Map<Id, Case> oldCaseMap
    *  @RETURN:  void
    */
    private static void clearRecallAcknowledgementFields(Case newCase, Case oldCase) {
        if (oldCase.Recall_Acknowledgement_Status__c == RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_CONFIRMED &&
            newCase.Recall_Acknowledgement_Status__c != RECALL_ACKNOWLEDGEMENT_STATUS_CUSTOMER_CONFIRMED) {
            newCase.Mode_of_Confirmation__c = '';
            newCase.Date_of_Customer_Confirmation__c = null;
        }
    }

     /**
    *  @author Vishal
    *  @description - Set blank values in Recall Activity fields.    
    *  @PARAM :  List<Case> newCases, Map<Id, Case> oldCaseMap
    *  @RETURN:  void
    */
    private static void clearRecallActivityFields(Case newCase, Case oldCase) {
        if (oldCase.Recall_Activity__c == RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED &&
            newCase.Recall_Activity__c != RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED) {
            newCase.Reason_Recall_Activity_Postpone__c = '';
        }

        if (oldCase.Recall_Activity__c == RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED &&
            newCase.Recall_Activity__c != RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED) {
            newCase.Reason_Recall_Activity_Declined__c = '';
        }
        if ((newCase.Recall_Activity__c == RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED &&
             newCase.Reason_Recall_Activity_Postpone__c != REASON_RECALL_ACTIVITY_POSTPONED_OTHER) ||
            (newCase.Recall_Activity__c == RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED &&
             newCase.Reason_Recall_Activity_Declined__c != REASON_RECALL_ACTIVITY_DECLINED_OTHER) || 
            (newCase.Recall_Activity__c != RECALL_ACTIVITY_RECALL_ACTIONS_DECLINED && 
             newCase.Recall_Activity__c != RECALL_ACTIVITY_RECALL_ACTIONS_POSTPONED)) {
            newCase.Reason_Recall_Postponed_Declined_Other__c = '';
        }
    }

     /**
    *  @author Vishal
    *  @description - Set blank values in Product return status fields.    
    *  @PARAM :  List<Case> newCases, Map<Id, Case> oldCaseMap
    *  @RETURN:  void
    */
    private static void clearProductReturnFields(Case newCase, Case oldCase) {
        if (oldCase.Product_Returned_Status__c == PRODUCT_RETURN_STATUS_OTHER &&
            newCase.Product_Returned_Status__c != PRODUCT_RETURN_STATUS_OTHER) {
            newCase.Product_Return_Status_Other__c = '';
        }

        if (oldCase.Product_Returned_Status__c == PRODUCT_RETURN_STATUS_RETURNED_THROUGH_ANOTHER_WO &&
            newCase.Product_Returned_Status__c != PRODUCT_RETURN_STATUS_RETURNED_THROUGH_ANOTHER_WO) {
            newCase.Product_Returned_Through_Work_Order__c = null;
        }
    }
}
