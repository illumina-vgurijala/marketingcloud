/***************************************************************************************************************************************
* NAME   : Attachments
* DESCRIPTION  : Domain class for AttachmentTrigger.
*                    
* @AUTHOR : Ritika Maheshwari
* @DATE   : 06-June-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Ritika               06-June-2018          Initial Version. Added logic to reparent inventory snapshot created for Location, to be associated to Work Order
* Soumya               10-Sept-2018          Added sendEmailLOA() method under after insert to send email when LOA is inserted.
* Sarath Pullanikkatt  07-Jan-2020           Removed Schema.getGlobalDescribe() to retrieve Locations and Agreements object prefixes.
* Roopal Verma         24-March-2021         DCP-45303 - Added logic to craete a task on quote when sales contract is attached on quote.
****************************************************************************************************************************************/ 
public with sharing class Attachments extends ilib_SObjectDomain { 

    public static final String STRING_ATTACHMENT_NAME = 'Letter of Acceptance - signed';
    public static final String STRING_WORK_ORDER_ACCEPTANCE_STATUS = 'Completed';
    public static final String STRING_AGREEMENT_NAME = 'Letter of Acceptance';
    public static final String STRING_AGREEMENT_STATUS_SIGNED = 'Signed';
    public static final String STRING_WORK_ORDER_ACCEPATNCE_FORECAST = '100% Completed - LOA Signed';
    public static final String LOCATION_OBJ_PREFIX = 'a2K'; //SVMXC__Site__c object Prefix
    public static final String ADOBE_AGREEMENT_OBJ_PREFIX = 'a8P'; //echosign_dev1__SIGN_Agreement__c object Prefix
	public static final String PARTS_ORDER_LINE_OBJ_PREFIX = 'a10'; //Parts Order Line object Prefix
    public static final String STRING_MOBILE_LOANER_NAME = 'Sign_Service_Loaner_Agreement__Mobile';//Loaner mobile document name
    public static final String QUOTATION_OBJ_PREFIX = 'a3s'; //Quotation object prefix
    public static final String STRING_TASK_SUBJECT = 'Sales Contract Generated';
    public static final String STRING_TASK_STATUS_OPEN = 'Open';
    public static final String STRING_TASK_PRIORITY_NORMAL = 'Normal';
    public static final String STRING_TASK_TYPE_OTHER = 'Other';
    
   /*
    * Constructor
    */
    public Attachments(List<Attachment> sObjectList)
    {
        super(sObjectList);
    }

    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
	    /*Param - sobjectList */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new Attachments(sObjectList);
        }
    }

    /**
    *  @author Ritika Maheshwari
    *  @description - To be executed, when the attachment is inserted. 
    *               1. Checks if attachment is created for Location. If yes, then fetch its work order and associate the attachment with Work Order
    **/
    public override void onbeforeInsert()
    {
        Map<Id, List<Attachment>> mapParentLocationIdToAttachments = new Map<Id, List<Attachment>>();
        Map<Id, List<Attachment>> mapParentQuotationIdToAttachments = new Map<Id, List<Attachment>>();
        Set<Id> setQuoteIds = new Set<Id>();
        List<Apttus_Proposal__Proposal__c> lstQuoteRecords = new List<Apttus_Proposal__Proposal__c>();

        for(Attachment objAttachment : (List<Attachment>)records){
            if(objAttachment.ParentId != null && String.valueOf(objAttachment.ParentId).startsWith(LOCATION_OBJ_PREFIX)){
                if(!mapParentLocationIdToAttachments.containsKey(objAttachment.ParentId)){
                    mapParentLocationIdToAttachments.put(objAttachment.ParentId, new List<Attachment>());
                }
                mapParentLocationIdToAttachments.get(objAttachment.ParentId).add(objAttachment);
            }

            if(objAttachment.ParentId != null && String.valueOf(objAttachment.ParentId).startsWith(QUOTATION_OBJ_PREFIX)){
                if(!mapParentQuotationIdToAttachments.containsKey(objAttachment.ParentId)){
                    mapParentQuotationIdToAttachments.put(objAttachment.ParentId, new List<Attachment>());
                }
                mapParentQuotationIdToAttachments.get(objAttachment.ParentId).add(objAttachment);
            }
        }
        if(mapParentLocationIdToAttachments.size() > 0 ){
            updateAttachmentParentIdToWorkOrder(mapParentLocationIdToAttachments);
        }

        setQuoteIds = mapParentQuotationIdToAttachments.keySet();
        if(!setQuoteIds.isEmpty()){
            lstQuoteRecords = new ApttusProposalsSelector().selectByQuoteId(setQuoteIds);
        }

        if(!lstQuoteRecords.isEmpty()){
        createTaskForSalesContract(lstQuoteRecords);
        }
    }

    /**
    *  @author Ritika M
    *  @description - This method reparents attachments to Work Order
    *  @parameters : mapParentLocationIdToAttachments - map of Location Ids versus its correspoding attachments which have been inserted
    *  @return : void
    **/
    private static void updateAttachmentParentIdToWorkOrder( Map<Id, List<Attachment>> mapParentLocationIdToAttachments){
        List<SVMXC__Service_Order__c> lstWorkOrderUpdate = new List<SVMXC__Service_Order__c>();
        for(SVMXC__Service_Order__c objWorkOrder : new WorkOrdersSelector().selectCycleCountWorkOrderforSpanshot(mapParentLocationIdToAttachments.keyset() ))
        {           
            for(Attachment objAttachment : mapParentLocationIdToAttachments.get(objWorkOrder.SVMXC__Site__c))    
            {
                objAttachment.ParentId = objWorkOrder.Id;
            }
            objWorkOrder.Generate_Inventory_Snapshot__c = false;
            lstWorkOrderUpdate.add(objWorkOrder);
        }
        
        update lstWorkOrderUpdate;
    }

    /**
    *  @author Roopal Verma
    *  @description - Create task on quote for sales contracts
    *  @parameters : List of quote records
    *  @return : void
    **/
    private static void createTaskForSalesContract(List<Apttus_Proposal__Proposal__c> lstQuoteRecords){
        List<Task> lstTask = new List<Task>();
        for(Apttus_Proposal__Proposal__c objQuote : lstQuoteRecords){
            if(objQuote.View_Contract__c){
                Task objtsk = new Task();
                objtsk.Subject = STRING_TASK_SUBJECT;
                objtsk.Status = STRING_TASK_STATUS_OPEN;
                objtsk.Priority = STRING_TASK_PRIORITY_NORMAL;
                objtsk.WhatId = objQuote.Id;
                objtsk.OwnerId = objQuote.Ultimate_Consignee__r.OwnerId;
                objtsk.Type = STRING_TASK_TYPE_OTHER;
                lstTask.add(objtsk);
            }
        }

        if(lstTask!=null && !lstTask.isEmpty()){
            insert lstTask;
        }
    }
    
    /**
    *  @author Soumya
    *  @description - To be executed, when the Attachment is inserted. 
    *  @parameters : null
    *  @return : void              
    **/
    public override void onAfterInsert()
    {
        Map<id,id> agreementIdToAttachmentIds = new Map<id,id>();
		//DCP-43150
		Attachment mobileloanerattch =new Attachment();
        //Check whether attachment is Letter of Acceptance
        for(Attachment objAttachment : (List<Attachment>)records){
            if(objAttachment.ParentId != null  
                && objAttachment.Name.contains(STRING_ATTACHMENT_NAME) 
                && String.valueOf(objAttachment.ParentId).startsWith(ADOBE_AGREEMENT_OBJ_PREFIX) ){
                agreementIdToAttachmentIds.put(objAttachment.ParentId,objAttachment.id);
            }
			 if(objAttachment.ParentId != null  
                && objAttachment.Name.contains(STRING_MOBILE_LOANER_NAME) 
                && String.valueOf(objAttachment.ParentId).startsWith(PARTS_ORDER_LINE_OBJ_PREFIX) ){
                  //  attachmentIdToPOLIds.put(objAttachment.id,objAttachment.ParentId);
                  if(mobileloanerattch.id == null)
            {
            mobileloanerattch= objAttachment;
            }
                    
        }
        sendEmailWhenLOASigned(agreementIdToAttachmentIds);
		if(mobileloanerattch.id != null)
        {
            ServiceUtilityCollection.createFilesFromAttachment(mobileloanerattch);
        }
       
      }
    }
    /**
    *  @author Soumya
    *  @description - To be executed, when the LOA is signed and attched through Adobe E-Sign (Smart Docs).This sends an email making the LOA as attachment.
    *  @parameters : Null
    *  @return : void             
    **/
    public void sendEmailWhenLOASigned(Map<id,id> agreementIdToAttachmentIds){
        
        if(agreementIdToAttachmentIds.size()>0){
            Map<id,id> workOrderIdToAgreementIds= new Map<id,id>();
            //Stores the agreement corresponding to the Work Orders
            for(echosign_dev1__SIGN_Agreement__c objAgreement :new AgreementsSelector().selectAgreements(agreementIdToAttachmentIds.keyset())){
                //To Check whether agreement is Letter of Acceptance and it is signed
                if(objAgreement.Name.contains(STRING_AGREEMENT_NAME) 
                    && objAgreement.echosign_dev1__Status__c==STRING_AGREEMENT_STATUS_SIGNED){
                    workOrderIdToAgreementIds.put(objAgreement.Work_Order__c,objAgreement.id);
                }

            }
            List<SVMXC__Service_Order__c> lstWorkOrders = new List<SVMXC__Service_Order__c>();
            //To store the work orders that are to be updated
            map<id,List<id>> workOrderIdToAttachmentIds= new map<id,List<id>>();
            //To store the work order record corresponding to the attachment
            for(SVMXC__Service_Order__c objWorkOrder : new WorkOrdersSelector().selectWorkOrdersFromIds(workOrderIdToAgreementIds.keyset())){
                
                workOrderIdToAttachmentIds.put(objWorkOrder.id,new List<id>());
                if(workOrderIdToAgreementIds.containsKey(objWorkOrder.id) && agreementIdToAttachmentIds.containsKey(workOrderIdToAgreementIds.get(objWorkOrder.id))){
                    workOrderIdToAttachmentIds.get(objWorkOrder.id).add(agreementIdToAttachmentIds.get(workOrderIdToAgreementIds.get(objWorkOrder.id)));
                }
                //update fields on work orders
                objWorkOrder.Acceptance_Status__c=STRING_WORK_ORDER_ACCEPTANCE_STATUS;
                objWorkOrder.LOA_Signed_and_Attached__c=true;
                objWorkOrder.Acceptance_Forecast_in_Current_Quarter__c=STRING_WORK_ORDER_ACCEPATNCE_FORECAST;
                lstWorkOrders.add(objWorkOrder);
            }
            try{
                update lstWorkOrders;
            }
            catch(Exception e){
                system.debug('Error:'+e.getMessage());
            }
            //Passing data to send emails
            SendEmailNotification.sendEmailWithAttachments('Letter_of_Acceptance',lstWorkOrders,workOrderIdToAttachmentIds,null,null);
        }
    }
}