/**
* @author Shivani Jain
* @date 8th Nov 2022
*
* @description DCP-54018 Queueable Class for Work Order trigger to upsert Field Action Items 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Dhairya Shah             17 April 2024       CMCM-6760 - Removed the method 'linkFieldActionItemsFromCase()'
* --------------------------------------------------------------------------------------------------------------------------------------
*/ 
public class FAIQueueable_WOHelper implements Queueable {

    Map<Id, Id> caseIdToWorkOrderIds = new Map<Id, Id>();
    String methodName;
    public static Boolean testClassCoverage = false;

    private static final String CUSTOM_EXCEPTION = 'Throwing Exception from Test Class';
    private static final String METHOD_UPDATEFAIRECORDS_ON_WO = 'updateFAIrecordsOnWO';
    private static final String METHOD_LINKFIELDACTIONITEMS_FROM_CASE = 'linkFieldActionItemsFromCase';

    /*******************************************************************************************************
    * @description Constructor
    * @param caseIdToWorkOrderIds Map<Id, Id>
    * @param methodName String
    * @return
    */
    public FAIQueueable_WOHelper(Map<Id, Id> caseIdToWorkOrderIds, String methodName) {
        this.caseIdToWorkOrderIds = caseIdToWorkOrderIds;
        this.methodName = methodName;
    }

    /*******************************************************************************************************
    * @description Execute method
    * @param QueueableContext qc
    * @return
    */
    public void execute(QueueableContext qc) { 
        try {
            if(methodName == METHOD_LINKFIELDACTIONITEMS_FROM_CASE) {
                linkFieldActionItemsFromCase(caseIdToWorkOrderIds);
            }
            if(methodName == METHOD_UPDATEFAIRECORDS_ON_WO) {
                updateFAIrecordsOnWO(caseIdToWorkOrderIds);
            }
            if(testClassCoverage && Test.isRunningTest()) {
                throw new CustomException(CUSTOM_EXCEPTION);
            }
        } catch(Exception ex) {  
            ApexExceptions.emit('FAIQueueable_WOHelper.'+ 'methodName', ex); 
            throw ex; 
        }
        
    }

     /**
     * DCP-17063
     *  @author Nitin Sood
     *  @description - If Work Order is created link the Field action item record from case.
     **/
    /* @AUTHOR:  Dhairya Shah
     * US- CMCM-6760 - Removed the following list 'lstWorkDetailsToBeInserted'
     */
    public static void linkFieldActionItemsFromCase(Map<Id, Id> caseIdToWorkOrderIds) {    
        List<Field_Action_Item__c> lstFieldActionItems = new List<Field_Action_Item__c>();
        if(caseIdToWorkOrderIds != null && caseIdToWorkOrderIds.keyset().size() > 0){
            for(Field_Action_Item__c objFieldActItem : new FieldActionItemsSelector().selectFieldActionItemsByCaseId(caseIdToWorkOrderIds.keyset())) {
                if(caseIdToWorkOrderIds.containsKey(objFieldActItem.Case__c)){
                    objFieldActItem.Work_Order__c = caseIdToWorkOrderIds.get(objFieldActItem.Case__c);
                    lstFieldActionItems.add(objFieldActItem);                   
                }
            }
        }

        if(!lstFieldActionItems.isEmpty()) {
            update lstFieldActionItems;
        }
    }

    /*
    * method updateFAIrecordsOnWO
    * params : Map<Id,Id> mapWOIdtoCaseId
    * description: update Case ID on relared FAI records
    * return:Void
    */
    public static void updateFAIrecordsOnWO(Map<Id,Id> mapWOIdtoCaseId) {
        List<Field_Action_Item__c> lstFAItobeUpdated=new List<Field_Action_Item__c>();
        Map<Id,Id> mapCaseIdtoWOId=new Map<Id,Id>();
   
        for(Id key:mapWOIdtoCaseId.keyset()) {
            mapCaseIdtoWOId.put(mapWOIdtoCaseId.get(key),key);
   
        }
        for(Field_Action_Item__c objFAI:new FieldActionItemsSelector().selectFieldActionItemsByCaseORWOId(mapWOIdtoCaseId.keySet(),mapCaseIdtoWOId.keyset())) {
   
           if(objFAI.Work_Order__c!=null) {
               objFAI.Case__c=mapWOIdtoCaseId.get(objFAI.Work_Order__c);
           } else {
               objFAI.Work_Order__c=mapCaseIdtoWOId.get(objFAI.Case__c);
           }
   
            lstFAItobeUpdated.add(objFAI);   
        }
         
        if(!lstFAItobeUpdated.IsEmpty())
            update lstFAItobeUpdated;
   }

    /*******************************************************************************************************
    * @description Custom Exception innner class
    */
    public class CustomException extends Exception {}
}