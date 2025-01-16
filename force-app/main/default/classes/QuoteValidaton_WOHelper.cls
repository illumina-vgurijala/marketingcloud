/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Quote creation from the Work Order. 
*/ 
public with sharing class QuoteValidaton_WOHelper {

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: Work Order Assignment for Quote Creation
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */
    public static void workOrderAssignmentForQuoteCreation(Map<Id, SObject> oldRecords, List<sObject> records, Id idEstimatesRecordTypeId) {
 
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 
            // DCP- 46318
            validateUserForAutomatedQuoteCreation(objWorkOrder,objOldWorkOrder, idEstimatesRecordTypeId);
            // Removed logic to update WO owner to estimate Queue //DCP-45874
        }
    }

    /**
    *   DCP- 46318
    *   @author Adyasha Satapathy
    *   @param Map<Id, SObject> idToOldWorkOrder
    *   @return void
    **/
    public static void validateUserForAutomatedQuoteCreation(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder, Id idEstimatesRecordTypeId) {
        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.validateUserForAutomatedQuoteCreation()');
        Id currentUserId = UserInfo.getUserId();
            
        if(objWorkOrder.RecordTypeId != idEstimatesRecordTypeId || currentUserId == objWorkOrder.OwnerId || Profiles.getAllAdminProfileIds().contains(Userinfo.getProfileId())
            || objWorkOrder.Initiate_Quoting__c == objOldWorkOrder.Initiate_Quoting__c || String.isBlank(objWorkOrder.Initiate_Quoting__c)) {
            ilib_LogEvent.pop();
            return;
        }

        Boolean boolLoggedInUserIsFieldSupport = String.isNotBlank(objWorkOrder.SVMXC__Group_Member__c) && currentUserId.to15().equals(objWorkOrder.Field_Support_Salesforce_User_Id__c);
        ilib_LogEvent.message('boolLoggedInUserIsFieldSupport: '+boolLoggedInUserIsFieldSupport);

        Boolean boolCriteriaPassedForBypass = false;
        Boolean boolLoggedInUserIsAccToFieldSupport = false;
        
        if(objWorkOrder.Partner_Work_Order__c) {
            boolLoggedInUserIsAccToFieldSupport = checkUserSatisfiesCriteria(currentUserId, WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c),new Set<String>{WorkOrders.STRING_LABEL_PRIMARY_FSE, WorkOrders.STRING_LABEL_SECONDARY_FSE, WorkOrders.STRING_LABEL_PRIMARY_FAS, WorkOrders.STRING_LABEL_FSM, WorkOrders.STRING_LABEL_SECONDARY_FAS});
            ilib_LogEvent.message('boolLoggedInUserIsAccToFieldSupport for partner wo: '+boolLoggedInUserIsAccToFieldSupport);
            boolCriteriaPassedForBypass = boolLoggedInUserIsAccToFieldSupport;
        } else {
            boolLoggedInUserIsAccToFieldSupport = checkUserSatisfiesCriteria(currentUserId,WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c),new Set<String>{WorkOrders.STRING_LABEL_FSM});
            ilib_LogEvent.message('boolLoggedInUserIsAccToFieldSupport for non partner wo: '+boolLoggedInUserIsAccToFieldSupport);
            boolCriteriaPassedForBypass = boolLoggedInUserIsFieldSupport || boolLoggedInUserIsAccToFieldSupport;
        }
        if(!boolCriteriaPassedForBypass) {
            objWorkOrder.addError(Label.WorkOrderPreventQuotingValidationErrorMessage);
        }    
        ilib_LogEvent.pop();
    }

    /**
    *   DCP- 46318
    *   @author Adyasha Satapathy
    *   @param Id userId, Map<String,Account_to_Field_Support__c> mapAccToFieldSupport, Set<String> setRoles
    *   @return Boolean
    **/
    public static Boolean checkUserSatisfiesCriteria(Id userId, Map<String,Account_to_Field_Support__c> mapAccToFieldSupport, Set<String> setRoles) {
        Boolean boolLoggedInUserSatisfiesCriteria = false;
        for(String strRole : setRoles) {
            if(mapAccToFieldSupport != NULL && !mapAccToFieldSupport.isEmpty() && mapAccToFieldSupport.get(strRole) != null) {
                Id accountToFieldSupportUserId = String.isNotBlank(mapAccToFieldSupport.get(strRole).User__c) ? mapAccToFieldSupport.get(strRole).User__r.SVMXC__Salesforce_User__c : NULL;
                boolLoggedInUserSatisfiesCriteria = userId == accountToFieldSupportUserId;                
            }
            if(boolLoggedInUserSatisfiesCriteria) break;
        }
        return boolLoggedInUserSatisfiesCriteria;
    }

}
