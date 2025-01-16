/***************************************************************************************************************************************
* NAME   : FieldActionItems
* DESCRIPTION  : Domain class for FieldActionItemTrigger.
*                    
* @AUTHOR : Debanka
* @DATE   : 8-Sept-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Debanka            	8-Sept-2018         Initial Version. Added logic to handle events handled before insert and before update
****************************************************************************************************************************************/ 
public class FieldActionItems extends ilib_SObjectDomain{

    public static final String STRING_FAN_RECORDTYPE = 'Notification';
    public static List<SVMXC__Service_Order__c> listWorkOrders = new List<SVMXC__Service_order__c>();
    public static List<Case> listCases = new List<Case>();

		/*
         * Constructor
         */
    public FieldActionItems(List<Field_Action_Item__c> sObjectList)
    {
        super(sObjectList);
    }

/*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	/*Param - sobjectList  */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new FieldActionItems(sObjectList);
        }
    }
    /**
*  @author Debanka
*  @description - To be executed before inserting records for checking number of notifications 
*  @parameters : null
*  @return : void              
**/
    public override void onAfterInsert()
    {
        checkNoOfNotificationOnCase(); 
    }

		/*
		 * description - onAfterUpdate method
         */	
    public override void onAfterUpdate(Map<Id, SObject> oldRecords)
    { 
        checkNoOfNotificationOnCase(); 
    }

/**
*  @author Digvijay
*  @description - (DCP-39744)To be executed before inserting records for checking number of notifications 
*  @parameters : null
*  @return : void              
**/
     public override void onBeforeInsert()
    {

         Map<id,Id> mapWOtoCaseassociation=new Map<Id,Id>();
         //update the map with Case or  Work Order Id's as key
        for(Field_Action_Item__c objFAI : (List<Field_Action_Item__c>)records)
        {
                if(objFAI.Work_Order__c!=null ){
                    mapWOtoCaseassociation.put(objFAI.Work_Order__c,null);
                }else if(objFAI.Case__c!=null && objFAI.Work_Order__c==null){
                    mapWOtoCaseassociation.put(objFAI.Case__c,null);
                }

                
        }
    //update the map to create a mapping between related Case and WorkOrder
        if(!mapWOtoCaseassociation.IsEmpty()){
            for(SVMXC__Service_Order__c objworkOrder:new WorkOrdersSelector().selectWorkOrderLstFromIds(mapWOtoCaseassociation.keySet(),mapWOtoCaseassociation.keySet())){
                if(mapWOtoCaseassociation.containsKey(objworkOrder.Id))
                    mapWOtoCaseassociation.put(objworkOrder.Id,objworkOrder.SVMXC__Case__c);
                
                if(mapWOtoCaseassociation.containsKey(objworkOrder.SVMXC__Case__c))
                    mapWOtoCaseassociation.put(objworkOrder.SVMXC__Case__c,objworkOrder.Id);
            }
            
            //update the Field Action Item Record 
            for(Field_Action_Item__c objFAI : (List<Field_Action_Item__c>)records)
            {
                    if(objFAI.Work_Order__c!=null && objFAI.Case__c==null){
                        objFAI.Case__c=mapWOtoCaseassociation.get(objFAI.Work_Order__c);
                    }else if(objFAI.Case__c!=null && objFAI.Work_Order__c==null){
                        objFAI.Work_Order__c=mapWOtoCaseassociation.get(objFAI.Case__c);
                    }else if(objFAI.Case__c!=null && objFAI.Work_Order__c!=null ){
                                 if(!mapWOtoCaseassociation.IsEmpty() && mapWOtoCaseassociation.get(objFAI.Work_Order__c)!=objFAI.Case__c)
                                    objFAI.addError(Label.CaseWorkOrderMisMatchError);
                    }

            }
        }
        updateFieldActionItemFields((List<Field_Action_Item__c>)records);
    }

/**
*  @author Debanka
*  @description - To check that only one notification is associated to a case
*   @parameters : Set<Id>
*  @return : void             
**/
    public void checkNoOfNotificationOnCase(){ 
        Set<id> setCaseIds = new Set<id>();
     
        for(Field_Action_Item__c objFAI : (List<Field_Action_Item__c>)records){
          // To check the record type of the associated Field Actiion Notification
          
            if (objFAI.Field_Action_Notification_Record_Type__c == STRING_FAN_RECORDTYPE && objFAI.Case__c!=Null)
            {
                setCaseIds.add(objFAI.Case__c);
                    
            }
              
      }
        Set<id> setCaseNotificationIds = new Set<id>();
        List<Field_Action_Item__c> lstFAI = new  List<Field_Action_Item__c>();
        lstFAI =new FieldActionItemsSelector().selectFieldActionItemsByFANRecType(setCaseIds,STRING_FAN_RECORDTYPE);
        
        // To fetch the Field Action Items related to this case and FAN record type is "Notification"
        
        if(lstFAI.size()>1){
            for(Field_Action_Item__c objFAI :lstFAI){
                setCaseNotificationIds.add(objFAI.Case__c);
            }    
    
            for(Field_Action_Item__c objFieldAction : (List<Field_Action_Item__c>)records){
                if(setCaseNotificationIds.contains(objFieldAction.Case__c))
                {
                    objFieldAction.addError(system.label.FANTriggerErrorMessage);
                }
            }
        } 
    }
/**
*  @author Kumar Gaurav
*  @return : void             
**/
    public static void updateFieldActionItemFields(list<Field_Action_Item__c> fieldActionItemList){
        set<id>caseIdset = new set<id>();
        set<id>workOrderIdSet = new set<id>();
        Map <id,SVMXC__Service_order__c> workOrderMap = new map <id,SVMXC__Service_order__c>();
        Map <id,case> casesmap = new map <id,case>();
        
        for (Field_Action_Item__c fieldAction : fieldActionItemList){
            if (fieldAction.case__c!= null){
                caseIdset.add(fieldAction.case__c);
            }
            if(fieldAction.Work_Order__c!=null){
                workOrderIdSet.add(fieldAction.Work_Order__c);
            }
        }

        if(listWorkOrders.isEmpty() && !workOrderIdSet.isEmpty()){
            listWorkOrders = new workOrdersSelector().getWorkOrderId(workOrderIdSet);
        }

        if(listCases.isEmpty() && !caseIdset.isEmpty()){
            listCases = new casesSelector().getCaseId(caseIdset);
        }

        if(listWorkOrders!=null && !listWorkOrders.isEmpty()){
            for(SVMXC__Service_order__c  workorder : listWorkOrders){
                workOrderMap.put(workorder.id,workorder);
            }
        }

        if(listCases!=null && !listCases.isEmpty()){
            for (Case  caseIns : listCases){
                casesmap.put(caseIns.id,caseIns);
            }
        }

        for(Field_Action_Item__c fieldAction : fieldActionItemList){
            if(casesmap!=null && casesmap.containsKey(fieldAction.case__c)){
                Case relatedCase = casesmap.get(fieldAction.Case__c);
                fieldAction.Installed_Product__c = relatedCase.SVMXC__Component__c;
                fieldAction.Product__c=relatedCase.SVMXC__Product__c;
            }
            else if(workOrderMap!=null && workOrderMap.containsKey(fieldAction.Work_Order__c)){
                SVMXC__Service_order__c relatedWorkOrder = workOrderMap.get(fieldAction.Work_Order__c);
                fieldAction.Installed_Product__c = relatedWorkOrder.SVMXC__Component__c;
                fieldAction.Product__c = relatedWorkOrder.SVMXC__Product__c;
            }
        }
    }

}