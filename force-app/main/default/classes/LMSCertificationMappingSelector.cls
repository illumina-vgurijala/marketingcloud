/**
*    @author Vaibhav
*    @date   19 Mar 2021
*    @description  LMSCertificationMapping Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                  Date                   Description
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class LMSCertificationMappingSelector extends ilib_SObjectSelector
{
    private static final String LOG_TITLE = 'LMSCertificationMappingSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    /**
     *  @author  Vaibhav 
     *  @description Retrieve getSObjectType 
     *  @return Schema.SObjectType
     **/
    public Schema.SObjectType getSObjectType()
    {
        return LMS_Certification_Mapping__c.sObjectType;
    }
    
    /**
     *  @author  Vaibhav 
     *  @description Retrieve list of fields for LMS_Certification_Mapping__c sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
       return new List<Schema.SObjectField> {
           LMS_Certification_Mapping__c.Id,
           LMS_Certification_Mapping__c.Name
       };
    }
    
    /**
     *  @author Vaibhav
     *  @description Fetch Mapping for Certification.
     *  @param 
     *  @return 
     **/
    public List<LMS_Certification_Mapping__c> selectProductFamilyByCertificationId(string certificationId) 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectProductFamilyByCertificationId', certificationId);
		
        List<LMS_Certification_Mapping__c> res = (List<LMS_Certification_Mapping__c>) Database.query(
             newQueryFactory().selectField('Product_Family__c')
             .selectField('Certification_Name__c')
             .selectField('Certification_ID__c')
             .selectField('Active__c')
             .setCondition('Certification_ID__c = :certificationId AND Active__c = true')
             .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }

    /**
     *  @author Vaibhav
     *  @description Fetch All Mapping records.
     *  @param 
     *  @return 
     **/
    public List<LMS_Certification_Mapping__c> selectLMSMappingRecords() 
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectLMSMappingRecords');
		
        List<LMS_Certification_Mapping__c> res = (List<LMS_Certification_Mapping__c>) Database.query(
             newQueryFactory().selectField('Product_Family__c')
             .selectField('Certification_Name__c')
             .selectField('Certification_ID__c')
             .selectField('Active__c')
             .toSOQL()
        );
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());

        return res;
    }  
 }