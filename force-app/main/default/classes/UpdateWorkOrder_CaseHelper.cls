/**
 * @description       : Update Work order fields based on the case criteria
 * @author            : Pooja Shalwadi
 * @last modified on  : 01-13-2023
**/

public with sharing class UpdateWorkOrder_CaseHelper {
    private static final Integer MAX_SIZE = 255;
    private static String reasonForReopen;
    private static final Set<String> WO_COMPLETED_STATUSES = new Set<String>{'Canceled','Closed','Reopen Requested','Completed','Closed-Duplicate'};
    private static final Set<String> CASE_PENDING_REVIEW_STATUSES = new Set<String>{'Pending Logistics Review', 'Pending QA Review'};
    public static List<Id> PendingReviewCases = new List<Id>();

    /**
    * @description :fetch and update work order records based on certain conditions
    * @param lstNewCases 
    * @param mapOldCases 
    **/
    public static void updateWorkOrderForVariousConditions(List<Case> lstNewCases, Map<Id, Case> mapOldCases){
        
        Set<Id> setCaseIds = new Set<Id>();		
        Map<Id, Case> mapIdToCase = new Map<Id, Case>();
        Map<Id, String> mapCasaeIdToChange = new map<Id, String>();
        Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder = new Map<Id, SVMXC__Service_Order__c>();         
		Map<Id,Case> mapCaseWithUpdatedProductsSerialLot = new Map<Id,Case>();
        Map<Id,Case> mapSubscriptionCase = new Map<Id,Case>();//Pooja
        setCaseIds=fetchUpdatedCases(lstNewCases,mapOldCases,mapIdToCase,mapCasaeIdToChange,mapCaseWithUpdatedProductsSerialLot,mapSubscriptionCase);
		CasesHelper.WorkOrders workOrderQuery = new  CasesHelper.WorkOrders();
        workOrderQuery.initMapWOIdToWorkOrders(setCaseIds, true);

        for(Case objNewCase : lstNewCases) {
            if(CASE_PENDING_REVIEW_STATUSES.contains(objNewCase.Previous_Status__c)){
                PendingReviewCases.add(objNewCase.Id);
            }
        }

        if(Cases.mapWOIdToWorkOrders != null && !Cases.mapWOIdToWorkOrders.isEmpty()){

            for(SVMXC__Service_Order__c objWorkOrder: Cases.mapWOIdToWorkOrders.values()){
                if(mapIdToCase.containsKey(objWorkOrder.SVMXC__Case__c)  && mapCasaeIdToChange.containsKey(objWorkOrder.SVMXC__Case__c)){
                    
                    addWORelatedToReopenCases(objWorkOrder,mapCaseWithUpdatedProductsSerialLot,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);              		
                    addWORelatedToUpdatedCase(objWorkOrder,mapCaseWithUpdatedProductsSerialLot,mapIdToWorkOrder,mapIdToCase,mapCasaeIdToChange);             
                }

                //DCP-46053 - Updating Product Serial Number and Product Lot Number 
                if(mapCaseWithUpdatedProductsSerialLot.containsKey(objWorkOrder.SVMXC__Case__c)){
                    if(mapIdToWorkOrder.containsKey(objWorkOrder.Id)){
                        mapIdToWorkOrder.get(objWorkOrder.Id).Product_Serial_Number__c = mapCaseWithUpdatedProductsSerialLot.get(objWorkOrder.SVMXC__Case__c).Product_Serial_Number__c;
                        mapIdToWorkOrder.get(objWorkOrder.Id).Product_Lot_Number__c = mapCaseWithUpdatedProductsSerialLot.get(objWorkOrder.SVMXC__Case__c).Product_Lot_Number__c;
                    }else{
                        objWorkOrder.Product_Serial_Number__c = mapCaseWithUpdatedProductsSerialLot.get(objWorkOrder.SVMXC__Case__c).Product_Serial_Number__c;
                        objWorkOrder.Product_Lot_Number__c = mapCaseWithUpdatedProductsSerialLot.get(objWorkOrder.SVMXC__Case__c).Product_Lot_Number__c;
                        mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder);
                    }
                }
                //DCP-46053 ends

               if(mapSubscriptionCase.containsKey(objWorkOrder.SVMXC__Case__c) && !WO_COMPLETED_STATUSES.contains(objWorkOrder.SVMXC__Order_Status__c)) {
                    objWorkOrder.Subscription__c = mapSubscriptionCase.get(objWorkOrder.SVMXC__Case__c).Subscription__c;
                    objWorkOrder.Subscription_License_Status__c = mapSubscriptionCase.get(objWorkOrder.SVMXC__Case__c).Subscription_License_Status__c;
                    objWorkOrder.Registrant_Email_Address__c = mapSubscriptionCase.get(objWorkOrder.SVMXC__Case__c).Registrant_Email_Address__c;
                    objWorkOrder.Domain_Name__c = mapSubscriptionCase.get(objWorkOrder.SVMXC__Case__c).Domain_Name__c;
                    objWorkOrder.Workgroup_Name__c = mapSubscriptionCase.get(objWorkOrder.SVMXC__Case__c).Workgroup_Name__c;
                    mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder);
               }
            }
        }
		                
		if(mapIdToWorkOrder != null && !mapIdToWorkOrder.isEmpty()){
            WorkOrders.skipWOTrigger = true; // INC0555781
            WorkOrders.isWOUpdatefromCase = true; // INC0555781 - WOTrigger-RecursionCheckAddOnCaseUpdate
			update  mapIdToWorkOrder.values();
		}
    }

    /**
    * @description : fetch updated Cases records
    * @param lstNewCases 
    * @param mapOldCases 
    * @param mapIdToCase 
    * @param mapCasaeIdToChange 
    * @param mapCaseWithUpdatedProductsSerialLot 
    * @return Set<Id> 
    **/
    public static Set<Id> fetchUpdatedCases(List<Case> lstNewCases, Map<Id, Case> mapOldCases,Map<Id, Case> mapIdToCase,Map<Id, String> mapCasaeIdToChange,Map<Id,Case> mapCaseWithUpdatedProductsSerialLot,Map<Id,Case> mapSubscriptionCase)
    {
        Set<Id> setCaseIds = new Set<Id>();	
        Boolean isFieldUpdated= false;
        
        for(Case objNewCase : lstNewCases) {
            Case objOldCase = null;
            if(mapOldCases != null){
                objOldCase = mapOldCases.get(objNewCase.id);
            }
            setCaseIds.add(objNewCase.Id);

            fetchUpdatedReopenRequestedCase(objNewCase,objOldCase,mapIdToCase,mapCasaeIdToChange);
           
           if(objNewCase.RecordTypeId == Cases.BUSINESS_ISSUE_CASE_RECORDTYPE && objNewCase.SVMXC__Site__c != objOldCase.SVMXC__Site__c){
            mapIdToCase.put(objNewCase.Id, objNewCase);
            mapCasaeIdToChange.put(objNewCase.Id, 'CaseOfLocationChange'); 
            }  
            
            isFieldUpdated=objNewCase.Subject != objOldCase.Subject || objNewCase.Description != objOldCase.Description || objNewCase.Next_Steps__c != objOldCase.Next_Steps__c || objNewCase.Follow_up_Needed__c != objOldCase.Follow_up_Needed__c;

            if( isFieldUpdated && objNewCase.Evaluation__c == objOldCase.Evaluation__c && objNewCase.Verification_Result__c == objOldCase.Verification_Result__c && objNewCase.Work_Performed__c == objOldCase.Work_Performed__c){
                mapIdToCase.put(objNewCase.Id, objNewCase);
                mapCasaeIdToChange.put(objNewCase.Id, 'SubjectDescriptionOthersChange'); 
            } 

            if(objNewCase.Product_Serial_Number__c != objOldCase.Product_Serial_Number__c || objNewCase.Product_Lot_Number__c != objOldCase.Product_Lot_Number__c ){
                mapCaseWithUpdatedProductsSerialLot.put(objNewCase.Id, objNewCase);
            }

            //pooja: start
            if(objNewCase.Subscription__c != objOldCase.Subscription__c){
                mapSubscriptionCase.put(objNewCase.Id, objNewCase);
            }
            //pooja: END
        }
        return setCaseIds; 
    }
	
  
    /**
    * @description :fetch updated records satisfying condition of Reopen requested cases
    * @author ChangeMeIn@UserSettingsUnder.SFDoc | 06-09-2022 
    * @param objNewCase 
    * @param objOldCase 
    * @param mapIdToCase 
    * @param mapCasaeIdToChange 
    **/
    public static void fetchUpdatedReopenRequestedCase(Case objNewCase, Case objOldCase,Map<Id, Case> mapIdToCase,Map<Id, String> mapCasaeIdToChange)
    {
         //Case Update Owner With Reopen Requester DCP-27008 
         if(objOldCase.Status != objNewCase.Status && objOldCase.Status == System.label.CaseStatusReopenRequested && 
         (objNewCase.Status == objNewCase.Previous_Status__c  ||objNewCase.Status == System.label.CaseStatusReopenedInProgress || objNewCase.Status == System.label.CaseStatusInProgress )){
            mapIdToCase.put(objNewCase.Id, objNewCase);
            mapCasaeIdToChange.put(objNewCase.Id, 'CaseOfReopenDenied'); 
        }
        //Case Update Reopen Requester And Send Email DCP-27008         
        if(objOldCase.Status != objNewCase.Status && 
        ((objOldCase.Status != System.label.CaseStatusReopenRequested && objNewCase.Status == System.label.CaseStatusReopenRequested ) || 
        (objOldCase.Status != System.label.CaseStatusReopened && objNewCase.Status == System.label.CaseStatusReopened )) )
        {
            mapIdToCase.put(objNewCase.Id, objNewCase);
            mapCasaeIdToChange.put(objNewCase.Id, 'CaseOfReopenStatus'); 
        }
        
    }

    /**
    * @description :Add work order to update for reopen denied and reopened cases
    * @param objWorkOrder 
    * @param mapCaseWithUpdatedProductsSerialLot 
    * @param mapIdToWorkOrder 
    * @param mapIdToCase 
    * @param mapCasaeIdToChange 
    **/
    public static void addWORelatedToReopenCases(SVMXC__Service_Order__c objWorkOrder,Map<Id,Case> mapCaseWithUpdatedProductsSerialLot,Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder,Map<Id, Case> mapIdToCase,Map<Id, String> mapCasaeIdToChange)
    {
        if(mapCasaeIdToChange.get(objWorkOrder.SVMXC__Case__c) == Cases.CASE_OF_REOPENED_DENIED){
            if(mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Status == Label.CaseStatusInProgress){
                objWorkOrder.SVMXC__Order_Status__c = (!PendingReviewCases.contains(objWorkOrder.SVMXC__Case__c) && objWorkOrder.WO_Precompletion_Status__c != null) ? objWorkOrder.WO_Precompletion_Status__c :Label.WorkOrderStatusAssigned; //CMCM-2640
                objWorkOrder.Reason_for_Approval_Denial_of_Reopen__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Reason_for_Approval_Denial_of_Reopen__c;
                objWorkOrder.Approver_Rejector__c= UserInfo.getUserId();
                mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder );
            }
            else{
                if(objWorkOrder.Order_Previous_Status__c != objWorkOrder.SVMXC__Order_Status__c){
                    objWorkOrder.SVMXC__Order_Status__c = objWorkOrder.Order_Previous_Status__c;
                    objWorkOrder.Approver_Rejector__c= UserInfo.getUserId();
                    objWorkOrder.Reason_for_Approval_Denial_of_Reopen__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Reason_for_Approval_Denial_of_Reopen__c;
                    mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder);
                }
            }               
        }
        
        if(mapCasaeIdToChange.get(objWorkOrder.SVMXC__Case__c) == Cases.CASE_OF_REOPEN_STATUS){
            if(mapIdToWorkOrder != null && !mapIdToWorkOrder.isEmpty() && mapIdToWorkOrder.containsKey(objWorkOrder.Id)){
                mapIdToWorkOrder.get(objWorkOrder.Id).Order_Previous_Status__c = mapIdToWorkOrder.get(objWorkOrder.Id).SVMXC__Order_Status__c;
                mapIdToWorkOrder.get(objWorkOrder.Id).SVMXC__Order_Status__c = mapIdToWorkOrder.get(objWorkOrder.Id).WO_Reopen_Status__c ;
                reasonForReopen = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Reason_for_Reopen__c;
                if(reasonForReopen.Length()>=MAX_SIZE){
                mapIdToWorkOrder.get(objWorkOrder.Id).Reason_for_Reopen__c =  reasonForReopen.substring(0, MAX_SIZE);
                }else{
                mapIdToWorkOrder.get(objWorkOrder.Id).Reason_for_Reopen__c = reasonForReopen;}
                mapIdToWorkOrder.get(objWorkOrder.Id).Reopen_Requester__c = UserInfo.getUserId();
            }
            else{
                objWorkOrder.Order_Previous_Status__c = objWorkOrder.SVMXC__Order_Status__c;
                objWorkOrder.SVMXC__Order_Status__c = objWorkOrder.WO_Reopen_Status__c ;
                reasonForReopen = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Reason_for_Reopen__c;
                if(reasonForReopen.Length()>MAX_SIZE){
                objWorkOrder.Reason_for_Reopen__c = reasonForReopen.substring(0, MAX_SIZE);}
                else
                { 
                    objWorkOrder.Reason_for_Reopen__c = reasonForReopen;
                }
                objWorkOrder.Reopen_Requester__c = UserInfo.getUserId();
                mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder);                        
            }               
        }
    }
    /**
    * @description : Add work order to update for which case location/ subject/ description is updated
    * @param objWorkOrder 
    * @param mapCaseWithUpdatedProductsSerialLot 
    * @param mapIdToWorkOrder 
    * @param mapIdToCase 
    * @param mapCasaeIdToChange 
    **/
    public static void addWORelatedToUpdatedCase(SVMXC__Service_Order__c objWorkOrder,Map<Id,Case> mapCaseWithUpdatedProductsSerialLot,Map<Id, SVMXC__Service_Order__c> mapIdToWorkOrder,Map<Id, Case> mapIdToCase,Map<Id, String> mapCasaeIdToChange)
    {
        
        if(mapCasaeIdToChange.get(objWorkOrder.SVMXC__Case__c) == Cases.CASE_OF_LOCATION_CHANGE){
            if(mapIdToWorkOrder != null && !mapIdToWorkOrder.isEmpty() && mapIdToWorkOrder.containsKey(objWorkOrder.Id)){
                mapIdToWorkOrder.get(objWorkOrder.Id).SVMXC__Site__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).SVMXC__Site__c;
            }
            else{
                objWorkOrder.SVMXC__Site__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).SVMXC__Site__c;
                mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder);                        
            }               
        }

        if(mapCasaeIdToChange.get(objWorkOrder.SVMXC__Case__c) == Cases.SUBJECT_DESC_OTHERS_CHANGE){ 
            if(objWorkOrder.SVMXC__Order_Status__c != Cases.STRING_COMPLETED && 
                objWorkOrder.SVMXC__Order_Status__c != Cases.STRING_CLOSED && objWorkOrder.SVMXC__Order_Status__c != Cases.STRING_CASE_STATUS_CLOSED_DUPLICATE){
                if(mapIdToWorkOrder != null && !mapIdToWorkOrder.isEmpty() && mapIdToWorkOrder.containsKey(objWorkOrder.Id)){
                    mapIdToWorkOrder.get(objWorkOrder.Id).Case_Subject__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Subject;
                    mapIdToWorkOrder.get(objWorkOrder.Id).Case_Description__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Description;
                    mapIdToWorkOrder.get(objWorkOrder.Id).Case_Next_Steps__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Next_Steps__c;
                    mapIdToWorkOrder.get(objWorkOrder.Id).Case_Follow_up_Needed__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Follow_up_Needed__c;
                }
                else{
                    objWorkOrder.Case_Subject__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Subject;
                    objWorkOrder.Case_Description__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Description;
                    objWorkOrder.Case_Next_Steps__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Next_Steps__c;
                    objWorkOrder.Case_Follow_up_Needed__c = mapIdToCase.get(objWorkOrder.SVMXC__Case__c).Follow_up_Needed__c;
                    mapIdToWorkOrder.put(objWorkOrder.Id, objWorkOrder);                        
                }
            }                   
        } 
    }
}