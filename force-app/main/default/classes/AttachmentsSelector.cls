/**
*    @author Govind Dubey
*    @date   03 Aug 2018
*    @description  DCP-5311: To fetch ContentDocument for the attached files
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Govind Dubey                   03 Aug 2018         Initial Version
*    Soumya Ranjan Sahu             10 Sept 2018        added getLatestAttachmentByParentId() method
*    Milan Savaliya                 26 OCT 2018         added selectById()
*    Rishab Wali                    17 June 2021        added method to get records by parentId
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class AttachmentsSelector extends ilib_SObjectSelector{
    /**
    *  @author Govind Dubey 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the proposal
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Attachment.sObjectType;
    }
    
    /**
    *  @author  Govind Dubey
    *  @description Retrieve list of fields for Attachment sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Attachment.id,
            Attachment.ParentId
    	};
    }
    
    /**
    *  @author Govind Dubey
    *  @description fetch Attachment details via EmailTemplate Id
    *  @param setEmailTemplateIds set of Email Template ids
    *  @return list of Attachment records
    **/
    public List<Attachment> selectByParentId(Set<Id> setEmailTemplateIds) 
    {
        return (List<Attachment>) Database.query(
            newQueryFactory().setCondition('ParentId IN :setEmailTemplateIds').toSOQL()
        );
    }
	
	private Boolean removeDefaultOrderBy=false;
     /**
    *  @author Soumya Sahu
    *  @description Override Default name Ordering
    *  
    *  @return String for Ordering  
    **/
    public override String getOrderBy() {
        if(removeDefaultOrderBy){
            return 'LastModifiedDate DESC';
        }else{
            return super.getOrderBy();
        }
        
    }   
    /**
    *  @author Soumya Ranjan Sahu
    *  @description fetch Attachment details via Parent Id
    *  @param setParentIds set of Parent Object ids, strAttachmentName- string containing attachment name
    *  @return list of Attachment records
    **/
    public List<Attachment> getLatestAttachmentByParentId(Set<Id> setParentIds,string strAttachmentName) 
    {
        removeDefaultOrderBy=TRUE;
        return (List<Attachment>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .setCondition('ParentId IN :setParentIds'+' AND Name LIKE \'%'+String.escapeSingleQuotes(strAttachmentName)+'%\'').toSOQL()
        );
    }


    
    /**
    *  @author Milan
    *  @description fetch Attachment with Body
    *  @param setAttachmentId set of Attachments ids
    *  @return list of Attachment records
    **/
    public List<Attachment> selectById(Set<String> setAttachmentId) 
    {
        return (List<Attachment>) Database.query(
            newQueryFactory()
                    .selectField('Body')
                    .selectField('Name')
                    .selectField('IsPrivate')
                    .selectField('Description')
                    .setCondition('Id IN :setAttachmentId').toSOQL()
        );
    }
	
	/**
    *  @author Rishab Wali
    *  @description fetch Attachment details via Parent Id
    *  @param setParentIds set of Parent Object ids
    *  @return list of Attachment records
    **/
    public List<Attachment> getAttachmentByParentId(Set<Id> setParentIds) 
    {
        return (List<Attachment>) Database.query(
            newQueryFactory()
            .selectField('Name')
            .selectField('Body')
            .selectField('ParentId')
            .setCondition('ParentId IN :setParentIds')
            .toSOQL()
        );
    }
}