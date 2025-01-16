/**
 *    @author Vignesh Sethuramalingam
 *    @date   10-07-2021
 *    @description :Class to get the SMAttributesTemplateSelector selector.
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      Vignesh                       07-Oct-2021          Initial Version
 *      Sagar                         21-Jul-2022          DCP-54367 : Created new method getAttributesTemplateByTitle()
 *    -------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class SMAttributesTemplateSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'SMAttributesTemplateSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /**
     *  @author Vignesh
     *  @description
     *  @return SObjectType The Schema.SObjectType of the SVMXC__SM_Attributes_Template__c.
     */
    public Schema.SObjectType getSObjectType(){
        return SVMXC__SM_Attributes_Template__c.sObjectType;
    }

    /**
     *  @author  Vignesh
     *  @description Retrieve list of fields for SVMXC__SM_Attributes_Template__c sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            SVMXC__SM_Attributes_Template__c.Id,
            SVMXC__SM_Attributes_Template__c.SVMXC__SM_Template_Json__c,
            SVMXC__SM_Attributes_Template__c.SVMXC__SM_Title__c,
            SVMXC__SM_Attributes_Template__c.SVMXC__SM_Active__c
        };
    }

    /**
     *  @author  Vignesh
     *  @description Retrieve Active list of SVMXC__SM_Attributes_Template__c sObject
     *  @return sObjectFieldList list of SVMXC__Service_Order__c
     */
    public List<SVMXC__SM_Attributes_Template__c> getActiveRecords(){ 
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getActiveRecords');
        }

        List<SVMXC__SM_Attributes_Template__c> res = (List<SVMXC__SM_Attributes_Template__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__SM_Active__c = TRUE')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
   /**
     *  @author  Sheikh Shahnawaz
     *  @description DCP-43632 : Retrieve list of SVMXC__SM_Attributes_Template__c sObject with title in setTitles
     *  @return sObjectFieldList list of SVMXC__SM_Attributes_Template__c
     */
    public List<SVMXC__SM_Attributes_Template__c> getTemplates(Set<String> setTitles) {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getTemplates');
        }
        List<SVMXC__SM_Attributes_Template__c> res = (List<SVMXC__SM_Attributes_Template__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__SM_Title__c IN : setTitles')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }
     /**
     *  @author  Sagar Madkaikar
     *  @description DCP-54367:Retrieve  SVMXC__SM_Attributes_Template__c records with Title
     *  @return sObjectFieldList list of SVMXC__SM_Attributes_Template__c
     */
    public List<SVMXC__SM_Attributes_Template__c> getAttributesTemplateByTitle(Set<String> setTitles){ 
        ilib_LogQuery logger=null;
        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger = new ilib_LogQuery(LOG_TITLE + '.getAttributesTemplateByTitle');
        }

        List<SVMXC__SM_Attributes_Template__c> res = (List<SVMXC__SM_Attributes_Template__c>) Database.query(
            newQueryFactory()
            .setCondition('SVMXC__SM_Title__c IN :setTitles')
            .toSOQL()
        );

        if(Feature.isOn(SERVICE_QUERY_LOGS)){
            logger.stop(res.size());
        }
        return res;
    }

}