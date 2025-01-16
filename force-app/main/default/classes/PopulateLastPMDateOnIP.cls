  /*
  @author        : Ritika M
* @ date         : 11-MAR-2022
* @ Description  : To Populate last PM date on installed product related to PM work order 
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* 
* 
*/
public with sharing class PopulateLastPMDateOnIP implements ilib_AdminOperationLogicInterface {

     /*
     * @param      : List<Id>
     * @return     : void 
     * @Description: Method to Populate last PM date on installed product related to PM work order
     **/
    public static void doBusinessLogic(List<Id> setPMCompletedWOIds){ 
        Map<Id,SVMXC__Installed_Product__c> mapIPIdtoIPObj = new Map<Id,SVMXC__Installed_Product__c>();
        for(SVMXC__Service_Order__c objWorkOrder : [SELECT Id, SVMXC__Component__c, SVMXC__Component__r.Last_PM_Date__c, (SELECT Id, SVMXC__Activity_Type__c,SVMXC__End_Date_and_Time__c FROM SVMXC__Service_Order_Line__r WHERE SVMXC__Activity_Type__c = 'Preventative Maintenance' AND SVMXC__End_Date_and_Time__c != Null AND SVMXC__Line_Status__c != 'Canceled' ORDER BY SVMXC__End_Date_and_Time__c DESC LIMIT 1) FROM SVMXC__Service_Order__c WHERE Id IN: setPMCompletedWOIds ] ){
            if(objWorkOrder.SVMXC__Service_Order_Line__r.size() > 0){
                
                if((objWorkOrder.SVMXC__Component__r.Last_PM_Date__c  == null) || (objWorkOrder.SVMXC__Component__r.Last_PM_Date__c != null && objWorkOrder.SVMXC__Service_Order_Line__r[0].SVMXC__End_Date_and_Time__c != null && objWorkOrder.SVMXC__Service_Order_Line__r[0].SVMXC__End_Date_and_Time__c.date() > objWorkOrder.SVMXC__Component__r.Last_PM_Date__c)){
                
                SVMXC__Installed_Product__c objInstalledProduct;
                    if(mapIPIdtoIPObj.ContainsKey(objWorkOrder.SVMXC__Component__c))
                        objInstalledProduct=mapIPIdtoIPObj.get(objInstalledProduct.Id);
                    else{
                        objInstalledProduct = new  SVMXC__Installed_Product__c();
                        objInstalledProduct.Id = objWorkOrder.SVMXC__Component__c;
                    }
                    objInstalledProduct.Last_PM_Date__c = objWorkOrder.SVMXC__Service_Order_Line__r[0].SVMXC__End_Date_and_Time__c.date();
                    mapIPIdtoIPObj.put(objInstalledProduct.Id,objInstalledProduct);
                }
            }
        }
        if(!mapIPIdtoIPObj.isEmpty()){
            update mapIPIdtoIPObj.values();
        }
    }

}
