/**
*    @author Govind Dubey
*    @date   20 Oct 2018
*    @description  PartnerAssociations Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*             Govind Dubey                  20 Oct 2018         PartnerAssociations Selector class
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class PartnerAssociationsSelector extends ilib_SObjectSelector  {

		/*
         * Constructor
         */	
    public PartnerAssociationsSelector()
    {
        super(false, false, false, false);
    }

     /*
    * @author Govind Dubey
    * @date   20th Oct 2018
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Partner_Association__c.Id,
            Partner_Association__c.Associated_Channel_Partner__c ,
            Partner_Association__c.Parent_Channel_Partner__c 

        };
    }

    /*
    * @author Govind Dubey
    * @date   20th Oct 2018
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    {
        return Partner_Association__c.sObjectType;
    }
    
    /*
    * @author Govind Dubey
    * @date   20th Oct 2018
    * @description Fetch Related Associated Distributor Partners for the Sold To Account
    * @param accountIds Set of Account Ids
    *
    */
    public List<Partner_Association__c> selectPartners(Set<Id> accountIds) 
    {
        return (List<Partner_Association__c>) Database.query(
        newQueryFactory().setCondition('Associated_Channel_Partner__c IN :accountIds').toSOQL());
    }   

}