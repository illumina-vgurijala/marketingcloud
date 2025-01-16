/**
 *    @author Sagar Madkaikar
 *    @date   21-07-2022
 *    @description :DCP-54367 : Selector class for SVMXC__SM_IB_Attributes_Template_Instance__c object
 *    Modification Log:
 *    -------------------------------------------------------------------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      Sagar                         21-Jul-2022         Initial Version
 *    -------------------------------------------------------------------------------------------------------------------------------------------------
 */
public with sharing class SMAttributesTemplateInstanceSelector extends ilib_SObjectSelector{

    private static final String LOG_TITLE = 'SMAttributesTemplateInstanceSelector';
    private static final  string SERVICE_QUERY_LOGS = 'ServiceQueryLogs';
    
    /**
     *  @author Sagar
     *  @description
     *  @return SObjectType The Schema.SObjectType of the SVMXC__SM_IB_Attributes_Template_Instance__c.
     */
    public Schema.SObjectType getSObjectType(){
        return SVMXC__SM_IB_Attributes_Template_Instance__c.sObjectType;
    }

    /**
     *  @author  Sagar
     *  @description Retrieve list of fields for SVMXC__SM_IB_Attributes_Template_Instance__c sObject
     *  @return sObjectFieldList list of Schema.SObjectField
     */
    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField> {
            SVMXC__SM_IB_Attributes_Template_Instance__c.Id,
            SVMXC__SM_IB_Attributes_Template_Instance__c.SVMXC__SM_Installed_Product_Id__c,
            SVMXC__SM_IB_Attributes_Template_Instance__c.SVMXC__SM_Attr_Payload__c,
            SVMXC__SM_IB_Attributes_Template_Instance__c.SVMXC__SM_Instance_Template_Id__c
        };
    }

}