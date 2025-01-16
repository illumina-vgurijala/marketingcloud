/**
*    @author: Pankaj 
*    @date:   23-Oct-2018
*    @description:  selector class for CountryRegionMapping MetaData
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        10-Sept-2018        Initial Build
*             Anand Palla                   08-Sept-2021        DCP-48672:Adding IVDR/EU queries
*             Jitesh Lakhwani               6-July-2022         Code Scan fixes of Comments
*             Deep Diwakar                  Mar-04-2024         CMCM-5551: Added new field in default field list
*    ------------------------------------------------------------------------------------ 
*                    
*/
public with sharing class CountryRegionMappingMetaDataSelector extends ilib_SObjectSelector {

    /**
    * @description: CountryRegionMappingMetaDataSelector class Constructor
    * @param : None
    * @return: None
    */
    public CountryRegionMappingMetaDataSelector()
    {
        super(false, false, false, false);
        
    }

    /**
    * @description: Method to retrieve the SObjectType of Country Region Mapping meta-data
    * @param : None
    * @return: Schema.SObjectType
    */
    public Schema.SObjectType getSObjectType()
    {
        return CountryRegionMapping__mdt.sObjectType;
    }
    
    /**
     *  @author  Pankaj Singla
     *  @description Retrieve list of fields for cCountryRegionMapping 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            CountryRegionMapping__mdt.CountryCode__c,
            CountryRegionMapping__mdt.CountryName__c,
            CountryRegionMapping__mdt.Region__c,
            CountryRegionMapping__mdt.Active__c,
            CountryRegionMapping__mdt.id,
            CountryRegionMapping__mdt.Marketability_Rule__c,
            CountryRegionMapping__mdt.Label,
            CountryRegionMapping__mdt.IVDR__c,
            CountryRegionMapping__mdt.EU__c,
            CountryRegionMapping__mdt.Opt_in_Rule__c // CMCM-5551
           
        };
    }
    
    
    
    /**
     *  @author  Pankaj Singla
     *  @description Fetch the list of cCountryRegionMapping where Active is true
     *  
     **/
     
    public List<CountryRegionMapping__mdt> selectCountryRegionMappingMetaRecords() 
    {
        return (List<CountryRegionMapping__mdt>) Database.query(
        newQueryFactory().setCondition('Active__c = true').toSOQL());
    } 
    
    /**
     *  @author  Anand Palla
     *  @description Fetch the list of CountryRegionMapping where IVDR is true
     **/     
    public List<CountryRegionMapping__mdt> selectIVDRCountryRegionMappingMetaRecords() 
    {
        return (List<CountryRegionMapping__mdt>) Database.query(
        newQueryFactory().setCondition('IVDR__c = true').toSOQL());
    }
    
    /**
     *  @author  Anand Palla
     *  @description Fetch the list of CountryRegionMapping where EU is true
     **/ 
    public List<CountryRegionMapping__mdt> selectEUCountryRegionMappingMetaRecords() 
    {
        return (List<CountryRegionMapping__mdt>) Database.query(
        newQueryFactory().setCondition('EU__c = true').toSOQL());
    }
       
}