/***************************************************************************************************************************************
* NAME         : CaseHistorySelector
* DESCRIPTION  : Selector class for CaseHistory objects
*                    
* @AUTHOR      : 
* @DATE        : 29-Sep-2022  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Saptarshi       29-Sep-2022            QACM-175: Initial Version
* 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class CaseHistorySelector extends ilib_SObjectSelector{
    private static final string  LOG_TITLE = 'CaseHistorySelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    /**
     * implemented method
     */
    public Schema.SObjectType getSObjectType()
    {
        return CaseHistory.sObjectType;
    }
 
    /**
    *  @author  Sagar Madkaikar
    *  @description Retrieve list of fields for CaseHistory Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            CaseHistory.Id,
            CaseHistory.CreatedById,
            CaseHistory.Field,
			CaseHistory.NewValue,
            CaseHistory.OldValue,
			CaseHistory.CreatedDate,
			CaseHistory.CaseId
        }; 
    }

     

    /**
     *  @author Saptarshi
     *  @description Fetch CaseHistory records for given setCaseIds
     *  @param String CaseIds
     *  @return List of CaseHistory records
     */
    public List<CaseHistory> selectCaseHistoryRecords(String caseId) {
        ilib_QueryFactory qualityRecordQuery = newQueryFactory();
        qualityRecordQuery.selectField('Id');
        qualityRecordQuery.selectField('CreatedBy.Name');
        qualityRecordQuery.selectField('NewValue');
        qualityRecordQuery.selectField('OldValue');
		qualityRecordQuery.selectField('NewValue');
        qualityRecordQuery.selectField('CreatedDate')	;
        qualityRecordQuery.selectField('CaseId');

        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseHistorys',caseId);
        }
        List<CaseHistory> res = (List<CaseHistory>) Database.query(
            qualityRecordQuery 
            .setCondition('CaseId = : caseId ')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }
        return res;
    }

}