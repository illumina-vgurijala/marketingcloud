/**
 * @author Akshay Mohan 
 * @date   28-June-2018
 * @description  Test Data creation class for Account_Sales_Area__c
 * Modification Log:
*  ------------------------------------------------------------------------------------ 
*   Developer                Date                Description                                                 
*   Akshay Mohan             28-June-2018         Original
*   Akshay Mohan			 31-Aug-2018		  Add logic for creating with Account
*   Jitesh Lakhwani          21-Feb-2023          Codescan - Avoid unused Variable
*  -----------------------------------------------------------------------------------          
*/
@isTest
public with sharing class TestDataAccountSalesArea {
    /*
    * 	@author Akshay Mohan
    *   @description  Set New Account Sales Area
    */
    public static Account_Sales_Area__c getNewAccountSalesArea(Id accountId, String accountErpKey, String salesOrg, String distChannel, String division, String priceList, String priceListType)
    {
        Account_Sales_Area__c rec = initAccountSalesArea(accountId, accountErpKey, salesOrg, distChannel, division, priceList, priceListType);
        insert rec;
        return rec;
    }
    /*
    * 	@author Akshay Mohan
    *   @description Set Erp Id and default other fields
    */
    public static Account_Sales_Area__c initAccountSalesArea(Id accountId, String accountErpKey, String salesOrg, String distChannel, String division, String priceList, String priceListType)
    {
        String erpId = accountErpKey + '_' + salesOrg + distChannel + division;
        Account_Sales_Area__c  rec = new Account_Sales_Area__c(
            Account__c = accountId,
            Sales_Organization__c= salesOrg,
            Distribution_Channel__c = distChannel,
            Contract_Number__c = erpId,
            ERP_Account_Sales_Area_Id__c = erpId,
            Division__c = division,
            IsInActive__c = false,
            Price_List__c = priceList,
            Price_List_Type__c = priceListType,
            Price_Group__c = TestData.getRandom(4),
            Price_Group_Description__c = TestData.getRandom()
        );
        return rec;
    }

    /*
    * 	@author Akshay Mohan
    *   @date   28-June-2018
    *   @description  Set Account Id and default other fields
    *
    */
    public static Account_Sales_Area__c getAccountSalesArea(String salesOrg, String distChannel,String extId,String division,Boolean isInActive)
    {
        Account_Sales_Area__c  s1 = new Account_Sales_Area__c(
            Sales_Organization__c= salesOrg,
            Distribution_Channel__c = distChannel,
            ERP_Account_Sales_Area_Id__c = extId,
            Division__c = division,
            IsInActive__c = isInActive
        );
        return s1;
    }
    /*
    * 	@author Akshay Mohan
    *   @date   31-Aug-2018
    *   @description Default  fields
    *
    */
	public static Account_Sales_Area__c getAccountSalesArea() {
        return getAccountSalesArea('org1','ch1','178','div1',true);
    }
    /*
    * 	@author Akshay Mohan
    *   @date   31-Aug-2018
    *   @description  Set Account Id and default other fields
    *
    */
    public static Account_Sales_Area__c getAccountSalesArea(String strAccountId) {
        Account_Sales_Area__c  s1 = getAccountSalesArea();
        s1.Account__c = strAccountId;
        return s1;
    }

    /*
    * 	@author Akshay Mohan
    *   @description  Set New Account Sales Area with Erp Id
    */
    public static Account_Sales_Area__c getNewAccountSalesArea(String accountErpId)
    {
        Account_Sales_Area__c asa = initAccountSalesArea(accountErpId);
        insert asa;
        return asa;
    }
    /*
    * 	@author Akshay Mohan
    *   @description  Set New Account Sales Area with Erp Id and Sales Org
    */
    public static Account_Sales_Area__c initAccountSalesArea(String accountErpId)
    {
        String salesOrg = getRandomSalesOrg();
        String distChannel = '01'; // accomodate 02 (distributors?)
        Account_Sales_Area__c asa = new Account_Sales_Area__c(
                Account__r = new Account(ERP_Customer_Id__c = accountErpId),
                Sales_Organization__c = salesOrg,
                Distribution_Channel__c = distChannel,
                Division__c = '00',
                IsInActive__c = false,
                ERP_Account_Sales_Area_Id__c = accountErpId + '-' + salesOrg + distChannel + '00'
        );
        return asa;
    }

    private static String getRandomSalesOrg()
    {
        // TODO
        return 'US01';
    }

}