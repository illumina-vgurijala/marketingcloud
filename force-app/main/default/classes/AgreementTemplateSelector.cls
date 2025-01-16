/**
*    @author Digvijay SIngh
*    @date   2020-05-14
*    @description    DCP-33468: AgreementTemplateSelector class
*    @Test class for 90% coverage: TestAgreementTemplateSelector
*    @Test class for 75% coverage: TestAgreementTemplateSelector
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Digvijay                   14/05/2020          Initial Version

*     ------------------------------------------------------------------------------------ 

*                    
*/
public with sharing class AgreementTemplateSelector extends ilib_SObjectSelector{
    private static final String LOG_TITLE = 'AgreementTemplateSelector';
    private static final String FEATURE_SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    public static boolean catchException = false;
	
	/**
     *  @author - Digvijay
     *  @description - SObjectType The Schema.SObjectType of the Agreement Template
     **/
    public Schema.SObjectType getSObjectType()
    {
        return echosign_dev1__Agreement_Template__c.sObjectType;
    }
    
    /**
    *  @author  Digvijay
    *  @description Retrieve list of fields for echosign_dev1__Agreement_Template__c 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            echosign_dev1__Agreement_Template__c.id,
            echosign_dev1__Agreement_Template__c.Name
            
            

        }; 
            
    }
    
    /**
     *  @author Digvijay
     *  @description Fetch List of Agreement templates
     *  @param  string  
     *  @return List<echosign_dev1__Agreement_Template__c>
     **/
    @AuraEnabled(cacheable=true)
    public Static List<echosign_dev1__Agreement_Template__c> selectAgreementTemplatebyName(String templatename) 
    {
        try{
            if(catchException == true){
                throw new AuraHandledException('throwing custom exception');
               }
         return new AgreementTemplateSelector().selectAgreementTemplatebyNames(templatename);
        }catch(Exception e){
            //get exception message
            catchException = false;
            throw new AuraHandledException(e.getMessage());
            
        }
    } 
    
    /**
     *  @author Digvijay
     *  @description Fetch List of Agreement templates
     *  @param  string  
     *  @return List<echosign_dev1__Agreement_Template__c>
     **/
    public  List<echosign_dev1__Agreement_Template__c> selectAgreementTemplatebyNames(String templatename) 
    {       
        ilib_LogQuery logger=null;
        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger = new ilib_LogQuery(LOG_TITLE + '.selectAgreementTemplatebyNames', templatename);
        
        List<echosign_dev1__Agreement_Template__c> res = (List<echosign_dev1__Agreement_Template__c>) Database.query(
                                    newQueryFactory().setCondition('name =:templatename').toSOQL()
        );
		

        if(Feature.isOn(FEATURE_SERVICE_QUERY_LOGS))
            logger.stop(res.size());
		
        return res;
    } 
 }