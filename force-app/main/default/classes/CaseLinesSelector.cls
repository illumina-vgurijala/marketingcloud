/**
 *    @author Shashank Singhal
 *    @date   17-08-2018
 *    @description    Class to get the case line records based on different conditions
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *      Developer                      Date                Description
 *      Shashank                         17-Aug-2018        Initial Version
 *      Preetha                       14-Mar-2022        QACM-18 Added method selectShowOnCaseLines to get Show on caselines 
 *      Preetha                       25-Mar-2022        QACM-82 Added method selectIVDCaseLines to get IVD Products
 *    ------------------------------------------------------------------------------------ 
 */
public class CaseLinesSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'CaseLinesSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
	/**  
    *  @author Shashank 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
   public Schema.SObjectType getSObjectType()
   {
        return SVMXC__Case_Line__c.sObjectType;
   }
    
   /**
     *  @author  Shashank 
     *  @description Retrieve list of fields for SVMXC__Case_Line__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {  
       return new List<Schema.SObjectField> {
           SVMXC__Case_Line__c.Id, 
           SVMXC__Case_Line__c.Show_On_Case__c,
           SVMXC__Case_Line__c.SVMXC__Installed_Product__c,
           SVMXC__Case_Line__c.SVMXC__Product__c,
           SVMXC__Case_Line__c.SVMXC__Case__c
       };
    } 
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch caselines for case line ids passed
     *  @return List of case lines
     **/
    public List<SVMXC__Case_Line__c> selectCaseLinesFromId(Set<Id> setCaseLineIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseLinesFromId', UtilsCollection.serializeIds(setCaseLineIds));
		
        List<SVMXC__Case_Line__c> res = (List<SVMXC__Case_Line__c>) Database.query(
           newQueryFactory().selectField('Product_Lot_Number__c')
            				.setCondition(' Id IN :setCaseLineIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
     *  @author Shashank Singhal
     *  @description Fetch caselines for case ids passed
     *  @return List of case Lines
     **/
    public List<SVMXC__Case_Line__c> selectCaseLinesOnCases(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseLinesOnCases', UtilsCollection.serializeIds(setCaseIds));
		
        List<SVMXC__Case_Line__c> res =  (List<SVMXC__Case_Line__c>) Database.query(
           newQueryFactory().selectField('SVMXC__Installed_Product__r.Product_Category__c')
            				.selectField('SVMXC__Product__r.Product_Category__c')
						    .selectField('IVD_Product_Identifier__c')
            				.setCondition(' SVMXC__Case__c IN :setCaseIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	 /**
     *  @author Digvijay
     *  @description Fetch the Cases Lines along with IVD Indicator associated with the IP
     *  @param caseIds
     *  @return List of cases
     **/
    public List<SVMXC__Case_Line__c> selectCaseLinesRelatedtoIP(Set<Id> setIPIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCaseLinesOnCases', UtilsCollection.serializeIds(setIPIds));
		
        List<SVMXC__Case_Line__c> res = (List<SVMXC__Case_Line__c>) Database.query(
            newQueryFactory().selectField('Id')
                            .selectField('Installed_Product_Upgrade_Type__c')
							.selectField('SVMXC__Case__r.status')
                            .selectField('SVMXC__Installed_Product__c')
                            .setCondition(' SVMXC__Installed_Product__c IN : setIPIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Raviteja
     *  @description Case Lines associated with the Proactive Run Detail Record
     *  @param prdIds
     *  @return List of case lines
     **/
    public List<SVMXC__Case_Line__c> fetchCaseLinesForPrd(Set<Id> prdIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.fetchCaseLinesForPrd', UtilsCollection.serializeIds(prdIds));
        }
		
        List<SVMXC__Case_Line__c> res = (List<SVMXC__Case_Line__c>) Database.query(
            newQueryFactory().selectField('Id')
                            .selectField('Proactive_Run_Detail__c')
                            .selectField('SVMXC__Installed_Product__c')
                            .setCondition('Proactive_Run_Detail__c IN : prdIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }

        return res;
    }
    /**
     *  @author Preetha
     *  @description Fetch caselines where Show on Case is true for case line ids passed
     *  @return List of case lines
     **/
    public List<SVMXC__Case_Line__c> selectShowOnCaseLines(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectShowOnCaseLines', UtilsCollection.serializeIds(setCaseIds));
		
        List<SVMXC__Case_Line__c> res = (List<SVMXC__Case_Line__c>) Database.query(
           newQueryFactory().selectField('Show_On_Case__c')
                            .selectField('Id')
                            .selectField('SVMXC__Case__c')
            				.setCondition('SVMXC__Case__c IN : setCaseIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        return res;
    }
    /**
    *  @author Preetha
    *  @description Fetch caselines to validate for IVD
    *  @return List of case lines
    **/
    public List<SVMXC__Case_Line__c> selectIVDCaseLines(Set<Id> setCaseIds){
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectIVDCaseLines', UtilsCollection.serializeIds(setCaseIds));
        List<SVMXC__Case_Line__c> res = (List<SVMXC__Case_Line__c>) Database.query(
           newQueryFactory().selectField('IVD_Product_Identifier__c')
                            .selectField('Id')
                            .selectField('SVMXC__Case__c')
                            .selectField('SVMXC__Product__r.Regulatory_Type__c')
            				.setCondition('SVMXC__Case__c IN : setCaseIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
        return res;
    }
}