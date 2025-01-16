/***************************************************************************************************************************************
* NAME         : QualityRecordSelector
* DESCRIPTION  : QACM-14:Selector class for Quality Record  objects
*                    
* @AUTHOR      : 
* @DATE        : 30-Mar-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       30-Mar-2021           QACM-14: Initial Version
* Gladis                14-Apr-2021           QACM-644 Modified selectQR method to add a child query
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class QualityRecordSelector extends ilib_SObjectSelector{
    private static final string  LOG_TITLE = 'QualityRecordSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /**
     * implemented method
     */
    public Schema.SObjectType getSObjectType()
    {
        return Quality_Record__c.sObjectType;
    }

    /**
    *  @author  Sagar Madkaikar
    *  @description Retrieve list of fields for Quality_Record__c Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Quality_Record__c.Case__c,
            Quality_Record__c.Field_Action_Notification__c,
            Quality_Record__c.EtQ_Number__c,
            Quality_Record__c.EtQ_Integration_Status__c
        }; 
    }

    

    /**
     *  @author Sagar Madkaikar
     *  @description Fetch Quality_Record__c records for given setQRIds
     *  @param Set<Id> setQRIds
     *  @return List of Quality_Record__c records
     */
    public List<Quality_Record__c> selectQR(Set<Id> setQRIds) {
        //QACM-644 Starts
        ilib_QueryFactory qualityRecordQuery = newQueryFactory();
        qualityRecordQuery.selectField('Id');
        qualityRecordQuery.selectField('Case__c');
        qualityRecordQuery.selectField('Case__r.CaseNumber');
        qualityRecordQuery.selectField('Field_Action_Notification__c');
        qualityRecordQuery.selectField('Field_Action_Notification__r.Name')	;
        qualityRecordQuery.selectField('EtQ_Number__c');
        qualityRecordQuery.selectField('CreatedBy.Email');
        qualityRecordQuery.selectField('Source__c');
        qualityRecordQuery.selectField('EtQ_Integration_Status__c');
        ilib_QueryFactory objQRJSelector = new QualityRecordJunctionSelector().addQueryFactorySubselect(qualityRecordQuery,'Quality_Record_Junctions__r');
        objQRJSelector.selectField('Id');

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQR', UtilsCollection.serializeIds(setQRIds));
        }
        List<Quality_Record__c> res = (List<Quality_Record__c>) Database.query(
            qualityRecordQuery //QACM-644 Ends
            .setCondition('ID IN : setQRIds ')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }


        /**
     *  @author Abhinav Gupta
     *  @description Fetch linked Quality Records/Junction records for given Case
     *  @param Id qrjId
     *  @return List of Quality_Record_Junction__c records
     */
    public List<Quality_Record__c> selectQrForCallout(String etqNum) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectQrForCallout');

        List<Quality_Record__c> res = (List<Quality_Record__c>) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('etq_number__c')
            .selectField('Problem_Title__c')
            .setCondition('etq_number__c =: etqNum')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }


}