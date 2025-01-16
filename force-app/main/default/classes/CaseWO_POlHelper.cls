/**************************************************************************************************************************************
* NAME   : CaseWO_POlHelper
* DESCRIPTION  : Domain class for v.
* Test Class- TestCaseWO_POlHelper.cls
*  
*                    
* @AUTHOR : Nitin Z 
* @DATE   : 19 -Aug -2024  
*  
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
  Nitin Z                  19-Aug -2024   

****************************************************************************************************************************************/ 

public with sharing class CaseWO_POlHelper{

    public static List<SVMXC__Service_Order__c> woList= new List<SVMXC__Service_Order__c>();

    /*  
      * Description - CMCM-9391 onBefore Insert  method to validate that when recall is true and Product_Returned_Status__c=Product Returned to Illumina then case is closed then wo associated  with the case must have at leat one PO with  status not as canceled and type= return
      * return - void
      */
     
      public  static void validateReturnPartOrder(List<Case> newRecords, Map<Id,Case> oldRecordsMap){
        
         Set<Id> closedOrCompletedCasesList= new  Set<Id>();
         Map<Id,ID> woCaseMap= new Map<Id,Id>();

         Id companyRecTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(System.label.CaseRecordTypeServiceRequest).getRecordTypeId();
 
         for(Case caseObject:newRecords){
             if(caseObject.status!=oldRecordsMap.get(caseObject.Id).Status
                &&  caseObject.Recall__c==true
                &&  caseObject.RecordTypeId==companyRecTypeId
                &&  (caseObject.Status==System.label.CaseStatusClosed || caseObject.Status==System.label.CaseStatusCompleted)
                &&  (caseObject.Product_Returned_Status__c==System.label.Product_Return_Status_Product_Returned_to_Illumina || caseObject.Product_Returned_Status__c==System.label.Product_Return_Status_Product_Returned_Through_Work_Order)){
                 
               closedOrCompletedCasesList.add(caseObject.Id);

               if(caseObject.Work_Order__c!=null){
                woCaseMap.put(caseObject.Work_Order__c,caseObject.Id);
               }

               if(caseObject.Product_Returned_Through_Work_Order__c!=null){
                woCaseMap.put(caseObject.Product_Returned_Through_Work_Order__c,caseObject.Id);
               }
            }
         }

           if((woList.isEmpty() || Feature.isOn(Cases.CASE_OPTIMIZATION)) && closedOrCompletedCasesList != null && !closedOrCompletedCasesList.isEmpty()){
             woList=new WorkOrdersSelector().selectWOWithGivenStatusAndReturnType(System.label.PartsOrderTypeReturn,System.label.PartsOrderLineCanceled,woCaseMap.keySet());
           }


             for(SVMXC__Service_Order__c woObject:woList){
              if(woObject.SVMXC__RMA_Shipment_Order__r.size()>0){
                  closedOrCompletedCasesList.remove(woCaseMap.get(woObject.id));
              }
            }

         
         for(Case caseObject:newRecords){
             if(closedOrCompletedCasesList.contains(caseObject.Id) ){
                 caseObject.addError(System.label.ErrorProoductRetuenToIllumina);                
             }
         }
     }
 
 }