/**
* @author Shivani Jain
* @date 6th May 2022
*
* @description DCP-54018 Helper Class for Work Order Trigger to run logic related to Billing Type and DCIR 
*/ 
public with sharing class BillingTypeAndDCIR_WOHelper {
    //CMCM-5307 - Start
    public static List<ContentDocumentLink> lstDocumentLink = new List<ContentDocumentLink>();
    public static List<Attachment> lstAttachment = new List<Attachment>();
    public static List<echosign_dev1__SIGN_Agreement__c> lstAgreement = new List<echosign_dev1__SIGN_Agreement__c>();
    //CMCM-5307 - End

    /**
     * method Name: billingTypeUpdateonWO
     * Description: Update  Billing_Type_Set_Manually__c to true and billing type as billable, if the customer service updates the billable type as billable.
     * */
    public static void billingTypeUpdateonWO(List<Sobject> records, Id idEstimatesRecordTypeId) {
       
        
        Map<Id,SVMXC__Installed_Product__c> idToWoIP = new Map<Id,SVMXC__Installed_Product__c>();
        List<id> lstWorkOrderId= new List<id>();

        processWOonBillingType(records,idEstimatesRecordTypeId);

        if(!WorkOrders.lstInstalledProductrecords.IsEmpty()) {
            for(SVMXC__Installed_Product__c obj:WorkOrders.lstInstalledProductrecords) {
                idToWoIP.put(obj.id, obj);
            }
        }
      
        addDCIRStatusCompletedWO(records,lstWorkOrderId,idToWoIP);

        //DCP-39881
        if(!lstWorkOrderId.isEmpty())
            validateIfDCIRAgreementIsGenerated(lstWorkOrderId, records);
        }

    /**
    * @description :Check WO based on billing type
    * @param records 
    * @param idEstimatesRecordTypeId 
    **/
    public static void processWOonBillingType(List<Sobject> records,Id idEstimatesRecordTypeId)
    {
        String customerServiceProfileId = WorkOrders.profileNameToProfile.containskey(System.Label.ProfileCustomerService) ? WorkOrders.profileNameToProfile.get(System.Label.ProfileCustomerService).ID :'';
        String systemAdminProfileId = WorkOrders.profileNameToProfile.containskey(System.Label.ProfileSystemAdmin) ? WorkOrders.profileNameToProfile.get(System.Label.ProfileSystemAdmin).ID :'';
        boolean boolCSOrSysAdmin = userinfo.getProfileId().equals(customerServiceProfileId) || userinfo.getProfileId().equals(systemAdminProfileId);
        String integrationSapServiceProfileId = WorkOrders.profileNameToProfile.containskey(System.Label.Integration_SAP_Service) ? WorkOrders.profileNameToProfile.get(System.Label.Integration_SAP_Service).ID :'';
        // DCP-38933
        String strIntegrationSNAPServiceProfileId = WorkOrders.profileNameToProfile.containskey(System.Label.Integration_Service_SNAP_Profile) ? WorkOrders.profileNameToProfile.get(System.Label.Integration_Service_SNAP_Profile).ID :'';
        for(SVMXC__Service_Order__c objWO: (List<SVMXC__Service_Order__c>)records) {
            if(Trigger.isUpdate && Trigger.oldMap!=null && !Trigger.oldMap.isempty() && WorkOrders.profileNameToProfile != null && !WorkOrders.profileNameToProfile.isEmpty()) {
                SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(Trigger.oldMap.get(objWO.Id));

                validateForNonBillableWOOnUpdate(objWO,objOldWorkOrder,boolCSOrSysAdmin,integrationSapServiceProfileId,strIntegrationSNAPServiceProfileId,idEstimatesRecordTypeId);
                
            } else if(Trigger.isInsert && WorkOrders.profileNameToProfile != null && !WorkOrders.profileNameToProfile.isEmpty() 
                    && objWO.SVMXC__Billing_Type__c==WorkOrders.STRING_LABEL_BILLABLE){

                    validateForNonBillableWOOnInsert(objWO,boolCSOrSysAdmin,integrationSapServiceProfileId,strIntegrationSNAPServiceProfileId);
            }
        }
        
    }

    /**
    * @description :Update Billing_Type_Set_Manually__c=true else throw error message for non billable WO based on criteria 
    * @param objWO 
    * @param objOldWorkOrder 
    * @param boolCSOrSysAdmin 
    * @param integrationSapServiceProfileId 
    * @param strIntegrationSNAPServiceProfileId 
    * @param idEstimatesRecordTypeId 
    **/
    public static void validateForNonBillableWOOnUpdate(SVMXC__Service_Order__c objWO,SVMXC__Service_Order__c objOldWorkOrder,boolean boolCSOrSysAdmin,
    String integrationSapServiceProfileId,String strIntegrationSNAPServiceProfileId,Id idEstimatesRecordTypeId)
    {
         //DCP-49512    
         if(objOldWorkOrder.RecordtypeId != objWO.RecordtypeId && objWO.RecordtypeId == idEstimatesRecordTypeId && objWO.PO_Number__c != Null  ){
            objWO.PO_Number__c = Null; // Blank out PO NUmber for Estimate Record Type
        }

        if(objWO.SVMXC__Billing_Type__c== WorkOrders.STRING_LABEL_BILLABLE 
                    || objOldWorkOrder.SVMXC__Billing_Type__c== WorkOrders.STRING_LABEL_BILLABLE) {// Added check for old WO for PRB0044899
                        if(objOldWorkOrder.SVMXC__Billing_Type__c!=objWO.SVMXC__Billing_Type__c 
                            && objWO.SVMXC__Billing_Type__c==WorkOrders.STRING_LABEL_BILLABLE 
                            && objWO.Billing_Type_Set_Manually__c ==false 
                            && boolCSOrSysAdmin){
                                objWO.Billing_Type_Set_Manually__c = true;
                        }
                        // DCP-38933
                        else if(objOldWorkOrder.SVMXC__Billing_Type__c != objWO.SVMXC__Billing_Type__c 
                                &&objOldWorkOrder.Number_of_Billable_Work_Details__c==objWO.Number_of_Billable_Work_Details__c 
                                && !(boolCSOrSysAdmin
                                    || userinfo.getProfileId().equals(integrationSapServiceProfileId) 
                                    || userinfo.getProfileId().equals(strIntegrationSNAPServiceProfileId) 
                                    || userinfo.getFirstName().equals(System.Label.Automated_Process_User))){
                                        objWO.addError(System.label.WO_Trigger_Billing_Type_Edit_Error_Message);
                        }
                }
    }

    /**
    * @description : Add all the completed work order records whose DCIR status is completed
    * @param records 
    * @param lstWorkOrderId 
    * @param idToWoIP 
    **/
    public static void addDCIRStatusCompletedWO(List<Sobject> records,List<id> lstWorkOrderId,Map<Id,SVMXC__Installed_Product__c> idToWoIP)
    {
        for(SVMXC__Service_Order__c objWo : (List<SVMXC__Service_Order__c>)records) {
            
            if(Trigger.isUpdate) {
                SVMXC__Service_Order__c objOldWorkOrder = (SVMXC__Service_Order__c)(Trigger.oldMap.get(objWO.Id));
                if(objWo.SVMXC__Order_Type__c==WorkOrders.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION 
                        && ((objWo.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED && objWo.DCIR_Status__c== WorkOrders.STRING_WORK_ORDER_DCIR_STATUS_OPEN) 
                                || objWo.DCIR_Status__c==WorkOrders.STRING_WORK_ORDER_DCIR_STATUS_COMPLETED) && (objOldWorkOrder.SVMXC__Order_Status__c != objWo.SVMXC__Order_Status__c
                                || objOldWorkOrder.DCIR_Status__c != objWo.DCIR_Status__c) ) {
                    lstWorkOrderId.add(objWo.id);
                }
                
             }
            //DCP-39881 End
            if(!objWo.Billing_Type_Set_Manually__c ) {
                objWo.SVMXC__Billing_Type__c = objWo.Number_of_Billable_Work_Details__c > 0 ? WorkOrders.STRING_LABEL_BILLABLE : '';
            }
            //DCP-45490 : Added check fo Partner WO // WO should not be billable for CP user. // merge 2 If onto one.
            //Added one statement (objWo.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) by Dhairya Shah for CMCM - 9198
            if(objWo.SVMXC__Order_Type__c == WorkOrders.STRING_WORK_ORDER_ORDER_TYPE_RELOCATION && !objWo.Partner_Work_Order__c
                    && objWo.SVMXC__Component__c != null && !idToWoIP.isEmpty() && idToWoIP.containskey(objWo.SVMXC__Component__c)  
                    && idToWoIP.get(objWo.SVMXC__Component__c).Asset_Type__c ==WorkOrders.STRING_WORK_ORDER_IP_ASSET_TYPE_CUSTOMER_OWNED) {
                objWo.SVMXC__Billing_Type__c = WorkOrders.STRING_LABEL_BILLABLE;
            }
            if(objWo.SVMXC__Order_Type__c == System.Label.WorkOrderTypeBillableInstall) {
                objWo.SVMXC__Billing_Type__c = WorkOrders.STRING_LABEL_BILLABLE;
            }
        }
    }

    /**
    * @description : Update Billing_Type_Set_Manually__c=true else throw error message for non billable WO based on criteria 
    * @param objWO 
    * @param boolCSOrSysAdmin 
    * @param integrationSapServiceProfileId 
    * @param strIntegrationSNAPServiceProfileId 
    **/
    public static void validateForNonBillableWOOnInsert(SVMXC__Service_Order__c objWO,boolean boolCSOrSysAdmin,
    String integrationSapServiceProfileId,String strIntegrationSNAPServiceProfileId)
    {
        
        if(objWO.SVMXC__Billing_Type__c==WorkOrders.STRING_LABEL_BILLABLE 
        && objWO.Billing_Type_Set_Manually__c ==false 
        && boolCSOrSysAdmin){
                objWO.Billing_Type_Set_Manually__c = true;
        }
        // DCP-38933
        else if(!(boolCSOrSysAdmin
                    || userinfo.getProfileId().equals(integrationSapServiceProfileId)
                    || userinfo.getProfileId().equals(strIntegrationSNAPServiceProfileId) 
                    ||  userinfo.getFirstName().equals(System.Label.Automated_Process_User)) ){
                objWO.addError(System.label.WO_Trigger_Billing_Type_Edit_Error_Message);
        }
    }
    /**
    *   DCP- 39881
    *   @author Gautam Arya
    *   @param List<id> woid, List<SVMXC__Service_Order__c> records
    *   @return 
    **/
    public static void validateIfDCIRAgreementIsGenerated(List<id> woid, List<SVMXC__Service_Order__c> records) {
       
        Channel_Partner_Profile_Settings__c cp = Channel_Partner_Profile_Settings__c.getInstance(Userinfo.getProfileID());
        Map<String ,List<ContentDocumentLink>> mapWOtocontentdoc=new Map<String ,List<ContentDocumentLink>>();
        Set<Id> setWOId=new Set<Id>(woid);
        Map<String ,List<Attachment>> mapWOtoAttachment=new Map<String ,List<Attachment>>();
        Map<String ,List<echosign_dev1__SIGN_Agreement__c>> mapWOtoesignAgreement=new Map<String ,List<echosign_dev1__SIGN_Agreement__c>>();
        //CMCM-5307 - Add empty check for WO Optimization
        if(lstDocumentLink.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstDocumentLink = new ContentDocumentLinksSelector().selectByMasterDataRequestIds(woid);
        }
        for(ContentDocumentLink obj: lstDocumentLink){
            if(!mapWOtocontentdoc.containsKey(obj.LinkedEntityId)) {
                mapWOtocontentdoc.put(obj.LinkedEntityId, new List<ContentDocumentLink>());
            }
            mapWOtocontentdoc.get(obj.LinkedEntityId).add(obj);
        }
        //For Mobile story DCP-39882
        //CMCM-5307 - Add empty check for WO Optimization
        if(lstAttachment.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
            lstAttachment = new AttachmentsSelector().selectByParentId(setWOId);
        }
        if(!cp.Is_Channel_Partner__c) {
            for(Attachment obj: lstAttachment) {
                if(!mapWOtoAttachment.containsKey(obj.ParentId)) {
                    mapWOtoAttachment.put(obj.ParentId, new List<Attachment>());
                }
                mapWOtoAttachment.get(obj.ParentId).add(obj);
            }
            //CMCM-5307 - Add empty check for WO Optimization
            if(lstAgreement.isEmpty() || Feature.isOn(System.label.Feature_Work_Order_Optimization)){
                lstAgreement = new AgreementsSelector().selectWOAgreements(setWOId);
            }

            for(echosign_dev1__SIGN_Agreement__c obj: lstAgreement) {
                if(!mapWOtoesignAgreement.containsKey(obj.Work_Order__c)){
                    mapWOtoesignAgreement.put(obj.Work_Order__c, new List<echosign_dev1__SIGN_Agreement__c>());
                }
                mapWOtoesignAgreement.get(obj.Work_Order__c).add(obj);
           }
        }

        validateAttachmentForCompleteWO(records,cp,mapWOtocontentdoc,mapWOtoAttachment,mapWOtoesignAgreement);
    }

    /**
    * @description :Throw error message for complete WO if attachment doesnot exist
    * @param records 
    * @param cp 
    * @param mapWOtocontentdoc 
    * @param mapWOtoAttachment 
    * @param mapWOtoesignAgreement 
    **/
    public static void validateAttachmentForCompleteWO(List<SVMXC__Service_Order__c> records,Channel_Partner_Profile_Settings__c cp,Map<String ,List<ContentDocumentLink>> mapWOtocontentdoc,
    Map<String ,List<Attachment>> mapWOtoAttachment,Map<String ,List<echosign_dev1__SIGN_Agreement__c>> mapWOtoesignAgreement)
    {
        
        for(SVMXC__Service_Order__c  objWO: records) {
            // To check the work order status is completed and an attachment is present.
            if((cp.Is_Channel_Partner__c  && !mapWOtocontentdoc.containsKey(objWO.id) && objWo.SVMXC__Order_Status__c == WorkOrders.STRING_WORK_ORDER_STATUS_COMPLETED)
                    ||(!cp.Is_Channel_Partner__c  && !mapWOtoAttachment.containsKey(objWO.id) && !mapWOtoesignAgreement.containsKey(objWO.Id) 
                        && !objWo.Is_DCIR_Filled__c && objWo.DCIR_Status__c == WorkOrders.STRING_WORK_ORDER_DCIR_STATUS_COMPLETED)) {
                objWO.addError(Label.WODCIRCheckErrorCP);
            }
            //To check the DCIR status is completed for CP work order and an attachment is present.
            if(cp.Is_Channel_Partner__c  && !mapWOtocontentdoc.containsKey(objWO.id) && objWo.DCIR_Status__c == WorkOrders.STRING_WORK_ORDER_DCIR_STATUS_COMPLETED) {
                objWO.addError(Label.WODCIRCheckError);
            }
        }
    }
}