/**
 * @description       : To Validate for case of status closed Duplicate associated with WO and Associated code / DCP:53957:CodeScan Fix
 * @author            : Pooja
 * @group             : 
 * @last modified on  : 06-07-2022
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class ValidateClosedDuplicate_CaseHelper {
 
    	/*
     * Description - checkForClosedDuplicateCases method
	 * return - void
     */
    public static void checkForClosedDuplicateCases(List<Sobject> records, Map<Id, SObject> oldRecords){

        set<Id> setCaseIds = new set<Id>();
        set<Id> setClosedDuplicateCaseIds = new set<Id>();
        set<Id> setParentCaseIds = new set<Id>();

        for(Case objCase : (List<Case>)records){
            
            Case objOldCase=null;               
            if(oldRecords!=null && !oldRecords.isEmpty()){
                objOldCase = (Case)(oldRecords.get(objCase.Id));
            }   
            setCaseIds.add(objCase.Id);
            if(objCase.Status != objOldCase.Status ){
                if(objCase.Status == Cases.STRING_CASE_STATUS_CLOSED_DUPLICATE){
                    setClosedDuplicateCaseIds.add(objCase.Id);
                }
                //create set of Case Ids

                if(objCase.ParentId != null){
                    setParentCaseIds.add(objCase.ParentId);
                }
            }   
        }
        
        if(!setClosedDuplicateCaseIds.isEmpty()){
           
            //query Parent cases
            if(!setParentCaseIds.isEmpty()){
				CasesHelper.ObjCases caseQuery = new CasesHelper.ObjCases();
                caseQuery.initMapParentCaseIdToParentCase(setParentCaseIds, false);
            }
            fetchAssociatedCodeWOOnCaseId(records,oldRecords,setCaseIds);
        }
        
    }

    /**
    * @description : To query on WO and associatedCode based on case which are not Closed Duplicate
    * @param setCaseIds 
    **/
    public static void fetchAssociatedCodeWOOnCaseId(List<Sobject> records, Map<Id, SObject> oldRecords,Set<Id> setCaseIds){
            map<Id, Integer> mapCaseIdToWorkOrderSize = new map<Id, Integer>();
            Map<Id, Integer> mapCaseIdToAssociatedCodesSize = new Map<Id, Integer>();
         //query Work orders on Case which are not Closed Duplicate
        if(!setCaseIds.isEmpty()){
            CasesHelper.WorkOrders workOrderQuery = new  CasesHelper.WorkOrders();
            workOrderQuery.initMapWOIdToWorkOrders(setCaseIds, false);
            if(Cases.mapWOIdToWorkOrders != null && !Cases.mapWOIdToWorkOrders.isEmpty()){

                mapCaseIdToWorkOrderSize=addCaseIdRelatedToWO();
            }               
            
            //query Associated Codes on Case which are not Code Disassociated
            CasesHelper.AssociatedCodes associatedCodesQuery = new  CasesHelper.AssociatedCodes();
            associatedCodesQuery.initMapAssociatedCodeIdsToAssociatedCodes(setCaseIds);
            if(Cases.mapAssociatedCodeIdsToAssociatedCodes != null && !Cases.mapAssociatedCodeIdsToAssociatedCodes.isEmpty()){

                mapCaseIdToAssociatedCodesSize=addCaseRelatedToAssociatedCode();
            }
        }
        handleErrorMsgOnCaseClosedDuplicate(records,oldRecords,mapCaseIdToWorkOrderSize,mapCaseIdToAssociatedCodesSize);
    }

    /**
    * @description : Add case id related to Work order
    * @return Map<Id, Integer> 
    **/
    public static Map<Id, Integer> addCaseIdRelatedToWO(){
        map<Id, Integer> mapCaseIdToWorkOrderSize = new map<Id, Integer>();
        for(SVMXC__Service_Order__c objWorkOrder:  Cases.mapWOIdToWorkOrders.values()){
            if(objWorkOrder.SVMXC__Order_Status__c  != Cases.STRING_CASE_STATUS_CLOSED_DUPLICATE){
                if(!mapCaseIdToWorkOrderSize.containsKey(objWorkOrder.SVMXC__Case__c)){
                    mapCaseIdToWorkOrderSize.put(objWorkOrder.SVMXC__Case__c, 0);
                }
                integer intWorkOrderNumber = mapCaseIdToWorkOrderSize.get(objWorkOrder.SVMXC__Case__c);
                mapCaseIdToWorkOrderSize.put(objWorkOrder.SVMXC__Case__c, intWorkOrderNumber+1);
            }
        }
        return mapCaseIdToWorkOrderSize;
    }

     /**
    * @description : Add case id related to Associated Code
    * @return Map<Id, Integer> 
    **/
    public static Map<Id, Integer> addCaseRelatedToAssociatedCode(){
        Map<Id, Integer> mapCaseIdToAssociatedCodesSize = new Map<Id, Integer>();
            for(Associated_Codes__c objAssociatedCode: Cases.mapAssociatedCodeIdsToAssociatedCodes.values()){
                if(objAssociatedCode.Code_Title__r.Name != Cases.CODE_DISASSOCIATED){
                    if(!mapCaseIdToAssociatedCodesSize.containsKey(objAssociatedCode.Case__c)){
                        mapCaseIdToAssociatedCodesSize.put(objAssociatedCode.Case__c, 0);
                    }
                    integer intAssociatedCodeNumber = mapCaseIdToAssociatedCodesSize.get(objAssociatedCode.Case__c);
                    mapCaseIdToAssociatedCodesSize.put(objAssociatedCode.Case__c, intAssociatedCodeNumber+1);
                }
            }
        return mapCaseIdToAssociatedCodesSize;
    }



    /**
    * @description :Error Message handler 
    **/
    public static void handleErrorMsgOnCaseClosedDuplicate(List<Sobject> records, Map<Id, SObject> oldRecords, map<Id, Integer> mapCaseIdToWorkOrderSize,Map<Id, Integer> mapCaseIdToAssociatedCodesSize) {
        for(Case objCase:(List<Case>)records){
            Case objOldCase = (Case)(oldRecords.get(objCase.Id));
            if(objCase.Status != objOldCase.Status && objCase.Status == Cases.STRING_CASE_STATUS_CLOSED_DUPLICATE){
                //check if Case has Work Order which are not Closed duplicate 
                if(mapCaseIdToWorkOrderSize.ContainsKey(objCase.Id) && mapCaseIdToWorkOrderSize.get(objCase.Id) > 0){
                    objCase.addError(system.label.Case_ClosedDuplicate_Error_1);
                }
                //check if BI Case has Parent Case other than BI or has Associated Codes other than Code Disassociated                  
                else if(string.isBlank(objCase.ParentId)
                      || (Cases.mapParentCaseIdToParentCase!= null && !Cases.mapParentCaseIdToParentCase.containsKey(objCase.ParentId))
                      || (Cases.mapParentCaseIdToParentCase !=  null && string.isNotBlank(objCase.ParentId) && Cases.mapParentCaseIdToParentCase.containsKey(objCase.ParentId) && objCase.RecordTypeId == Cases.BUSINESS_ISSUE_CASE_RECORDTYPE && Cases.mapParentCaseIdToParentCase.get(objCase.ParentId).RecordTypeId != Cases.BUSINESS_ISSUE_CASE_RECORDTYPE)
                      || (mapCaseIdToAssociatedCodesSize.ContainsKey(objCase.Id) && mapCaseIdToAssociatedCodesSize.get(objCase.Id) > 0 && objOldCase.Status != Cases.STRING_PENDING_QA_REVIEW)){
                          objCase.addError(system.label.Case_ClosedDuplicate_Error_2);
                }
                //check if Case subject or Description is blank
                else if(string.isBlank(objCase.Subject) || string.isBlank(objCase.Description)){
                    objCase.addError(system.label.Case_ClosedDuplicate_Error_3);
                }
                //check if Case status has not been moved to Closed Duplicate from Pre Completion Status
                //Bypass this validation for DCP-25229
                else if(!Cases.SET_CASE_PRE_COMPLETION_STATUS.contains(objOldCase.Status) && !objCase.Has_Closed_Duplicate_WO__c){
                    objCase.addError(system.label.Case_ClosedDuplicate_Error_4);
                }
            }
        }
    }
}
