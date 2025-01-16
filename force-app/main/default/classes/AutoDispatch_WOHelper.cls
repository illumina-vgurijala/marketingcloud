/**
* @author Shivani Jain
* @date 27th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Auto Dispatch Functionality 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shivani                 18-July-2022         Restrict auto rejected logic for dispatch console
*/ 
public with sharing class AutoDispatch_WOHelper {

    /*
    *  @AUTHOR:  Digvijay(Code refractored)
    *  @DESCRIPTION: Refactored. 
    *  @PARAM : :ist WorkOrders
    */
    public static void workOrderAutoDispatch(List<Sobject> records) { 

        List<SVMXC__Service_Order__c> lstWorkOrderToBeDispatched = new List<SVMXC__Service_Order__c>();
        List<SVMXC__Service_Order__c> lstNonDispatchWorkOrder = new List<SVMXC__Service_Order__c>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
           
            updateFSUserRoleToNull(objWorkOrder);//CodeScan Fix
            //added one condition (objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM 6756
            if(objWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null && (objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) && objWorkOrder.opportunity__c != NULL && objWorkOrder.Partner_Installation_WO__c == true){                
                lstWorkOrderToBeDispatched.add(objWorkOrder);
            }
            //added one condition (objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM 6756
            if((objWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null && (objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall))  || (String.isNotBlank(objWorkOrder.Origin__c) && objWorkOrder.Origin__c.EqualsIgnoreCase(WorkOrders.STRING_EMAIL_PROACTIVE_TS) && objWorkOrder.RecordTypeId == ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_RTYPE_FIELD_SERVICE) && objWorkOrder.SVMXC__Order_Type__c==WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES )){
                lstWorkOrderToBeDispatched.add(objWorkOrder);
            }
        }
  
        //CodeScan Fix
        lstNonDispatchWorkOrder=addNonDispatchWO(lstWorkOrderToBeDispatched);
        //CodeScan Fix
        validateForNonDispatchWO(lstNonDispatchWorkOrder);
       
    }

    /**
    * @description :Update Field Support user role to null
    * @param objWorkOrder 
    **/
    public static void updateFSUserRoleToNull(SVMXC__Service_Order__c objWorkOrder)
    {
         //DCP-844
         //added one condition (objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM 6756
            if(objWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null && (objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall)
                && objWorkOrder.Partner_Installation_WO__c == false || (String.isNotBlank(objWorkOrder.Origin__c) && objWorkOrder.Origin__c.EqualsIgnoreCase(WorkOrders.STRING_EMAIL_PROACTIVE_TS))){
                objWorkorder.Field_Support_User_Role__c = null;    
            }
            //added one condition (objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM 6756
            if(objWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null && (objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION || objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall)
                && objWorkOrder.Partner_Installation_WO__c == true) {
                objWorkorder.Field_Support_User_Role__c = null;  
            }
    }



    /**
    * @description : add all the non dispatch work order to a list
    * @param lstNonDispatchWorkOrder 
    * @param lstWorkOrderToBeDispatched 
    **/
    public static List<SVMXC__Service_Order__c> addNonDispatchWO(List<SVMXC__Service_Order__c> lstWorkOrderToBeDispatched)
    {
        List<SVMXC__Service_Order__c> lstNonDispatchWorkOrder = new List<SVMXC__Service_Order__c>();
        
        if(!WorkOrders.mapaccountIdToPFSERoles.isEmpty()) {
            Set<Id> setUnavailableTechnician = new ServiceUtilityCollection.ServiceSystemUtilityCollection().checkTechniciansCalendar(WorkOrders.mapaccountIdToPFSERoles);
            Map<Id,Set<Id>> technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(WorkOrders.mapaccountIdToPFSERoles);
            List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata = ServiceUtilityCollection.fetchBusinessHoursMetadata();
            
            for(SVMXC__Service_Order__c objDispatchWorkOrder :lstWorkOrderToBeDispatched) {
                if(objDispatchWorkOrder.Partner_Installation_WO__c == true){
                    lstNonDispatchWorkOrder = ServiceUtilityCollection.fetchNextAvailableEngineer(objDispatchWorkOrder, 
                    WorkOrders.mapaccountIdToPFSERoles.get(objDispatchWorkOrder.Account_Sold_To__c), 
                                                                    setUnavailableTechnician, null, technicianToExertise, lstBusinessHoursMetadata
                                                                    );
                } else{
                    lstNonDispatchWorkOrder = ServiceUtilityCollection.fetchNextAvailableEngineer(objDispatchWorkOrder, 
                                                                    WorkOrders.mapaccountIdToPFSERoles.get(objDispatchWorkOrder.SVMXC__Company__c), 
                                                                    setUnavailableTechnician, null, technicianToExertise, lstBusinessHoursMetadata
                                                                    );
                }
                                
                objDispatchWorkOrder.Is_Auto_Dispatch__c = true;                          
            }
        }
        return lstNonDispatchWorkOrder;
    }

    /**
    * @description :Throw error message for non dispatch work order
    * @param lstNonDispatchWorkOrder 
    **/
    public static void validateForNonDispatchWO(List<SVMXC__Service_Order__c> lstNonDispatchWorkOrder)
    {
        if(!lstNonDispatchWorkOrder.isEmpty()) {
            for(SVMXC__Service_Order__c objNonDispatchWorkOrder :lstNonDispatchWorkOrder) {
                if(objNonDispatchWorkOrder.Apttus_Sales_Order__c  == NULL && !UserInfo.getName().containsIgnoreCase(WorkOrders.STRING_SNAP_INTEGRATION_USER))
                    objNonDispatchWorkOrder.addError(Label.WorkOrderAutoAssignmentError);
            }
        }
    }

    

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders from Case and Installed Products
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public static void processAutoDispatchonWOUPdate(Map<Id, SObject> oldRecords, List<sObject> records) {

        //List of work orders to be dispatched
        List<SVMXC__Service_Order__c> lstWorkOrderToBeDispatched = new List<SVMXC__Service_Order__c>();
        Map<Id,Set<Id>> technicianToExertise = new Map<Id,Set<Id>>();
        Set<Id> setUnavailableTechnician = new Set<Id>();
        Map<Id,Boolean> mapAutoDispatchTriggered = new Map<Id,Boolean>();  //INC0227199
        Map<Id, Id> mapWorkOrderCaseOwner = new Map<Id, Id>();
        List<SVMXC__Service_Order__c> lstAutoRejectedWorkOrder = new List<SVMXC__Service_Order__c>(); //List of work orders that are auto rejected
        List<SVMXC__Service_Order__c> lstNonDispatchWorkOrder = new List<SVMXC__Service_Order__c>();
        Map<id,Case> mapCaseIdtoCaseObj=new Map<id,Case>();
        map<Id, string> mapTechIdToTimeZone = new map<Id, string>(); //DCP-25273
        Set<Id> setRejectedWorkOrdersIds = new Set<Id>();
        List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata =  ServiceUtilityCollection.fetchBusinessHoursMetadata();

        for(Case caseObj: WorkOrders.lstCaserecords) {        
            mapCaseIdtoCaseObj.put(caseObj.id,caseObj);
        }

        if(!WorkOrders.lstServiceGroupMembers.isEmpty()) {
            for(SVMXC__Service_Group_Members__c objTech:WorkOrders.lstServiceGroupMembers) {
                mapTechIdToTimeZone.put(objTech.Id, objTech.SVMXC__Salesforce_User__r.TimeZoneSidKey);
            }
        }

        addWOToBeDispatched(records,oldRecords,mapTechIdToTimeZone,lstWorkOrderToBeDispatched,lstAutoRejectedWorkOrder,setRejectedWorkOrdersIds,mapWorkOrderCaseOwner,mapCaseIdtoCaseObj);

        if(!WorkOrders.mapaccountIdToPFSERoles.isEmpty()) {
            setUnavailableTechnician = new ServiceUtilityCollection.ServiceSystemUtilityCollection().checkTechniciansCalendar(WorkOrders.mapaccountIdToPFSERoles);
            technicianToExertise = ServiceUtilityCollection.checkTechniciansExpertise(WorkOrders.mapaccountIdToPFSERoles);
        }

        
        for(SVMXC__Service_Order__c objDispatchWorkOrder :lstWorkOrderToBeDispatched) {
            lstNonDispatchWorkOrder = ServiceUtilityCollection.fetchNextAvailableEngineer(objDispatchWorkOrder, 
                                                                WorkOrders.mapaccountIdToPFSERoles.get(objDispatchWorkOrder.SVMXC__Company__c), 
                                                                setUnavailableTechnician, null, technicianToExertise, lstBusinessHoursMetadata
                                                            );
            objDispatchWorkOrder.Is_Auto_Dispatch__c = true; 
            //INC0227199
            mapAutoDispatchTriggered.put(objDispatchWorkOrder.id,true);                          
        }

        //DCP-1053 : if work Order is auto rejected
        for(SVMXC__Service_Order__c objRejectedWorkOrder :lstAutoRejectedWorkOrder) {
            ServiceUtilityCollection.fetchNextAvailableEngineer(objRejectedWorkOrder, 
            WorkOrders.mapaccountIdToPFSERoles.get(objRejectedWorkOrder.SVMXC__Company__c), 
                                                            setUnavailableTechnician,mapWorkOrderCaseOwner, technicianToExertise, lstBusinessHoursMetadata
                                                            );
            //INC0227199
            mapAutoDispatchTriggered.put(objRejectedWorkOrder.id,true);
        }
        if(!lstNonDispatchWorkOrder.isEmpty()) {
            for(SVMXC__Service_Order__c objNonDispatchWorkOrder :lstNonDispatchWorkOrder) {
                if(UserInfo.getName().containsIgnoreCase(WorkOrders.STRING_SNAP_INTEGRATION_USER)){
                    objNonDispatchWorkOrder.addError(Label.WorkOrderAutoAssignmentError);
                }
            }
        }
       
        updateWOFieldIsAutoDispatch(records,oldRecords,mapAutoDispatchTriggered,lstBusinessHoursMetadata,mapTechIdToTimeZone);
    }

    /**
    * @description :Add Work Order that to be dispatched to a list
    * @param records 
    * @param oldRecords 
    * @param mapTechIdToTimeZone 
    * @param lstWorkOrderToBeDispatched 
    * @param lstAutoRejectedWorkOrder 
    * @param setRejectedWorkOrdersIds 
    * @param mapWorkOrderCaseOwner 
    * @param mapCaseIdtoCaseObj 
    **/
    public static void addWOToBeDispatched(List<sObject> records,Map<Id, SObject> oldRecords,map<Id, string> mapTechIdToTimeZone,List<SVMXC__Service_Order__c> lstWorkOrderToBeDispatched,
    List<SVMXC__Service_Order__c> lstAutoRejectedWorkOrder,Set<Id> setRejectedWorkOrdersIds,Map<Id, Id> mapWorkOrderCaseOwner,Map<id,Case> mapCaseIdtoCaseObj)
    {
        
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
            if(WorkOrders.mapaccountIdToPFSERoles.ContainsKey(objWorkOrder.SVMXC__Company__c) && WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c)!=null) {
                for(Account_to_Field_Support__c obj :WorkOrders.mapaccountIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c).values()) {
                    mapTechIdToTimeZone.put(obj.User__c, obj.User__r.SVMXC__Salesforce_User__r.TimeZoneSidKey);
                }
            }

            //If the work order is selected for auto dispatch then assign technician to it based on the role
            if(objWorkOrder.Is_Auto_Dispatch__c && !objOldWorkOrder.Is_Auto_Dispatch__c && objWorkOrder.SVMXC__Company__c != null 
                    && objWorkOrder.RecordTypeId == ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_RTYPE_FIELD_SERVICE) 
                    && objWorkOrder.SVMXC__Order_Type__c== WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES ) {
                objWorkorder.Field_Support_User_Role__c = null;
                lstWorkOrderToBeDispatched.add(objWorkOrder);
            }

            //DCP-27709
            if(objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED && objoldWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED && objoldWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED && objWorkOrder.Is_Auto_Dispatch__c==true) {
                objWorkOrder.Is_Auto_Dispatch__c=false; 
                }
            
                addAutoRejectedWO(objWorkOrder,objOldWorkOrder,lstAutoRejectedWorkOrder,setRejectedWorkOrdersIds,mapWorkOrderCaseOwner,mapCaseIdtoCaseObj);
        }
    }

    /**
    * @description :add all the auto rejected WO based on cretain criteria
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    * @param lstAutoRejectedWorkOrder 
    * @param setRejectedWorkOrdersIds 
    * @param mapWorkOrderCaseOwner 
    * @param mapCaseIdtoCaseObj 
    **/
    public static void addAutoRejectedWO(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder,List<SVMXC__Service_Order__c> lstAutoRejectedWorkOrder,
    Set<Id> setRejectedWorkOrdersIds,Map<Id, Id> mapWorkOrderCaseOwner,Map<id,Case> mapCaseIdtoCaseObj)
    {   
        //DCP-54492 [add logic to bypass for Dispatcher Queues]
        Map<String, WorkOrder_SubRegion_Queue_Mapping__mdt> metaSubRegionQueue = WorkOrder_SubRegion_Queue_Mapping__mdt.getAll();
        Set<Id> queuesToIgnore = new Set<Id>();
        for(WorkOrder_SubRegion_Queue_Mapping__mdt metaRec : metaSubRegionQueue.values()) {
            queuesToIgnore.add(metaRec.Queue_Name__c);
        }

        //DCP-1053 : if work Order is auto rejected
        if(objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED && objOldWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED && objWorkOrder.Reason__c != null && objWorkOrder.Reason__c != '' && objWorkOrder.SVMXC__Company__c != null
            && !queuesToIgnore.contains(objWorkOrder.OwnerId)) {
                
            lstAutoRejectedWorkOrder.add(objWorkOrder);
            setRejectedWorkOrdersIds.add(objWorkOrder.Id);
                //INC0362493 : to handle Attempt to de-reference null object error on case field.
                if(objWorkOrder.SVMXC__Case__c != null && mapCaseIdtoCaseObj != null && mapCaseIdtoCaseObj.containskey(objWorkOrder.SVMXC__Case__c) && mapCaseIdtoCaseObj.get(objWorkOrder.SVMXC__Case__c) != null) {
                mapWorkOrderCaseOwner.put(objWorkOrder.id,mapCaseIdtoCaseObj.get(objWorkOrder.SVMXC__Case__c).OwnerId);
                }   
            WorkOrders.mapWorkOrderIdRejectionStatus.put(objWorkOrder.Id, objWorkOrder.SVMXC__Order_Status__c);
        } 
    }

    /**
    * @description :Update is Auto dispatch field on Work Order
    * @param records 
    * @param oldRecords 
    * @param mapAutoDispatchTriggered 
    * @param lstBusinessHoursMetadata 
    * @param mapTechIdToTimeZone 
    **/
    public static void updateWOFieldIsAutoDispatch(List<sObject> records,Map<Id, SObject> oldRecords,Map<Id,Boolean> mapAutoDispatchTriggered,List<Business_Hours_Setting__mdt> lstBusinessHoursMetadata,
    map<Id, string> mapTechIdToTimeZone)
    {
         for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //DCP-25273
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 
            if(objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED && objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Group_Member__c != null ) {
                ServiceUtilityCollection.setAutoRejectionDates(objWorkorder,lstBusinessHoursMetadata, mapTechIdToTimeZone.get(objWorkOrder.SVMXC__Group_Member__c));
            }
            //INC0227199
            if(objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c && objWorkOrder.Is_Auto_Dispatch__c  && !mapAutoDispatchTriggered.containsKey(objWorkOrder.id)) {
                objWorkOrder.Is_Auto_Dispatch__c=false;
            }
        }
    }
}