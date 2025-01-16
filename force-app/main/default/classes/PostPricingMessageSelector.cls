/**
*    @author Akash Kumar
*    @date   2018-10-23
*    @description    Class to get the Custom Metadata records for Post Pricing Message based on different conditions 
*    @ Test class Coverage: 100% - TestGlobalLanguageController.cls
*    @ Test class Coverage: 75% - TestGlobalLanguageController.cls
*    
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Akash Kumar                  2018-10-29          Initial Version
*    Govind Dubey                 2019-03-20          selectPostPricingMessageByDeveloperName
*    ------------------------------------------------------------------------------------                  
*/

public with sharing class PostPricingMessageSelector extends ilib_SObjectSelector 
{
  /**
   *  @return Post_Pricing_Messages__c.sObjectType
   **/
 public Schema.SObjectType getSObjectType()
 {
    return Post_Pricing_Messages__c.sObjectType;
 }
  
  /**
   *  @author  Akash Kumar
   *  @description Retrieve list of fields for Post Pricing Message Metadata type 
   *  @return sObjectFieldList list of Schema.SObjectField
   **/
  public List<Schema.SObjectField> getSObjectFieldList()
  {
     return new List<Schema.SObjectField> {
        Post_Pricing_Messages__c.Name,
		Post_Pricing_Messages__c.Value__c,
		Post_Pricing_Messages__c.PicklistValue__c,
        Post_Pricing_Messages__c.Preferred_Language__c,
        Post_Pricing_Messages__c.Active__c
		
     };
  }
  
  /**
   *  @author Akash Kumar
   *  @description Fetch Post Pricing Message records
   *  @return list of Post Pricing Message records
   **/
  public Post_Pricing_Messages__c selectPostPricingMessage(String sPpmValue) 
  {
      return (Post_Pricing_Messages__c) Database.query(
      newQueryFactory().setCondition(' PicklistValue__c =:sPpmValue ').toSOQL()
      );
  }

/**
   *  @author Akash Kumar
   *  @description Fetch Post Pricing Message records
   *  @return list of Post Pricing Message records
   **/
   public List<Post_Pricing_Messages__c> selectPostPricingMessageByName(String strName){
        String strValue = strName+'%';
        return (List<Post_Pricing_Messages__c>) Database.query(
        newQueryFactory().setCondition(' PicklistValue__c LIKE :strValue ').toSOQL()
        );
    } 
    /**
   *  @author Rishi Sharma
   *  @description Fetch Post Pricing Message records
   *  @return list of Post Pricing Message records
   **/
    public List<Post_Pricing_Messages__c> selectPostPricingMessageByNameAndRegion(String strName, String strRegion){
        String strValue = strName+'%';
        return (List<Post_Pricing_Messages__c>) Database.query(
        newQueryFactory().setCondition(' Preferred_Language__c LIKE :strValue AND Region__c includes (:strRegion) AND  Active__c = true').toSOQL()
        );
    } 
    /**
   *  @author Govind Dubey
   *  @description Fetch Post Pricing Message records
   *  @return list of Post Pricing Message records
   **/
   public List<Post_Pricing_Messages__c> selectPostPricingMessageByDeveloperName(String strName){
        String strValue = strName+'%';
        return (List<Post_Pricing_Messages__c>) Database.query(
        newQueryFactory().setCondition(' Name LIKE :strValue ').toSOQL()
        );
    }  
}