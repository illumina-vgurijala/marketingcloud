/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic when Work Order is Updated 
* MODIFICATION LOG: 
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Shivani                 10-Jun-2022          Initial version
* Vignesh                 22-Jun-2022          Logic to populate Assignment Acceptance Due Date.
* Sagar Madkaikar         09-Nov-2022          DCP-57117
* Gladis                  20-Feb-2023          DCP-58285 - Updated updateOwnerForFieldTechnician method to populate date/time field when the owner is FSC
* Nancy                   08-Aug-2023          CMCM-507 - Optimised Onsite Response Date Calculation
* Abhishek                14-Nov-2023          CMCM-2117 - refector the processonSiteResponseDueDateonWOUPdate method 
* Nancy                   13-Feb-2024             CMCM-5307 Work Order Trigger Query Optimization
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/ 
public with sharing class PopulateFieldsOnUpdate_WOHelper {

    public static final string FIELD_TECHNICIAN ='Field Technician';	
    public static final list<String> DISPATCH_SOURCES = new list<String>{'Coordinator','Field Technician'};
    public static List<SVMXC__Service_Order__c> lstWOForOwnerUpdate = new List<SVMXC__Service_Order__c>();
    public static Boolean triggeredFromDC = false;
    public static final String FIELD_SERVICE_COORDINATION_EUR_NORTH = 'Field_Service_Coordination_EUR_North'; //DCP-58285
    public static final String ONSITE_RESPONSE_DUE_DATE = 'Onsite_Response_Due_Date__c';
    public static final String OWNER = 'Owner';
    public static Map <Id, DateTime> mapWOToORDDChange = new Map <Id, DateTime>();/* CMCM-507 Maps WO to first ORDD change date value*/
    public static Map<Id, Id> mapWOIdToNewOwnerId = new Map<Id, Id>();/* CMCM-507 Map each WO Id to its newly added Owner Id*/
    public static List<Id> woOwnerIds = new List<Id>();/* CMCM-507 Map each WO Id to its newly added Owner Profile Name*/
    public static Map<Id, DateTime> mapWOIdToFirstChangeDate = new Map<Id, DateTime>(); /* CMCM-507 Map each WO Id to the date the first Owner being assigned to FS user*/
    public static Map<Id, Id> mapWOIdToCreatedById= new Map<Id, Id>();/* CMCM-4384 Map each WO Id to its created Id*/
    public static List<Id> woCreatedByIds = new List<Id>();
    //CMCM-5307 - Start
    public static List<User> filteredUserRecords = new List<User>();
    public static List<SVMXC__Service_Order__History> woHistoryList = new List<SVMXC__Service_Order__History>();
    public static Map<Id, User> mapUserIdToUser = new Map<Id, User>();
    public static Map<Id,SVMXC__Service_Level__c> idToSLATerms = new Map<Id,SVMXC__Service_Level__c>();
    public static List<SVMXC__Service_Group_Members__c> fieldSupportList = new List<SVMXC__Service_Group_Members__c>();
    //CMCM-5307 - End

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders 
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */ 
    public static void onfieldSupportUpdate(Map<Id, SObject> oldRecords, List<sObject> records) {
        
        Map<Id,SVMXC__Service_Group_Members__c> maptechnicianIdtotechnician = new Map<Id,SVMXC__Service_Group_Members__c>();
        Map<Id,SVMXC__Service_Group_Members__c> technicianMap = new Map<Id,SVMXC__Service_Group_Members__c>();
		
        for(SVMXC__Service_Group_Members__c objTechnician : WorkOrders.lstServiceGroupMembers) {
            maptechnicianIdtotechnician.put(objTechnician.id, objTechnician);
            technicianMap.put(objTechnician.SVMXC__Salesforce_User__c, objTechnician);
        }
        
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
            if((objWorkOrder.Is_Reopen_Approved__c == False)
                && (objWorkOrder.SVMXC__Order_Status__c != null 
                    && objWorkOrder.RecordTypeId != ServiceUtilityCollection.getRecordTypeId('SVMXC__Service_Order__c', WorkOrders.STRING_WORK_ORDER_FIELD_STOCK_RECORDTYPE_NAME) 
                    && (objWorkOrder.SVMXC__Order_Status__c.equals (WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED) 
                        || objWorkOrder.SVMXC__Order_Status__c.equals (WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS)) 
                    && objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c)) {
                if(!technicianMap.IsEmpty() && technicianMap.ContainsKey(UserInfo.getUserId())) {
                    objWorkOrder.SVMXC__Group_Member__c=technicianMap.get(UserInfo.getUserId()).Id;
                }
            } 

            //DCP-30846
            if(objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c && maptechnicianIdtotechnician.ContainsKey(objWorkOrder.SVMXC__Group_Member__c) ) {
                //DCP-30846
                objWorkOrder.SVMXC__Member_Email__c = maptechnicianIdtotechnician.get(objWorkOrder.SVMXC__Group_Member__c).Related_User_Email__c;
                        
                //DCP-38964
                if(objWorkOrder.OwnerID != maptechnicianIdtotechnician.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Salesforce_User__c) {
                    objWorkOrder.OwnerID = maptechnicianIdtotechnician.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Salesforce_User__c;
                    objWorkOrder.SVMXC__Order_Status__c = objWorkOrder.Partner_Work_Order__c ? WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNMENT_ACCEPTED : objWorkOrder.SVMXC__Order_Status__c;
                }
            }

            updateFirstTimeFixCountAndDistAccount(objWorkOrder,objOldWorkOrder,maptechnicianIdtotechnician);
            updateDispatchSourceOnWO(objWorkOrder , objOldWorkOrder);
        }

        if(!lstWOForOwnerUpdate.isEmpty()){
            updateOwnerForFieldTechnician(lstWOForOwnerUpdate);
        }
        //DCP-54492 - Ends

    }

    /**
    * @description :Update First time fix count and Distributor Account field on WO
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    **/
    public static void updateFirstTimeFixCountAndDistAccount(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder,Map<Id,SVMXC__Service_Group_Members__c> maptechnicianIdtotechnician){

        //Refactor WorkFlow - Work Order : Update First Time Fix Count
        if(objWorkOrder.RecordTypeId == ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, System.Label.WorkOrderRecordTypeFieldService) 
        && objWorkOrder.SVMXC__Order_Status__c!=objOldWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == System.Label.WorkOrderStatusTechnicianOnsite 
        && objWorkOrder.SVMXC__Order_Type__c == System.Label.WorkOrderTypeServiceActivities) {
            objWorkOrder.First_Time_Fix_Count__c = objWorkOrder.First_Time_Fix_Count__c == null ? 0 : objWorkOrder.First_Time_Fix_Count__c + 1;
        }
        // DCP-39824  Prepare map to hold list of field support for cp wo.
        if(objWorkOrder.SVMXC__Group_Member__c !=null && objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c 
        && objWorkOrder.Partner_Work_Order__c && String.isBlank(objWorkOrder.Distributor_Account__c)) {
            if(!maptechnicianIdtotechnician.isEmpty() && maptechnicianIdtotechnician.containskey(objWorkOrder.SVMXC__Group_Member__c)) {
                objWorkOrder.Distributor_Account__c = maptechnicianIdtotechnician.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Inventory_Location__r.SVMXC__Account__r.ERP_Customer_Id__c;

            }
			
        }
    }

    /**
    * @description : Update Dispatch Source and Assignment Acceptance Due Date Time on Work Order
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    **/
    public static void updateDispatchSourceOnWO(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder)
    {
        //DCP-54492 - Starts   
        if(objWorkOrder.SVMXC__Locked_By_DC__c && objWorkOrder.SVMXC__Locked_By_DC__c != objOldWorkOrder.SVMXC__Locked_By_DC__c){
            objWorkOrder.Dispatch_Source__c = 'Coordinator';
            objWorkOrder.Dispatcher__c = Userinfo.getUserId();
            objWorkOrder.SVMXC__Locked_By_DC__c = false;
            triggeredFromDC = true;
        }

        if(!String.isBlank(objWorkOrder.Dispatch_Source__c) && objWorkOrder.Dispatch_Source__c != objOldWorkOrder.Dispatch_Source__c){
            if(DISPATCH_SOURCES.contains(objWorkOrder.Dispatch_Source__c)){
                WorkOrders.setWOForCaseOwnerSync.add(objWorkOrder.Id);
            }
            lstWOForOwnerUpdate.add(objWorkOrder);
        }
           
    }

    /*
    *  @AUTHOR: Vignesh Sethuramalingam
    *  @DESCRIPTION: To populate Owner  on Work Orders 
    *  @PARAM : List of WorkOrder
    *  @RETURN:  void
    */ 
    public static void updateOwnerForFieldTechnician(list<SVMXC__Service_Order__c> lstWOForOwnerUpdate){
        Map<Id,Map<String,Account_to_Field_Support__c>> mapaccIdToPFSERoles = WorkOrders.mapaccountIdToPFSERoles;
        Map<String, WorkOrder_SubRegion_Queue_Mapping__mdt> metaSubRegionQueue = WorkOrder_SubRegion_Queue_Mapping__mdt.getAll();
        for(SVMXC__Service_Order__c objWorkOrder : lstWOForOwnerUpdate){
            if(objWorkOrder.Dispatch_Source__c == FIELD_TECHNICIAN){
                String strOwnerId;
                String fsUserId;
				String regionSubRegion;
				if(String.isNotBlank(objWorkOrder.Account_region__c) && String.isNotBlank(objWorkOrder.Account_Subregion__c) ){
					regionSubRegion = objWorkOrder.Account_region__c+'_'+objWorkOrder.Account_Subregion__c.replace(' ','_');
                }

				if( String.isNotBlank(regionSubRegion) && metaSubRegionQueue.containsKey(regionSubRegion) ){
                    strOwnerId = metaSubRegionQueue.get(regionSubRegion).Queue_Name__c;
                } else if (mapaccIdToPFSERoles.containsKey(objWorkOrder.SVMXC__Company__c) && mapaccIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c).containsKey('Primary Field Service Engineer') ){
                    strOwnerId = mapaccIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c).get('Primary Field Service Engineer').Salesforce_User_ID__c;
                    fsUserId = mapaccIdToPFSERoles.get(objWorkOrder.SVMXC__Company__c).get('Primary Field Service Engineer').User__c;
                }
                
                if(!String.isBlank(strOwnerId)){
                    objWorkOrder.OwnerId  = strOwnerId;
                    objWorkOrder.SVMXC__Order_Status__c =  strOwnerId.startsWith(WorkOrders.STRING_005) ?  WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED : WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED;
                    objWorkOrder.SVMXC__Group_Member__c = strOwnerId.startsWith(WorkOrders.STRING_005) ? fsUserId : null;
                }
            }
            objWorkOrder.Dispatch_Source__c = Null;
        }
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders 
    *  Updated the logic to include Regulatory Type 'EUA' for DCP-47691
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */ 
    public static void updateFieldsonWorkOrder(Map<Id, SObject> oldRecords, List<sObject> records, Channel_Partner_Profile_Settings__c channelPartner) {
        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.updateFieldsonWorkOrder()');
        Map<Id,Product2> mapIVDProducts=new Map<Id,Product2>() ;
            
        Map<Id,Product2> allProductRecMap=new Map<Id,Product2>(WorkOrders.lstProducts);//POC: DCP-49644
        for(Product2 obj:WorkOrders.lstProducts) {
            if(!String.IsBlank(obj.Regulatory_Type__c) && (obj.Regulatory_Type__c.contains('DX') || obj.Regulatory_Type__c=='IUO' || obj.Regulatory_Type__c=='EUA')) {
                mapIVDProducts.put(obj.Id,obj);
            }
        }

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
            //POC: DCP-49644 Start:Product family update on WO
            AutoPopulateWOField_WOHelper.autoPopulateWOFields(objWorkOrder, objOldWorkOrder, allProductRecMap);
            //DCP-49644: END

            //DCP-46837 To prefix "Abandoned" to Work Order subject when Abandoned Reason is selected from SFM 
            WorkOrdersCustomerAbandonedService.updateCustomerAbandonedWorkOrder(objWorkOrder, objOldWorkOrder);
            //DCP-49916 Start
            updateTrainingReqFieldsOnWO(objWorkOrder,objOldWorkOrder);
            //DCP-49916 END
           
            //Codescan fix :complexity issue
            updateScheduledDateTimeAndSendERP(objWorkOrder,objOldWorkOrder);
            updateWOFieldsForVariousConditions(objWorkOrder,objOldWorkOrder,mapIVDProducts);
            updateWOFields(objWorkOrder,objOldWorkOrder);
            updateInitialResponseAndWOScheduledOn(objWorkOrder,objOldWorkOrder);
            updateWOCompletedDateTime(objWorkOrder,objOldWorkOrder);
            updateIsCustomerSignMandatAndAppliedSrvcContract(objWorkOrder,objOldWorkOrder,channelPartner);
        }
    }     
    
    /**
    * @description :Update WO Scheduled Date Time and Send ERP fields
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    **/
    public static void updateScheduledDateTimeAndSendERP(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder)
    {
        //DCP-DCP-42762-Start
        if(objWorkOrder.Cost_Center__c != objOldWorkOrder.Cost_Center__c && !WorkOrders.stopIntegrationOnCostCenterChange) {
            objWorkOrder.Send_to_ERP__c = true;
            WorkOrders.stopIntegrationOnCostCenterChange = true;
        }
        //DCP-42762-End
        //Start DCP-46317: Update Scheduled Date Time field
        if(objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WO_STATUS_TECHNICIAN_ONSITE
		        && objWorkOrder.SVMXC__Billing_Type__c==WorkOrders.STRING_LABEL_BILLABLE && objWorkOrder.Reason_for_Reopen__c==null //DCP-57117
                && (objWorkOrder.SVMXC__Scheduled_Date_Time__c == null || objWorkOrder.SVMXC__Scheduled_Date_Time__c < System.now())) {
            objWorkOrder.SVMXC__Scheduled_Date_Time__c = System.now();
        }
        //End of DCP-46317
        //DCP-39952-Start
        if(objWorkOrder.SVMXC__Scheduled_Date_Time__c != objOldWorkOrder.SVMXC__Scheduled_Date_Time__c && Label.WorkOrderBillingTypeBillable.equals(objWorkOrder.SVMXC__Billing_Type__c)){
            ilib_LogEvent.message('Marking Send_to_ERP__c for SVMXC__Scheduled_Date_Time__c change');
            objWorkOrder.Send_to_ERP__c = true;
        }
        //DCP-39952-End
                     
        
    }

    /**
    * @description :Update Work Order Fields based on various conditions
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    * @param mapIVDProducts 
    **/
    public static void updateWOFieldsForVariousConditions(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder,Map<Id,Product2> mapIVDProducts)
    {   
        //DCP-58285-to fill the Date_Time_in_coordinator_queue__c field when user is FSC-EUR
        List<Group> lstQueues = ServiceUtilityCollection.getQueueFromName(new Set<String>{FIELD_SERVICE_COORDINATION_EUR_NORTH}); //DCP-58285
        Id fSCoordinationEurNorthId = lstQueues[0].Id; 

        if(objOldWorkOrder.OwnerId != objWorkOrder.OwnerId && objWorkOrder.OwnerId == fSCoordinationEurNorthId){
            objWorkOrder.Date_Time_in_coordinator_queue__c=system.now();
        }

        //DCP-58285-to blank the Date_Time_in_coordinator_queue__c field when user is not FSC-EUR
        if(objWorkOrder.Date_Time_in_coordinator_queue__c != null && objWorkOrder.OwnerId != fSCoordinationEurNorthId){
            objWorkOrder.Date_Time_in_coordinator_queue__c = null;
        }
        //for populating original owner
        if(objWorkOrder.OwnerId != objOldWorkOrder.OwnerId && string.valueOf(objWorkOrder.OwnerId).startsWith(WorkOrders.STRING_005)){
            objWorkOrder.Original_Owner__c = objWorkOrder.OwnerId;
        }
        // DCP-29459 // codescan fix: combined iff
        if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c 
                && (objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED || objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED) 
                && objWorkOrder.SVMXC__Product__c != null && mapIVDProducts.containsKey(objWorkOrder.SVMXC__Product__c)) {
            objWorkOrder.IVD_Identifier_at_Completion__c = true;
        } 

        //refactor: Work Order: Order Status Closed  
        if(objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED && objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c) { //Codescan fix changed condition
            objWorkOrder.SVMXC__Closed_On__c = system.now();
        }
       
    }
    /**
    * @description :Update WO fields on certain conditions
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    **/
    public static void updateWOFields(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder)
    {
         //refactor: Fields Auto Populated From Case  
         if(objWorkOrder.OwnerId != objOldWorkOrder.OwnerId && String.ValueOf(objOldWorkOrder.OwnerId).left(3) == WorkOrders.STRING_005 && objWorkOrder.OwnerId != objWorkOrder.Previous_Owner__c){
            objWorkOrder.Previous_Owner__c = objOldWorkOrder.OwnerId;
        }
        if(objOldWorkOrder.Update_Work_Order_Owner__c != true && objWorkOrder.Update_Work_Order_Owner__c == true && objWorkOrder.OwnerId != objWorkOrder.Previous_Owner__c && objWorkOrder.Previous_Owner__c != null){
            objWorkOrder.OwnerId = objWorkOrder.Previous_Owner__c;
            objWorkOrder.Update_Work_Order_Owner__c = false;  
        }
        if(objWorkOrder.SVMXC__Order_Type__c != WorkOrders.STRING_LABEL_PLANNED_MAINTENANCE && objOldWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_PLANNED_MAINTENANCE && objWorkOrder.SVMXC__Billing_Type__c == WorkOrders.STRING_LABEL_BILLABLE){
            objWorkOrder.SVMXC__Billing_Type__c = '';
        }
        
    }
    
    /**
    * @description :Update WO Initial Response and WO_Scheduled_On Fields on certain condition
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    **/
    public static void updateInitialResponseAndWOScheduledOn(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder)
    {
        if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_SCHEDULED){
            objWorkOrder.WO_Scheduled_On__c = DateTime.now();
        }
         //Refactor PB :: Work_Order_Update_Initial_and_Average_Response_dates
         if(objOldWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED){
            objWorkOrder.SVMXC__Actual_Initial_Response__c= DateTime.now();
            Long lngCreatedDate = objWorkOrder.CreatedDate.getTime() ;
            Long lngCurrentTime = DateTime.now().getTime();
            Long lngMilliseconds = lngCurrentTime - lngCreatedDate;
            Long lngSeconds = lngMilliseconds / 1000;
            Long lngMinutes = lngSeconds / 60;
            objWorkOrder.SVMXC__Time_to_Initial_Response__c= lngMinutes;
        } 
       
       
    }

    /**
    * @description :Update Completed Date and Time and Latest completed date time on WO
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    **/
    public static void updateWOCompletedDateTime(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder)
    {     
         // to populate date completed 
        if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED){
            objWorkOrder.SVMXC__Completed_Date_Time__c=DateTime.now();
            objWorkOrder.Latest_Completion_Date_Time__c =DateTime.now();//Added dCP-39890
        }

        if( objWorkOrder.SVMXC__Completed_Date_Time__c != null && objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c &&objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED) {
            objWorkOrder.SVMXC__Completed_Date_Time__c = DateTime.now();
        }
        Id woRecordTypeId = ServiceUtilityCollection.getRecordTypeId(WorkOrders.STRING_WORK_ORDER_API_NAME, WorkOrders.STRING_WORK_ORDER_RTYPE_REMOTE_SUPPORT);
        if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Completed_Date_Time__c!=null && (objWorkOrder.SVMXC__Order_Status__c==WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED||(objWorkOrder.RecordTypeId==woRecordTypeId && objWorkOrder.SVMXC__Order_Status__c==WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS))){
            objWorkOrder.Latest_Completion_Date_Time__c =objWorkOrder.SVMXC__Completed_Date_Time__c;//Added dCP-39890
            objWorkOrder.SVMXC__Completed_Date_Time__c=null;
        }
       
    }
    /**
    * @description :Update Is customer SIgned Mandatory and applied service contract field on WOrk order
    * @param objWorkOrder 
    * @param objOldWorkOrder 
    * @param channelPartner 
    **/
    public static void updateIsCustomerSignMandatAndAppliedSrvcContract(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder, Channel_Partner_Profile_Settings__c channelPartner)
    {
        if(objOldWorkOrder.SVMXC__Component__c != objWorkOrder.SVMXC__Component__c || objWorkOrder.SVMXC__Site__c != objOldWorkOrder.SVMXC__Site__c)
        objWorkOrder.Applied_Service_Contract__c = null; //INC0260493
     //Refactor WorkFlow - WorkOrder:Update Is Customer Sign Mandatory
        // Installation condition has been removed as part of DCP-45359 & DCP-46827(added CP check)
        if(objWorkOrder.SVMXC__Billing_Type__c!= objOldWorkOrder.SVMXC__Billing_Type__c && objWorkOrder.SVMXC__Billing_Type__c == WorkOrders.STRING_LABEL_BILLABLE && !channelPartner.Is_Channel_Partner__c){
            objWorkOrder.Is_Customer_Sign_Mandatory__c = true;
        }else if(objOldWorkOrder.SVMXC__Billing_Type__c == WorkOrders.STRING_LABEL_BILLABLE && objWorkOrder.SVMXC__Billing_Type__c != WorkOrders.STRING_LABEL_BILLABLE){
            objWorkOrder.Is_Customer_Sign_Mandatory__c = false;
        }
    }
    /*
    *  @AUTHOR: Pooja Shalwadi
    *  @DESCRIPTION: To Update training required and reason for no training Fields on Work Orders 
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */ 
    public static void updateTrainingReqFieldsOnWO(SVMXC__Service_Order__c objWorkOrder,SVMXC__Service_Order__c objOldWorkOrder) {
        //Ritika Incident : Fix INC0286227
        if(objWorkOrder.SVMXC__Order_Type__c!=objOldWorkOrder.SVMXC__Order_Type__c ){
             if(objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_INSTALLATION){
                 objWorkOrder.Training_Required__c = true;
                 //Pooja: DCP-49916 Start
                 objWorkOrder.Reason_for_No_Training__c=null;
                 //DCP-49916 End
             }
             else //AC3
             {
                 objWorkOrder.Training_Required__c = false;
                 //Pooja: DCP-49916 Start : AC3
                 if(objOldWorkOrder.SVMXC__Order_Type__c ==WorkOrders.STRING_LABEL_INSTALLATION) 
                 {
                     objWorkOrder.Reason_for_No_Training__c=WorkOrders.NON_INSTALL_WO;
                 }
                 //DCP-49916 End
             } 
        }
         //Pooja: DCP-49916 Start: //AC4.1& ac5
        
        if(objWorkOrder.Training_Required__c!=objOldWorkOrder.Training_Required__c && 
        objWorkOrder.Training_Required__c && objWorkOrder.Reason_for_No_Training__c!=null)
        {
            objWorkOrder.Reason_for_No_Training__c=null;
           
        }
        
        //AC4.2
        if(objWorkOrder.Reason_for_No_Training__c!=objOldWorkOrder.Reason_for_No_Training__c && objWorkOrder.Reason_for_No_Training__c!=null && !objWorkOrder.Training_Required__c)
        {
            objWorkOrder.Training_Required__c=false;
        }
    }

    /*
     * From the Account on a Work Order, populate the Region field
     */
    public static void populateRegionFromAccount(List<sObject> records) {
        Map<Id, Account> mapIdToAccount = new Map<Id, Account>();
        for(Account acc: WorkOrders.lstAccountRecords) {
            mapIdToAccount.put(acc.id,acc);
        }
        for(SVMXC__Service_Order__c wo : (List<SVMXC__Service_Order__c>)records) {
            if(wo.SVMXC__Company__c != null && mapIdToAccount.get(wo.SVMXC__Company__c) != null) {
                wo.Region__c = mapIdToAccount.get(wo.SVMXC__Company__c).Territory_Region__c;
            }
        }
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To update Integration status on Completed WorkOrders 
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */ 
    public static void checkforCaseandIPUpdateonWorkOrder(Map<Id, SObject> oldRecords, List<Sobject> records) {
        List<Sobject> updatedrecords = new List<Sobject>();
        List<Sobject> lstWOupdatedtoAssignedAndInProgress = new List<Sobject>();
        Set<Id> updatedrecordsId = new Set<Id>();
        Map<Id,Case> mapRelatedCase = new Map<Id,Case>(WorkOrders.lstCaserecords);

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));

            populateUpdatedRecords(objWorkOrder, objOldWorkOrder, updatedrecords);

            if(objOldWorkOrder.SVMXC__Order_Status__c != objWorkOrder.SVMXC__Order_Status__c 
                    && (objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED 
                            || objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS)) {
                lstWOupdatedtoAssignedAndInProgress.add(objWorkOrder);
            }

            if(objOldWorkOrder.SVMXC__Case__c != objWorkOrder.SVMXC__Case__c && objWorkOrder.SVMXC__Case__c != null) {
                //DCP-46053 - Updating Product Serial Number and Product Lot Number 
                if(mapRelatedCase.containsKey(objWorkOrder.SVMXC__Case__c)) {
                    objWorkOrder.Product_Lot_Number__c = mapRelatedCase.get(objWorkOrder.SVMXC__Case__c).Product_Lot_Number__c;
                    objWorkOrder.Product_Serial_Number__c = mapRelatedCase.get(objWorkOrder.SVMXC__Case__c).Product_Serial_Number__c;
                }
                //DCP-46053 Ends
                updatedrecordsId.add(objWorkOrder.SVMXC__Case__c);
                
            }
        }
        if(!updatedrecords.IsEmpty()) {
            AutoPopulateWOField_WOHelper.populateWorkOrderFieldsfromCaseandIP(updatedrecords, WorkOrders.lstCaserecords, WorkOrders.lstInstalledProductrecords);
        }
        if(!updatedrecordsId.IsEmpty()) {
            ValidateManualCreation_WOHelper.workOrderCaseAssociationCheck(updatedrecordsId, records);
        }
        if(!lstWOupdatedtoAssignedAndInProgress.IsEmpty()) {
            populateCaseFieldsonWOOnWOStatusChange(lstWOupdatedtoAssignedAndInProgress);
        }
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To update Integration status on Completed WorkOrders 
    *  @PARAM : List of Sobjects
    *  @RETURN:  void
    */ 
    private static void populateUpdatedRecords(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder, List<Sobject> updatedrecords) {
        if(!objWorkOrder.Record_Created_from_SFM__c && objOldWorkOrder.SVMXC__Case__c != objWorkOrder.SVMXC__Case__c && objWorkOrder.SVMXC__Case__c != null ){
            updatedrecords.add(objWorkOrder);
            WorkOrders.isCaseUpdated = true;
        } else if(objOldWorkOrder.SVMXC__Component__c !=objWorkOrder.SVMXC__Component__c  && objWorkOrder.SVMXC__Component__c != null){
            updatedrecords.add(objWorkOrder);
            WorkOrders.isIPorProdUpdated = true;
        }
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders from Case and Installed Products
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public static void populateCaseFieldsonWOOnWOStatusChange(List<Sobject> records) {
        Map<id, Case> mapCaseIdToCaseRec = new Map<id, Case>();
        //DCP-33452 added 2 fields Follow_up_Needed__c & Next_Steps__c.
        for(Case objCase: WorkOrders.lstCaserecords){
            mapCaseIdToCaseRec.put(objCase.Id, objCase);
        }

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
            //DCP-33452
            if(!mapCaseIdToCaseRec.isEmpty() && mapCaseIdToCaseRec.containsKey(objWorkOrder.SVMXC__Case__c) 
                    && mapCaseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c) != null && objWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED
                    && objWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED ){
                objWorkOrder.Case_Subject__c = mapCaseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Subject;
                objWorkOrder.Case_Description__c = mapCaseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Description;
                objWorkOrder.Case_Next_Steps__c = mapCaseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Next_Steps__c;
                objWorkOrder.Case_Follow_up_Needed__c = mapCaseIdToCaseRec.get(objWorkOrder.SVMXC__Case__c).Follow_up_Needed__c;
            }
        }
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders from Case and Installed Products
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ 
    public static void processContactFieldonWorkOrder(Map<Id, SObject> oldRecords, List<sObject> records) {
        // DCP-33497
        Map<Id,contact> contactIdToRecord = new Map<Id,contact>();
        Map<Id,SVMXC__Service_Group_Members__c> fsIdToFieldSupport = new Map<Id,SVMXC__Service_Group_Members__c>();
        
        
        for(Contact objCont: WorkOrders.lstContactRecords) {
            ContactIdToRecord.put(objCont.Id, objCont);
        }
        
        for(SVMXC__Service_Group_Members__c objTechnician : WorkOrders.lstServiceGroupMembers){
            fsIdToFieldSupport.put(objTechnician.id, objTechnician);
        }
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
            //DCP-25273
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)); 

            //Refactor WorkFlow - WorkOrderUpdateContactPhoneAndContactEmail
            if(objWorkOrder.SVMXC__Contact__c !=null && ContactIdToRecord.containsKey(objWorkOrder.SVMXC__Contact__c)){
                objWorkOrder.SVMX_PS_Contact_Email__c=ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Email;
                objWorkOrder.SVMX_PS_Contact_Phone__c=ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Phone;
            }

            if(String.IsBlank(objWorkOrder.Contact_Preferred_Language__c) && (objWorkOrder.SVMXC__Contact__c != objOldWorkOrder.SVMXC__Contact__c) || objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c) {
                // if contact preferred Language is available
                if (objWorkOrder.SVMXC__Contact__c != null && !ContactIdToRecord.isEmpty() && ContactIdToRecord.containsKey(objWorkOrder.SVMXC__Contact__c) && ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c) != null && !String.isBlank(ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Preferred_Language__c)) {
                    objWorkOrder.Contact_Preferred_Language__c = ContactIdToRecord.get(objWorkOrder.SVMXC__Contact__c).Preferred_Language__c;
                    
                } else if ( String.IsBlank(objWorkOrder.Contact_Preferred_Language__c) && objWorkOrder.SVMXC__Group_Member__c != null && !fsIdToFieldSupport.isEmpty() && fsIdToFieldSupport.containsKey(objWorkOrder.SVMXC__Group_Member__c) && fsIdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c) != null && !String.isBlank(fsIdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c).Preferred_Service_Report_Language__c)) {
                    // if field support preferred language is available.
                    objWorkOrder.Contact_Preferred_Language__c = fsIdToFieldSupport.get(objWorkOrder.SVMXC__Group_Member__c).Preferred_Service_Report_Language__c;
                    
                } else {
                    // if both contact preferred and field support preferred language are not available
                    if(String.IsBlank(objWorkOrder.Contact_Preferred_Language__c))
                    objWorkOrder.Contact_Preferred_Language__c = WorkOrders.STRING_WO_CONTACT_PREFERRED_LANGUAGE_ENGLISH;
                }
            }
        }
            
    }

    /*
    *  @AUTHOR: Digvijay Singh
    *  @DESCRIPTION: To populate Fields on Work Orders from Case and Installed Products
    *  @PARAM : List of Sobject
    *  @RETURN:  void
    */ public static void processonSiteResponseDueDateonWOUPdate(Map<Id, SObject> oldRecords, List<sObject> records) {
        Map<SVMXC__Service_Order__c, Id> mapOnsiteDueDateWOToFieldSupportId = new Map<SVMXC__Service_Order__c, Id>();
        Map<Id, String> profileMap = new Map<Id, String>();
        //CMCM-507 - Start
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
            mapWOIdToNewOwnerId.put(objWorkOrder.Id, objWorkOrder.OwnerId);
            mapWOIdToCreatedById.put(objWorkOrder.Id, objWorkOrder.CreatedById);
        }
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(filteredUserRecords.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            filteredUserRecords = [Select Id, Profile.Name From User Where Profile.Name = : System.Label.ProfileFieldService AND (Id IN :mapWOIdToNewOwnerId.values() OR Id IN :mapWOIdToCreatedById.values())];
        }
        for (User usr : filteredUserRecords) {
            profileMap.put(usr.Id,usr.Profile.Name);
        }
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            Id woAssociatedUser = mapWOIdToNewOwnerId.get(objWorkOrder.Id); /*Owner Id */
            Id woCreatedByUser = mapWOIdToCreatedById.get(objWorkOrder.Id); /*Created By user Id */
            if(!filteredUserRecords.isEmpty()) {
                    if (profileMap.containsKey(woAssociatedUser)) {
                        woOwnerIds.add(objWorkOrder.Id);
                    } 
                    if (profileMap.containsKey(woCreatedByUser)) {
                        woCreatedByIds.add(objWorkOrder.Id); 
                    }
            }
        }
        ilib_LogEvent.message('woOwnerIds---' + woOwnerIds);

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
            SVMXC__Service_Order__c objOldWorkOrder = oldRecords != NULL && oldRecords.containsKey(objWorkOrder.Id) ? (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)) : NULL;
                //Logic to populate Onsite Response Due Date 
                if(objWorkOrder.SVMXC__SLA_Terms__c != NULL /*Currently SVMXC__SLA_Terms__c is populated*/
                && objWorkOrder.SVMXC__Order_Type__c == WorkOrders.STRING_LABEL_SERVICE_ACTIVITIES /*The Order Type on Work Order is Service Activities*/
                && objWorkOrder.Case_Record_Type__c == WorkOrders.STRING_CASE_RECORD_TYPE_BUSINESS_ISSUE /*The Related Case's Record Type is Business Issue*/
                && String.valueof(objWorkOrder.OwnerId).left(3) == WorkOrders.STRING_005 /*Currently the Work Order is assigned to a user as Owner (not a queue)*/
                && objWorkOrder.SVMXC__Group_Member__c != NULL /*Field Support is populated*/
                && woOwnerIds.contains(objWorkOrder.Id)) /*Current Owner is FS User*/
                {
                   if(( (Trigger.IsInsert) /* If Work Order is created by a Field Service User*/ 
                    ||(Trigger.IsUpdate && objOldWorkOrder != NULL && objWorkOrder != NULL && (((objOldWorkOrder.Onsite_Response_Due_Date__c == NULL && objWorkOrder.Onsite_Response_Due_Date__c != objOldWorkOrder.Onsite_Response_Due_Date__c) || objOldWorkOrder.Onsite_Response_Due_Date__c == NULL) && 
                    (objWorkOrder.SVMXC__Order_Type__c != objOldWorkOrder.SVMXC__Order_Type__c /*Order Type is changed*/
                    || objWorkOrder.Case_Record_Type__c != objOldWorkOrder.Case_Record_Type__c /*Case Record Type is changed*/
                    || objWorkOrder.SVMXC__Group_Member__c != objOldWorkOrder.SVMXC__Group_Member__c /*Field Support is changed*/
                    || objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c
                    || objWorkOrder.SVMXC__SLA_Terms__c != objOldWorkOrder.SVMXC__SLA_Terms__c
                    || objWorkOrder.OwnerId != objOldWorkOrder.OwnerId )) || (objWorkOrder.SVMXC__SLA_Terms__c != objOldWorkOrder.SVMXC__SLA_Terms__c /*SVMXC__SLA_Terms__c is changing*/
                    && ((objOldWorkOrder.Onsite_Response_Due_Date__c != NULL && objWorkOrder.Onsite_Response_Due_Date__c != objOldWorkOrder.Onsite_Response_Due_Date__c) || objOldWorkOrder.Onsite_Response_Due_Date__c != NULL))))) /*Status is changed*/{
                        mapOnsiteDueDateWOToFieldSupportId.put(objWorkOrder, objWorkOrder.SVMXC__Group_Member__c);
                    }
                }
                populateAssignmentAcceptanceDueDate(objWorkOrder , objOldWorkOrder);
        }
        //CMCM-507 - End

        if(!mapOnsiteDueDateWOToFieldSupportId.isEmpty()){
            populateOnsiteResponseDueDate(mapOnsiteDueDateWOToFieldSupportId);
        }
    } 

    /*
     *  @author:  Sarath Pullanikkatt
     *  @description: Populate Onsite Response Due Date using SLA minutes and business hours.
     *  @param :  Map of Work Order to Field Support ID.  
     *  @return : void
    */ 
    public static void populateOnsiteResponseDueDate(Map<SVMXC__Service_Order__c, Id> mapWOToFieldSupportId) {

    //CMCM-507 - start
    Map<Id, List<SVMXC__Service_Order__History>> mapWOIdToHistoryList = new Map<Id, List<SVMXC__Service_Order__History>>();
    List<Id> newOwnerIds = new List<Id>();
    Set<Id> setWOIds = new Set<Id>();

    for(SVMXC__Service_Order__c wo : mapWOToFieldSupportId.keySet()) {
        setWOIds.add(wo.Id);
    }
    // CMCM-507 - Get History Records for Owner field and determine the first time Owner was populated as FS user
    //CMCM-5307 - Add empty check for WO trigger Optimization
    if(woHistoryList.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
        woHistoryList = [SELECT OldValue, NewValue, Field, CreatedById, CreatedDate, ParentId
        FROM SVMXC__Service_Order__History
        WHERE Field= :OWNER AND ParentId  IN :setWOIds Order By CreatedDate ASC];
    }
    if(woHistoryList != null && !woHistoryList.isEmpty()){
        for(SVMXC__Service_Order__History historyRecord : woHistoryList) {
            Id parentId = historyRecord.ParentId;
            if(String.valueof(historyRecord.NewValue).left(3) == WorkOrders.STRING_005){
                newOwnerIds.add((Id)historyRecord.NewValue);
                if(!mapWOIdToHistoryList.containsKey(parentId)) {
                    mapWOIdToHistoryList.put(parentId, new List<SVMXC__Service_Order__History>());
                }    
                mapWOIdToHistoryList.get(parentId).add(historyRecord);
            }
        }
    }
    //CMCM-5307 - Add empty check for WO trigger Optimization
    if(mapUserIdToUser.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
        mapUserIdToUser = new Map<Id, User>([SELECT Id, Profile.Name FROM User WHERE Id IN :newOwnerIds]);
    }
    //CMCM-507 - end
        
        //List<SVMXC__Service_Group_Members__c> lstFieldSupports = new TechniciansSelector().selectTechnicians(new Set<Id>(mapWOToFieldSupportId.values()));
        Map<Id, SVMXC__Service_Group_Members__c> mapFieldSupports = new Map<Id, SVMXC__Service_Group_Members__c>(WorkOrders.lstServiceGroupMembers);
        Set<Id> setSLAtermsIds = UtilsCollection.getSetOfIds(new List<SVMXC__Service_Order__c>(mapWOToFieldSupportId.keySet()), 'SVMXC__SLA_Terms__c');
        if(setSLAtermsIds.isEmpty())
            return;
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(idToSLATerms.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            idToSLATerms = new Map<Id,SVMXC__Service_Level__c>(new SLATermsSelector().selectSLATermsFromIds(setSLAtermsIds));
        }

        for(SVMXC__Service_Order__c wo : mapWOToFieldSupportId.keySet()) {
            Boolean foundFieldServiceUser = false;
            if(mapWOIdToHistoryList.containsKey(wo.Id) && mapUserIdToUser != null && mapUserIdToUser.size() > 0){
                for(SVMXC__Service_Order__History historyRecord : mapWOIdToHistoryList.get(wo.Id)){
                    User newOwner = mapUserIdToUser.get((Id)historyRecord.NewValue);
                    if(newOwner != null && newOwner.Profile.Name == System.Label.ProfileFieldService && !foundFieldServiceUser) {
                        mapWOIdToFirstChangeDate.put(wo.Id, historyRecord.CreatedDate);
                        foundFieldServiceUser = true;
                    }
                } 
            }
            //Get the Time Zone of the Field Support User
            Timezone tz = null;
            SVMXC__Service_Level__c objSLAterms = idToSLATerms.get(wo.SVMXC__SLA_Terms__c);
            if(mapFieldSupports!=null && mapFieldSupports.Containskey(wo.SVMXC__Group_Member__c))
                tz = Timezone.getTimeZone(mapFieldSupports.get(wo.SVMXC__Group_Member__c).SVMXC__Salesforce_User__r.TimeZoneSidKey);

            DateTime currentTime;
            Datetime currentDatetime = System.now();
            if(Trigger.IsUpdate && woCreatedByIds.contains(wo.Id)){  
                currentTime = Datetime.newInstance(wo.CreatedDate.year(), wo.CreatedDate.month(), wo.CreatedDate.day(), currentDatetime.hour(), currentDatetime.minute(), currentDatetime.second());
            }
            else if(Trigger.IsUpdate && mapWOIdToFirstChangeDate.containsKey(wo.Id)){ /* If record is updated to meet criteria, and owner was previously set to FS user, get the latest date it was set to FS user*/
                currentTime = Datetime.newInstance(mapWOIdToFirstChangeDate.get(wo.Id).year(), mapWOIdToFirstChangeDate.get(wo.Id).month(), mapWOIdToFirstChangeDate.get(wo.Id).day(), currentDatetime.hour(), currentDatetime.minute(), currentDatetime.second());
            } else if(Trigger.isInsert || (Trigger.IsUpdate && !mapWOIdToFirstChangeDate.containsKey(wo.Id) && woOwnerIds.contains(wo.Id))){
                currentTime = System.now();
            }
            //Get the Time Zone Offset of Field Support User in seconds
            if (currentTime != null) {
                Integer intAssigneesOffsetInSeconds=0;
                if(tz!=null)
                    intAssigneesOffsetInSeconds = tz.getOffset(currentTime) / 1000;
                //Onsite Response SLA in milliseconds
                Long longSLAMilliSeconds = (Integer.valueOf(objSLAterms.Least_SLA__c) * 60 + intAssigneesOffsetInSeconds) * 1000;
                //If local time of Field Support user is past 3 PM
                if(currentTime.addSeconds(intAssigneesOffsetInSeconds).hourGmt() >= WorkOrders.INTEGER_15) {
                    Long longOneDayMilliSeconds = 86400000;
                    longSLAMilliSeconds += longOneDayMilliSeconds; //Add 1 day
                }
                //Adds the SLA milliseconds from current time traversing business hours only. Returns the result Datetime in GMT.
                DateTime dtOnsiteResponseDate = BusinessHours.addGmt(System.Label.Onsite_Response_Business_Hour_Id, currentTime, longSLAMilliSeconds);

                wo.Onsite_Response_Due_Date__c = dtOnsiteResponseDate.dateGMT();
            }
        }

    }


    /*
    *  @author:  Vignesh Sethuramalingam    
    *  @description: Populate Onsite Response Due Date using SLA minutes and business hours.
    *  @param :  Map of Work Order to Field Support ID.  
    *  @return : void
    */ 
    public static void populateAssignmentAcceptanceDueDate(SVMXC__Service_Order__c objWorkOrder  , SVMXC__Service_Order__c objOldWorkOrder) {
        if( objOldWorkOrder != NULL && objWorkOrder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_ASSIGNED 
                && String.valueof(objWorkOrder.OwnerId).left(3) == WorkOrders.STRING_005 
                && (objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c || objWorkOrder.OwnerId != objOldWorkOrder.OwnerId)
            ) {
            if(triggeredFromDC) {
                Map<Id, SVMXC__Service_Group_Members__c> mapFieldSupports = new Map<Id, SVMXC__Service_Group_Members__c>(WorkOrders.lstServiceGroupMembers);
                if( mapFieldSupports.containsKey(objWorkOrder.SVMXC__Group_Member__c) &&
                mapFieldSupports.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Salesforce_User__c != Null &&
                mapFieldSupports.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Salesforce_User__r.TimeZoneSidKey != Null ){
                    TimeZone tz = Timezone.getTimeZone(mapFieldSupports.get(objWorkOrder.SVMXC__Group_Member__c).SVMXC__Salesforce_User__r.TimeZoneSidKey);
                    Business_Hours_Setting__mdt paramBusinessHour = Business_Hours_Setting__mdt.getInstance('Default_Business_Hour_Setting');
                    
                    objWorkOrder.Assignment_Acceptance_Due_Date_Time__c = ServiceUtilityCollection.calculateDueTimeOnWorkingHours( tz , paramBusinessHour , System.now() , 14400 );
                }
            } else {
                objWorkOrder.Assignment_Acceptance_Due_Date_Time__c = null;
            }
           
            
        }
	}

    /*
    *  @author:  Nancy Al Kalach
    *  @description: CMCM-507 - Populate SVMXC__Group_Member__c field as current user whenever SVMXC__Order_Status__c is changed to 'Technician Onsite' by a Field Service User
    *  @param :  WO records
    *  @return : void
    */ 
    public static void updateFSBasedOnStatusChange(Map<Id, SObject> oldRecords, List<sObject> records) {

        Id currentUserId = UserInfo.getUserId();
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(fieldSupportList.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            fieldSupportList = new TechniciansSelector().selectTechniciansMatchingUsers(new Set<Id>{currentUserId});
        }
        if(fieldSupportList.size() > 0){
            Id currentFieldSupportId = fieldSupportList[0].Id;
            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
                SVMXC__Service_Order__c objOldWorkOrder = oldRecords != null ? (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)) : null;
                if ((objWorkOrder.Is_Reopen_Approved__c== False) &&
                    (objWorkOrder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && objWorkOrder.SVMXC__Order_Status__c == 'Technician Onsite' && objOldWorkOrder.SVMXC__Group_Member__c != currentFieldSupportId)) {
                    objWorkOrder.SVMXC__Group_Member__c = currentFieldSupportId;
                    objWorkOrder.OwnerId = currentUserId;
                }
            }
        }
    }
    
    /*
        *  @author:  Nitin Z
        *  @description: CMCM-9579 - Populate Date_Billable_Completion_Changed field as  todays date if the Billing type is Billable_Completion_in_Current_Quarter__c is changed 
        *  @param :  WO records
        *  @return : void
        */ 
        public static void updateBillableCompletionChanged(Map<Id, SObject> oldRecords, List<sObject> records) {

            for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records){
                SVMXC__Service_Order__c objOldWorkOrder = oldRecords != null ? (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id)) : null;  
                    if (objWorkOrder.SVMXC__Billing_Type__c=='Billable' && (objWorkOrder.Billable_Completion_in_Current_Quarter__c!=objOldWorkOrder.Billable_Completion_in_Current_Quarter__c)){
                        objWorkOrder.Date_Billable_Completion_Changed__c=Date.today();
                    } 
            }
    }

}