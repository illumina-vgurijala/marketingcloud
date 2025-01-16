/**
*   @author Akash Kumar
*   @date   2018-07-30
*   @description   US-4113: ProductOptionComponent Selector class
*   Modification Log:
*   ------------------------------------------------------------------------------------ 
*   Developer                Date                Description
*   Akash Kumar              2018-07-30          ProductOptionGroupsSelector Selector Class
*   Joshith k                2018-07-30          DCP-13185 Change Added Sequence Field In getSObjectFieldList
*	Joshith k				 2018-11-05			 DCP 11324 Change Added Method selectProductOptionComponentforproductid Which Returns List Of ProductOptionComponent
*   ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ProductOptionComponentSelector extends ilib_SObjectSelector {

/*
*   @author Akash Kumar
*   @date   2018-07-30
*   @description  Describe the object
*
*/
    public Schema.SObjectType getSObjectType(){
      return Apttus_Config2__ProductOptionComponent__c.sObjectType;
   }

/*
*   @author Akash Kumar
*   @date   2018-07-30
*   @description  Set Select fields
*
*/
    public List<Schema.SObjectField> getSObjectFieldList(){
       return new List<Schema.SObjectField> {
          Apttus_Config2__ProductOptionComponent__c.Id,
          Apttus_Config2__ProductOptionComponent__c.Name,
          Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ComponentProductId__c,
          Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__Sequence__c,
          Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ParentProductId__c,
          Apttus_Config2__ProductOptionComponent__c.Apttus_Config2__ProductOptionGroupId__c
       };
    }
	
	/**
     *  @author Joshith k
     *  @description fetch the Productoptioncomponents on basis of componentproducts
     *  @param Set of productids prodids
     *  @return Apttus_Config2__ProductOptionComponent__c List
    **/    
    public List<Apttus_Config2__ProductOptionComponent__c> selectProductOptionComponentforproductid(Set<id> prodids){

        return (List<Apttus_Config2__ProductOptionComponent__c>) Database.query(
        newQueryFactory().setCondition('Apttus_Config2__ComponentProductId__c IN :prodids').toSOQL());
                         
    }
}