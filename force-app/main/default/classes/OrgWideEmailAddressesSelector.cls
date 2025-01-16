/**
*    @author Rishab Wali
*    @date   22nd Feb 2021
*    @description    Class to get Org Wide Email Addresses [Test Class - TestApttusProposals]
*    Modification Log:
*   ------------------------------------------------------------------------------------------------
*    Developer                      Date                		Description
*    Rishab Wali                    17 June 2021              Initial Version
*    -----------------------------------------------------------------------------------------------
*/
public with sharing class OrgWideEmailAddressesSelector  extends ilib_SObjectSelector {

    /* getSObjectType method*/
    public Schema.SObjectType getSObjectType()
    {
        return OrgWideEmailAddress.sObjectType;
    }
    
    /**
    *  @author - Rishab Wali
    *  @description - Retrieve list of fields for CLM Preferred Language to Template Metadata type 
    *  @return - sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
                 OrgWideEmailAddress.Id,
                 OrgWideEmailAddress.Address
        };
    }

    /**
    *  @author Rishab Wali
    *  @description Fetch CLM Preferred Language To Template records
    *  @return list of CLM Preferred Language to Template records
    **/
    public List<OrgWideEmailAddress> getOWDAddress(set<String> setAddresses){
    return (List<OrgWideEmailAddress>) Database.query(
        newQueryFactory()
        .setCondition('Address IN :setAddresses')
        .toSOQL()
    );
    }

}