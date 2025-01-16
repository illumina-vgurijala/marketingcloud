/**
*    @author Satya Swain
*    @date   2018-10-23
*    @description    Class to get the Custom Metadata records for Company Code Address based on different conditions 
*    Modification Log:
*   ------------------------------------------------------------------------------------ 
*    Developer                      Date                Description
*    Satya Swain                  2018-10-23          Initial Version
*    Himanshu                2022-03-30               Code Scan Fixes  
*    ------------------------------------------------------------------------------------                  
*/

public with sharing class CompanyCodeAddressesSelector extends ilib_SObjectSelector 
{
  /*
   *   @author Satya Swain       
   *   @date   2018-10-23  
   *   @description  Describe the object
   *
 */
 public Schema.SObjectType getSObjectType()
 {
    return Company_Code_Address__mdt.sObjectType;
 }
  
  /**
   *  @author  Satya Swain
   *  @description Retrieve list of fields for Company Code Address Metadata type 
   *  @return sObjectFieldList list of Schema.SObjectField
   **/
  public List<Schema.SObjectField> getSObjectFieldList()
  {
     return new List<Schema.SObjectField> {
    Company_Code_Address__mdt.Company_Code__c,
		Company_Code_Address__mdt.Company_Name__c,
		Company_Code_Address__mdt.Country__c,
		Company_Code_Address__mdt.Street__c,
		Company_Code_Address__mdt.City__c,
		Company_Code_Address__mdt.Postal_Code__c,
		Company_Code_Address__mdt.PO_Box__c,
		Company_Code_Address__mdt.Currency__c,
		Company_Code_Address__mdt.DeveloperName,
		Company_Code_Address__mdt.MasterLabel,
    Company_Code_Address__mdt.Address_Line_1__c,
    Company_Code_Address__mdt.Address_Line_2__c,
    Company_Code_Address__mdt.Address_Line_3__c,
    Company_Code_Address__mdt.Address_Line_4__c,
    Company_Code_Address__mdt.Address_Line_5__c,
    Company_Code_Address__mdt.Address_Line_6__c,
    Company_Code_Address__mdt.Footer_Full_Street__c,
    Company_Code_Address__mdt.Footer_City__c
     };
  }
  
  /**
   *  @author Satya Swain
   *  @description Fetch Related Company Code Addresses for the Opportunity's Company Code
   *  @param setCompanyCodes set of Company Codes
   *  @return list of Company Code Address records
   **/
  public List<Company_Code_Address__mdt> selectCompanyCodeAddress(Set<String> setCompanyCodes) 
  {
      return (List<Company_Code_Address__mdt>) Database.query(
      newQueryFactory().setCondition('Company_Code__c  IN :setCompanyCodes').toSOQL()
      );
  }
  
}