/**
* @author Shivani Jain
* @date 30th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Channel Partner 
*/  
public with sharing class ChannelPartner_WOHelper {

    /*
     *  @DESCRIPTION: Method to set Partner work order checkbox 
     *  @PARAM :  Map<Id, List<SVMXC__Service_Order__c>> - map of owner's user ids vd list of work orders being inserted/updated
     *  @PARAM : Boolean isInsert - check if the method is being called from insert or update
     * return : void.
     */
    public static void  channelParterCheckForWorkOrder(List<Sobject> records,Map<Id, SObject> oldRecords, Id idEstimatesRecordTypeId) {

        Map<Id, List<SVMXC__Service_Order__c>> ownerIdToWorkOrderLst = new Map<Id, List<SVMXC__Service_Order__c>>();
        Map<Id,User> userMap = new Map<Id,User>();
        Map<Id,SVMXC__Service_Group_Members__c> technicianMap = new Map<Id,SVMXC__Service_Group_Members__c>();

        ownerIdToWorkOrderLst = populateOwnerIdToWorkOrderLst(records);
        
        for(User objUser : WorkOrders.lstUserRecords) {
            userMap.put(objUser.Id, objUser);
        }
        for(SVMXC__Service_Group_Members__c objTechnician : WorkOrders.lstServiceGroupMembers) {
            technicianMap.put(objTechnician.SVMXC__Salesforce_User__c, objTechnician);
        }

        for(Id userId : ownerIdToWorkOrderLst.keySet()) {
            for(SVMXC__Service_Order__c objWorkOrder : ownerIdToWorkOrderLst.get(userId)) {
                SVMXC__Service_Order__c objOldWorkOrder = oldRecords != null ? (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)) : null;
                
                if(userMap.containsKey(userId) && userMap.get(userId).IsPortalEnabled) {
                    objWorkOrder.Partner_Work_Order__c = true;

                    populateFSAndDistributor(technicianMap, objWorkOrder, objOldWorkOrder, userId);

                    if (Trigger.isInsert && objWorkOrder.RecordTypeId != idEstimatesRecordTypeId) {
                        objWorkOrder.SVMXC__Order_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED;
                    }

                    //START CMCP-64
                    if(objWorkOrder.Request_Ownership_Status__c == WorkOrders.STRING_REQUESTED) {
                        objWorkOrder.Request_Ownership_Status__c = WorkOrders.STRING_COMPLETED;
                    }
                    //END CMCP-64
                }
            }
        } 
    }

    /*
     *  @DESCRIPTION: 
     */
    private static void  populateFSAndDistributor(Map<Id,SVMXC__Service_Group_Members__c> technicianMap, SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder, Id userId) {
        if(technicianMap.containsKey(userId)) {

            objWorkOrder.SVMXC__Group_Member__c = objOldWorkOrder == null || objWorkOrder.OwnerId != objOldWorkOrder.OwnerId 
                    ? technicianMap.get(userId).Id : objWorkOrder.SVMXC__Group_Member__c;
            objWorkOrder.SVMXC__Member_Email__c = objOldWorkOrder == null || objWorkOrder.OwnerId != objOldWorkOrder.OwnerId 
                    ? technicianMap.get(userId).Related_User_Email__c : objWorkOrder.SVMXC__Member_Email__c;
            //DCP-39824 update the Distributor Account on wo with ERP cusotmer id.
            objWorkOrder.Distributor_Account__c = (Trigger.isInsert ? technicianMap.get(userId).SVMXC__Inventory_Location__r.SVMXC__Account__r.ERP_Customer_Id__c:objWorkOrder.Distributor_Account__c);
           
        }
    }

    /*
     *  @DESCRIPTION: 
     */
    private static Map<Id, List<SVMXC__Service_Order__c>> populateOwnerIdToWorkOrderLst(List<sObject> records) {
        Map<Id, List<SVMXC__Service_Order__c>> ownerIdToWorkOrderLst = new Map<Id, List<SVMXC__Service_Order__c>>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //for populating original owner     
            if(String.valueOf(objWorkOrder.OwnerId).startsWith(WorkOrders.STRING_005)) {     
                objWorkOrder.Original_Owner__c = objWorkOrder.OwnerId;  

                if(!ownerIdToWorkOrderLst.containsKey(objWorkOrder.OwnerId)) {
                    ownerIdToWorkOrderLst.put(objWorkOrder.OwnerId, new List<SVMXC__Service_Order__c>());
                } 
                ownerIdToWorkOrderLst.get(objWorkOrder.OwnerID).add(objWorkorder);       
            }

            //Start (CMCP-23)
            //Setting Partner Work Order flag to True if Work Order is created by Channel Partner user.
            if(Trigger.isInsert && Channel_Partner_Profile_Settings__c.getInstance(UserInfo.getProfileId()).Is_Channel_Partner__c && !objWorkOrder.Partner_Work_Order__c) {
                objWorkOrder.Partner_Work_Order__c=true;
            }

            ilib_LogEvent.message('PartnerWOFlagEnabled:'+objWorkOrder.Partner_Work_Order__c);
            //End (CMCP-23)
        }
        return ownerIdToWorkOrderLst;
    }
    
}
