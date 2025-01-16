/*** @author Maruthi
*    @date   7th Oct 2021
*    @description    Class to get the Custom Metadata records for Informatics Dragen Products metadata
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                    Description
*    Maruthi                       7th Oct 2021            Initial Version
*    ------------------------------------------------------------------------------------                  
*/
public with sharing class DragenProductsSelector extends ilib_SObjectSelector{


    /**
    *  @author  Maruthi
    *  @description Retrieve list of fields for Informatics Dragen Products Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public Schema.SObjectType getSObjectType()
    {
        return Dragen_Products__mdt.sObjectType;
    }    
    
    /**
    *  @author  Maruthi
    *  @description Retrieve list of fields for Informatics Dragen Products Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {        
        return new List<Schema.SObjectField> {                        
            Dragen_Products__mdt.Required_Fields__c,
            Dragen_Products__mdt.Product_Family__c,
            Dragen_Products__mdt.Select_Instance_Type__c,            
            Dragen_Products__mdt.Quote_Line_Item_Fields__c,
            Dragen_Products__mdt.Line_Item__c,
            Dragen_Products__mdt.Read_Only_Fields__c
        };
    }
    /**
    *  @author  Maruthi
    *  @description Retrieve list of fields for Informatics Dragen Products Metadata type 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Dragen_Products__mdt> loadAllInformaticsConfigurations(){
        return (List<Dragen_Products__mdt>) Database.query(
            newQueryFactory()            
            .toSOQL()
        );
    }
}