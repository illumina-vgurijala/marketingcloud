/**
*    @author Prashanth Kumar
*    @date   2020-08-28
*    @description    DCP-40109: DupeblockerScenariosSelector class
*    Test Class - TestDupeblockerScenariosSelector
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description     
*    ------------------------------------------------------------------------------------ 
*     Prashanth Kumar                      28/8/2020           original version
*     Rishab Wali                          21/11/2022          [DCP-58632] Added Query Instrumentation           
*/
public with sharing class DupeblockerScenariosSelector extends ilib_SObjectSelector{
    
    private static final String LOG_TITLE = 'DupeblockerScenariosSelector';
    private static final String STRMARKETINGQUERYLOGS = 'MarketingQueryLogs';
    
    /**
     * constructor for this selector class.
     */
	public Schema.SObjectType getSObjectType()
    {
        return CRMfusionDBR101__scenario__c.sObjectType;
    }
    /**
    *  @author  Prashanth Kumar
    *  @description Retrieve list of fields for Dupeblocker Scanrios Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            CRMfusionDBR101__scenario__c.id,
            CRMfusionDBR101__scenario__c.name,
			CRMfusionDBR101__scenario__c.CRMfusionDBR101__Scenario_Type__c
        }; 
    }
    
    /**
    *  @author Prashanth Kumar
    *  @description Return List of dupeblocker scenarios based on the scenario type.
    *  @return List of DupeBlocker Scenarios  
    **/
    public List<CRMfusionDBR101__scenario__c> selectDupeBlockerScenariosByType(String scenarioType) 
    {
        ilib_LogQuery logger = null;

        if (Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.selectDupeBlockerScenariosByType',scenarioType);
        }

        List<CRMfusionDBR101__scenario__c> res = (List<CRMfusionDBR101__scenario__c>) Database.query(newQueryFactory().setCondition('CRMfusionDBR101__Scenario_Type__c =:scenarioType').toSOQL());

        if(Feature.isOn(STRMARKETINGQUERYLOGS)){
            logger.stop(res.size());
        }
        return res;
    }
}