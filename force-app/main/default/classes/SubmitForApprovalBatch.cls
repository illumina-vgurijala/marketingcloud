/**
* @author Dushyant Srivastava
* @date   2022-02-22
* @description    DCP-52265: Fixes for Signatures coming in as Attachment.
*/
public with sharing class SubmitForApprovalBatch extends ilib_BatchDeferrable {

    public final static String LOG_TITLE = 'SubmitForApprovalBatch';
    private List<Apttus_Approval__ApprovalProcessInstance__c> lstUpdateApprovalInstance;
    private Inputs inputs;
        
    /*
    *  @author       : Dushyant
    *  @description  : Wrapper class for better serialization
    *  @param        : NA
    */
    public class Inputs
    {
        public Id quoteId;
        /*
        *  @author       : Dushyant
        *  @description  : Constructor of the input class
        *  @param        : ID - quoteId
        */
        public Inputs(Id quoteId)
        {
            this.quoteId = quoteId;
        }
    }

    /* required to reinstantiate after deferral */
    public SubmitForApprovalBatch() {
        super();
     }

    /* collect parameters of batch operation */
    public SubmitForApprovalBatch(Id quoteId)
    {
        super();
        this.inputs = new Inputs(quoteId);
        
        lstUpdateApprovalInstance = new List<Apttus_Approval__ApprovalProcessInstance__c>();
        ilib_LogEvent.setTitle(LOG_TITLE);
    }
    /* specify scope of batch to fetch Approval Process Instance */
    public override Database.QueryLocator start(Database.BatchableContext bc) {
        String updatedQuoteId = inputs.quoteId;
        String query = 'Select id, Apttus_Approval__ProcessInstanceId__c, Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__AssignmentEmailTemplate__c, Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__ReassignmentEmailTemplate__c, Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__EscalationEmailTemplate__c, Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__NotifyOnlyEmailTemplate__c, Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__CancellationEmailTemplate__c from Apttus_Approval__Approval_Request__c where Apttus_Approval__Object_Id__c = :updatedQuoteId';
        return Database.getQueryLocator(query);
    }
    /* update one batch worth of records */
    public override void execute(Database.BatchableContext bc, List<SObject> records){
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        Map<String , EmailTemplate> mapEmailTemp = new Map<String , EmailTemplate>();
        Set<String> setEmailTemplateName = new Set<String>();
        List<Id> lstIds = new List<Id>();
        for(Apttus_Approval__Approval_Request__c objApprovalRequest : (List<Apttus_Approval__Approval_Request__c>)records){
            setEmailTemplateName.add(objApprovalRequest.Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__AssignmentEmailTemplate__c);
            setEmailTemplateName.add(objApprovalRequest.Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__ReassignmentEmailTemplate__c);
            setEmailTemplateName.add(objApprovalRequest.Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__EscalationEmailTemplate__c);
            setEmailTemplateName.add(objApprovalRequest.Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__NotifyOnlyEmailTemplate__c);
            setEmailTemplateName.add(objApprovalRequest.Apttus_Approval__ProcessInstanceId__r.Apttus_Approval__CancellationEmailTemplate__c);
            lstIds.add(objApprovalRequest.Apttus_Approval__ProcessInstanceId__c);
        }

        EmailTemplatesSelector objEmailTemplatesSelector = new EmailTemplatesSelector(); 
        List<EmailTemplate> lstEmailTemplate = objEmailTemplatesSelector.selectByNameOrDeveloperName(new List<String>(setEmailTemplateName));
        for(EmailTemplate objEmailTemplate : lstEmailTemplate){
            EmailTemplate objCloneEmailTemplate = objEmailTemplate.clone(false , true, false, false);
            Integer len = 10;
            Blob blobKey = crypto.generateAesKey(128);
            String key = EncodingUtil.convertToHex(blobKey);
            objCloneEmailTemplate.DeveloperName = 'TEMP' + key.substring(0,len) ;
            mapEmailTemp.put(objEmailTemplate.DeveloperName , objCloneEmailTemplate);
        }    
        
        getApprovalProcessInstanceList(mapEmailTemp, lstIds);

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }    
    /* update header now that line batches have been completed */
    public override void finish(Database.BatchableContext bc){
        //CMSI-19 setting transaction id
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.push(LOG_TITLE + '.finish()');
        ilib_LogEvent.message('lstUpdateApprovalInstance: ' + lstUpdateApprovalInstance);
        if(!lstUpdateApprovalInstance.isEmpty()){
            update lstUpdateApprovalInstance;
        }

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    } 

        /*
    Author - Dushyant Srivastava
    Purpose - This will insert the Temporary email templates into the system.(As part of the Code scan fix Jitesh created this method and moved the code here).
    */
    public void getApprovalProcessInstanceList(Map<String , EmailTemplate> mapEmailTemp, List<Id> lstIds){

        if(!mapEmailTemp.isEmpty()){
            ApttusApprovalProcessInstancesSelector objApttusApprovalProcessInstancesSelector = new ApttusApprovalProcessInstancesSelector();
            List<Apttus_Approval__ApprovalProcessInstance__c> lstApttusApprovalProcessInstancesSelector = objApttusApprovalProcessInstancesSelector.selectById(lstIds);
            for(Apttus_Approval__ApprovalProcessInstance__c objApprovalProcessInstance : lstApttusApprovalProcessInstancesSelector){
                objApprovalProcessInstance.Apttus_Approval__AssignmentEmailTemplate__c = mapEmailTemp.containsKey(objApprovalProcessInstance.Apttus_Approval__AssignmentEmailTemplate__c) ? mapEmailTemp.get(objApprovalProcessInstance.Apttus_Approval__AssignmentEmailTemplate__c).DeveloperName : objApprovalProcessInstance.Apttus_Approval__AssignmentEmailTemplate__c;
                objApprovalProcessInstance.Apttus_Approval__ReassignmentEmailTemplate__c = mapEmailTemp.containsKey(objApprovalProcessInstance.Apttus_Approval__ReassignmentEmailTemplate__c) ? mapEmailTemp.get(objApprovalProcessInstance.Apttus_Approval__ReassignmentEmailTemplate__c).DeveloperName : objApprovalProcessInstance.Apttus_Approval__ReassignmentEmailTemplate__c;
                objApprovalProcessInstance.Apttus_Approval__EscalationEmailTemplate__c = mapEmailTemp.containsKey(objApprovalProcessInstance.Apttus_Approval__EscalationEmailTemplate__c) ? mapEmailTemp.get(objApprovalProcessInstance.Apttus_Approval__EscalationEmailTemplate__c).DeveloperName : objApprovalProcessInstance.Apttus_Approval__EscalationEmailTemplate__c;
                objApprovalProcessInstance.Apttus_Approval__NotifyOnlyEmailTemplate__c = mapEmailTemp.containsKey(objApprovalProcessInstance.Apttus_Approval__NotifyOnlyEmailTemplate__c) ? mapEmailTemp.get(objApprovalProcessInstance.Apttus_Approval__NotifyOnlyEmailTemplate__c).DeveloperName : objApprovalProcessInstance.Apttus_Approval__NotifyOnlyEmailTemplate__c;
                objApprovalProcessInstance.Apttus_Approval__CancellationEmailTemplate__c = mapEmailTemp.containsKey(objApprovalProcessInstance.Apttus_Approval__CancellationEmailTemplate__c) ? mapEmailTemp.get(objApprovalProcessInstance.Apttus_Approval__CancellationEmailTemplate__c).DeveloperName : objApprovalProcessInstance.Apttus_Approval__CancellationEmailTemplate__c;
                lstUpdateApprovalInstance.add(objApprovalProcessInstance);
            }

            if(!mapEmailTemp.Values().isEmpty()){
                insert mapEmailTemp.Values();
            }
        }
    }

    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************

    /* simple input serialization */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /* simple input deserialization */
    public override void restoreInputs(String serializedInputs)
    {
        this.inputs = (SubmitForApprovalBatch.Inputs)JSON.deserialize(serializedInputs, submitForApprovalBatch.Inputs.class);
    }

    /* default val */
    public override Integer getDefaultBatchSize()
    {
        return 100;
    }

}