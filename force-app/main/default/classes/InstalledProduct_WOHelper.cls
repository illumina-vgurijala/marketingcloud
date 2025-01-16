/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Installed Products 
*/ 
public with sharing class InstalledProduct_WOHelper {

    /**DCP-39877
     *  @author Soumya
     *  @description Update Account and Location on Installed Products on Relocation Work Order Completion
     *  @param Map : <id,SVMXC__Service_Order__c> 
     *  @return part orders 
     **/
    public static void updateAccountLocationOnIPForRelocationWO(Map<Id, SObject> mapOld) {
        //DCP-39877
        map<id,SVMXC__Service_Order__c> idtoWOMap=new map<id,SVMXC__Service_Order__c>();
       
        
        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            //DCP-39877
            if(objNewWorkorder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED
            && objNewWorkorder.SVMXC__Component__c != null && (objNewWorkorder.Relocated_Account__c != null || objNewWorkorder.Relocated_Location__c != null) 
            && !objNewWorkorder.Relocated_Site_Unknown__c && objNewWorkorder.SVMXC__Order_Type__c=='Relocation') {
                idtoWOMap.put(objNewWorkorder.id,objNewWorkorder);
            }
        }
        //Populate value from workorder map to Installed Product List
        For(id idWO : idtoWOMap.keyset()) {
            SVMXC__Installed_Product__c objIP= new SVMXC__Installed_Product__c(id=idtoWOMap.get(idWO).SVMXC__Component__c);

            if(WorkOrders.mapIPIdtoIPObj.ContainsKey(objIP.Id))
                objIP=WorkOrders.mapIPIdtoIPObj.get(objIP.Id);
                    

            if(idtoWOMap.get(idWO).Relocated_Account__c!=null) {
                objIP.SVMXC__Company__c=idtoWOMap.get(idWO).Relocated_Account__c;
            }
            if(idtoWOMap.get(idWO).Relocated_Location__c!=null) {
                objIP.SVMXC__Site__c=idtoWOMap.get(idWO).Relocated_Location__c;
            }

            WorkOrders.mapIPIdtoIPObj.put(objIP.id,objIP);

        }
    }
   
}
