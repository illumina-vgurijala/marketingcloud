/**
 *    @author Vaibhav
 *    @date   15 May 2019
 *    @description    Class to get the EmailMessage records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                Description
 *      Shivani Jain                   17 Mar 2022         DCP-51321 Hide potential logos 
 *                                                          and signature from Files list
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public with sharing class EmailMessagesSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'EmailMessagesSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String STRING_INCOMING = 'Incoming';
    private static final String STRING_PARENTID= 'ParentId'; 
   /**
    *  @author Vaibhav
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return EmailMessage.sObjectType;
   }
    
    /**
     *  @author  Vaibhav
     *  @description Retrieve list of fields for Email Message sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
       return new List<Schema.SObjectField> {
           EmailMessage.id
       
       };
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch the Email Messages by Id
     *  @param emailMessageIds
     *  @return List of email 
     **/
    public EmailMessage selectEmailMessages(Set<String> emailMessageIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEmailMessages', UtilsCollection.serializeIds(emailMessageIds));

        EmailMessage res = (EmailMessage) Database.query( 
            newQueryFactory().selectField('RelatedToId')
                             .selectField('IsClientManaged')
                             .selectField('ThreadIdentifier')
                             .selectField('MessageIdentifier')
                             .selectField('IsExternallyVisible')
                             .selectField('ReplyToEmailMessageId')
                             .selectField('IsDeleted')
                             .selectField('MessageDate')
                             .selectField('Status')
                             .selectField('HasAttachment')
                             .selectField(STRING_INCOMING)
                             .selectField('BccAddress')
                             .selectField('CcAddress')
                             .selectField('ToAddress')
                             .selectField('FromAddress')
                             .selectField('FromName')
                             .selectField('Subject')
                             .selectField('Headers')
                             .selectField('HtmlBody')
                             .selectField('TextBody')
                             .selectField('SystemModstamp')
                             .selectField('LastModifiedById')
                             .selectField('LastModifiedDate')
                             .selectField('CreatedDate')
                             .selectField('CreatedById')
                             .selectField('ActivityId') 
                             .selectField('Email_Transfer_Status__c')
                             .selectField(STRING_PARENTID)
                             .setCondition('ID IN : emailMessageIds ').setLimit(1).toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop();

        return res;
    }


    /**
     *  @author Vaibhav
     *  @description Fetch the Email Messages by ParentId - DCP-37828
     *  @param parentIds
     *  @return List of email 
     **/
    public List<EmailMessage> selectEmailMessageByParentId(Set<String> parentIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEmailMessageByParentId', UtilsCollection.serializeIds(parentIds));
        
        List<EmailMessage> res = (List<EmailMessage>) Database.query(
            newQueryFactory().selectField('RelatedToId')
                             .selectField('IsClientManaged')
                             .selectField('ThreadIdentifier')
                             .selectField('MessageIdentifier')
                             .selectField('IsExternallyVisible')
                             .selectField('ReplyToEmailMessageId')
                             .selectField('IsDeleted')
                             .selectField('MessageDate')
                             .selectField('Status')
                             .selectField('HasAttachment')
                             .selectField(STRING_INCOMING)
                             .selectField('BccAddress')
                             .selectField('CcAddress')
                             .selectField('ToAddress')
                             .selectField('FromAddress')
                             .selectField('FromName')
                             .selectField('Subject')
                             .selectField('Headers')
                             .selectField('HtmlBody')
                             .selectField('TextBody')
                             .selectField('SystemModstamp')
                             .selectField('LastModifiedById')
                             .selectField('LastModifiedDate')
                             .selectField('CreatedDate')
                             .selectField('CreatedById')
                             .selectField('ActivityId') 
                             .selectField('Email_Transfer_Status__c')
                             .selectField(STRING_PARENTID)
                             .setCondition('ParentId IN : parentIds ').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description Fetch the Email Messages by Id - DCP-37828
     *  @param emailMessageIds
     *  @return List of email 
     **/
    public List<EmailMessage> selectEmailMessagesByIds(Set<String> emailMessageIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEmailMessagesByIds', UtilsCollection.serializeIds(emailMessageIds));

        List<EmailMessage> res = (List<EmailMessage>) Database.query(
            newQueryFactory().selectField('RelatedToId')
                             .selectField('IsClientManaged')
                             .selectField('ThreadIdentifier')
                             .selectField('MessageIdentifier')
                             .selectField('IsExternallyVisible')
                             .selectField('ReplyToEmailMessageId')
                             .selectField('IsDeleted')
                             .selectField('MessageDate')
                             .selectField('Status')
                             .selectField('HasAttachment')
                             .selectField(STRING_INCOMING)
                             .selectField('BccAddress')
                             .selectField('CcAddress')
                             .selectField('ToAddress')
                             .selectField('FromAddress')
                             .selectField('FromName')
                             .selectField('Subject')
                             .selectField('Headers')
                             .selectField('HtmlBody')
                             .selectField('TextBody')
                             .selectField('SystemModstamp')
                             .selectField('LastModifiedById')
                             .selectField('LastModifiedDate')
                             .selectField('CreatedDate')
                             .selectField('CreatedById')
                             .selectField('ActivityId') 
                             .selectField('Email_Transfer_Status__c')
                             .selectField(STRING_PARENTID)
                             .setCondition('ID IN : emailMessageIds ').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
     * @author: Prashanth
     * @description: fetch the count of emails for a case
     * @params: set of case Ids
     * @return: List<AggregateResult
     */
    public List<AggregateResult> getAggregateResult(String strGroupByField,Set<Id> setCaseIds){
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS )){
            logger = new ilib_LogQuery(LOG_TITLE + '.getAggregateResult', strGroupByField +'|'+ UtilsCollection.serializeIds(setCaseIds));
        }
        String query = 'Select '+strGroupByField+' ,count(id) NumberOfRecord from EmailMessage where ParentId IN: setCaseIds group by '+strGroupByField;
        List<AggregateResult> res = (List<AggregateResult>) Database.query(query);
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS )){
            logger.stop(res.size());
        }
        return res;
    }

/*DCP-43125
Updated by Deepika Ayyavari
* @description Method to sort by MessageDate by desc order
*/

    public string stringSortOrder = 'MessageDate desc';
    /**
     *  @description  getOrderBy
     **/
    public override String getOrderBy(){
         return stringSortOrder;
     }

/*********************************************
    * @description Method to return the list of Email Messages on a Case
    * @param setParentIds parameter which passes caseId
    * @param offSetCount this passes offSetCount to the query
    * @return returns list of emails associated to a case
    * DCP-43125
    * updated by Deepika Ayyavari
    */

    public List<EmailMessage> selectEmailMsgByParentId(Integer offSetCount, set<Id> setParentIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectEmailMsgByParentId',
            UtilsCollection.serializeIds(setParentIds)
        );
        stringSortOrder = 'MessageDate desc';
        ilib_QueryFactory strQuery = newQueryFactory();
                            strQuery.selectField('MessageDate');
                            strQuery.selectField('Status');
                            strQuery.selectField('HasAttachment');
                             strQuery.selectField(STRING_INCOMING);
                             strQuery.selectField('BccAddress');
                             strQuery.selectField('CcAddress');
                             strQuery.selectField('ToAddress');
                             strQuery.selectField('FromAddress');
                             strQuery.selectField('Subject');
                             strQuery.selectField(STRING_PARENTID);
                             strQuery.selectField('ParentId.CaseNumber');
                             strQuery.setCondition('ParentId IN : setParentIds');
                             strQuery.setLimit(2000);  
                             strQuery.setOffSet(offSetCount);        
        //START - DCP-51321
        ilib_QueryFactory attachedContentDocsSelector = new ContentDocumentLinksSelector().addQueryFactorySubselect(strQuery,'ContentDocumentLinks');
        attachedContentDocsSelector.selectField('ContentDocument.ContentSize');
        attachedContentDocsSelector.selectField('ContentDocument.Title');
        attachedContentDocsSelector.setCondition('((NOT ContentDocument.ContentSize < '
            + Label.EnhancedFileExcludeLogo_Size+') OR (NOT ContentDocument.Title LIKE \''+String.escapeSingleQuotes(Label.EnhancedFileExcludeLogo_NamePattern)+'\'))');
        //END - DCP-51321

        List<EmailMessage> res = (List<EmailMessage>) Database.query(strQuery.toSOQL());
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS )) logger.stop(res.size());
            return res;
        
    }

    /*******************************************************************************************************
    * @description DCP-51321 Fetch the Email Messages where Attachments are present by Parent Id  
    * @param parentIds Set<Id>
    * @return List<EmailMessage>
    */
    public List<EmailMessage> selectEmailMsgsByParentWithAttachment(Set<Id> parentIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectEmailMsgsByParentWithAttachment', UtilsCollection.serializeIds(parentIds));

        List<EmailMessage> res = (List<EmailMessage>) Database.query(
            newQueryFactory().selectField('HasAttachment')
                             .setCondition('ParentId IN : parentIds AND hasAttachment = true').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }


    /*******************************************************************************************************
    * @description   
    * @param parentIds Set<Id>
    * @return List<EmailMessage>
    */
    public List<EmailMessage> getEmailMessageFromIds(Set<Id> emailMessageIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getEmailMessageFromIds', UtilsCollection.serializeIds(emailMessageIds));

        List<EmailMessage> res = (List<EmailMessage>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField(STRING_PARENTID)
            .selectField(STRING_INCOMING)
            .selectField('Parent.OwnerId')
            .setCondition('ID IN : emailMessageIds')
            .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
}