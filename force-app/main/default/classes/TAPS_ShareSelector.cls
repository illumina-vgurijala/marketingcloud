/**
*    @Author: Todd Newman
*    @Date:   
*    @Description:   This class contains the implementations for sharing records	
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                                      Initial Version
          Nesar Mohan                 2022-03-30           CodeScan Fix - Add code comments
*    ---------------------------------------------------------------------------------------------------------------------------
**/

public without sharing class TAPS_ShareSelector extends ilib_SObjectSelector implements TAPS_ISelector {

    private final String LOG_TITLE = 'TAPS_ShareSelector';

    private Schema.SObjectType sobjectType;
    private String parentFieldName = 'ParentId';
    private String manualCause = 'Manual';

    /*
    *  @Author      : Todd Newman
    *  @Description : TAPS_ShareSelector constructor to initialize the specific SObject that holds sharing records
    *  and to get the name of the field on the Share table that refers to the parent record ID
    *  @Param       : TAPS_IBatch
    *  @Return      : void
    */

    public TAPS_ShareSelector(TAPS_IBatch batchSupport)
    {
        super(false, false, false, false);
        this.sobjectType = batchSupport.getShareObjectType();
        this.parentFieldName = batchSupport.getShareParentFieldName();
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : DCP-42122 TAPS_ShareSelector constructor to initialize the specific SObject that holds sharing records
    *  and to get the name of the field on the Share table that refers to the parent record ID
    *  @Param       : ilib_ShareFactory
    *  @Return      : void
    */

    public TAPS_ShareSelector(ilib_ShareFactory shareSupport)
    {
        super(false, false, false, false);
        this.sobjectType = shareSupport.getShareObjectType();
        this.parentFieldName = shareSupport.getShareParentFieldName();
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the sobjectType
    *  @Param       : None
    *  @Return      : Schema.SObjectType
    */

    public Schema.SObjectType getSObjectType()
    {
        return sobjectType;
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method to return the list of fields
    *  always the same except for the ParentId field
    *  @Param       : None
    *  @Return      : List<Schema.SObjectField>
    */

    public List<Schema.SObjectField> getSObjectFieldList()
    {
        Map<String, Schema.SObjectField> fieldMap = getSObjectType().getDescribe().fields.getMap();

        return new List<Schema.SObjectField> {
            fieldMap.get('Id'),
            fieldMap.get(parentFieldName),
            fieldMap.get('UserOrGroupId'),
            fieldMap.get('RowCause')
        };
    }

    /*
    *  @Author      : Todd Newman
    *  @Description : Method returns manual shares related to passed-in recordIds
    *  @Param       : Set<Id>
    *  @Return      : List<SObject>
    */
    
    public List<SObject> selectManualByParentId(Set<Id> recordIds)
    {
        ilib_LogQuery logger;
        if (Feature.isOn('SalesQueryLogs')) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectManualByParentId',
            UtilsCollection.serializeIds(recordIds)
        );

        List<SObject> res = Database.query(
            newQueryFactory(true)
            .setCondition(parentFieldName + ' IN :recordIds AND RowCause = :manualCause')
            .toSOQL()
        );

        if (Feature.isOn('SalesQueryLogs')) logger.stop(res.size());
        return res;
    }

}