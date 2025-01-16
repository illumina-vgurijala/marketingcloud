/**
* @author Shivani Jain
* @date 6th June 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Agreements 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Pooja                 20-Dec-2022            DCP-57153 : To Update Work Order fields for Installation/Preventive maintenance order type
* Sudarshan             05-Dec-2023            CMCM-1354  EOL WO Changes
*/ 
public with sharing class WorkOrderAssignment_WOHelper {

    /*
    *  @AUTHOR:  Digvijay (code refractoring)
    *  @DESCRIPTION: Installation and PM Work Order Assignment
    *  @PARAM :  List<Sobject>  
    *  return : void
    */ 
    public static void installationandPMWorkOrderAssignment(List<Sobject> records) {
        Map<String,Account_to_Field_Support__c> mapAccToFieldSupport = new Map<String,Account_to_Field_Support__c> ();
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
        //DCP-26101 && DCP-28624
        //Added one condition (objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM 6756
            if((objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM || objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeTradeinEOL || objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) 
            && !WorkOrders.mapaccountIdToPFSERoles.isEmpty()){
                mapAccToFieldSupport = WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c);
                //Start: DCP-57153
                if(mapAccToFieldSupport != NULL && mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PARTNER_PRIMARY_FSE) != NULL && objWorkOrder.SVMXC__Order_Type__c != System.Label.WorkOrderTypeTradeinEOL){
                        updateWOFields(mapAccToFieldSupport,objWorkOrder,WorkOrders.STRING_LABEL_PARTNER_PRIMARY_FSE);
                }//END   
                else if(mapAccToFieldSupport != NULL && mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PRIMARY_FSE) != NULL){
                        updateWOFields(mapAccToFieldSupport,objWorkOrder,WorkOrders.STRING_LABEL_PRIMARY_FSE);// modified DCP-57153
                }           
               
            }
        
            if((mapAccToFieldSupport == NULL || mapAccToFieldSupport.isEmpty()) && objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM) {
                List<Group> lstQueues = ServiceUtilityCollection.getQueueFromName(new Set<String>{'Field_Support_Unassigned_Work_Orders'});
                if(!lstQueues.IsEmpty()) {
                    objWorkOrder.OwnerId = lstQueues[0].Id;
                }
            }
        }
    }

    /**
     * DCP-38964
     * Method Name: populateFSAndOwneronPOChange
     * Description: Process PO Number change on work Order
     * Author: Digvijay Singh
     * DCP-38893 : Added bypass for ZDST order creation
     **/
    public static void populateFSAndOwneronPOChange(List<Sobject> records,Map<Id, SObject> oldRecords) {
        Map<Id,User> userMap = new Map<Id,User>();
        Map<String , String> mapFieldSupportDistributorAccount = new Map<String,String>();
        Map<Id,SVMXC__Service_Group_Members__c> technicianMap = new Map<Id,SVMXC__Service_Group_Members__c>();
        Map<Id,SVMXC__Service_Group_Members__c> maptechnicianIdtotechnician = new Map<Id,SVMXC__Service_Group_Members__c>();

        for(User objUser : WorkOrders.lstUserRecords) {
            userMap.put(objUser.Id, objUser);
        }

        populateGroupMembersMaps(technicianMap, maptechnicianIdtotechnician);

        mapFieldSupportDistributorAccount = populateMapFieldSupportDistributorAccount(records, userMap, technicianMap);

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = oldRecords != NULL && oldRecords.containsKey(objWorkOrder.Id) ? (SVMXC__Service_Order__c)oldRecords.get(objWorkOrder.Id) : NULL;

            if(!String.IsEmpty(objWorkOrder.PO_Number__c) && objWorkOrder.SVMXC__Billing_Type__c == WorkOrders.STRING_LABEL_BILLABLE && Trigger.IsInsert 
                    && !ZDSTWorkOrderDataReceiver.boolByPassOwnerChangeOnPOUpdate) {
                assignmentOnInsert(mapFieldSupportDistributorAccount, objWorkOrder);
            } else if(Trigger.isUpdate && objOldWorkOrder != NULL && (objWorkOrder.PO_Number__c != objOldWorkOrder.PO_Number__c && !String.IsBlank(objWorkOrder.PO_Number__c) 
                    && !String.valueOf(objWorkOrder.OwnerId).startsWith(WorkOrders.STRING_005)) 
                    || (objOldWorkOrder != NULL && String.IsBlank(objOldWorkOrder.PO_Number__c) && !String.IsBlank(objWorkOrder.PO_Number__c)) ) {
                  
                assignmentOnUpdate(maptechnicianIdtotechnician, objWorkOrder);
            }
            populateFieldSupportForFSOnInsert(objWorkOrder, technicianMap);
        }
        
    }

    /*******************************************************************************************************
    * @description Returns technicianMap and maptechnicianIdtotechnician
    * @param maptechnicianIdtotechnician Map<Id,SVMXC__Service_Group_Members__c>
    * @param technicianMap Map<Id,SVMXC__Service_Group_Members__c>
    * @return void
    */
    private static void populateGroupMembersMaps(Map<Id,SVMXC__Service_Group_Members__c> technicianMap, Map<Id,SVMXC__Service_Group_Members__c> maptechnicianIdtotechnician) {
        for(SVMXC__Service_Group_Members__c objTechnician : WorkOrders.lstServiceGroupMembers) {
            technicianMap.put(objTechnician.SVMXC__Salesforce_User__c, objTechnician);
            maptechnicianIdtotechnician.put(objTechnician.id, objTechnician);
        }
    }

    /*******************************************************************************************************
    * @description Returns mapFieldSupportDistributorAccount
    * @param records List<SVMXC__Service_Order__c>
    * @param userMap Map<Id,User> 
    * @param technicianMap Map<Id,SVMXC__Service_Group_Members__c>
    * @return Map<String, String>
    */
    private static Map<String, String> populateMapFieldSupportDistributorAccount(List<SVMXC__Service_Order__c> records, Map<Id,User> userMap, Map<Id,SVMXC__Service_Group_Members__c> technicianMap) {
        Map<String, String> mapFieldSupportDistributorAccount = new Map<String, String>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            if(userMap.containsKey(objWorkOrder.OwnerId) && technicianMap.containsKey(objWorkOrder.OwnerId) 
                    && Trigger.isInsert && technicianMap.get(objWorkOrder.OwnerId) != NULL) {
                mapFieldSupportDistributorAccount.put(objWorkOrder.SVMXC__Group_Member__c, technicianMap.get(objWorkOrder.OwnerId).SVMXC__Inventory_Location__r.SVMXC__Account__c); 
           }
        }
        return mapFieldSupportDistributorAccount;
    }

    /*******************************************************************************************************
    * @description logic to run on insert 
    * @param mapFieldSupportDistributorAccount Map<String, String>
    * @param objWorkOrder new WO
    * @return void
    */
    private static void assignmentOnInsert(Map<String, String> mapFieldSupportDistributorAccount, SVMXC__Service_Order__c objWorkOrder) {
        Account_to_Field_Support__c acctoFSobj = NULL;
        Map<String,Account_to_Field_Support__c> mapAccToFieldSupport = objWorkOrder.Partner_Work_Order__c && !mapFieldSupportDistributorAccount.IsEmpty() ? WorkOrders.mapaccountIdToPFSERoles.get(mapFieldSupportDistributorAccount.get(objWorkOrder.SVMXC__Group_Member__c)) 
                                                        : WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c);
        
        if(mapAccToFieldSupport != NULL) {
            acctoFSobj = objWorkOrder.Partner_Work_Order__c && mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PARTNER_PRIMARY_FSE) != NULL ? 
                            mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PARTNER_PRIMARY_FSE) : mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PRIMARY_FSE) != NULL ?
                            mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PRIMARY_FSE) : NULL;
            if(acctoFSobj != NULL) {
                objWorkOrder.SVMXC__Group_Member__c = acctoFSobj.User__c;
                objWorkOrder.SVMXC__Member_Email__c = acctoFSobj.User__r.Related_User_Email__c;                                   
                objWorkOrder.OwnerId = acctoFSobj.User__r.SVMXC__Salesforce_User__c;
                objWorkOrder.SVMXC__Order_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED;
            }
        }
    }

    /*******************************************************************************************************
    * @description logic to run on update 
    * @param maptechnicianIdtotechnician Map<Id,SVMXC__Service_Group_Members__c>
    * @param objWorkOrder new WO
    * @return void
    */
    private static void assignmentOnUpdate(Map<Id,SVMXC__Service_Group_Members__c> maptechnicianIdtotechnician, SVMXC__Service_Order__c objWorkOrder) {
        Map<String , String> mapERPIdtoID = new Map<String,String>();
        Account_to_Field_Support__c acctoFSobj = NULL;
        Map<String,Account_to_Field_Support__c> mapAccToFieldSupport = new Map<String,Account_to_Field_Support__c>();
        
        for(Account accobj : WorkOrders.lstAccountRecords) {
            mapERPIdtoID.put(accobj.ERP_Customer_Id__c,accobj.Id);
        }

        mapAccToFieldSupport = objWorkOrder.Partner_Work_Order__c && !mapERPIdtoID.IsEmpty() ? WorkOrders.mapaccountIdToPFSERoles.get(mapERPIdtoID.get(objWorkOrder.Distributor_Account__c )) :
                                    WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c);
        
        //DCP-39815
        if(mapAccToFieldSupport != NULL) {
            acctoFSobj = objWorkOrder.Partner_Work_Order__c && mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PARTNER_PRIMARY_FSE)!=NULL ? 
                            mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PARTNER_PRIMARY_FSE) :  mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PRIMARY_FSE) != NULL ?
                            mapAccToFieldSupport.get(WorkOrders.STRING_LABEL_PRIMARY_FSE) : NULL;
        }
        
        if(acctoFSobj != NULL) {
            if(objWorkOrder.SVMXC__Group_Member__c == NULL) {
                objWorkOrder.SVMXC__Group_Member__c=acctoFSobj.User__c;
                objWorkOrder.SVMXC__Member_Email__c=acctoFSobj.User__r.Related_User_Email__c;
                objWorkOrder.OwnerId = acctoFSobj.User__r.SVMXC__Salesforce_User__c;
            } else if(!maptechnicianIdtotechnician.isEmpty() && maptechnicianIdtotechnician.containskey(objWorkOrder.SVMXC__Group_Member__c)) {
                objWorkOrder.OwnerId = maptechnicianIdtotechnician.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Salesforce_User__c;
            }
            
            if(objWorkOrder.Partner_Work_Order__c) {
                objWorkOrder.SVMXC__Order_Status__c = WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED;
            }
        }
    }

    /*******************************************************************************************************
    * @description logic to run on update 
    * @param maptechnicianIdtotechnician Map<Id,SVMXC__Service_Group_Members__c>
    * @param objWorkOrder new WO
    * @return void
    */
    private static void populateFieldSupportForFSOnInsert(SVMXC__Service_Order__c objWorkOrder, Map<Id,SVMXC__Service_Group_Members__c> technicianMap) {
        // starts DCP-46058
        Id fsRecordTypeId = ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_RTYPE_FIELD_SERVICE);
        if(!String.isBlank(WorkOrders.loggedInUserProfileName) && WorkOrders.loggedInUserProfileName == WorkOrders.STRING_WORK_ORDER_RTYPE_FIELD_SERVICE 
                && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED 
                && objWorkOrder.RecordTypeId == fsRecordTypeId && objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES 
                && Trigger.isInsert) {
            objWorkOrder.SVMXC__Group_Member__c = technicianMap.containskey(objWorkOrder.OwnerId) ? technicianMap.get(objWorkOrder.OwnerId).Id : NULL;
        }
        //Ends DCP-46058
    }

    /**
    * @description :DCP-57153 , Update work order fields for Installed and PM Order Type
    **/
    private static void updateWOFields(Map<String,Account_to_Field_Support__c> mapAccToFieldSupport,SVMXC__Service_Order__c objWorkOrder,String urserRole){
        objWorkOrder.SVMXC__Group_Member__c = mapAccToFieldSupport.get(urserRole).User__c;
        objWorkOrder.SVMXC__Member_Email__c = mapAccToFieldSupport.get(urserRole).User__r.Related_User_Email__c;                                                                                               
        objWorkOrder.OwnerId = mapAccToFieldSupport.get(urserRole).User__r.SVMXC__Salesforce_User__c; 
        objWorkOrder.SVMXC__Order_Status__c = objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_WO_ORDER_TYPE_PM ? WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED : objWorkOrder.SVMXC__Order_Status__c;      
    }

}