/**
*    @author: Pankaj Singla
*    @date:   10-April-2019
*    @description:  Controller class for MasterDataRequest Component and MDRFileUpload Component
*    Modification Log:
*    -----------------------------------------------------------------------------------
*    Developer         Date           Description
*    Pankaj Singla     10-Apr-2019    Initial Build
*    Akshay Mohan      26-Jun-2019    DCP-26543: Edit changes
*    Nishan Shetty     22-Apr-2022    CodeScan Fix-Avoid Literals in If condition 
*    Nesar Mohan       01-Apr-2022    CodeScan Fix
*    Saddam            08-Dec-2022    Codescan Fix , Varaible naming convention. 
*    Enrique Reyes     28-Jun-2024    Use specific contact as target instead of creating & deleting for each email sent.
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class MasterDataRequestController {

    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    private static final String CONTACT_NAME = 'Master Data Request Dummy Contact';
    //End CodeScan Fix

    /**
    *  @author Akshay Mohan
    *  @description To get the assigned page layout for a given Record Type and profile
    *  @param RecordTypeID- RecordTypeId
    *  @return String JSON
    **/
    @AuraEnabled 
    public static String loadPage(String RecordTypeID){
        Map<String,String> mapLabels = new Map<String,String>();
        mapLabels.put('UI_Label_MDG_Cancel_Button',Label.UI_Label_MDG_Cancel_Button);
        mapLabels.put('UI_Label_MDG_Save_Button',Label.UI_Label_MDG_Save_Button);
        mapLabels.put('UI_Label_MDG_Submit_Button',Label.UI_Label_MDG_Submit_Button);

        return '{"name": "'+getPageLayoutAssignment(RecordTypeID)+'",'
                +' "mapLabels": '+JSON.serialize(mapLabels)+'}';
    }
    
    /*
    *  @author Pankaj Singla
    *  @description To delete or fetch latest attachments uploaded
    *  @param docId- FileId
    *  @param linkedId-Master Data Request Record Id
    *  @return List<contentDocumentLink>- Files added to Master Data Request Record
    */
    @AuraEnabled 
    public static List<contentDocumentLink> updateContentDocument(String docId,string linkedid){
        if(docId!=null && docId!='') {
            delete (new ContentDocumentSelector().selectById(docId) );
        }
        return (new ContentDocumentLinksSelector().selectByMasterDataRequestId(linkedid));
    }
    
    
    /*
    *  @author Pankaj Singla
    *  @description To get the assigned page layout for a given Record Type and profile
    *  @param RecordTypeID- RecordTypeId
    *  @return String strPageLayoutName
    */
    @AuraEnabled
    public static String getPageLayoutAssignment(String RecordTypeID){
       String strPageLayoutName='';
        /*This will call tooling api as ProfileLayout object is not supported by SOQL*/
        strPageLayoutName=toolingAPISOQL('select Layout.Name from ProfileLayout where ProfileId = \'' + UserInfo.getProfileId() + '\' AND RecordTypeId = \'' + RecordTypeID + '\'');
        String name = strPageLayoutName.substringBetween('"Name":"', '"');
        return name; 
    }
    
    /*
    *  @author Pankaj Singla
    *  @description To get the Account Object Details for given Account Id
    *  @param AccountId- Id of Account
    *  @return Account
    */
    @AuraEnabled
    public static Account getAccountDetails(String AccountId){
        return (new AccountsSelector().selectLoggedInAccountForUser(AccountId)[0]);
    }
    
    /*
    *  @author Pankaj Singla
    *  @description To get the metadata for the pagelayout
    *  @param pageLayoutName
    *  @return PageLayout
    */
    @AuraEnabled
    public static PageLayout getPageLayoutMetadata(String pageLayoutName) {
        List<String> lstComponentNameList = new List<String>{pageLayoutName};        
        if (String.isBlank(pageLayoutName)) {
            return new PageLayout();
        }        
        /*User Standard MetaData class for fetching layout details*/
        List<Metadata.Metadata> layouts =  
            Metadata.Operations.retrieve(Metadata.MetadataType.Layout, lstComponentNameList);
        if (layouts.size() == INTEGER_ONE) {
            system.debug('  layouts[0]: ' + layouts[0]);
            
            return new PageLayout((Metadata.Layout) layouts[0]);
        }
        
        return new PageLayout();
    }
    /*
    *  @author Pankaj Singla
    *  @description To return the pagelayout name using the Tooling API
    *  @param strQuery
    *  @return PageLayoutName
    */
    static String toolingAPISOQL( String strQuery) {
        
        Http objHttp = new Http();
        HttpRequest objHttpRequest = new HttpRequest();
        objHttpRequest.setEndpoint('callout:Salesforce_Org/services/data/v43.0/tooling/query/?q='+(strQuery.replace(' ', '+')));
        objHttpRequest.setMethod('GET');
        HttpResponse objHttpResponse = objHttp.send(objHttpRequest);
        return objHttpResponse.getBody();
    } 
    /*
    *  @author Pankaj Singla
    *  @description Wrapper class for Page Layout MetaData
    *  
    */
    public class PageLayout { 
        @AuraEnabled
        public List<PageLayoutSection> Sections { get; set; }
        
        /*
        *  @author Pankaj Singla
        *  @description Constructor to initialize the sections variable
        */
        
        public PageLayout() {
            Sections = new List<PageLayoutSection>();
        }
        
        /*
        *  @author Pankaj Singla
        *  @description Parameterized Constructor
        */

        public PageLayout(Metadata.Layout layout) {
            this();

            for (Metadata.LayoutSection section : layout.layoutSections) {
                system.debug('sction name is-'+section);
                if (section.style != Metadata.LayoutSectionStyle.CustomLinks) {
                    Sections.add(new PageLayoutSection(section));
                }
            }
        }
    }
    /*
    *  @author Pankaj Singla
    *  @description Wrapper class for Page Layout Sections
    *  
    */
    public class PageLayoutSection {
        @AuraEnabled
        public List<PageLayoutSectionColumn> Columns { get; set;}
        
        @AuraEnabled
        public String Label { get; set; }
        /*
        *  @author Pankaj Singla
        *  @description Parameterized Constructor
        */
        public PageLayoutSection(Metadata.LayoutSection section ) {
            Columns = new List<PageLayoutSectionColumn>();
            
            Label = section.label;
            
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                Columns.add(new PageLayoutSectionColumn(column));
            }
        }
    }
    /*
    *  @author Pankaj Singla
    *  @description Wrapper class for Page Layout Columns
    *  
    */
    public class PageLayoutSectionColumn { 
        @AuraEnabled
        public List<PageLayoutField> Fields { get; set; }
        /*
        *  @author Pankaj Singla
        *  @description Parameterized Constructor
        */
        public PageLayoutSectionColumn(Metadata.LayoutColumn column) {
            Fields = new List<PageLayoutField>();
            
            if (column.layoutItems == null){ 
                return;
            }

            for (Metadata.LayoutItem item : column.layoutItems) {
                Fields.add(new PageLayoutField(item));
            }
        }
    }
    /*
    *  @author Pankaj Singla
    *  @description Wrapper class for Page Layout Fields
    *  
    */
    public class PageLayoutField {
        @AuraEnabled
        public String APIName { get; set;}
        @AuraEnabled
        public String Behavior {get;set;}
       
        /*
        *  @author Pankaj Singla
        *  @description Parameterized Constructor
        */

        public PageLayoutField(Metadata.LayoutItem item) {
            APIName = item.field;
            Behavior=string.valueof(item.behavior);
        }
    }
    /*
    *  @author Pankaj Singla
    *  @description To update the Process Builder Flag to trigger Email to User
    *  @param strMDRId
    *  @return void
    */
    @AuraEnabled
    public static void handlerFileUploadFinish(String strMDRId){
        List<Master_Data_Request__c> lstMDR=new list<Master_Data_Request__c>();
        /*This flag will trigger process builder to send emails*/
        for(Master_Data_Request__c objMDR :new MasterDataRequestSelector().selectByMDRId(strMDRId)){
            if(objMDR.Trigger_Email__c==false){
                  objMDR.Trigger_Email__c=true; 
                  //DCP-26543: add update by sys flag
                  objMDR.Is_Updated_By_System__c=true;
                  lstMDR.add(objMDR);
            }                                               
        }
        
        if(lstMDR.size()>0){
            update lstMDR;
        }
    }
    /*
    *  @author Pankaj Singla
    *  @description To Send emails to user. Called from process builder
    *  @param lstMDRID
    *  @return void
    */
    @InvocableMethod
    public static void sendEmailAlerts(List<Id> lstMDRID){
        set<String> setTerritoryRegion=new set<String>();
        List<Code_Parameter__mdt> lstCodeParamater;
        List<Messaging.SingleEmailMessage> lstMails = new List<Messaging.SingleEmailMessage>();
        List<id> lstContentDocumentids = new List<id>();
        /*Prefix for code parameter metadata*/
        String mdgRegionalEmails='MDG_Regional_Emails_';
        List<Messaging.EmailFileAttachment> lstAttachments=new List<Messaging.EmailFileAttachment>();
        List<Master_Data_Request__c> lstMDR=new MasterDataRequestSelector().selectByListMDR(lstMDRID);
        Set<String> strSendEmailMetaNames=new Set<String>();
        Map<String,EmailTemplate> strNameToEmailTemplateObj=new Map<String,EmailTemplate>();
        Map<String,String> strToStrMdtNameEmailTempName=new Map<String,String>();
        Map<String,Code_Parameter__mdt> strToCodeParamMap=new map<String,Code_Parameter__mdt>();
        List<Master_Data_Request__c> lstMDRForFlagReset=new List<Master_Data_Request__c>();

        for(Master_Data_Request__c objMDR:lstMDR){
            if(objMDR.Account_Name__r.Territory_Region__c!=null){
                setTerritoryRegion.add(mdgRegionalEmails+objMDR.Account_Name__r.Territory_Region__c);
            }
            strSendEmailMetaNames.add('MDR_'+objMDR.RecordType.DeveloperName);
        }
        
        for(Send_Email_Setting__mdt objSendEmail: new SendEmailSettingSelector().selectSendEmailSettingByDeveloperName(strSendEmailMetaNames)){
            strToStrMdtNameEmailTempName.put(objSendEmail.DeveloperName,objSendEmail.Template_Name__c);
        }
        
        for(EmailTemplate objEmailTmp : new EmailTemplatesSelector().selectByNameOrDeveloperName(strToStrMdtNameEmailTempName.values())){
            strNameToEmailTemplateObj.put(objEmailTmp.DeveloperName,objEmailTmp);
        }
        
        if(!setTerritoryRegion.isEmpty()){
            lstCodeParamater=new CodeParametersSelector().selectCodeParameterByDeveloperName(setTerritoryRegion);
        }
        
        for(Code_Parameter__mdt objCodeParam:lstCodeParamater){
            strToCodeParamMap.put(objCodeParam.DeveloperName,objCodeParam);
        }
        
         /*Get all the attachments related to Master Data Request Record*/      
        for(contentDocumentLink objCDLink : new ContentDocumentLinksSelector().selectByMasterDataRequestIds(lstMDRID)){
               lstContentDocumentids.add(objCDLink.ContentDocumentid); 
        }
        /*Fetch attachment details*/
        
        for ( ContentVersion objCversion : new ContentVersionsSelector().selectByContentDocument(lstContentDocumentids)){
             blob bbWOCFbody = objCversion.versiondata;
             Messaging.EmailFileAttachment fileEFA = new Messaging.EmailFileAttachment();
             fileEFA.setFileName(objCversion.ContentDocument.Title+'.'+objCversion.FileExtension);
             fileEFA.setBody(bbWOCFbody);                                             
            lstAttachments.add(fileEFA);
        }

        Contact objDummyContact = null;
        try{
            objDummyContact = [select Id from Contact where Name = :CONTACT_NAME and Is_Active__c = true limit 1];
        } catch(QueryException queryException) {
            ilib_LogEvent.info('Dummy contact not found, using random contact instead');
            objDummyContact = [select Id from Contact where Is_Active__c = true limit 1];
        }

        if(objDummyContact != null) {
            /*Form Email messages for different record types*/
            for(Master_Data_Request__c objMDR:lstMDR){
                objMDR.Trigger_Email__c=false;
                //DCP-26543: add update by sys flag
                objMDR.Is_Updated_By_System__c=true;
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String strMetaDataName='MDR_'+objMDR.RecordType.DeveloperName;
                String strEmailTemplateName=strToStrMdtNameEmailTempName.get(strMetaDataName);
                Id idEmailTemplateId=strNameToEmailTemplateObj.get(strEmailTemplateName).Id;
                List<String> lstSendTo = new List<String>();
                if(strToCodeParamMap.containsKey(mdgRegionalEmails+objMDR.Account_Name__r.Territory_Region__c)){
                    lstSendTo.add(strToCodeParamMap.get(mdgRegionalEmails+objMDR.Account_Name__r.Territory_Region__c).value__c);
                }
            
                mail.setToAddresses(lstSendTo);
                mail.setTemplateID(idEmailTemplateId); 
                mail.setTargetObjectId(objDummyContact.Id);
                mail.SaveAsActivity=false;
                mail.setTreatTargetObjectAsRecipient(false);
                mail.setWhatId(objMDR.id);
                lstMails.add(mail);
                mail.setFileAttachments(lstAttachments);
            
                lstMDRForFlagReset.add(objMDR);
            } 
        } else {
            ilib_LogEvent.info('objDummyContact is null');
        }
        
        /*Send the emails*/
        System.debug('lstMails: ' + lstMails);
        if(lstMails.size()>0){
            Messaging.SendEmailResult [] lstEmailResults =Messaging.sendEmail(lstMails);
        }
        
        if(!lstMDRForFlagReset.isEmpty()){
            update lstMDRForFlagReset;
        }
        
    }
}