/**
 * @author Akshay Mohan 
 * @date   31-Aug-2018
 * @description  Selector class for Account_Relationship__c
 * Modification Log:
*  ------------------------------------------------------------------------------------------------------
*   Developer                Date                Description                                                 
*   Akshay Mohan             31-Aug-2018         Original
*   Ashish Kr.               09-Apr-2019         Modified selectByAccountGroupExceptIds | DCP-17249
*   Satya Swain              04 Sep 2019         Added cache for selectbyid method as part of INC0225110
*   B Kamini                 20 Jan 2020         Added method selectCustomerMasterDataIds as part of DCP-31442
*   Himanshu                 30 Mar 2022         Code Scan Fixes 
*   Aman Tyagi               12 Dec 2022         CodeScan Fixes  
*  ------------------------------------------------------------------------------------------------------          
*/
public class CustomerMasterDataSelector extends ilib_SObjectSelector{
    
	/*
    * 	@author Akshay Mohan
    *   @date   31-Aug-2018
    *   @description  Describe the object
    *
    */
	public Schema.SObjectType getSObjectType() {
      return Customer_Master_Data__c.sObjectType;
    }

    /*
    * 	@author Akshay Mohan
    *   @date   31-Aug-2018
    *   @description  Set Select fields
    *
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Customer_Master_Data__c.Id,
            Customer_Master_Data__c.Name,
            Customer_Master_Data__c.Street__c,
            Customer_Master_Data__c.City__c,
            Customer_Master_Data__c.Zip_Postal_Code__c,
            Customer_Master_Data__c.State_Province__c,
            Customer_Master_Data__c.Country__c,
            Customer_Master_Data__c.Country_Code__c,
            Customer_Master_Data__c.ERP_Customer_Id__c,
            Customer_Master_Data__c.Account_Group__c,
            Customer_Master_Data__c.Care_Of__c,
            Customer_Master_Data__c.Mark_For_Deletion__c
       };
    }

    /**
     *  @author Akshay Mohan
     *  @date   30-Aug-2018
     *  @description Fetch the Customer Master Data Record for an Account Id
     *  @param Set<String> setIds
     *  @param List<String> Account Group
     *  @param strName Name of the Customer Master Data
     *  @return Customer_Master_Data__c List 
     * 
    **/
    public List<Customer_Master_Data__c> selectByAccountGroupExceptIds(Set<String> setIds, List<String> lstAccountGroup, String strName)
    {
        strName = '%' + strName + '%';
        return (List<Customer_Master_Data__c>) Database.query(
            newQueryFactory().setCondition(' Account_Group__c IN :lstAccountGroup '
                                            + ' AND ( Name LIKE :strName OR Street__c LIKE :strName OR Zip_Postal_Code__c LIKE :strName OR Care_Of__c LIKE :strName OR ERP_Customer_Id__c LIKE :strName) '
                                            + ' AND Mark_For_Deletion__c = false '
                                           	+ ' AND ID NOT IN :setIds '
                                          ).toSOQL()
        );
    }

    /**
     *  @author Akshay Mohan
     *  @date   30-Aug-2018
     *  @description Fetch the Customer Master Data Record for an Account Id
     *  @param setAccountIds
     *  @param List<String> Account Group
     *  @return Customer_Master_Data__c List 
     * 
    **/
    public List<Customer_Master_Data__c> selectByAccountERPId(Set<String> setAccountERPIds)
    {
    	return (List<Customer_Master_Data__c>) Database.query(newQueryFactory()
    									.setCondition(' ERP_Customer_Id__c IN :setAccountERPIds'
                                                      +' AND Mark_For_Deletion__c = false '
                                                      +' AND Account_Group__c != \'Legacy\''
    									).toSOQL());
    }

   
    // Added by Satya for INC0225110
    private static Map<String, List<Customer_Master_Data__c>> cacheForSelectById = new Map<String, List<Customer_Master_Data__c>>();
     /**
     *  @author Govind Dubey
     *  @description fetch master data for the ids passed in the argument
     *  @param idSet set of customer master data ids
     *  @return Customer Master Data record list
     **/
    public List<Customer_Master_Data__c> selectById(Set<ID> idSet) 
    {   
        String serialized = UtilsCollection.serializeIds(idSet);

        if (cacheForSelectById.containsKey(serialized))
            return cacheForSelectById.get(serialized);

        List<Customer_Master_Data__c> res = (List<Customer_Master_Data__c>) selectSObjectsById(idSet);

        cacheForSelectById.put(serialized, res);
        return res;
    }
	
    /**
     *  @author B Kamini
     *  @date   20-Jan-2020
     *  @description Fetch all the Customer Master Data Record
     *  @param list of Customer ERP numbers on Agreement Line items
     *  @return Customer_Master_Data__c List 
     * 
    **/
    public List<Customer_Master_Data__c> selectByERPId(List<String> customerERPsOnAgreementLineItem)
    {
        return (List<Customer_Master_Data__c>) Database.query(
            newQueryFactory().setCondition('ERP_Customer_Id__c IN :customerERPsOnAgreementLineItem'
                                          ).toSOQL()
        );
    }
}