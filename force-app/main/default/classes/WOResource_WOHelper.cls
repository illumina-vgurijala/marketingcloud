/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Work Order Resources 
*/ 
public with sharing class WOResource_WOHelper {

    /*
    *  @AUTHOR:  Digvijay(Refactored)
    *  @DESCRIPTION: update Case Statuses
    *  @PARAM :  Set<Id> - case ids
    *  return : void
    */ 
    public static void workOrderResourceUpdate(Map<Id, SObject> mapOld, List<SVMXC__Work_Order_Resource__c>  lstWOResource) {

        //DCP-25271   
        Map<String, SVMXC__Work_Order_Resource__c>  mapWORToWORobj=new Map<String, SVMXC__Work_Order_Resource__c>();
        List<SVMXC__Service_Order__c> lstWORecords=new List<SVMXC__Service_Order__c>();
        List<SVMXC__Work_Order_Resource__c>  lstWOResourcetobeUpdated=new List<SVMXC__Work_Order_Resource__c>();
        List<SVMXC__Work_Order_Resource__c>  lstWOResourcetobedeleted=new List<SVMXC__Work_Order_Resource__c>();

        for(SVMXC__Work_Order_Resource__c obj :lstWOResource) {
            mapWORToWORobj.put(String.valueOf(obj.SVMXC__Group_Member__c) + String.valueOf(obj.SVMXC__Work_Order__c), obj);
        }
       
        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            //DCP-25271
            
            if(objNewWorkorder.SVMXC__Group_Member__c == NULL && objOldWorkorder.SVMXC__Group_Member__c != NULL  && mapWORToWORobj.containsKey(''+objOldWorkorder.SVMXC__Group_Member__c + objNewWorkorder.id)) { //&& objNewWorkorder.SVMXC__Order_Type__c!=STRING_LABEL_INSTALLATION
                lstWOResourcetobedeleted.add(mapWORToWORobj.get(''+objOldWorkorder.SVMXC__Group_Member__c + objNewWorkorder.id));        
            } else if(objNewWorkorder.SVMXC__Group_Member__c != NULL   && (objNewWorkorder.SVMXC__Scheduled_Date_Time__c!=objOldWorkorder.SVMXC__Scheduled_Date_Time__c 
                || objNewWorkorder.SVMXC__Group_Member__c!=objOldWorkorder.SVMXC__Group_Member__c) ) {
                
                SVMXC__Work_Order_Resource__c  objWOR = mapWORToWORobj.get(''+objNewWorkorder.SVMXC__Group_Member__c + objNewWorkorder.id);
                if(objWOR != NULL) {
                    objWOR = populateWOResource(objWOR, objNewWorkorder, objOldWorkorder);
                            
                    lstWOResourcetobeUpdated.add(objWOR);
                } else{
                    lstWORecords.add(objNewWorkorder);
                }
                
                if(objNewWorkorder.SVMXC__Group_Member__c!=objOldWorkorder.SVMXC__Group_Member__c && mapWORToWORobj.containsKey(''+objoldWorkorder.SVMXC__Group_Member__c + objoldWorkorder.id)){
                            SVMXC__Work_Order_Resource__c  objExistingWOR= mapWORToWORobj.get(''+objoldWorkorder.SVMXC__Group_Member__c + objoldWorkorder.id);
                            if(objExistingWOR!=NULL)
                            lstWOResourcetobedeleted.add(objExistingWOR);
                }
            }

        }

        //DCP-25271 
        if(!lstWORecords.isEmpty() || !lstWOResourcetobeUpdated.isEmpty() || !lstWOResourcetobedeleted.isEmpty()) {
            if(!WorkOrders.hasupdaterun) {
                new ServiceUtilityCollection.ServiceSystemUtilityCollection().insertWOResourceRecord(lstWORecords,lstWOResourcetobedeleted,lstWOResourcetobeUpdated);
                WorkOrders.hasupdaterun=true;
            }
        }
    }

    private static SVMXC__Work_Order_Resource__c populateWOResource(SVMXC__Work_Order_Resource__c objWOR, SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder) {
        if(objNewWorkorder.SVMXC__Scheduled_Date_Time__c != objOldWorkorder.SVMXC__Scheduled_Date_Time__c) {
            objWOR.Schedule_Date_Time__c=objNewWorkorder.SVMXC__Scheduled_Date_Time__c;
        }
        if(objNewWorkorder.SVMXC__Group_Member__c!=objOldWorkorder.SVMXC__Group_Member__c) {
            objWOR.SVMXC__Group_Member__c = objNewWorkorder.SVMXC__Group_Member__c;
            objWOR.Schedule_Date_Time__c = objNewWorkorder.SVMXC__Scheduled_Date_Time__c;
            objWOR.Primary__c = true;
        }
        return objWOR;
    }
}
