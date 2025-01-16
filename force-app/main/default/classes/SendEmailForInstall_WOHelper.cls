/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to Trigger EMail on installation Work Order Assignment.  
*/ 
public with sharing class SendEmailForInstall_WOHelper {
            //CMCM-5307 - Start
            public static List<Account> lstAccountsWithFS = new List<Account>();
            public static List<SVMXC__Service_Order__c> lstWOs = new List<SVMXC__Service_Order__c>();
            //CMCM-5307 - End

    /*
     *  DCP-28403
     *  @AUTHOR Vignesh S
     *  @DESCRIPTION - Method to Trigger EMail on installation Work Order Assignment. 
     *  @PARAM : New List of Work order Records and Old Map of Work Orders.
     *  @RETURN : void
     */
    public static void sendInstallationNotificationEmail(List<SVMXC__Service_Order__c> records, Map<Id,SVMXC__Service_Order__c> mapOld) { 
        List<Id> lstAccIds = new List<Id>();
        Set<Id> setPartnerOwnerId = new Set<Id>();
        List<SVMXC__Service_Order__c> lstPartnerWO = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Order__c> lstStdWOTOEmail = new List<SVMXC__Service_Order__c>();
        List<Id> lstStdWOId = new List<Id>();
        List<SVMXC__Service_Order__c> lstPartnerWOTOEmail = new List<SVMXC__Service_Order__c>();
        Map<Id,Id> mapPartnerWoIdAccId = new Map<Id,Id>();
        Map<Id,user> mapUser = new Map<Id,user>();

       
       try {     
            populateSets(records, mapOld, lstPartnerWO, setPartnerOwnerId, lstStdWOTOEmail, lstStdWOId, lstAccIds);
            
            if(!setPartnerOwnerId.isEmpty()) {
                mapUser = new Map<Id,user>(WorkOrders.lstUserRecords);
            }
            
            for(SVMXC__Service_Order__c objWO : lstPartnerWO) {
                if(mapUser.containsKey(objWO.ownerId) && mapUser.get(objWO.ownerId).AccountId != Null ) {
                    lstPartnerWOTOEmail.add(objWO);
                    lstStdWOId.add(objWO.Id);
                    lstAccIds.add(mapUser.get(objWO.ownerId).AccountId);
                    mapPartnerWoIdAccId.put(objWO.Id, mapUser.get(objWO.ownerId).AccountId );
                } else {
                    lstStdWOTOEmail.add(objWO);
                    lstStdWOId.add(objWO.Id);
                    lstAccIds.add(objWO.SVMXC__Company__c);
                }
            }
            if(!lstStdWOTOEmail.isEmpty()) {
                sendInstallationMailAsync(WorkOrders.STRING_INSTALLED_WORK_ORDER ,lstAccIds, lstStdWOId , null);
            }
            
            if(!lstPartnerWOTOEmail.isEmpty()) {
                sendInstallationMailAsync(WorkOrders.STRING_INSTALLED_WORK_ORDER ,lstAccIds, lstStdWOId , 'Partner');
            }
        } catch(Exception e) {
            ApexExceptions.emit('WorkOrders', e);
        }
    }

    /*
    *@Method: sendInstallationMailAsync
    */
    @future
    public static void sendInstallationMailAsync(String notificationType,List<Id> lstAccIds ,List<Id> lstWoId,String accntApi) {
        Map<Id,Map<String,Account_to_Field_Support__c>> mapAccIdAFSIds = new Map<Id,Map<String,Account_to_Field_Support__c>>();
        Map<Id,Id> mapPartnerWoIdAccId = new Map<Id,Id>();
        List<SVMXC__Service_Order__c> lstStdWOTOEmail = new List<SVMXC__Service_Order__c>();
       //CMCM-5307 - Add empty check for WO trigger Optimization
        if(!lstAccIds.isEmpty()) {
            if (lstAccountsWithFS.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                lstAccountsWithFS = new AccountsSelector().accountWithFieldSupport( lstAccIds , new List<string>{'Field Service Manager','Field Application Manager'});
            }
            for(Account objAcc : lstAccountsWithFS){
                Map<string,Account_To_Field_Support__c> mapAFS = new Map<string,Account_To_Field_Support__c>();
                for(Account_To_Field_Support__c objAFS : objAcc.Account_Field_Support_Roles__r ) {
                    mapAFS.put(objAFS.User_Role__c, objAFS);
                }
                mapAccIdAFSIds.put(objAcc.Id, mapAFS);
            }
        }
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(lstWOs.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstWOs = new WorkOrdersSelector().selectWorkOrderId(new Set<Id>(lstWoId));
        }
        for(SVMXC__Service_Order__c obj: lstWOs) {
            mapPartnerWoIdAccId.put(obj.Id , obj.SVMXC__Company__c);
            lstStdWOTOEmail.add(obj);
        }
    
        if(accntApi==WorkOrders.STRING_PARTNER) {
            SendEmailNotification.getSendEmailtoPartnerAccount(WorkOrders.STRING_INSTALLED_WORK_ORDER,lstStdWOTOEmail, mapAccIdAFSIds , mapPartnerWoIdAccId);
        } else {
            SendEmailNotification.getSendEmailParamaters(WorkOrders.STRING_INSTALLED_WORK_ORDER,lstStdWOTOEmail, mapAccIdAFSIds , WorkOrders.STRING_COMPANY);
        }
    }

    private static void populateSets(List<SVMXC__Service_Order__c> records, Map<Id,SVMXC__Service_Order__c> mapOld, List<SVMXC__Service_Order__c> lstPartnerWO,  
                            Set<Id> setPartnerOwnerId, List<SVMXC__Service_Order__c> lstStdWOTOEmail, List<Id> lstStdWOId, List<Id> lstAccIds) {
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = mapOld != Null && mapOld.containsKey(objWorkOrder.Id) ? (SVMXC__Service_Order__c) mapOld.get(objWorkOrder.Id) : Null;
            
            if(objWorkOrder.SVMXC__Order_Type__c == 'Installation' 
                && (objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED  || objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED) 
                && objWorkOrder.SVMXC__Dispatch_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED  
                && (objOldWorkOrder == Null || objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c || objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c)) {
            
                if(objWorkOrder.Partner_Installation_WO__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED) {
                    lstPartnerWO.add(objWorkOrder);
                    setPartnerOwnerId.add(objWorkOrder.OwnerId);
                } else if(!objWorkOrder.Partner_Installation_WO__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED) { 
                    lstStdWOTOEmail.add(objWorkOrder);
                    lstStdWOId.add(objWorkOrder.Id);
                    lstAccIds.add(objWorkOrder.SVMXC__Company__c);
                }
            }
        }
    }

}
