/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Cases 
  MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Shivani Jain          11-Jan-2023        DCP-52634 : Sync Subscriptions & its fields on Case from Work Order
 * Dhairya Shah          19-Sept-2024        Requirement to convert process builder to code (Work Order : Email Alert for Reopen Request)
 * Dhairya Shah          24-Sept-2024       CMCM-1652
 * Vineeta Verma		 8-Nov-2024			PRB0048383- Add info log statements
*/ 
public with sharing class UpdateCase_WOHelper {

    public static List<GroupMember> lstGroupMember = new List<GroupMember>();//CMCM-5307
    public static final String STRING_IN_PROGRESS = 'In Progress';
    private static final String LOG_TITLE = 'UpdateCase_WOHelper'; //PRB0048383

    /**
    *  @author Ritika Maheshwari
    *  @description - Update the Case with appropriate work order status and/or updating the Next steps fields
                      DCP-47271 - Update related work order field on case record after insert.
    *  @param : caseIdTOWOStatus : final map of case id against its work order status which is to be upated at case level
    *  @param : mapCaseIdToCase : Map of Case Id against Case object for updating the Cases.
    *  @return : void
    **/
    public static void updateCases(List<Sobject> records) {

        Map<Id,String> caseIdTOWOStatus=new Map<Id,String>(); 
        Map<Id,Case> mapCaseIdToCase=new Map<Id,Case>();
        Map<Id,SVMXC__Service_Order__c> mapCaseIdWO = new Map<Id,SVMXC__Service_Order__c>();
        ilib_LogEvent.push(LOG_TITLE + '.updateCases'); //PRB0048383
        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>)records) {
            //if a new work order is created with a case, then update its Work Order Status
            if(objWorkOrder.SVMXC__Case__c != null) {
                ilib_LogEvent.info('objWorkOrder.SVMXC__Case__c before : '+objWorkOrder.SVMXC__Case__c); //PRB0048383
                caseIdTOWOStatus.put(objWorkOrder.SVMXC__Case__c, WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS);            
            }
            mapCaseIdWO.put(objWorkOrder.SVMXC__Case__c, objWorkOrder );
        }
        populateMapCaseIdToCase(mapCaseIdToCase, caseIdTOWOStatus, mapCaseIdWO);

        if(!mapCaseIdToCase.isEmpty()) { //update cases
            Cases.skipCaseTrigger = true; // Added for CMCM-8242
            update mapCaseIdToCase.values(); //update cases
            ilib_LogEvent.info('mapCaseIdToCase.values() after: '+mapCaseIdToCase.values()); //PRB0048383
        }
    }

    /*
     *  //DCP-25229
     *  @AUTHOR Digvijay(code refactored)
     *  @DESCRIPTION - Method to Trigger EMail on installation Work Order Assignment. 
     *  @PARAM :  Old Map of Work Orders.
     *  @RETURN : void
     */
    public static void updateCaseifWOisClosedasDuplicate(Map<Id, SObject> mapOld) {
        Map<id, Case> caseIdToCaseRec = new Map<id, Case>();
       
        for(Case objCase: WorkOrders.lstCaserecords) {
            caseIdToCaseRec.put(objCase.Id, objCase);
        }

        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            //DCP-25229
            //added old status = closed-duplicate condition for INC0249066
            if(objNewWorkorder.SVMXC__Order_Status__c != objOldWorkOrder.SVMXC__Order_Status__c && (objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WO_ORDER_STATUS_CLOSED_DUPP || objOldWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WO_ORDER_STATUS_CLOSED_DUPP) && objNewWorkorder.SVMXC__Case__c != null) {
                Case cs=caseIdToCaseRec.get(objNewWorkorder.SVMXC__Case__c);
                if(!cs.Has_Closed_Duplicate_WO__c) {
                    cs.Has_Closed_Duplicate_WO__c = true;
                } else {
                     //added logic to make it as false for INC0249066
                    cs.Has_Closed_Duplicate_WO__c = false;
                }
                
                WorkOrders.mapCaseIdtoCaseObj.put(cs.id,cs);   
            }

            if(objNewWorkorder.SVMXC__Case__c != NULL  && objOldWorkorder.SVMXC__Order_Status__c !='Reopen Requested' && objOldWorkorder.SVMXC__Order_Status__c != objNewWorkorder.SVMXC__Order_Status__c 
                    && (objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                        || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE)) {
                Case objCase = populateObjCase(objNewWorkorder, objOldWorkorder);
                WorkOrders.mapCaseIdtoCaseObj.put(objCase.id, objCase);             
            }
        }
    }

    /*
    *  @AUTHOR:  Digvijay(Refactored)
    *  @DESCRIPTION: update Case Statuses
    *  @PARAM :  Set<Id> - case ids
    *  return : void
    */ 
    public static void updatedCaseStatusesAfterWOUpdate(Map<Id, SObject> mapOld) {

        //Map case id to status
        Map<Id,String> caseIdTOWOStatus = new Map<Id,String>();
        //INC0282942 
        Map<Id,Case> mapCaseIdToCase= new map<Id,Case>();
        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            createCollectionCompletedClosedWO(objNewWorkorder, objOldWorkorder, mapCaseIdToCase);

            //INC0216365 START
            //If case is not null and the work order status is changed, then udpate the Work Order status on case.
            if(objNewWorkorder.SVMXC__Case__c != null) {
                createCollectionForStatusAndOwner(objNewWorkorder, objOldWorkorder);
                
                String strCurrentStatus = objNewWorkorder.SVMXC__Order_Status__c;
                //set WO status to Closed if it is Closed-Duplicate as part of INC0376449
                if(strCurrentStatus == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE ) {
                    strCurrentStatus = WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED ;
                }
                
                if(!caseIdTOWOStatus.containsKey(objNewWorkorder.SVMXC__Case__c)) {
                    //adding STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE check as part of INC0376449			
                    caseIdTOWOStatus.put(objNewWorkorder.SVMXC__Case__c, 
                                            strCurrentStatus != WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED && strCurrentStatus != WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED  
                                            && strCurrentStatus != WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED 
                                            ? WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS : strCurrentStatus);
                    } else {
                    getWorkOrderStatus(caseIdTOWOStatus, objNewWorkorder);
                }
            }
            //If work order is reparented 
            workOrderReparentedLogic(objNewWorkorder, objOldWorkorder, caseIdTOWOStatus);

            updateSNAndLotNo(objNewWorkorder, objOldWorkorder, mapCaseIdToCase);
        }

        if(!caseIdTOWOStatus.isEmpty()) {
            //Query the existing work orders which are not CANCELLED, and update the Work Order Status accordingly
            for(SVMXC__Service_Order__c existingWorkOrder : WorkOrders.lstWorkOrders) {
                if(existingWorkOrder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED && caseIdTOWOStatus.containsKey(existingWorkOrder.SVMXC__Case__c) )
                getWorkOrderStatus(caseIdTOWOStatus, existingWorkOrder);
            }  
        } 

        if(!caseIdTOWOStatus.isEmpty() || !mapCaseIdToCase.isEmpty()) {                 
            updateCases(caseIdTOWOStatus,mapCaseIdToCase); 
        }
    }

     /**
    *  @author Ritika Maheshwari
    *  @description - Get the appropriate work order status, by comparing with other work orders for the same case
    *  @parameters : caseIdTOWOStatus - case id to the current work order status at case level
    *         objWorkOrder : work order which has been updated, its status is checked against the status at case
    *  @return : void
    **/
    private static void getWorkOrderStatus(Map<Id,String> caseIdTOWOStatus, SVMXC__Service_Order__c objWorkOrder) {
        String strStatusFromMap = caseIdTOWOStatus.get(objWorkOrder.SVMXC__Case__c);
        String strWorkOrderStatus = objWorkOrder.SVMXC__Order_Status__c;
        if(strWorkOrderStatus != WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED && strWorkOrderStatus != WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED && strWorkOrderStatus != WorkOrders.STRING_WORK_ORDER_STATUS_CANCELLED && strWorkOrderStatus != WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE) {
            caseIdTOWOStatus.put(objWorkOrder.SVMXC__Case__c, WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS);
        } else if(strWorkOrderStatus == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED && strStatusFromMap != WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS) {
            caseIdTOWOStatus.put(objWorkOrder.SVMXC__Case__c, WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED);
        } else if(strWorkOrderStatus == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED && strStatusFromMap != WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS && strStatusFromMap != WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED) {
            caseIdTOWOStatus.put(objWorkOrder.SVMXC__Case__c, WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED);
        }
        
    }

   /**
    *  @author Ritika Maheshwari
    *  @description - Update the Case with appropriate work order status and/or updating the Next steps fields
    *  @param : caseIdTOWOStatus : final map of case id against its work order status which is to be upated at case level
    *  @param : mapCaseIdToCase : Map of Case Id against Case object for updating the Cases.
    *  @return : void
    **/
    private static void updateCases(Map<Id,String> caseIdTOWOStatus, map<Id,Case> mapCaseIdToCase) {

        for(Case objCase : WorkOrders.lstCaserecords) {
            if(caseIdTOWOStatus.ContainsKey(objCase.Id)) {
                if(mapCaseIdToCase.containsKey(objCase.Id)) {
                    objCase = mapCaseIdToCase.get(objCase.Id);
                }
                if(objCase.Work_Order_Status__c != caseIdTOWOStatus.get(objCase.Id) && !objCase.IsClosed) {
                    if(WorkOrders.mapCaseIdtoCaseObj.containsKey(objCase.Id)) {
                         objCase = WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id);
                    }

                    objCase.Work_Order_Status__c = caseIdTOWOStatus.get(objCase.Id);

                    
                    if(objCase.Work_Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_NOTAPPLICABLE)
                        objCase.Work_Order__c = null;//INC0416687 


                    WorkOrders.mapCaseIdtoCaseObj.put(objCase.Id,objCase);
                }
            }
			 
			 //DCP-45000 : 
            if(!WorkOrders.mapCaseIdToCaseStatus.isEmpty()) {
               
                if(!WorkOrders.mapCaseIdtoCaseObj.isEmpty() && WorkOrders.mapCaseIdtoCaseObj.containsKey(objCase.Id)) {
                    objCase = WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id);
                }

                if(WorkOrders.mapCaseIdToCaseStatus.containsKey(objCase.Id)) {
                    objCase.Status=WorkOrders.mapCaseIdToCaseStatus.get(ObjCase.Id);
                    //DCP-47530
                    //adding this boolean to bypass the validation on editing case status field for TPSP user.
                    Cases.bypassStatusEditValidationForTPSP = true;
                    if(!WorkOrders.mapCaseIdToWOOwner.isEmpty() && WorkOrders.mapCaseIdToWOOwner.containsKey(objCase.Id)) {
                        objCase.OwnerId = WorkOrders.mapCaseIdToWOOwner.get(objCase.Id);
                        
                    }
					WorkOrders.mapCaseIdtoCaseObj.put(objCase.Id,objCase);
                    
                }
        
            }
            //DCP-45000 : END
			
        }
    }

    /*
    *  @AUTHOR:  Rishi Sharma
    *  @DESCRIPTION: DCP-47271 - Update related work order field on case record after update.
    *  @PARAM :  Map<Id, SObject> --  mapOld map of old Work Order records.
    *  return : void
    */ 
    public static void updateWOonCaseAfterUpdate(Map<Id, SObject> mapOld) {
        Map<Id,SVMXC__Service_Order__c> mapCaseIdWO = new Map<Id,SVMXC__Service_Order__c>();
        Map<Id,SVMXC__Service_Order__c> mapCaseIdWOSubscriptionChange = new Map<Id,SVMXC__Service_Order__c>();  //DCP-52634

        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);
            
            mapCaseIdWO.put(objNewWorkorder.SVMXC__Case__c, objNewWorkorder );
            //START - DCP-52634
            if(objNewWorkorder.Subscription__c != objOldWorkorder.Subscription__c) {
                mapCaseIdWOSubscriptionChange.put(objNewWorkorder.SVMXC__Case__c, objNewWorkorder );
            }
            //END - DCP-52634
        }
        for(Case objCase : WorkOrders.lstCaserecords) {
            if(mapCaseIdWO.containsKey(objCase.id)  && !objCase.IsClosed) {
                if(!WorkOrders.mapCaseIdtoCaseObj.containsKey(objCase.Id)) {
                    WorkOrders.mapCaseIdtoCaseObj.put(objCase.Id,objCase);
                }
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).Work_Order__c = mapCaseIdWO.get(objCase.Id).id;
                
            }

            //START - DCP-52634
            if(mapCaseIdWOSubscriptionChange.containsKey(objCase.id)  && !objCase.IsClosed) {
                if(!WorkOrders.mapCaseIdtoCaseObj.containsKey(objCase.Id)) {
                    WorkOrders.mapCaseIdtoCaseObj.put(objCase.Id,objCase);
                }
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).Subscription__c = mapCaseIdWOSubscriptionChange.get(objCase.Id).Subscription__c;
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).SubscriptionID__c = mapCaseIdWOSubscriptionChange.get(objCase.Id).Subscription__c!=null ? WorkOrders.mapOfSubscription.get(mapCaseIdWOSubscriptionChange.get(objCase.Id).Subscription__c).Zuora_Subscription_ID__c : '';
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).Subscription_License_Status__c = mapCaseIdWOSubscriptionChange.get(objCase.Id).Subscription_License_Status__c;
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).Registrant_Email_Address__c = mapCaseIdWOSubscriptionChange.get(objCase.Id).Registrant_Email_Address__c;
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).Domain_Name__c = mapCaseIdWOSubscriptionChange.get(objCase.Id).Domain_Name__c;
                WorkOrders.mapCaseIdtoCaseObj.get(objCase.Id).Workgroup_Name__c = mapCaseIdWOSubscriptionChange.get(objCase.Id).Workgroup_Name__c;
            }
            //END - DCP-52634
        }
    }

     /*
    *  @AUTHOR:  Vignesh Sethuramalingam
    *  @DESCRIPTION: Sync WorkOrder Owner with case owner on dispatching via Dispatch Console or via 
    *  @PARAM : Old Map of Workorders , NewList of WorkOrders 
    *  return : void
    */ 
    public static void updateCaseOwnerForDispatchedWO( List<SObject> newList ) {
        list<SVMXC__Service_Order__c> lstWorkOrdersToSendNotification = new list<SVMXC__Service_Order__c>();
        Map<Id,SVMXC__Service_Order__c> mapWO = new Map<Id,SVMXC__Service_Order__c>( (List<SVMXC__Service_Order__c>) newList);
		Map<Id, Id> mapWOIDOwnerId = new Map<Id, Id>();

		for(Id objWOID: WorkOrders.setWOForCaseOwnerSync){
            SVMXC__Service_Order__c objWorkorder = (SVMXC__Service_Order__c)mapWO.get(objWOID);
			if(objWorkOrder.SVMXC__Case__c != null && !WorkOrders.mapCaseIdtoCaseObj.containsKey(objWorkOrder.SVMXC__Case__c)) {//INC0424021 
				WorkOrders.mapCaseIdtoCaseObj.put(objWorkOrder.SVMXC__Case__c,new case (Id = objWorkOrder.SVMXC__Case__c));
			}

            if(objWorkOrder.SVMXC__Case__c != null)//INC0424021 
			    WorkOrders.mapCaseIdtoCaseObj.get(objWorkOrder.SVMXC__Case__c).OwnerId = objWorkOrder.OwnerId;
            
            lstWorkOrdersToSendNotification.add(objWorkorder);
            if(((string)objWorkorder.OwnerId).startsWith('00G') ){
                mapWOIDOwnerId.put(objWorkorder.Id , objWorkorder.OwnerId);
            }
        }

        if(!mapWOIDOwnerId.isEmpty()){
            Map<Id,Set<string>> mapQueuememberId = new Map<Id,Set<string>>();
            Map<Id,Set<String>> sobjectToAdditionalEmailsList = new Map<Id,Set<String>> ();
            //CMCM-5307 - Add empty check for WO trigger Optimization
            if(lstGroupMember.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                lstGroupMember = [select id,userorgroupid,GroupId from GroupMember where GroupId IN :mapWOIDOwnerId.values()];
            }
            for( GroupMember objGM : lstGroupMember){
                if( !mapQueuememberId.containsKey(objGM.GroupId) ){
                    mapQueuememberId.put(objGM.GroupId, new set<String>());
                }
                mapQueuememberId.get(objGM.GroupId).add(objGM.userorgroupid);
            }
            
            for(Id woId : mapWOIDOwnerId.keyset()){
                if(mapQueuememberId.containsKey(mapWOIDOwnerId.get(woId))  ){
                    sobjectToAdditionalEmailsList.put(woId , mapQueuememberId.get(mapWOIDOwnerId.get(woId)) );
                }
            }
            SendEmailNotification.getSendEmailParamaters( 'Notification_on_Work_Order_Reassignment' , lstWorkOrdersToSendNotification , null , null , sobjectToAdditionalEmailsList );
        
        }
        
        WorkOrders.setWOForCaseOwnerSync.clear();
    }

    /*******************************************************************************************************
     * @description populate mapCaseIdToCase
     * @param mapCaseIdToCase Map<Id,Case>
     * @param caseIdTOWOStatus Map<Id,String>
     * @param mapCaseIdWO Map<Id,SVMXC__Service_Order__c> 
     * @return void
     */
    private static void populateMapCaseIdToCase(Map<Id,Case> mapCaseIdToCase, Map<Id,String> caseIdTOWOStatus,  Map<Id,SVMXC__Service_Order__c> mapCaseIdWO) {
        for(Case objCase : WorkOrders.lstCaserecords) {
            if(objCase.Status != WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED) {
                if(mapCaseIdToCase.containsKey(objCase.Id)) {
                    objCase = mapCaseIdToCase.get(objCase.Id);
                }
                if(objCase.Work_Order_Status__c != caseIdTOWOStatus.get(objCase.Id) && !objCase.IsClosed) {
                    objCase.Work_Order_Status__c = caseIdTOWOStatus.get(objCase.Id);
                    mapCaseIdToCase.put(objCase.Id,objCase);
                }
                //DCP-47271 - Update related work order field on case record after insert.
                if(objCase.recordType.Name != Label.CaseRecordTypeElevation && !objCase.IsClosed && mapCaseIdWO.get(objCase.Id) != null) {
                    if(!mapCaseIdToCase.containsKey(objCase.Id)) {
                        mapCaseIdToCase.put(objCase.Id,objCase);
                    }
                    mapCaseIdToCase.get(objCase.Id).Work_Order__c = mapCaseIdWO.get(objCase.Id).id;
                }
                //DCP-47271
        }

            //DCP-46053 - updating related case record Product Serial Number and Product Lot Number
            if(mapCaseIdWO.containskey(objCase.Id) && (mapCaseIdWO.get(objCase.Id).Product_Serial_Number__c != objCase.Product_Serial_Number__c 
            || mapCaseIdWO.get(objCase.Id).Product_Lot_Number__c != objCase.Product_Lot_Number__c )) {
                if(!mapCaseIdToCase.containsKey(objCase.Id)) {
                    mapCaseIdToCase.put(objCase.Id,objCase);
                }
                mapCaseIdToCase.get(objCase.Id).Product_Lot_Number__c = mapCaseIdWO.get(objCase.Id).Product_Lot_Number__c;
                mapCaseIdToCase.get(objCase.Id).Product_Serial_Number__c = mapCaseIdWO.get(objCase.Id).Product_Serial_Number__c;
            }
        //DCP-46053

            //START - DCP-52634
            if(mapCaseIdWO.containskey(objCase.Id) && mapCaseIdWO.get(objCase.Id).Subscription__c != NULL) {
                if(!mapCaseIdToCase.containsKey(objCase.Id)) {
                    mapCaseIdToCase.put(objCase.Id, objCase);
                }
                mapCaseIdToCase.get(objCase.Id).Subscription__c = mapCaseIdWO.get(objCase.Id).Subscription__c;
                mapCaseIdToCase.get(objCase.Id).Subscription_License_Status__c = mapCaseIdWO.get(objCase.Id).Subscription_License_Status__c;
                mapCaseIdToCase.get(objCase.Id).Registrant_Email_Address__c = mapCaseIdWO.get(objCase.Id).Registrant_Email_Address__c;
                mapCaseIdToCase.get(objCase.Id).Domain_Name__c = mapCaseIdWO.get(objCase.Id).Domain_Name__c;
                mapCaseIdToCase.get(objCase.Id).Workgroup_Name__c = mapCaseIdWO.get(objCase.Id).Workgroup_Name__c;
            }
            //END - DCP-52634
        }
    }

    /*******************************************************************************************************
     * @description populate objCase
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param objOldWorkorder SVMXC__Service_Order__c
     * @return Case
     */
    private static Case populateObjCase(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder) {
        Case objCase;
        if(WorkOrders.mapCaseIdtoCaseObj.containsKey(objNewWorkorder.SVMXC__Case__c)) {
            objCase = WorkOrders.mapCaseIdtoCaseObj.get(objNewWorkorder.SVMXC__Case__c);
        } else {
            objCase = new Case();
            objCase.Id = objNewWorkorder.SVMXC__Case__c;
        }
        
        objCase.Attempt_Case_Completion__c = objNewWorkorder.Attempt_case_completion__c;
        if(String.isNOTBlank(objNewWorkorder.Case_Description__c) && objOldWorkorder.Case_Description__c != objNewWorkorder.Case_Description__c) {
            objCase.Description = objNewWorkorder.Case_Description__c;
        }
        if(objOldWorkorder.Case_Follow_up_Needed__c != objNewWorkorder.Case_Follow_up_Needed__c) {
            objCase.Follow_up_Needed__c = objNewWorkorder.Case_Follow_up_Needed__c;
        }
        if(objOldWorkorder.Case_Next_Steps__c != objNewWorkorder.Case_Next_Steps__c) {
            objCase.Next_Steps__c = objNewWorkorder.Case_Next_Steps__c;
        }
        if(String.isNOTBlank(objNewWorkorder.Case_Subject__c) && objOldWorkorder.Case_Subject__c != objNewWorkorder.Case_Subject__c) {
            objCase.Subject = objNewWorkorder.Case_Subject__c;
        }
        
        //DCP-38815 - Data sync from WO To Case
        if(String.isNOTBlank(objNewWorkorder.Abandoned_Reason__c)) {
            objCase.Abandoned_Reason__c = objNewWorkorder.Abandoned_Reason__c;
            objCase.Other_Abandoned_Reason__c = objNewWorkorder.Other_Abandoned_Reason__c;
        }


        return objCase;
    }

    /*******************************************************************************************************
     * @description update Product Serial Number and Lot Number
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param objOldWorkorder SVMXC__Service_Order__c
     * @param mapCaseIdToCase Map<Id, Case>
     * @return void
     */
    private static void updateSNAndLotNo(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, Map<Id,Case> mapCaseIdToCase) {
        Map<Id,Case> mapRelatedCase = new Map<Id,Case>(WorkOrders.lstCaserecords);

        //DCP-46053 - updating related case record Product Serial Number and Product Lot Number
        if((objNewWorkorder.Product_Serial_Number__c != objOldWorkorder.Product_Serial_Number__c || objNewWorkorder.Product_Lot_Number__c != objOldWorkorder.Product_Lot_Number__c) 
                && String.isNotBlank(objNewWorkorder.SVMXC__Case__c) && mapRelatedCase.containsKey(objNewWorkorder.SVMXC__Case__c) 
                && (mapRelatedCase.get(objNewWorkorder.SVMXC__Case__c).Product_Lot_Number__c != objNewWorkorder.Product_Lot_Number__c 
                    || mapRelatedCase.get(objNewWorkorder.SVMXC__Case__c).Product_Serial_Number__c != objNewWorkorder.Product_Serial_Number__c)) {
            Case objCase;
            if(WorkOrders.mapCaseIdtoCaseObj.containsKey(objNewWorkorder.SVMXC__Case__c)) {
                objCase = WorkOrders.mapCaseIdtoCaseObj.get(objNewWorkorder.SVMXC__Case__c);
            } else {
                objCase = new Case();
                objCase.Id = objNewWorkorder.SVMXC__Case__c;
            }
            objCase.Product_Serial_Number__c = objNewWorkorder.Product_Serial_Number__c ;
            objCase.Product_Lot_Number__c = objNewWorkorder.Product_Lot_Number__c ;
            mapCaseIdToCase.put(objNewWorkorder.SVMXC__Case__c,objCase);  
        }
        //DCP-46053 ends
    }

    /*******************************************************************************************************
     * @description populate mapCaseIdToCase
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param objOldWorkorder SVMXC__Service_Order__c
     * @param mapCaseIdToCase Map<Id,Case>
     * @return void
     */
    private static void createCollectionCompletedClosedWO(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, Map<Id,Case> mapCaseIdToCase) {
        if(objNewWorkorder.SVMXC__Case__c != NULL  && objOldWorkorder.SVMXC__Order_Status__c !='Reopen Requested' 
                && objOldWorkorder.SVMXC__Order_Status__c != objNewWorkorder.SVMXC__Order_Status__c 
                && ( objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
                    || objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_CLOSED_DUPLICATE)) {
            Case objCase;
            if(WorkOrders.mapCaseIdtoCaseObj.containsKey(objNewWorkorder.SVMXC__Case__c)) {
                objCase = WorkOrders.mapCaseIdtoCaseObj.get(objNewWorkorder.SVMXC__Case__c);
            } else {
                objCase = new Case();
                objCase.Id = objNewWorkorder.SVMXC__Case__c;
            }
            mapCaseIdToCase.put(objNewWorkorder.SVMXC__Case__c, objCase);  
        }
    }

    /*******************************************************************************************************
     * @description populate WorkOrders.mapCaseIdToCaseStatus and WorkOrders.mapCaseIdToWOOwner
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param objOldWorkorder SVMXC__Service_Order__c
     * @return void
     */
    private static void createCollectionForStatusAndOwner(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder) {
        //DCP-45000 START        
        Map<Id,Case> mapExistingCase = new Map<Id,Case>(WorkOrders.lstCaserecords);

        if(mapExistingCase.containsKey(objNewWorkorder.SVMXC__Case__c) && objNewWorkorder.SVMXC__Order_Status__c != objOldWorkorder.SVMXC__Order_Status__c 
                && objNewWorkorder.SVMXC__Order_Status__c != WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED  
                && String.valueOf(objNewWorkorder.OwnerId).startsWith(WorkOrders.STRING_005) 
                && mapExistingCase.get(objNewWorkorder.SVMXC__Case__c).Status == WorkOrders.STRING_WORK_ORDER_STATUS_INITIATED) {
            WorkOrders.mapCaseIdToCaseStatus.put(objNewWorkorder.SVMXC__Case__c, WorkOrders.STRING_WORK_ORDER_STATUS_INPROGRESS);
            if(String.valueOf(mapExistingCase.get(objNewWorkorder.SVMXC__Case__c).OwnerId).startsWith('00G')) {
                WorkOrders.mapCaseIdToWOOwner.put(objNewWorkorder.SVMXC__Case__c,objNewWorkorder.OwnerId);
            }
        }
        //DCP-45000 END
    }

    /*******************************************************************************************************
     * @description If work order is reparented
     * @param objNewWorkorder SVMXC__Service_Order__c
     * @param objOldWorkorder SVMXC__Service_Order__c
     * @param caseIdTOWOStatus Map<Id,String>
     * @return void
     */
    private static void workOrderReparentedLogic(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, Map<Id,String> caseIdTOWOStatus) {
        if(objNewWorkorder.SVMXC__Case__c != objOldWorkOrder.SVMXC__Case__c && objOldWorkOrder.SVMXC__Case__c != null) {
            caseIdTOWOStatus.put(objOldWorkOrder.SVMXC__Case__c, WorkOrders.STRING_WORK_ORDER_STATUS_NOTAPPLICABLE);
        }
    }

    /*
    *  @AUTHOR: Dhairya Shah
    *  @DESCRIPTION: Requirement to convert process builder to code (Work Order : Email Alert for Reopen Request)
    *  @RETURN:  void
    */ 
    public static void updateCaseToAcceptOrReject(List<SVMXC__Service_Order__c> records,Map<Id, SObject> oldRecords) {
        List<Case> listCase = new List<Case>();
        List<SVMXC__Service_Order__c> listWO = new List<SVMXC__Service_Order__c>();

        for(SVMXC__Service_Order__c objWorkOrder : (List<SVMXC__Service_Order__c>) records){ 
            SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(oldRecords.get(objWorkOrder.Id));
            if(objWorkOrder.SVMXC__Case__c == null) {
                continue;
            }

            listCase = updateCaseMethod(objWorkOrder, objOldWorkOrder);
            listWO = updateWOMethod(objWorkOrder, objOldWorkOrder);
        }

        Id profileId = userinfo.getProfileId();
        Set<id> setOfProfileId = new Set<Id>();
        setOfProfileId.add(profileId);
        if(listCase != null && !listCase.isEmpty() && !String.isBlank(WorkOrders.loggedInUserProfileName) && WorkOrders.loggedInUserProfileName != label.ProfileName_CustomerService){
            Cases.skipCaseTrigger = true;
            UPDATE listCase; //BYPASSING UPDATE FOR CS USER DUE TO INSUFFICIENT_ACCESS_ON_CROSS_REFERENCE_ENTITY
        }

        if(listWO != null && !listWO.isEmpty()){
            WorkOrders.skipWOTrigger = true;
            UPDATE listWO;
        }
    }

    /*Method called in updateCaseToAcceptOrReject to avoid NPATH Complexity*/
    /*Method called in updateCaseToAcceptOrReject to avoid NPATH Complexity*/
    public static List<Case> updateCaseMethod(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder){
        List<Case> listCase = new List<Case>();
        Case objUpdateCase = new Case(id=objWorkOrder.SVMXC__Case__c);
        if(objWorkOrder.SVMXC__Case__c != null && objOldWorkOrder.SVMXC__Order_Status__c == System.Label.ReopenRequested && objWorkOrder.SVMXC__Order_Status__c == objWorkOrder.Order_Previous_Status__c && objWorkOrder.SVMXC__Case__r.status == System.Label.ReopenRequested){
            objUpdateCase.Reason_for_Approval_Denial_of_Reopen__c = objWorkOrder.Reason_for_Approval_Denial_of_Reopen__c;
            objUpdateCase.Status = objWorkOrder.SVMXC__Case__r.Previous_Status__c;         
            listCase.add(objUpdateCase);
        } else if(objWorkOrder.SVMXC__Case__c != null && objOldWorkOrder.SVMXC__Order_Status__c == System.Label.ReopenRequested && (objWorkOrder.SVMXC__Order_Status__c == System.Label.WorkOrderStatusInProgress || objWorkOrder.SVMXC__Order_Status__c == System.Label.WorkOrderStatusAssigned)&& objWorkOrder.SVMXC__Case__r.status == System.Label.ReopenRequested && objWorkOrder.SVMXC__Case__r.status != STRING_IN_PROGRESS){
            objUpdateCase.Reason_for_Approval_Denial_of_Reopen__c = objWorkOrder.Reason_for_Approval_Denial_of_Reopen__c;
            objUpdateCase.Status = STRING_IN_PROGRESS;
            listCase.add(objUpdateCase);
        }
        return listCase;
    }

    /*Method called in updateCaseToAcceptOrReject to avoid NPATH Complexity*/
    public static List<SVMXC__Service_Order__c> updateWOMethod(SVMXC__Service_Order__c objWorkOrder, SVMXC__Service_Order__c objOldWorkOrder){
        List<SVMXC__Service_Order__c> listWO = new List<SVMXC__Service_Order__c>();
        SVMXC__Service_Order__c objUpdateWO = new SVMXC__Service_Order__c(id=objWorkOrder.Id);
        if(objWorkOrder.Reopen_Request_Initiated_From_WO__c == true 
        && (objWorkOrder.SVMXC__Order_Status__c!=Label.WorkOrderStatusCompleted 
        && objWorkOrder.SVMXC__Order_Status__c!=Label.WorkOrderStatusClosed
        && objWorkOrder.SVMXC__Order_Status__c!=Label.WorkOrderStatusClosedDuplicate)){
            objUpdateWO.Order_Previous_Status__c = objOldWorkOrder.SVMXC__Order_Status__c;
            objUpdateWO.Reopen_Request_Initiated_From_WO__c = false;
            listWO.add(objUpdateWO); // fixing unnecessary dml
        }
        return listWO;
    }
}