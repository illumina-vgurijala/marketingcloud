/**
* @author Shivani Jain
* @date 7th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Work details 
*/ 
public with sharing class WorkDetail_WOHelper {
    //CMCM-5307 - Start
    public static List<SVMXC__Service_Order_Line__c> lstLaborLines = new List<SVMXC__Service_Order_Line__c>();
    public static List<Applied_Contract__c> appliContList = new List<Applied_Contract__c>(); 
    //CMCM-5307 - End
    /**
    *  @author Shashank Singhal
    *  @description - create Related product for WO when Additional product is there on Case
                      DCP-49487 - PM Work Orders to not create Customer Care Reviews
    *  @parameters : List<SVMXC__Service_Order__c> lstInstallWO
    *  @return : void
    **/
    public static void createRelatedProductForInstallWOnQSRCreation(Map<Id, SObject> mapOld) {
        ilib_LogEvent.push(WorkOrders.LOG_TITLE + '.createRelatedProductForInstallWOnQSRCreation()');
        //DCP-10944
        List<SVMXC__Service_Order__c> lstInstallWO = new List<SVMXC__Service_Order__c>();
        //Added by Shruti Karn for populating product group on Work Order for ICE integration
        set<Id> setWOIdforICEPrdGrp = new set<Id>();
        List<SVMXC__Service_Order_Line__c> lstQSReviewWDToInsert = new List<SVMXC__Service_Order_Line__c>();
        Set<Id> setWorkOrderIdsForHealthCheck = new Set<Id>();
        String profileName = !String.isBlank(WorkOrders.loggedInUserProfileName) ? WorkOrders.loggedInUserProfileName : '';

        populateSetWorkOrderIdsForHealthCheck(mapOld, setWorkOrderIdsForHealthCheck);
        ilib_LogEvent.message('@@45746 setWorkOrderIdsForHealthCheck: ' + setWorkOrderIdsForHealthCheck); 

        for(Id idWorkOrder : mapOld.keySet()) {
            SVMXC__Service_Order__c objNewWorkorder = (SVMXC__Service_Order__c)Trigger.newMap.get(idWorkOrder);
            SVMXC__Service_Order__c objOldWorkorder = (SVMXC__Service_Order__c)mapOld.get(idWorkOrder);

            populatelstInstallWO(objNewWorkorder, objOldWorkorder, lstInstallWO);

            populateSetWOIdforICEPrdGrp(objNewWorkorder, objOldWorkorder, setWOIdforICEPrdGrp);

            populateLstQSReviewWDToInsert(objNewWorkorder, objOldWorkorder, lstQSReviewWDToInsert, setWorkOrderIdsForHealthCheck, profileName);
        }
        //Added by Shruti Karn for populating product group on Work Order for ICE integration
        if(!setWOIdforICEPrdGrp.isEmpty()) {
            UpdateProductGroup_WorkdetailHelper.updateProductGrponWorkOrder(setWOIdforICEPrdGrp);
        }

        //DCP-25289
        if(!lstQSReviewWDToInsert.isEmpty()) {
            WorkOrders.lstworkDetailsToInsert.addAll(lstQSReviewWDToInsert);
        }
        ilib_LogEvent.pop();
    }
    /*******************************************************************************************************
    * @description populate setWorkOrderIdsForHealthCheck
    * @param mapOld (Map<Id, SObject>
    * @return void
    */
    private static void populateSetWorkOrderIdsForHealthCheck(Map<Id, SObject> mapOld, Set<Id> setWorkOrderIdsForHealthCheck) {
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(lstLaborLines.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstLaborLines = new WorkDetailsSelector().selectLaborWorkDetailRecords(mapOld.keySet());
        }
        Id debriefRecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(Label.Work_Detail_Record_Type_Usage_Consumption).getRecordTypeId();
        
        for(SVMXC__Service_Order_Line__c objWorkDetail : lstLaborLines) {
            if(objWorkDetail.RecordTypeId == debriefRecordTypeId && objWorkDetail.SVMXC__Activity_Type__c == WorkOrders.STRING_HEALTH_CHECK_ACTIVITY_TYPE) {
                setWorkOrderIdsForHealthCheck.add(objWorkDetail.SVMXC__Service_Order__c);
            }
        }
    }

    /*******************************************************************************************************
    * @description populate lstInstallWO
    * @param objNewWorkorder SVMXC__Service_Order__c
    * @param objOldWorkorder SVMXC__Service_Order__c
    * @param lstInstallWO List<SVMXC__Service_Order__c>
    * @return void
    */
    private static void populatelstInstallWO(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, List<SVMXC__Service_Order__c> lstInstallWO) {
        //DCP-10944 Create set of Cases associated with Install WO
        if(objNewWorkorder.SVMXC__Case__c != objOldWorkorder.SVMXC__Case__c && objNewWorkorder.SVMXC__Case__c != null) {
            lstInstallWO.add(objNewWorkorder);
        }
    }

    /*******************************************************************************************************
    * @description populate setWOIdforICEPrdGrp
    * @param objNewWorkorder SVMXC__Service_Order__c
    * @param objOldWorkorder SVMXC__Service_Order__c
    * @param setWOIdforICEPrdGrp Set<Id>
    * @return void
    */
    private static void populateSetWOIdforICEPrdGrp(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, Set<Id> setWOIdforICEPrdGrp) {
        //Added by Shruti Karn for populating product group on Work Order for ICE integration
        if(objNewWorkorder.SVMXC__Component__c != objOldWorkorder.SVMXC__Component__c ) {
            setWOIdforICEPrdGrp.add(objNewWorkorder.Id);
        }
    }

    /*******************************************************************************************************
    * @description populate lstQSReviewWDToInsert
    * @param objNewWorkorder SVMXC__Service_Order__c
    * @param objOldWorkorder SVMXC__Service_Order__c
    * @param lstQSReviewWDToInsert List<SVMXC__Service_Order_Line__c>
    * @param setWorkOrderIdsForHealthCheck Set<Id>
    * @return void
    */
    private static void populateLstQSReviewWDToInsert(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, 
                            List<SVMXC__Service_Order_Line__c> lstQSReviewWDToInsert, Set<Id> setWorkOrderIdsForHealthCheck, String profileName) {
        Boolean boolCSReviewEligible = false; //DCP-45746
        //start of DCP-25289
        //DCP-25289 and DCP-37757 
        if(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED 
            && objOldWorkorder.SVMXC__Order_Status__c != objNewWorkorder.SVMXC__Order_Status__c && objNewWorkorder.Total_Open_IQ_OQ_or_OQ_or_PQ_activity__c > 0) {
            lstQSReviewWDToInsert.add(new SVMXC__Service_Order_Line__c(SVMXC__Line_Type__c = WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR, Is_Auto_Created__c = true, 
                        SVMXC__Activity_Type__c= 'Qualification Service Review', SVMXC__Line_Status__c ='Open', Include_in_Service_Report__c = false,
                        RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkOrders.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId(), 
                        SVMXC__Service_Order__c =objNewWorkorder.id, Work_Order_Type__c = objNewWorkorder.SVMXC__Order_Type__c));
        }
        //end of DCP-25289
        
        //START - PB - Work Order : Create Work Details & Auto Closure refactored
        
        //DCP-45746
        ilib_LogEvent.message('@@@@ objNewWorkorder.SVMXC__Order_Status__c: '+objNewWorkorder.SVMXC__Order_Status__c);
        ilib_LogEvent.message('@@@@ objNewWorkorder.SVMXC__Billing_Type__c: '+objNewWorkorder.SVMXC__Billing_Type__c);
        ilib_LogEvent.message('@@@@ Total_CS_Review_Activity_Open__c: ' + objNewWorkorder.Total_CS_Review_Activity_Open__c); 
        ilib_LogEvent.message('@@@@ setWorkOrderIdsForHealthCheck: ' + setWorkOrderIdsForHealthCheck.contains(objNewWorkorder.Id));   

        boolCSReviewEligible = checkCSReviewEligible(objNewWorkorder, objOldWorkorder, setWorkOrderIdsForHealthCheck);

        ilib_LogEvent.message('@@45746 final boolCSReviewEligible: ' + boolCSReviewEligible);
        if(boolCSReviewEligible) {
            lstQSReviewWDToInsert.add(new SVMXC__Service_Order_Line__c(SVMXC__Line_Type__c = WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR, SVMXC__Activity_Type__c=WorkOrders.STRING_WD_ACTIVITY_CUSTOMER_SERVICE_REVIEW, SVMXC__Line_Status__c =WorkOrders.STRING_WORK_ORDER_STATUS_OPEN,SVMXC__Is_Billable__c = false, RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkOrders.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId(), SVMXC__Service_Order__c =objNewWorkorder.id));
        }
        ilib_LogEvent.message('@@45746 final lstQSReviewWDToInsert: ' + lstQSReviewWDToInsert);
        //End of DCP-45746

        if(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED
                && objOldWorkorder.SVMXC__Order_Status__c != objNewWorkorder.SVMXC__Order_Status__c) {
            if(objNewWorkorder.Product_Regulatory_Type__c != null 
                    && (string.valueOf(objNewWorkorder.Product_Regulatory_Type__c).contains(Label.IPRegulatoryTypeDX) || string.valueOf(objNewWorkorder.Product_Regulatory_Type__c).contains(Label.IPRegulatoryTypeEUA)) 
                    && (objNewWorkorder.CaseSubTypeComplaint__c !=Label.CaseSubTypeComplaint || objNewWorkorder.SVMXC__Case__c == null)) {
                lstQSReviewWDToInsert.add(new SVMXC__Service_Order_Line__c(SVMXC__Line_Type__c = WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR, SVMXC__Activity_Type__c=WorkOrders.STRING_WD_ACTIVITY_FIELD_COMPLIANCE_REVIEW, SVMXC__Line_Status__c =WorkOrders.STRING_WORK_ORDER_STATUS_OPEN,SVMXC__Is_Billable__c = false, RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkOrders.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId(), SVMXC__Service_Order__c =objNewWorkorder.id));
            }
            if(profileName == Label.Field_Service_Third_Party) {
                lstQSReviewWDToInsert.add(new SVMXC__Service_Order_Line__c(SVMXC__Line_Type__c = WorkOrders.STRING_WORK_DETAIL_LINE_TYPE_IS_LABOR, SVMXC__Activity_Type__c=Label.WorkDetailActivityIlluminaReview, SVMXC__Line_Status__c =WorkOrders.STRING_WORK_ORDER_STATUS_OPEN,SVMXC__Is_Billable__c = false, RecordTypeId = Schema.SObjectType.SVMXC__Service_Order_Line__c.getRecordTypeInfosByName().get(WorkOrders.STRING_WORK_DETAIL_RECORD_TYPE_USAGE_CONSUMPTION).getRecordTypeId(), SVMXC__Service_Order__c =objNewWorkorder.id));
            }
        }
    }

    /*******************************************************************************************************
    * @description populate boolCSReviewEligible
    * @param objNewWorkorder SVMXC__Service_Order__c
    * @param objOldWorkorder SVMXC__Service_Order__c
    * @param setWorkOrderIdsForHealthCheck Set<Id>
    * @return Boolean
    */
    private static Boolean checkCSReviewEligible(SVMXC__Service_Order__c objNewWorkorder, SVMXC__Service_Order__c objOldWorkorder, Set<Id> setWorkOrderIdsForHealthCheck) {
        Boolean boolCSReviewEligible = false;
        //CMCM-5307 - Add empty check for WO trigger Optimization
        if(appliContList.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            appliContList =  new AppliedContractsSelector().selectActiveAppliedContractFromWO(new Set<Id>{objNewWorkorder.id});
        }
             // added one statement (objNewWorkorder.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM - 9198
             if(objNewWorkorder.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED
                &&objOldWorkorder.SVMXC__Order_Status__c != objNewWorkorder.SVMXC__Order_Status__c
                && ((objNewWorkorder.SVMXC__Order_Type__c == Label.WorkOrderTypeTradeinEOL && !appliContList.isEmpty()) || objNewWorkorder.SVMXC__Order_Type__c == Label.WorkOrderTypeInstallation || objNewWorkorder.SVMXC__Order_Type__c == Label.WorkOrderTypeBillableInstall || objNewWorkorder.SVMXC__Billing_Type__c == Label.WorkOrderBillingTypeBillable)
                && objNewWorkorder.Total_CS_Review_Activity_Open__c == 0) { 
                    if((!setWorkOrderIdsForHealthCheck.isEmpty() 
                    && setWorkOrderIdsForHealthCheck.contains(objNewWorkorder.Id) 
                    && WorkOrderDataReceiver.checkOrderTypeRecordTypeCombination(objNewWorkorder,Label.WorkOrderRecordTypeServiceSupport, Label.WorkOrderTypeProfessionalServices))
                    || (WorkOrderDataReceiver.checkOrderTypeRecordTypeCombination(objNewWorkorder,Label.WorkOrderRecordTypeFieldService, Label.WorkOrderTypeServiceActivities)
                    && objNewWorkorder.Abandoned_Reason__c != objOldWorkorder.Abandoned_Reason__c
                    && objNewWorkorder.SVMX_PS_Subject__c.startsWithIgnoreCase(System.Label.Work_Order_Customer_Abandoned_Prefix))){
                boolCSReviewEligible = true;
            } else if(!(WorkOrderDataReceiver.checkOrderTypeRecordTypeCombination(objNewWorkorder,Label.WorkOrderRecordTypeServiceSupport,Label.WorkOrderTypeProfessionalServices) 
                    || WorkOrderDataReceiver.checkOrderTypeRecordTypeCombination(objNewWorkorder,Label.WorkOrderRecordTypeFieldService,Label.WorkOrderTypeServiceActivities) 
                    || WorkOrderDataReceiver.checkOrderTypeRecordTypeCombination(objNewWorkorder,Label.WorkOrderRecordTypeFieldService,Label.WorkOrderTypePreventativeMaintenance))){
                boolCSReviewEligible = true;
            }               
        }
        return boolCSReviewEligible;
    }

}