/**
*    @author Govind Dubey
*    @date   03 Aug 2018
*    @description  DCP-5311: To fetch Apttus Approval Processes for Quotation
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Govind Dubey                   03 Aug 2018         Initial Version
*    Govind Dubey                   23 Sep 2020         DCP-41751 add fields in select
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class EmailTemplatesSelector extends ilib_SObjectSelector{
    /**
    *  @author Govind Dubey 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType()
    {
        return EmailTemplate.sObjectType;
    }
    
    /**
    *  @author  Govind Dubey
    *  @description Retrieve list of fields for Attachment sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            EmailTemplate.id,
            EmailTemplate.Name,
            EmailTemplate.DeveloperName,
            EmailTemplate.FolderId,
            EmailTemplate.TemplateType,
            EmailTemplate.Markup,
            EmailTemplate.Subject,
            EmailTemplate.encoding, 
            EmailTemplate.isActive,
            //DCP-41751 changes
            EmailTemplate.HtmlValue,
            EmailTemplate.Body,
            EmailTemplate.Subject
        };
    }
    
    /**
    *  @author Govind Dubey 
    *  @description fetch EmailTemplate for the ids passed in the argument
    *  @param idSet set of EmailTemplate ids
    *  @return lstEmailTemplate list of EmailTemplate records
    **/
    public List<EmailTemplate> selectById(Set<ID> idSet) 
    {
        return (List<EmailTemplate>) selectSObjectsById(idSet);
    }
    
    /**
    *  @author Govind Dubey
    *  @description fetch EmailTemplate details via Template DeveloperName
    *  @param setEmailTemplateIds set of Email Template ids
    *  @return list of EmailTemplate records
    **/
    public List<EmailTemplate> selectByNameOrDeveloperName(List<String> lstTemplateName) 
    {
        return (List<EmailTemplate>) Database.query(
            newQueryFactory(false,false,true).setCondition('DeveloperName IN :lstTemplateName').toSOQL()
        );
    }
    
}