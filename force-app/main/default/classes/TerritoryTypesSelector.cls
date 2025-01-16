/* TerritoryTypesSelector class
* NAME         : TerritoryTypesSelector
* DESCRIPTION  : Selector Class for TerritoryTypesSelector.
*                    
* @AUTHOR : 
* @DATE   : 
*   
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*            Nishan Shetty                  9-Aug-2021          Added new Static Value TYPE_TERRITORY_VAD_CP in selectKnownTypes method
*                                                               and query instrumentation for CMCP-23.
*    -----------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class TerritoryTypesSelector extends ilib_SObjectSelector {

    private static final String LOG_TITLE = 'TerritoryTypesSelector';
    private static final String FEATURE_SALES_QUERY_LOGS = 'SalesQueryLogs';
    
    /*
    *  @author 
    *  @description  Constructor
    */
    public TerritoryTypesSelector() {
        super(false, false, false, false);
        //m_orderBy = ''; 
    }
    
    /*
    *  @author 
    *  @description  Retrieve list of fields for TerritoryTypes sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    */
    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            Territory2Type.Id,
            Territory2.DeveloperName
        };
    }
    
    /*
    *  @author 
    *  @description
    *  @return SObjectType The Schema.SObjectType of the proposal
    */
    public Schema.SObjectType getSObjectType() {
        return Territory2Type.sObjectType;
    }
    
    /*
     * @author
     * @date 
     * @description  get territory types records
     */
    public List<Territory2Type> selectKnownTypes() {   
        Set<String> knownTypes = new Set<String> {
            TerritoryTypesService.TYPE_TERRITORY,
            TerritoryTypesService.TYPE_DISTRICT,
            TerritoryTypesService.TYPE_SUBREGION,
            TerritoryTypesService.TYPE_BU,
            TerritoryTypesService.TYPE_REGION,
            TerritoryTypesService.TYPE_TERRITORY_CP,
            TerritoryTypesService.TYPE_TERRITORY_VAD_CP
        };

        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
           logger = new ilib_LogQuery(LOG_TITLE + '.selectKnownTypes', UtilsCollection.serializeIds(knownTypes));
        }

        List<Territory2Type> res= (List<Territory2Type>) Database.query(
            newQueryFactory(true)
                .setCondition('DeveloperName IN :knownTypes')
                .toSOQL()
        );

        if(Feature.isOn(FEATURE_SALES_QUERY_LOGS)) {
            logger.stop(res == null ? 0 : 1);
        }

        return res;
 
    }
}