/**
*    @author Kristiyan Petkov
*    @date   26 Oct 2018
*    @description  DCP-11002: Prevent Quote Based on Material Attributes
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Kristiyan Petkov               26 Oct 2018         Initial Version
     Kushagra Desai                 7-July-2019         Added selectByProductAndRTPId method
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class ProductSalesAreaSelector extends ilib_SObjectSelector{

	/**
    *  @author Kristiyan Petkov
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Procut Sales Area object
    **/
	public Schema.SObjectType getSObjectType()
    {
        return Product_Sales_Area__c.sObjectType;
    }

        /**
    *  @author  Kristiyan Petkov
    *  @description Retrieve list of fields for Product_Sales_Area__c sObject 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
        	Product_Sales_Area__c.Id,
        	Product_Sales_Area__c.Product__c,
        	Product_Sales_Area__c.Sales_Organization__c,
        	Product_Sales_Area__c.Distribution_Channel__c,
        	Product_Sales_Area__c.Distribution_Chain_Specific_Status__c
    	};
    }


    /**
     *  @author Kristiyan Petkov 
     *  @description fetch Product_Sales_Area__c for the ids passed in the argument
     *  @param idSet set of Product_Sales_Area__c ids
     *  @return Product_Sales_Area__c list of Product_Sales_Area__c records
     **/
    public List<Product_Sales_Area__c> selectByProductId(Set<ID> productIdSet) 
    {
        return (List<Product_Sales_Area__c>) Database.query(
        	newQueryFactory().setCondition('Product__c IN: productIdSet').toSOQL());
    }
    /**
     *  @author Kushagra Desai 
     *  @description 
     *  @param Line item
     *  @return Product_Sales_Area__c list of Product_Sales_Area__c records
     **/
    public List<Product_Sales_Area__c> selectByProductAndRTPId(ID productId, String salesOrg, String distChannel, String strCategory) 
    {
        system.debug('Selector called --'+productId+salesOrg+distChannel);
        return (List<Product_Sales_Area__c>) Database.query(
            newQueryFactory().setCondition('Product__c =: productId AND Distribution_Channel__c =: distChannel AND Sales_Organization__c =: salesOrg AND Category_Group__c =: strCategory').toSOQL());
    }
}