/*Modification Log:
 *   ------------------------------------------------------------------------------------
 *    Developer                      Date                    Description
 *    Saptarshi Das               15-Sep-2022            QACM-175 - Printable Case View for Audit & Non-SFDC Users
 *
 *    ------------------------------------------------------------------------------------
 */
public without sharing class CasePDFController {
    public Case caseData { get; set; }

    private String fieldSet = '';

    public String caseStatus { get; set; }

    public Id caseId { get; set; }

    public List<Case> contactData { get; set; }

    public List<Quality_Record_Junction__c> qrData { get; set; }

    public List<Associated_Codes__c> codes { get; set; }

    public List<ContentDocumentLink> filesData { get; set; }

    public List<EmailMessage> emailData { get; set; }

    public List<CaseComment> caseComentData { get; set; }

    public List<CaseHistory> caseHistoryData { get; set; }

    public List<SVMXC__RMA_Shipment_Order__c> partsOrderData { get; set; }

    public List<SVMXC__Service_Order__c> workOrderData { get; set; }

    public List<Metadata.LayoutSection> layoutSections { get; set; }

    public Map<String, String> mapFieldLabel { get; set; }

    
    private string fieldIdtoName = '';
    //Get Contact data
    private static final String CONTACT_QUERY = ' CaseNumber, LastModifiedDate, Contact.Contact_Record_Type__c, Contact.OtherPhone, Contact.Full_Name_Local__c, Contact.Alternate_Email__c, Contact.OtherCountry, Contact.OtherCountryCode, Contact.OtherStreet , Contact.OtherCity,  Contact.OtherState,Contact.OtherPostalCode, Contact.CreatedBy.Name, Contact.LastModifiedBy.Name';
    
    //To check the skippable fields
    public string chkMapKey { get; set; }

    //To check the skippable Sections
    public string chkSkipSections { get; set; }

    //To check the ID to name converted fields
    public string chkMapID { get; set; }

    public Map<String, String> apiNameMap { get; set; }

    public String userDateTime { get; set; }

    private static final String LOG_TITLE = 'CasePDFController';
    private static final String PAGE_LAYOUT = 'Case-Business Issue';
    private static final String SKIP_SECTION = 'Custom Links, Internal Notes';//To skip 2 layout sections
    
    private static final String CONTACT_ID = 'Contact ID';
    private static final String CONTACT_NAME = 'Contact Name';
    private static final String OWNER_ID = 'Owner ID';
    private static final String CASE_OWNER = 'Case Owner';
    private static final String PARENT_CASE_ID = 'Parent Case ID';
    private static final String PARENT_CASE = 'Parent Case';
    private static final String CREATED_BY_ID = 'Created BY ID';
    private static final String CREATED_BY = 'Created By';
    private static final String CREATED_DATE = 'Created Date';
    private static final String DATETIME_OPENED = 'Date/Time Opened';
    private static final String LASTMODIFIED_BY_ID = 'Last Modified By ID';
    private static final String LASTMODIFIED_BY = 'Last Modified By';
    private static final String CLOSED_DATE = 'Closed Date';
    private static final String DATETIME_CLOSED = 'Date/Time Closed';
    /**
     *
     *
     * @author Saptarshi
     */
    public CasePDFController() {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SERVICE);
    }

    /**
     *
     *
     * @author Saptarshi
     * Description: query the related records
     */
    private void getRelatedRecords(Id caseId) {
        ilib_LogEvent.push(LOG_TITLE + '.CasePDFController.getRelatedRecords()');
        try {
                     //Get Quality Record Data
                     qrData =  new QualityRecordJunctionSelector().selectCaseQR(String.valueOf(caseId) );

                     //Get Associated Codes
                     //To Check the Object Permission:
                     if(Schema.sObjectType.Associated_Codes__c.isAccessible()) {
                         Codes = new AssociatedCodeSelector().selectAssociatedCodesOnCases(new Set<Id>{caseId});
                         }
                         else {
                             Codes = new List<Associated_Codes__c>();
                         }
         
                     //Get Files data
                     filesData = new List<ContentDocumentLink>();
                     Set<Id> recsSet = new Set<Id>();
                     Id recordId  = caseId;
                     List<EmailMessage> emailMsgs = new List <EmailMessage>(new EmailMessagesSelector().selectEmailMsgsByParentWithAttachment(new Set<Id>{recordId}));
                     recsSet = UtilsCollection.getSetOfIds(emailMsgs);
                     recsSet.add(recordId);
                 
                    // filesData = new List <ContentDocumentLink>(new ContentDocumentLinksSelector().selectContentDocumentLinksWithoutLogos(recsSet));
                     List<ContentDocumentLink> tempFilesData = new List <ContentDocumentLink>(new ContentDocumentLinksSelector().selectContentDocumentLinksWithoutLogos(recsSet));
                         for( ContentDocumentLink file : tempFilesData) {
                             if(file.ContentDocument.FileExtension != 'snote') { //exclude notes from attachments
                                 filesData.add(file);
                             }
                         }
         
                     //Get Email data
                     //Direct query because toLabel is not supported by queryfactory
                      emailData = [Select Id, Subject, MessageDate, FromAddress, HasAttachment, toLabel(Status), TextBody from EmailMessage where ParentId = :caseId];
                     //Enable wrap text for large Email body
                     for(EmailMessage email : emailData){
                         String tempString = email.TextBody;
                         if(String.isNotBlank(tempString)) {
                             email.TextBody = tempString.replaceAll('\n','<br/>');
                         }  
                     }
         
                     //Get Case Comments Data
         
                     caseComentData = new CaseCommentSelector().selectCaseComments(String.valueOf(caseId));
         
                     //Enable wrap text for case comments
                     for(CaseComment commData : caseComentData) {
                         String tempString = commData.CommentBody;
                         if(String.isNotBlank(tempString)) {
                             commData.CommentBody = tempString.replaceAll('\n','<br/>');
                         }  
                     }
                     
                     //Get Case History Data
                     caseHistoryData = new CaseHistorySelector().selectCaseHistoryRecords(String.valueOf(caseId));
         
                     //Get Parts Order Data
                     partsOrderData = new PartsOrdersSelector().selectPartsOrdersWithCase(String.valueOf(caseId) );
         
                     //Get Work Order Data
                     workOrderData = new WorkOrdersSelector().selectWorkOrderIdOnCase(new Set<Id>{caseId});   
        } catch (Exception e){
            ApexExceptions.emit('CasePDFController.getRelatedRecords :', e, ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();

        }
    }

    /**
     *
     *
     * @author Saptarshi
     * Description: Replace Field Label Names
     */
    private void replaceFieldName(String fieldSet) {
        ilib_LogEvent.push(LOG_TITLE + '.CasePDFController.replaceFieldName()');
        try {
            Map<String, Schema.SObjectField> mapCaseObj = Schema.SObjectType.Case.fields.getMap();
            mapFieldLabel = new Map<String, String>();
            for (String str : fieldSet.split(',')) {

                mapFieldLabel.put(str, mapCaseObj.get(str).getDescribe().getLabel());
                if(mapCaseObj.get(str).getDescribe().getLabel() == CONTACT_ID) {
                    mapFieldLabel.put(str, CONTACT_NAME);
                }
                if(mapCaseObj.get(str).getDescribe().getLabel() == OWNER_ID) {
                    mapFieldLabel.put(str, CASE_OWNER);
                }
                if(mapCaseObj.get(str).getDescribe().getLabel() == PARENT_CASE_ID) {
                    mapFieldLabel.put(str, PARENT_CASE);
                }
                if(mapCaseObj.get(str).getDescribe().getLabel() == CREATED_BY_ID) {
                    mapFieldLabel.put(str, CREATED_BY);
                }
                if(mapCaseObj.get(str).getDescribe().getLabel() == LASTMODIFIED_BY_ID) {
                    mapFieldLabel.put(str, LASTMODIFIED_BY);
                }
                if(mapCaseObj.get(str).getDescribe().getLabel() == CREATED_DATE) {
                    mapFieldLabel.put(str, DATETIME_OPENED);
                }
                if(mapCaseObj.get(str).getDescribe().getLabel() == CLOSED_DATE) {
                    mapFieldLabel.put(str, DATETIME_CLOSED);
                }
            }
        } catch (Exception e){
            ApexExceptions.emit('CasePDFController.replaceFieldName :', e, ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();

        }
    }

    /**
     *
     *
     * @author Saptarshi
     * Description: get all the fields from layout
     */
    private void getFieldset(List<Metadata.LayoutSection> layoutSections) {
        ilib_LogEvent.push(LOG_TITLE + '.CasePDFController.getFieldset()');
        try {
            for (Metadata.LayoutSection section : layoutSections) {
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null){
                        for (Metadata.layoutItem item : column.layoutItems) {
                            if (item.field != null) {
                                fieldSet = fieldSet + item.field + ',';
                            }
                        }
                    }
                }
            }
        } catch (Exception e){
            ApexExceptions.emit('CasePDFController.getFieldset :', e, ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();
        }
    }

    /**
     *
     *
     * @author Saptarshi
     * Description: Generated PDF based on page layout
     */
    public void getLayouts() {
        ilib_LogEvent.push(LOG_TITLE + '.CasePDFController()');
        try {
            caseId = ApexPages.CurrentPage().getparameters().get('recId').escapeHtml4();
            List<String> lstLayout = new List<String>{ PAGE_LAYOUT };
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.layout, lstLayout);
            Metadata.layout caseLayout = (Metadata.layout)layouts.get(0);
            layoutSections = caseLayout.LayoutSections;

            //add method for the loop
            getFieldset(layoutSections);

            //get all related records
            getRelatedRecords(caseId);

            //Generate Date Time For Header
            userDateTime = String.valueOf(datetime.now().format('yyyy-MM-dd HH:mm:ss', 'GMT'));

            //Skip/Hide certain sections
            chkSkipSections = SKIP_SECTION;

            //skip fields from metadata
            List<String> fieldtoSkip = new List<String>();
            Map<String, Bypass_Case_PDF_Fields__mdt> mapEd = Bypass_Case_PDF_Fields__mdt.getAll();
            for (String fieldSkip : mapEd.keySet()) {
                ilib_LogEvent.message('mapEd data : ' + mapEd.get(fieldSkip).Fields_to_Skip__c);

                fieldtoSkip.add('~'+mapEd.get(fieldSkip).Fields_to_Skip__c+'~');
            }
            System.debug('Skipped Fields :' + fieldtoSkip);
            chkMapKey = string.valueof(fieldtoSkip);

            //Convert Lookup Ids to Name
            apiNameMap = new Map<String, String>();
            
            Map<String, Lookup_to_Name_CasePDF__mdt> mapdata = Lookup_to_Name_CasePDF__mdt.getAll();

            for (String fieldName : mapdata.keySet()) {
                apiNameMap.put(mapdata.get(fieldName).Field_API__c, mapdata.get(fieldName).Name_Field__c);
                fieldIdtoName = fieldIdtoName + mapdata.get(fieldName).Name_Field__c + ' , ';
            }
            System.debug('API Name Map :' + apiNameMap);
            fieldIdtoName = fieldIdtoName.removeEnd(' , ');

            chkMapID = '' ;
            
            //to add all the ID api names
            for(String key :apiNameMap.keySet() ) {
                chkMapID = chkMapID+key;
            }

            fieldSet = fieldSet.removeEnd(',');
            System.debug('fieldset Values :' + fieldSet);
           
            //replace Field name labels
            replaceFieldName(fieldSet);

            String queryString = 'Select ' + fieldSet + ' , ' + fieldIdtoName + ' , '+ CONTACT_QUERY +' from Case where Id =:caseId LIMIT 1';
            System.debug('queryString :' + queryString);

            caseData = Database.query(queryString);
            System.debug('CaseData :'+caseData );

            if (caseData.Status == System.Label.CaseStatusCompleted || caseData.Status == System.Label.CaseStatusClosed || caseData.Status == System.Label.CaseStatusClosedDuplicate){
                caseStatus = 'CLOSED';
            }
            ilib_LogEvent.pop();
        } catch (Exception e){
            ApexExceptions.emit('CasePDFController.getLayouts :', e, ilib_LogEvent.SERVICE);
            ilib_LogEvent.pop();

        }
    }

}