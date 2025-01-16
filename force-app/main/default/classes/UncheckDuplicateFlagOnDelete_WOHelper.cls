/**
* @author Shivani Jain
* @date 8th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to uncheck Duplicate Flag on Case on WO Deletion
*/ 
public with sharing class UncheckDuplicateFlagOnDelete_WOHelper {

    /*******************************************************************************************************
    * @description  Method to uncheck Duplicate Flag on Case on WO Deletion
    * @return void
    */
    public static void uncheckDuplicateFlagOnCase() {
        for(Case cs : WorkOrders.lstCaseToUpdate) {
            //get the caselist for that set and check if case is business issue type
            //iterate over that caselist and update the flag to false
            if(cs.Has_Closed_Duplicate_WO__c) {
                if(!WorkOrders.idTocaseDeleteUpdate.isEmpty() && WorkOrders.idTocaseDeleteUpdate.containskey(cs.id)) {
                    WorkOrders.idTocaseDeleteUpdate.get(cs.id).Has_Closed_Duplicate_WO__c = false;
                } else {
                    cs.Has_Closed_Duplicate_WO__c=false;
                    WorkOrders.idTocaseDeleteUpdate.put(cs.id,cs);
                }
                
            }
        }
        
    }
}
