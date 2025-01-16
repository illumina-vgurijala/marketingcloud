/*** @author Prakhar Kumar
*    @date   3rd December 2019
*    @description    Class to get the Custom Metadata records for Informatics Products metadata
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Prakhar Kumar                  3rd December 2019       Initial Version
*    Jitesh Lakhwani                6-July-2022             Code Scan fixes of Comments
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class InformaticsProductsSelector extends ilib_SObjectSelector{
    
    /**
    * @description: Method to retrieve the SObjectType of Informatics Product meta-data
    * @param : None
    * @return: Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return Informatics_Product__mdt.sObjectType;
    }    
    
    /**
    *  @author  Prakhar Kumar
    *  @description Retrieve list of fields for Informatics Products Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
                Informatics_Product__mdt.DeveloperName,
                Informatics_Product__mdt.MasterLabel,
                Informatics_Product__mdt.Required_Fields__c,
                Informatics_Product__mdt.Product_Family__c,
                Informatics_Product__mdt.Product_Type__c,
                Informatics_Product__mdt.Subscription_Type__c,
                Informatics_Product__mdt.Quote_Line_Item_Fields__c,
                Informatics_Product__mdt.Line_Item__c,
                Informatics_Product__mdt.Read_Only_Fields__c
                };
    }

    /**
    * @description: Method to retrieve all records of Informatics Product meta-data
    * @param : None
    * @return: List<Informatics_Product__mdt>
    */
    public List<Informatics_Product__mdt> loadAllInformaticsConfigurations(){
        return (List<Informatics_Product__mdt>) Database.query(
            newQueryFactory()
            .setCondition('Product_Family__c <> NULL'
                            +' AND Product_Type__c <> NULL'
                            +' AND Subscription_Type__c <> NULL')
            .toSOQL()
        );
    }
}