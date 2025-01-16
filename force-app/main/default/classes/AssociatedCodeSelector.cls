/**
*    @author Nitin Sood
*    @date   26-06-2018
*    @description    Class to get the Associated_Codes__c records based on different conditions
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*      Developer                      Date                Description
*     Nitin Sood                     26-June-2018        Initial Version
*     Shashank Singhal               12-July-2018        Changes for DCP-837
*     Shashank Singhal               12-July-2018        Changes for DCP-8176
*     Kushagra Desai                 19-May-2020         Enhanced methods
*     Deepika                        17-May-2021         DCP-38815 createdd the method selectParticularAssociatedCodesOnWorkOrders
*    Susmitha                        26-Aug-2022         QACM-108 Method to Fetch related associated codes on case and work order
*     Avina                          06-Oct-2022         QACM-175 created selectAssociatedCodesWithCases to Fetch the list of associated codes with cases
*    Vijay Masne                     28-March-2024       CMCM-5321 add Has_Logistic_Code__c field in Associated_Codes__c SOQL 
*   ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class AssociatedCodeSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'AssociatedCodeSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';

    private static final String CODEID   = 'Code_ID__c';  
    private static final String CODETYPE = 'Code_Type__c';
    private static final String PARENTCODENAME = 'Parent_Code__r.Name';
    private static final String CASETYPE = 'Case_Type__c';
    private static final String CODETITLENAME = 'Code_Title_Name__c';

    /**
    *  @author  Nitin Sood 
    *  @description Retrieve list of fields for Associated_Codes__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    
    public Schema.SObjectType getSObjectType(){
        return Associated_Codes__c.sObjectType;
    }
    
    /**
    *  @author  Nitin Sood
    *  @description Retrieve list of fields for Associated_Codes__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            Associated_Codes__c.id,
                Associated_Codes__c.Case__c,
                Associated_Codes__c.Associated_Code__c,
                Associated_Codes__c.Code_Notes__c, 
                Associated_Codes__c.Code_Type__c,
                Associated_Codes__c.Product_Class__c ,   
                Associated_Codes__c.Subject__c ,     
                Associated_Codes__c.OwnerId ,
                Associated_Codes__c.Work_Order__c,
                Associated_Codes__c.Code_Title__c,
                Associated_Codes__c.Product_Category__c,
                Associated_Codes__c.Name,
                Associated_Codes__c.Code_ID__c,
                Associated_Codes__c.Parent_Code__c,
                Associated_Codes__c.Case_Type__c,
                //DCP-37793 : Hazard code
                Associated_Codes__c.Code_Title_Name__c,
                Associated_Codes__c.Parent_Code_ID__c,
                Associated_Codes__c.Code_Description__c
                };
                    }
    
    /**
    *  @author Nitin Sood
    *  @description Fetch the list of associated codes associated to cases
    *  @param case ids
    *  @return List of Associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnCases(Set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnCases', UtilsCollection.serializeIds(setCaseIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().selectField('Code_Title__r.Case_Type__c')
                             .selectField('Code_Title__r.Code_Type__c')
                             .selectField('Code_Title__r.Name')
                             .selectField('Case__r.Has_Analysis_Code__c')
                             .selectField('Case__r.Has_Resolution_Code__c')
                             .selectField('Case__r.Has_Verification_Code__c')
                             .selectField('Case__r.Has_Inquiry_Case_Subject_Code__c')
                             .selectField('Case__r.Has_SR_Case_Subject_Code__c')
                             .selectField('Case__r.Has_BI_Case_Subject_Code__c')
                             //DCP-37793 : Hazard code
                             .selectField('Case__r.HasHazardCode__c')
            				 //CMCM-5321 : Has Logistic Code
                             .selectField('Case__r.Has_Logistic_Code__c')
                             .selectField(CODEID)
                             .selectField(CODETITLENAME)
                             .selectField(CODETYPE)
                             .selectField('Work_Order__r.Name')
                             .selectField('Parent_Code_ID__c')
                             .selectField('Product_Category__c')
                             .setCondition('Case__c IN : setCaseIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }  
    
    /**
    *  @author Shashank Singhal
    *  @description Fetch related associated codes on case and work order
    *  @param work order id, case id
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnWOAndCase(string sWorkOrderId, string sParentCaseId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnWOAndCase', sWorkOrderId + '|' + sParentCaseId);
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().selectField('Code_Title__r.Name')
            				 .selectField(PARENTCODENAME)
            				 .selectField('Case__r.CaseNumber')
            				 .setCondition('Work_Order__c = :sWorkOrderId'
                                          +' OR (Case__c = :sParentCaseId'
                                          +' AND Work_Order__c = NULL AND Case__c != NULL)').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

     /**
    *  @author Susmitha - QACM-108
    *  @description Fetch related associated codes on case and work order
    *  @param work order id, case id
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesForWOAndCase(string sWorkOrderId, string sParentCaseId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesForWOAndCase', sWorkOrderId + '|' + sParentCaseId);
        }
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().selectField('Code_Title__c')
            				 .selectField('Parent_Code__c')
                             .selectField('Work_Order__c')
                             .selectField('Case__c')
            				 .selectField('Case__r.CaseNumber')
            				 .setCondition('Work_Order__c = :sWorkOrderId'
                                          +' OR Case__c = :sParentCaseId').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
    
    
    /**
    *  @author Shashank Singhal
    *  @description Fetch related associated codes on work order
    *  @param work order id, code id
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnWO(Id wOId, Id codeID) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnWO', wOId + '|' + codeID);
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().setCondition('Work_Order__c = : wOId'+
                                           ' AND Code_Title__c = : codeID'
                                          ).toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
    
    /**
    *  @author Shashank Singhal
    *  @description Fetch related associated codes on case
    *  @param work order id, code id
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnCase(Id caseId, Id codeID) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnCase', caseId + '|' + codeID);
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().setCondition('Case__c = : caseId'+
                                           ' AND Code_Title__c = : codeID'
                                          ).toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
    *  @author Shashank Singhal
    *  @description Fetch associated codes with associated code ids
    *  @param associated code ids
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodes(set<Id> setAssociatedCodeIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodes', UtilsCollection.serializeIds(setAssociatedCodeIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().setCondition('Id IN : setAssociatedCodeIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
    *  @author Shashank Singhal
    *  @description Fetch associated codes with case and code title
    *  @param case ids, code titles, code type
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnCaseWithCodeTitle(set<Id> setCaseIds, set<string> setCodeTitles, string strCodeType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnCaseWithCodeTitle', UtilsCollection.serializeIds(setCaseIds) + '|' + setCodeTitles + '|' + strCodeType);
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().selectField('Code_Title__r.Name')
            				.setCondition('Case__c IN :setCaseIds AND Code_Title__r.Name IN :setCodeTitles AND Code_Type__c = :strCodeType').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	/**
    *  @author Shashank Singhal
    *  @description Fetch disassociated codes with WO
    *  @param WO Ids
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnWorkOrders(set<Id> setWOIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnWorkOrders', UtilsCollection.serializeIds(setWOIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().setCondition('Work_Order__c IN :setWOIds AND Code_Title__r.Name != \'Code Disassociated\'').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
    *  @author Shashank Singhal
    *  @description Fetch disassociated codes with Case
    *  @param Case Ids
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectNotDisAssociatedCodesOnCase(set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectNotDisAssociatedCodesOnCase', UtilsCollection.serializeIds(setCaseIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().setCondition('Case__c IN :setCaseIds AND Code_Title__r.Name != \'Code Disassociated\'').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	 /**
    *  @author Soumya Ranjan Sahu
    *  @description: Fetch Logistics Code only
    *  @param Associated Code Ids
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectLogisticsAssociatedCodes(set<Id> setAssociatedCodeIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLogisticsAssociatedCodes', UtilsCollection.serializeIds(setAssociatedCodeIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().setCondition('Id IN :setAssociatedCodeIds AND Code_Title__r.Logistics_Supply_Chain_code__c = true').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
    *  @author Soumya Ranjan Sahu
    *  @description: Fetch Logistics Code only
    *  @param Associated Code Ids, case ids
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectLogisticsAssociatedCodesWithCases(set<Id> setAssociatedCodeIds,set<Id> setCaseIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLogisticsAssociatedCodesWithCases', UtilsCollection.serializeIds(setAssociatedCodeIds) + '|' + UtilsCollection.serializeIds(setCaseIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
           newQueryFactory().setCondition('Code_Title__r.Logistics_Supply_Chain_code__c = true AND Case__c IN :setCaseIds AND Code_Type__c= \'Analysis\'').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
	  /**
    *  @author Mandeep Singh
    *  @description Fetch the list of associated codes associated to Work Order
    *  @param Work Orderids
    *  @return List of Associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnWO(Set<Id> setWorkOrderIds) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnWO', UtilsCollection.serializeIds(setWorkOrderIds));
            
        String query = newQueryFactory()
            .selectField('Work_Order__r.Has_Verification_Code__c')
            .selectField('Work_Order__r.Has_Resolution_Code__c')
            .setCondition('Work_Order__c IN :setWorkOrderIds AND (Work_Order__r.SVMXC__Order_Status__c != \'Closed\' AND Work_Order__r.SVMXC__Order_Status__c != \'Completed\')')
            .toSOQL();
    
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(query);
            
        if (Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
    
        return res;
    }    
	
	/**
    *  @author Tapas C
    *  @description Fetch associated codes with case and code title id
    *  @param case ids, code title id
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectAssociatedCodesOnCaseWithCodeIds(set<Id> setCaseIds, set<Id> setCodeTitleIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAssociatedCodesOnCaseWithCodeIds', UtilsCollection.serializeIds(setCaseIds) + '|' + UtilsCollection.serializeIds(setCodeTitleIds));
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory().selectField('Code_Title__r.Name')
            				.setCondition('Case__c IN :setCaseIds AND Code_Title__c IN :setCodeTitleIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
    *  @author Naomi Thammadi
    *  @description Fetch disassociated codes with Case with sort on field
    *  @param Case Ids, sort order, fieldname
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectActiveAssociatedCodesOnCase(set<Id> setCaseIds, String fieldName, String sortOrder) 
    {   
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveAssociatedCodesOnCase', UtilsCollection.serializeIds(setCaseIds) + '|' + fieldName + '|' + sortOrder);
        String strWhereClause = ' Code_Title__r.Name != \'Code Disassociated\''+
                                ' AND Case__c IN: setCaseIds';
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory()
            .selectField('Code_Title__r.Name')
            .selectField(PARENTCODENAME)
            .setCondition(strWhereClause)
            .addOrdering(String.escapeSingleQuotes(fieldName),sortOrder=='ASC'? ilib_QueryFactory.SortOrder.ASCENDING : ilib_QueryFactory.SortOrder.DESCENDING)
            .toSOQL()
            );
			
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
    *  @author Naomi Thammadi
    *  @description Fetch disassociated codes with WO with sort of field
    *  @param WO Ids, sort order, fieldname
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectActiveAssociatedCodesOnWOs(set<Id> setWOIds, Set<Id> setCaseIds, String fieldName, String sortOrder) 
    {
		
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectActiveAssociatedCodesOnWOs', UtilsCollection.serializeIds(setWOIds) + '|' + UtilsCollection.serializeIds(setCaseIds) + '|' + fieldName + '|' + sortOrder);
        String strWhereClause = ' Code_Title__r.Name != \'Code Disassociated\''+
                                ' AND (Case__c IN: setCaseIds'+
                                ' OR Work_Order__c IN :setWOIds)';
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
            newQueryFactory()
            .selectField('Code_Title__r.Name')
            .selectField(PARENTCODENAME)
            .setCondition(strWhereClause)
            .addOrdering(String.escapeSingleQuotes(fieldName),sortOrder=='ASC'? ilib_QueryFactory.SortOrder.ASCENDING : ilib_QueryFactory.SortOrder.DESCENDING)
            .toSOQL()
            );
			
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;

    }
    /**
    * DCP-38815
    *  @author KD
    *  @description Fetch codes with WO of particulate title 
    *  @param 
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> selectParticularAssociatedCodesOnWorkOrders(set<Id> setWOIds,String strCodeTitle) 
    {
        ilib_LogQuery logger = null;
        if (Feature.isOn('SalesQueryLogs')) logger = new ilib_LogQuery(
            LOG_TITLE + '.selectParticularAssociatedCodesOnWorkOrders',
            UtilsCollection.serializeIds(setWOIds)
        );
        String strQuery = newQueryFactory().setCondition('Work_Order__c IN :setWOIds AND Code_Title__r.Name =: strCodeTitle').toSOQL();
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(strQuery);
        if (Feature.isOn('SalesQueryLogs')) logger.stop(res.size());
        return res;
    }

    /**
    *  @author Sudarshan Kataria CMCM-105
    *  @description Fetch related associated codes on case  
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> getAssociatedCodesOnCase(string sCaseId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getAssociatedCodesOnCase', sCaseId);
		
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
                    newQueryFactory().selectField('Id').
                    selectField(CODEID)
                    .selectField(CODETITLENAME)
                    .selectField(CODETYPE)
                    .selectField(CASETYPE)
                    .selectField('Parent_Code_ID__c')
                    .selectField('Code_Description__c')
                    .selectField(PARENTCODENAME).
                    setCondition('Case__c=:sCaseId AND Code_Title__r.Name NOT IN (\'Code Disassociated\')').toSOQL()
                );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    
    /**
    *  @author Sudarshan Kataria CMCM-105
    *  @description Fetch related associated codes from WO Or Case  
    *  @return List of associated codes
    **/
    public List<Associated_Codes__c> getAssociatedCodesFromWorkOrderOrCase(string sWOId, string sCaseId) 
    {
        ilib_LogQuery logger=null;
        String queryCondition = '';
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getAssociatedCodesFromWorkOrderOrCase', sWOId + '|' + sCaseId); 
        if(sCaseId == NULL || sCaseId == ''){
            queryCondition = '(Work_Order__c=:sWOId) AND Code_Title__r.Name NOT IN (\'Code Disassociated\')';
        }else{
            queryCondition = '(Work_Order__c=:sWOId OR Case__c=:sCaseId) AND Code_Title__r.Name NOT IN (\'Code Disassociated\')';
        }
        List<Associated_Codes__c> res = (List<Associated_Codes__c>) Database.query(
                    newQueryFactory().selectField('Id')
                    .selectField(CODEID)
                    .selectField(CODETITLENAME)
                    .selectField(CODETYPE)
                    .selectField(CASETYPE)
                    .selectField('Parent_Code_ID__c')
                    .selectField('Code_Description__c')
                    .selectField(PARENTCODENAME).
                    setCondition(queryCondition).toSOQL()
                );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
}