/**
*    @author Pankaj Singla
*    @date   12th November 2018
*    @description    Class to get the Custom Metadata records for Send Email Setting 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Pankaj Singla                  10th Apr 2019          Initial Version
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class SendEmailSettingSelector extends ilib_SObjectSelector{
    /*
        * Method Description:getSObjectType created
    */
    public Schema.SObjectType getSObjectType()
    {
        return Send_Email_Setting__mdt.sObjectType;
    }    
    
    /**
    *  @author  Pankaj Singla
    *  @description Retrieve list of fields for Send Email Setting  type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Send_Email_Setting__mdt.DeveloperName,
                Send_Email_Setting__mdt.Target_Object_Field__c,
                Send_Email_Setting__mdt.Template_Name__c
                
                };
                    }
    /**
    *  @author Pankaj Singla
    *  @description Fetch SendEmailSetting records based on Developer name of metadata
    *  @return list of SendEmailSetting records
    **/
    public List<Send_Email_Setting__mdt> selectSendEmailSettingByDeveloperName(set<String> setSendEmailDeveloperName){
        return (List<Send_Email_Setting__mdt>) Database.query(
            newQueryFactory().setCondition('DeveloperName IN :setSendEmailDeveloperName').toSOQL()
        );
    }
    
}