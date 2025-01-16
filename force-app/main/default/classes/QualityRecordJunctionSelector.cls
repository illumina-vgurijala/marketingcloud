/***************************************************************************************************************************************
* NAME         : QualityRecordJunctionSelector
* DESCRIPTION  : QACM-14:Selector class for Quality Record Junction objects
*                    
* @AUTHOR      : 
* @DATE        : 30-Mar-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       30-Mar-2021           QACM-14: Initial Version
* Abhinav Gupta         07-APR-2021           QACM-14: Added new selector methods
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class QualityRecordJunctionSelector extends ilib_SObjectSelector {
    private static final string  LOG_TITLE = 'QualityRecordSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /**
     * implemented method
     */
    public Schema.SObjectType getSObjectType()
    {
        return Quality_Record_Junction__c.sObjectType;
    }

    /**
    *  @author  Sagar Madkaikar
    *  @description Retrieve list of fields for Quality_Record_Junction__c Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Quality_Record_Junction__c.Case__c,
            Quality_Record_Junction__c.Field_Action_Notification__c,
            Quality_Record_Junction__c.Quality_Record__c,
            Quality_Record_Junction__c.EtQ_Integration_Status__c
        }; 
    }

    /**
     *  @author Sagar Madkaikar
     *  @description Fetch Quality_Record_Junction__c records for given setQRJIds
     *  @param Set<Id> setQRJIds
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record_Junction__c> selectQRJ(Set<Id> setQRJIds) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQRJ', UtilsCollection.serializeIds(setQRJIds));

        List<Quality_Record_Junction__c> res = (List<Quality_Record_Junction__c>) Database.query(
            newQueryFactory()
            .selectField('Id') //QACM-644
            .selectField('Case__c')
            .selectField('Case__r.CaseNumber')
            .selectField('Field_Action_Notification__c')
            .selectField('Field_Action_Notification__r.Name')	
            .selectField('Quality_Record__c')
            .selectField('Quality_Record__r.EtQ_Number__c')
            .selectField('CreatedBy.Email')
            .selectField('EtQ_Integration_Status__c')
            .setCondition('ID IN : setQRJIds ')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Abhinav Gupta
     *  @description Fetch Quality_Record_Junction__c records for given Case
     *  @param Set<Id> setQRJIds
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record_Junction__c> selectQRJForCase(Id caseId, Id qrId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQRJForCase');

        List<Quality_Record_Junction__c> res = (List<Quality_Record_Junction__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Case__c')
            .selectField('Quality_Record__c')
            .setCondition('Case__c =: caseId and Quality_Record__c =: qrId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Abhinav Gupta
     *  @description Fetch Quality_Record_Junction__c records for given FAN
     *  @param Set<Id> setQRJIds
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record_Junction__c> selectQRJForFAN(Id fanId, Id qrId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQRJForFAN');

        List<Quality_Record_Junction__c> res = (List<Quality_Record_Junction__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Field_Action_Notification__c')
            .selectField('Quality_Record__c')
            .setCondition('Quality_Record__c =: qrId and Field_Action_Notification__c =: fanId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Abhinav Gupta
     *  @description Fetch linked Quality Records/Junction records for given Case
     *  @param Id qrjId
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record_Junction__c> selectQRJForCaseLinked(Id qrId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQRJForCaseLinked');

        List<Quality_Record_Junction__c> res = (List<Quality_Record_Junction__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('EtQ_Integration_Status__c')
            .selectField('Quality_Record__r.Id')
            .selectField('Quality_Record__r.Problem_Title__c')
            .selectField('Quality_Record__r.Sites_Impacted__c')
            .selectField('Quality_Record__r.EtQ_Number__c')
            .selectField('Quality_Record__r.CreatedDate')
            .selectField('Quality_Record__r.Quality_Record_Link__c')
            .selectField('Quality_Record__r.External_URL__c')
            .selectField('Quality_Record__r.EtQ_Integration_Status__c')
            .setCondition('Case__c =: qrId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }


    /**
     *  @author Abhinav Gupta
     *  @description Fetch linked Quality Records/Junction records for given Case
     *  @param Id qrjId
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record_Junction__c> selectQRJForFANLinked(Id qrId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQRJForFANLinked');

        List<Quality_Record_Junction__c> res = (List<Quality_Record_Junction__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('EtQ_Integration_Status__c')
            .selectField('Quality_Record__r.Id')
            .selectField('Quality_Record__r.Problem_Title__c')
            .selectField('Quality_Record__r.Sites_Impacted__c')
            .selectField('Quality_Record__r.EtQ_Number__c')
            .selectField('Quality_Record__r.CreatedDate')
            .selectField('Quality_Record__r.Quality_Record_Link__c')
            .selectField('Quality_Record__r.External_URL__c')
            .selectField('Quality_Record__r.EtQ_Integration_Status__c')
            .setCondition('Field_Action_Notification__c =: qrId')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

        /**
     *  @author Saptarshi Das
     *  @description Fetch Quality_Record_Junction__c records for given CaseId
     *  @param String caseId
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record_Junction__c> selectCaseQR(String caseId) {
        //QACM-175 Starts
        ilib_QueryFactory qualityRecordQuery = newQueryFactory();
        qualityRecordQuery.selectField('Id');
        qualityRecordQuery.selectField('Case__c');
        qualityRecordQuery.selectField('Quality_Record__r.Problem_Title__c'); 
        qualityRecordQuery.selectField('Quality_Record__r.EtQ_Number__c');

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseQR', caseId);
        }
        List<Quality_Record_Junction__c> res = (List<Quality_Record_Junction__c>) Database.query(
            qualityRecordQuery //QACM-175 Ends
            .setCondition('Case__c = :caseId ')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }


}