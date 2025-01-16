/**
*   @author Akash Kumar
*   @date   2018-07-30
*   @description   US-4113: ProductOptionGroup Selector class
*   Modification Log:
*   ------------------------------------------------------------------------------------ 
*   Developer                Date                Description
*   Akash Kumar              2018-07-30          ProductOptionGroupsSelector Selector Class
*   ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ProductOptionGroupsSelector extends ilib_SObjectSelector {

/*
* 	@author Akash Kumar
*   @date   2018-07-30
*   @description  Describe the object
*
*/
	public Schema.SObjectType getSObjectType(){
      return Apttus_Config2__ProductOptionGroup__c.sObjectType;
   }

/*
* 	@author Akash Kumar
*   @date   2018-07-30
*   @description  Set Select fields
*
*/
    public List<Schema.SObjectField> getSObjectFieldList(){
       return new List<Schema.SObjectField> {
          Apttus_Config2__ProductOptionGroup__c.Id,
          Apttus_Config2__ProductOptionGroup__c.Name  
          //add ProductOptionComponent fields as required, adds fields in the inner query
       };
    }

/**
 *  @author Akash Kumar
 *  @description Fetch the Related Options
 *  @param recordIds Set of ProductOptionsGroup Ids
 *  @return Apttus_Config2__ProductOptionGroup__c List with related Options
**/
    public List<Apttus_Config2__ProductOptionGroup__c> selectByIdWithOptionGroups(Set<Id> recordIds){

      // avoid burning SOQL
      if (recordIds.isEmpty())
        return new list<Apttus_Config2__ProductOptionGroup__c>(); 

      ilib_QueryFactory query = newQueryFactory();
      //query.setCondition('Id IN :recordIds');
      query.setCondition('Apttus_Config2__ProductId__r.Id IN :recordIds');
 
      //add configureQueryFactoryFields for related Product2 records(Apttus_Config2__ProductId__r)
      ilib_SObjectSelector productsSelector = new ProductsSelector();
      productsSelector.configureQueryFactoryFields(query, 'Apttus_Config2__ProductId__r');
 
      //System.debug('@@@@query at line 69==>' +query);
      ilib_QueryFactory optionGrpQuery = query.subselectQuery('Apttus_Config2__Options__r').
                                        selectFields( new ProductOptionComponentSelector().getSobjectFieldList() ).
                                        selectField('Apttus_Config2__ComponentProductId__r.ProductCode').
                                        selectField('Apttus_Config2__ComponentProductId__r.Apttus_Config2__ConfigurationType__c');
      
        System.debug('@@@query==> '+query.toSOQL() );
        System.debug('the optionGrpQuery string formed==> ' +optionGrpQuery.toSOQL());
      return (List<Apttus_Config2__ProductOptionGroup__c>) Database.query( query.toSOQL() );
   }  

}