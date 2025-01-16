/**
*    @author Nitin Sood
*    @date   26-06-2018
*    @description    Class to get the Code Library records based on different conditions
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*      Developer                      Date                Description
*     Nitin Sood                     09-July-2018         Initial Version
*     Shashank Singhal               12-July-2018        Changes for DCP-837
*     Kushagra Desai                 11-May-2020         DCP-37793 : Hazard code addition. 
*     Preetha                        09-Mar-2011         QACM-51 - Added Sub_type__c to get the codes based on Case Sub_Type__c
*     Preetha                        31-Aug-2022         QACM-782 Added new method to get the code selectCodeByCodeId
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class CodeLibrarySelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'CodeLibrarySelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs'; 
    private static final String CODEID   = 'Code_ID__c';  
    private static final String CODETYPE = 'Code_Type__c';
    private static final String CASETYPE = 'Case_Type__c';
    private static final String PARENTCODENAME = 'Parent_Code__r.Name';   
    private static final String PARENTPARENTCODE = 'Parent_Code__r.Parent_Code__c'; 
    /**
    *  @author  Nitin Sood 
    *  @description Retrieve list of fields for Code_Library__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    
    public Schema.SObjectType getSObjectType(){
        return Code_Library__c.sObjectType;
    }
    
    /**
    *  @author  Nitin Sood
    *  @description Retrieve list of fields for Code_Library__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    { 
        return new List<Schema.SObjectField> {
            Code_Library__c.id,
            Code_Library__c.Name,
            Code_Library__c.Code_Description__c,
            Code_Library__c.Code_Type__c,
            Code_Library__c.Service_Product_Type__c ,   
            Code_Library__c.Parent_Code__c ,     
            Code_Library__c.OwnerId ,
            Code_Library__c.Product_Category__c,
            Code_Library__c.Code_ID__c,
            Code_Library__c.Case_Type__c,
            Code_Library__c.Case_Sub_Type__c
            };
    }
    
    /**
    *  @author Nitin Sood
    *  @description Fetch code Library records on basis of code type
    *  @param code type
    *  @return List of open cases
    **/
    public List<Code_Library__c> selectCodeLibraryByType(set<String> setCodeType) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibraryByType', UtilsCollection.serializeIds(setCodeType));
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            newQueryFactory()
            .selectField('Parent_Code__r.Case_Type__c')
            .selectField('Parent_Code__r.Code_Description__c')
            .selectField(PARENTPARENTCODE)
            .selectField('Parent_Code__r.Code_Type__c')
            .setCondition('Code_Type__c In : setCodeType').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }  
    /**
    *  @author Shashank Singhal
    *  @description Fetch code Library records on basis of code title
    *  @param code title
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibraryByTitle(set<String> setCodeTitle) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibraryByTitle', UtilsCollection.serializeIds(setCodeTitle));
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            newQueryFactory().selectField(CASETYPE).setCondition('Name IN : setCodeTitle'
                                          ).toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 

    /**
    *  @author Nitin Sood
    *  @description Fetch code Library records on basis of Ids
    *  @param code title
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibraryById(set<Id> setCodeLibraryId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibraryById', UtilsCollection.serializeIds(setCodeLibraryId));
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            newQueryFactory().selectField(CASETYPE).setCondition('Id IN : setCodeLibraryId'
                                          ).toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
	
    /**
    *  @author Naomi Thammadi
    *  @description Fetch code Library records on basis of similar code title
    *  @param code title, Set of Code Library Ids
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibraryBySimilarTitle(String strCodeSearch, Set<Id> codeLibIds , String fieldName, String sortOrder) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibraryBySimilarTitle', strCodeSearch+'|'+ UtilsCollection.serializeIds(codeLibIds)+'|'+fieldName+'|'+sortOrder);
		//QACM-51 added case_sub_Type__c in the query
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            'select Id,Name,Code_Description__c,Code_Type__c,Parent_Code__c ,Product_Category__c,Code_ID__c,Case_Type__c,Case_Sub_Type__c from Code_Library__c where ( Name Like :strCodeSearch OR Name Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' ) AND Name <> \'Code Disassociated\' AND Inactive__c <> true AND ID NOT IN: codeLibIds ORDER BY '+String.escapeSingleQuotes(fieldName) +' '+String.escapeSingleQuotes(sortOrder)
            //newQueryFactory().selectField('Case_Type__c').setCondition('( Name Like :strCodeSearch OR Name Like \'%'+strCodeSearch+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+strCodeSearch+'%\' ) AND Inactive__c <> true AND ID NOT IN: codeLibIds').toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
    
    /**
    *  @author Naomi Thammadi
    *  @description Fetch code Library records on basis of similar code title and Code Type
    *  @param code title, code type, Set of Code Library Ids
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibrBySimilarTitleAndType(String strCodeSearch, String strCodeType, Set<Id> codeLibIds, String fieldName, String sortOrder) 
    {
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibrBySimilarTitleAndType', strCodeSearch+'|'+ strCodeType+'|'+UtilsCollection.serializeIds(codeLibIds)+'|'+ fieldName+'|'+ sortOrder);
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
           'select Id,Name,Code_Description__c,Code_Type__c,Parent_Code__c ,Product_Category__c,Code_ID__c,Case_Type__c from Code_Library__c where ( Name Like :strCodeSearch OR Name Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' ) AND Name <> \'Code Disassociated\' AND Code_Type__c=: strCodeType AND Inactive__c <> true AND ID NOT IN: codeLibIds ORDER BY '+String.escapeSingleQuotes(fieldName) +' '+String.escapeSingleQuotes(sortOrder)
           //newQueryFactory().selectField('Case_Type__c').setCondition('( Name Like :strCodeSearch OR Name Like \'%'+strCodeSearch+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+strCodeSearch+'%\' ) AND Code_Type__c=: strCodeType AND Inactive__c <> true AND ID NOT IN: codeLibIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
    
    /**
    *  @author Naomi Thammadi
    *  @description Fetch code Library records on basis of similar code title, Code Type and case type
    *  @param code title, code type, case type, Set of Code Library Ids
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibrByTitleCodeTypeCaseType(String strCodeSearch, String strCodeType, String strCaseType, Set<Id> codeLibIds, String fieldName, String sortOrder) 
    {
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibrByTitleCodeTypeCaseType', strCodeSearch+'|'+ strCodeType+'|'+ strCaseType+'|'+ UtilsCollection.serializeIds(codeLibIds)+'|'+ fieldName+'|'+ sortOrder);
		
        List<Code_Library__c> res =  (List<Code_Library__c>) Database.query(
            'select Id,Name,Code_Description__c,Code_Type__c,Parent_Code__c ,Product_Category__c,Code_ID__c,Case_Type__c from Code_Library__c where ( Name Like :strCodeSearch OR Name Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' ) AND Name <> \'Code Disassociated\' AND Code_Type__c=: strCodeType AND Case_Type__c =:strCaseType AND Inactive__c <> true AND ID NOT IN: codeLibIds ORDER BY '+String.escapeSingleQuotes(fieldName) +' '+String.escapeSingleQuotes(sortOrder)
            //newQueryFactory().selectField('Case_Type__c').setCondition('( Name Like :strCodeSearch OR Name Like \'%'+strCodeSearch+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+strCodeSearch+'%\' ) AND Code_Type__c=: strCodeType AND Case_Type__c =:strCaseType AND Inactive__c <> true AND ID NOT IN: codeLibIds').toSOQL()
        );
		
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
    *  @author Preetha 
    *  @description Fetch code Library records on basis of similar code title, Code Type and case type and Case subtype
    *  @param code title, code type, case type,case subtype, Set of Code Library Ids
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibrByCodeTypeAndSubType(String strCodeSearch, String strCodeType, String strCaseType,String strCaseSubType, Set<Id> codeLibIds, String fieldName, String sortOrder) 
    {
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibrByTitleCodeTypeCaseTypeSubType', strCodeSearch+'|'+ strCodeType+'|'+ strCaseType+'|'+strCaseSubType+'|'+ UtilsCollection.serializeIds(codeLibIds)+'|'+ fieldName+'|'+ sortOrder);
		
        List<Code_Library__c> res =  (List<Code_Library__c>) Database.query(
            'select Id,Name,Code_Description__c,Code_Type__c,Parent_Code__c ,Product_Category__c,Code_ID__c,Case_Type__c,Case_Sub_Type__C from Code_Library__c where ( Name Like :strCodeSearch OR Name Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR '+'Code_ID__c Like :strCodeSearch OR Code_ID__c Like \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' ) AND Name <> \'Code Disassociated\' AND Code_Type__c=: strCodeType AND Case_Type__c =:strCaseType AND (Case_Sub_Type__C = null OR Case_Sub_Type__C INCLUDES (:strCaseSubType)) AND Inactive__c <> true AND ID NOT IN: codeLibIds ORDER BY '+String.escapeSingleQuotes(fieldName) +' '+String.escapeSingleQuotes(sortOrder)
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
        logger.stop(res.size());

        return res;
    }   
    /**
    *  @author KD
    *  @description DCP-37793 : Fetch code Library records on basis of similar code title, Code Type and case type for HAZARD ONLY
    *  @param code title, code type, case type, Set of Code Library Ids
    //DCP-37793 : Hazard code
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibrByHazard(String strCodeSearch, String strCodeType, String strCaseType, Set<Id> codeLibIds, String fieldName, String sortOrder) 
    {
        String strWhereClause = '(Name LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Name =: strCodeSearch'+
                                ' OR Parent_Code__r.Name LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Parent_Code__r.Name =: strCodeSearch'+
                                ' OR Code_ID__c LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Code_ID__c =: strCodeSearch'+
                                ' OR Code_ID__c LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Code_ID__c =: strCodeSearch)'+
                                ' AND Name != \'Code Disassociated\''+
                                ' AND Code_Type__c=: strCodeType'+
                                ' AND Case_Type__c =:strCaseType'+
                                ' AND Inactive__c != true'+
                                ' AND ID NOT IN: codeLibIds'+
                                ' AND Parent_Code__c != NULL';
								
								
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibrByHazard', strCodeSearch+'|'+strCodeType+'|'+ strCaseType+'|'+UtilsCollection.serializeIds(codeLibIds)+'|'+fieldName+'|'+sortOrder);
		
        List<Code_Library__c> res =(List<Code_Library__c>) Database.query(
            newQueryFactory()
            .selectField(PARENTCODENAME)
            .setCondition(strWhereClause)
            .addOrdering('Code_ID__c', ilib_QueryFactory.SortOrder.ASCENDING)
            .toSOQL()
            );
			
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
	
	    /******************************************************
    *  @author Deepika Ayyavari
    *  @description DCP-43515 : Fetch code Library records on basis of similar code title, Code Type and case type for Logistics Review Code ONLY
    *  @param code title, code type, case type, Set of Code Library Ids
   
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibrByLogisticsReviewCode(String strCodeSearch, String strCodeType, String strCaseType, Set<Id> codeLibIds, String fieldName, String sortOrder) 
    {
        String strWhereClause = '(Name LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Name =: strCodeSearch'+
                                ' OR Parent_Code__r.Name LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Parent_Code__r.Name =: strCodeSearch'+
                                ' OR Code_ID__c LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Code_ID__c =: strCodeSearch'+
                                ' OR Code_ID__c LIKE \'%'+String.escapeSingleQuotes(strCodeSearch)+'%\' OR Code_ID__c =: strCodeSearch)'+
                                ' AND Name != \'Code Disassociated\''+
                                ' AND Code_Type__c=: strCodeType'+
                                ' AND Case_Type__c =:strCaseType'+
                                ' AND Inactive__c != true'+
                                ' AND ID NOT IN: codeLibIds';
                               // ' AND Parent_Code__c != NULL';
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibrByLogisticsReviewCode', strCodeSearch+'|'+strCodeType+'|'+ strCaseType+'|'+ UtilsCollection.serializeIds(codeLibIds)+'|'+ fieldName+'|'+sortOrder);
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            newQueryFactory()
            .selectField(PARENTCODENAME)
            .setCondition(strWhereClause)
            .addOrdering('Code_ID__c', ilib_QueryFactory.SortOrder.ASCENDING)
            .toSOQL()
            );
			
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
		
    } 
  /*********************************************************************/ 
    
    /**
    *  @author Naomi Thammadi
    *  @description Fetch disassociated code Library record
    *  @param code title
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectDisassocaiatedCodeLibrary() 
    {
        
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectDisassocaiatedCodeLibrary');
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            newQueryFactory().setCondition('Name = \'Code Disassociated\'').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    } 
    
    /**
    *  @author Naomi Thammadi
    *  @description Fetch code Library records on basis of code id
    *  @param code Ids
    *  @return List of Code Library
    **/
    public List<Code_Library__c> selectCodeLibraryByIds(Set<id> setCodeIds) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeLibraryByIds', UtilsCollection.serializeIds(setCodeIds));
		
        List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
            newQueryFactory().selectField(CASETYPE)
                             .selectField(PARENTCODENAME)
                             .selectField('Parent_Code__r.Code_ID__c')
                             .selectField('Parent_Code__r.Case_Type__c')
                             .selectField('Parent_Code__r.Code_Description__c')
                             .selectField('Parent_Code__r.Code_Type__c')
                             .selectField(PARENTPARENTCODE)
                             .selectField('Parent_Code__r.Parent_Code__r.Name')
                             .selectField('Parent_Code__r.Parent_Code__r.Code_ID__c')
                             .setCondition('Id IN :setCodeIds').toSOQL()
        );
		
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
    /**
     *  @author Preetha
     *  @description Fetch the Code by ids - QACM-782
     *  @param String codeId
     *  @return Code_Library__c
     */
    public Code_Library__c selectCodeByCodeId(Id codeId) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.selectCodeByCodeId', codeId);
        }

            Code_Library__c res = (Code_Library__c) Database.query(
            newQueryFactory()
            .selectField('Id')
            .selectField('Name')   
            .setCondition('ID = : codeId')
            .toSOQL()
        );

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS)) {
            logger.stop(res == null ? 0 : 1);
        }

        return res;
    }

    /**
    *  @author Sudarshan Kataria CMCM-105
    *  @description Fetch Code Library by Case Type  
    *  @return List of associated codes
    **/
    public List<Code_Library__c> getCodeLibraryByCaseType(String sCaseType) 
    {
        String queryCondition = ''; 
        if(sCaseType == NULL || sCaseType == ''){
            queryCondition = '(Name = \'Code Disassociated\' OR Code_Type__c = \'Verification\' OR Code_Type__c = \'Product\' OR Code_Type__c = \'Resolution\') AND Inactive__c=false';
        }else{
            queryCondition = '(Name = \'Code Disassociated\' OR Case_Type__c = :sCaseType OR Case_Type__c = \'\') AND Inactive__c=false';
        } 
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.getCodeLibraryByCaseType', sCaseType);
		
            List<Code_Library__c> res = (List<Code_Library__c>) Database.query(
                newQueryFactory().selectField('Id')
                .selectField('Name')
                .selectField(CODEID)
                .selectField('Code_Description__c')
                .selectField(CODETYPE)
                .selectField(CASETYPE)
                .selectField(PARENTCODENAME)
                .selectField('Parent_Code__c')
                .selectField('Parent_Code__r.Case_Type__c')
                .selectField('Parent_Code__r.Code_Description__c')
                .selectField('Parent_Code__r.Code_Type__c')
                .selectField(PARENTPARENTCODE).
                setCondition(queryCondition).toSOQL()
            ); 

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }
}
