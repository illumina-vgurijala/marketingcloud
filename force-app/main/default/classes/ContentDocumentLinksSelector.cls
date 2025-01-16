/**
*    @author Govind Dubey
*    @date   03 Aug 2018
*    @description  DCP-5311: To fetch ContentDocumentLinks for the attached files
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Govind Dubey                   03 Aug 2018         Initial Version
*    Pankaj Singla					10 Apr 2019			Added methods for Master Data Request Object 
*	 Nishan Shetty                  08 Jun 2021         (SPQ-15) Added selectContentDocumentLinks method
*                                                        to retrieve related contentdocumentlink records.
*    Prem Ranjan                    19/11/2021              DCP-50569 : 
*    Shivani Jain                   29 Nov 2021          DCP-42926 Parts Order Line Optimization 
*    Shivani Jain                   17 Mar 2022          DCP-51321 Hide potential logos & signature 
*                                                        from Files list
*    Avina                          1 Apr 2022          QACM-36  Added selectContentDocumentLinks method to
*                                                       Retrieve contentDocumentLink by content DocumentID. 
*    Gladis                         26-Sep-2022         Added Query Instrumentation
*    Avina                          06 Oct 2022         QACM-175 Created  selectContentDocLinkByEntitytype method to get 
                                                        contentDocumentLink by linked entity type or case id
*    Adithi Acharya                 2023-01-10          Codescan fix (Avoid duplicate literals)
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class ContentDocumentLinksSelector extends ilib_SObjectSelector {
    private static final String SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    private static final String LOG_TITLE = 'ContentDocumentLinksSelector'; //DCP-51321
    private static final String STRING_CONTENT_DOC_ID = 'ContentDocument.id'; //DCP-51321
    private static final String STRING_CONTENT_DOC_TYPE = 'ContentDocument.FileType'; //DCP-51321
    private static final String STRING_CONTENT_DOC_TITLE = 'ContentDocument.Title'; //DCP-51321
    private static final String STRING_CONTENT_DOC_SIZE = 'ContentDocument.ContentSize'; //DCP-51321
    private static final String STRING_CONTENT_DOC_FILEEXTENSION = 'ContentDocument.FileExtension'; //codescanfix


/**
*  @author Govind Dubey 
*  @description  
*  @return SObjectType The Schema.SObjectType of the proposal
**/
    public Schema.SObjectType getSObjectType()
    {
        return ContentDocumentLink.sObjectType;
    }
    
    /**
*  @author  Govind Dubey
*  @description Retrieve list of fields for ContentDocumentLink sObject 
*  @return sObjectFieldList list of Schema.SObjectField
**/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            ContentDocumentLink.id,
                ContentDocumentLink.LinkedEntityId,
                ContentDocumentLink.SystemModstamp,
                ContentDocumentLink.ContentDocumentId
                };
                    }
    /**
    *  @author Govind Dubey
    *  @description fetch ContentDocumentLink and related ContentDocument field details via Linked Entity
    *  @param setQuoteIds set of proposal ids
    *  @return list of ContentDocumentLink records
    **/
    public List<ContentDocumentLink> selectByQuoteId(Set<ID> setQuoteIds) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByQuoteId', UtilsCollection.serializeIds(setQuoteIds));
        }
        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(
            newQueryFactory().selectField(STRING_CONTENT_DOC_ID)
            .selectField(STRING_CONTENT_DOC_TYPE) 
            .selectField(STRING_CONTENT_DOC_TITLE)
            .selectField(STRING_CONTENT_DOC_SIZE)
            .setCondition('LinkedEntityId IN :setQuoteIds').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }
    
    /**
    *  @author Pankaj Singla
    *  @description fetch ContentDocumentLink and related ContentDocument field details via Linked Entity
    *  @param lstMDRID List of Master Data Request ids
    *  @return list of ContentDocumentLink records
    **/
    
    public List<ContentDocumentLink> selectByMasterDataRequestIds(List<Id> lstMDRID) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByMasterDataRequestIds');
        }
        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(
            newQueryFactory().selectField(STRING_CONTENT_DOC_ID)
            .setCondition('LinkedEntityId IN :lstMDRID').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }
    
    
    /**
    *  @author Pankaj Singla
    *  @description fetch ContentDocumentLink and related ContentDocument field details via Linked Entity
    *  @param strLinkedId M
    *  @return list of ContentDocumentLink records
    **/
    public List<ContentDocumentLink> selectByMasterDataRequestId(String strLinkedId) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByMasterDataRequestId', strLinkedId);
        }
        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(
            newQueryFactory().selectField(STRING_CONTENT_DOC_ID)
            .selectField(STRING_CONTENT_DOC_TYPE) 
            .selectField(STRING_CONTENT_DOC_TITLE)
            .selectField(STRING_CONTENT_DOC_SIZE)
            .setCondition('LinkedEntityId = :strLinkedId').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }
     /**
    *  @author Kushagra Desai
    *  @description fetch Files Id for signed docs 
    *  @param parent entity id, Document Title
    *  @return list of ContentDocumentLink records
    **/
    public List<ContentDocumentLink> selectDocumentsWithKey(set<String> setLinkedId, String strKey) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectDocumentsWithKey', strKey);
        }
        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(
            newQueryFactory().selectField(STRING_CONTENT_DOC_ID)
            .selectField(STRING_CONTENT_DOC_TYPE) 
            .selectField(STRING_CONTENT_DOC_TITLE)
            .selectField(STRING_CONTENT_DOC_SIZE)
            .selectField('ContentDocument.Ownerid')
            .setCondition('LinkedEntityId IN :setLinkedId'+' AND ContentDocument.Title LIKE \'%'+String.escapeSingleQuotes(strKey)+'%\'')
                            .addOrdering('SystemModstamp', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }


    /**
    *  @author Vaibhav
    *  @description fetch ContentDocumentLink and related ContentDocument field details via Linked Entity - DCP-37828
    *  @param set<Id> emailMessagesId
    *  @return list of ContentDocumentLink records
    **/
    
    public List<ContentDocumentLink> selectByEmailMessagesRecordIds(set<Id> emailMessagesId) 
    {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectByEmailMessagesRecordIds', UtilsCollection.serializeIds(emailMessagesId));
        }
        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(
            newQueryFactory().selectField(STRING_CONTENT_DOC_ID)
            .selectField(STRING_CONTENT_DOC_TITLE)
            .selectField(STRING_CONTENT_DOC_TYPE)
            .selectField(STRING_CONTENT_DOC_FILEEXTENSION)
            .selectField('ContentDocument.LatestPublishedVersionId')
            .selectField('ContentDocument.LatestPublishedVersion.VersionData')
            .setCondition('LinkedEntityId IN :emailMessagesId').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }

    /*
     *  @author Nishan Shetty
     *  @description Select campaignMember 
     *  @param setLinkedEntityIds Set of LinkedEntity Ids
     *  @return List of ContentDocumentLink
     */
    public List<ContentDocumentLink> selectContentDocumentLinks(Set<Id> setLinkedEntityIds) {
        ilib_LogQuery logger = null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContentDocumentLinks', UtilsCollection.serializeIds(setLinkedEntityIds));
        }
        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(
            newQueryFactory()
            .selectField(STRING_CONTENT_DOC_TYPE) 
            .selectField(STRING_CONTENT_DOC_TITLE)
            .selectField('LinkedEntityId') //DCP-42926
            .selectField('ContentDocumentId') //DCP-42926
            .setCondition('LinkedEntityId IN :setLinkedEntityIds').toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
			logger.stop(res.size());
		}

		return res;
    }

    /*******************************************************************************************************
    * @description DCP-51321 Fetch the ContentDocumentLinks excluding potential logos and signatures  
    * [DO NOT ADD VERSION DATA FIELD else Enhanced Files component will fail in case of larger files] 
    * @param recsSet Set<Id>
    * @return List<ContentDocumentLink>
    */
    public List<ContentDocumentLink> selectContentDocumentLinksWithoutLogos(Set<Id> recsSet) {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContentDocumentLinksWithoutLogos', UtilsCollection.serializeIds(recsSet));
        }
        String strQuery = newQueryFactory()
            .selectField(STRING_CONTENT_DOC_ID)
            .selectField(STRING_CONTENT_DOC_TITLE)
            .selectField(STRING_CONTENT_DOC_TYPE)
            .selectField(STRING_CONTENT_DOC_FILEEXTENSION)
            .selectField('ContentDocument.Title') //175 Start
            .selectField(STRING_CONTENT_DOC_FILEEXTENSION)
            .selectField('ContentDocument.ContentSize') 
            .selectField('ContentDocument.Owner.Name')
            .selectField('ContentDocument.LastViewedDate')//175 End
            .selectField('ContentDocument.CreatedDate')
            .selectField('ContentDocument.LastModifiedDate')
            .selectField(STRING_CONTENT_DOC_SIZE)
            .setCondition('LinkedEntityId IN: recsSet AND ((NOT ContentDocument.ContentSize < '
                + Label.EnhancedFileExcludeLogo_Size+' ) OR (NOT ContentDocument.Title LIKE \''
                +String.escapeSingleQuotes(Label.EnhancedFileExcludeLogo_NamePattern)+'\'))')
            .toSOQL();

        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(strQuery);
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*******************************************************************************************************
    * @description DCP-51321 Fetch the ContentDocumentLinks 
    * [DO NOT ADD VERSION DATA FIELD else Enhanced Files component will fail in case of larger files]  
    * @param emailMessagesId Set<Id>
    * @return List<ContentDocumentLink>
    */
    public List<ContentDocumentLink> selectByEmailMessagesIds(set<Id> emailMessagesId)  {

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectContentDocumentLinksWithoutLogos', UtilsCollection.serializeIds(emailMessagesId));
        }
        String strQuery = newQueryFactory()
        .selectField(STRING_CONTENT_DOC_ID)
        .selectField(STRING_CONTENT_DOC_TITLE)
        .selectField(STRING_CONTENT_DOC_FILEEXTENSION)
        .selectField('ContentDocument.CreatedDate')
        .selectField('ContentDocument.LastModifiedDate')
        .selectField(STRING_CONTENT_DOC_SIZE)
        .setCondition('LinkedEntityId IN :emailMessagesId').toSOQL();

        List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(strQuery);
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

    /*
    *  @author Avina
    *  @description  QACM-36 Select contentDocumentLink by content Document Id
    *  @param setContentDocIds Set of LinkedEntity Ids
    *  @return List of ContentDocumentLink
    */
   public List<ContentDocumentLink> selectContentDocLinkByConDocId(Set<Id> setContentDocIds) {
       ilib_LogQuery logger=null;
       if(Feature.isOn(SERVICE_QUERY_LOGS)) {
           logger = new ilib_LogQuery(LOG_TITLE + '.selectContentDocLinkByConDocId', UtilsCollection.serializeIds(setContentDocIds));
       }
       String strQuery = newQueryFactory()
       .selectField('ContentDocument.FileType') 
       .selectField('ContentDocument.Title')
       .selectField('LinkedEntityId') 
       .selectField('ContentDocumentId')
       .setCondition('ContentDocumentId IN :setContentDocIds').toSOQL();
       List<ContentDocumentLink> res = (List<ContentDocumentLink>) Database.query(strQuery);
       if(Feature.isOn(SERVICE_QUERY_LOGS)) {
           logger.stop(res.size());
       }
       return res;
   }

}