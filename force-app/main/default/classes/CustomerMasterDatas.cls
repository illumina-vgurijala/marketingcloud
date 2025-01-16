/**
* @author : Akshay Mohan
* @date  :
* @description : Domain class for Customer_Master_Data__c object
*
* Modification Log:
*       ------------------------------------------------------------------------------------
*        Developer             Date                 Description
*       Akshay Mohan                              Initial Version
*       Aman Tyagi           30/03/2022            CodeScan Fixes
*       Saddam                           08-Dec-2022             Codescan Fix , Varaible naming convention. 
*       ------------------------------------------------------------------------------------
*/
public with sharing class CustomerMasterDatas extends ilib_SObjectDomain {

    public static final String GROUP_SOLD_TO = 'Sold To'; // Label.AccountGroupSoldTo;
    public static final String GROUP_SHIP_TO = 'Ship To'; // Label.AccountRelationshipShipTo;
    public static final String GROUP_BILL_TO = 'Bill To'; // Label.AccountRelationshipBillTo;
    public static final String GROUP_PAYER = 'Payer'; // Label.AccountGroupPayer;

    public static final String GROUP_DISTRIBUTOR = 'Distributor';
    public static final String GROUP_ULTIMATE_CONSIGNEE = 'Ultimate Consignee';
    public static final String GROUP_PROSPECT = 'Prospect';
    public static final String GROUP_LEGACY = 'Legacy';

    public static final Set<String> ACCOUNT_GROUP_VALUES = new Set<String> {
        GROUP_SOLD_TO, GROUP_PROSPECT, GROUP_DISTRIBUTOR, GROUP_SHIP_TO, GROUP_BILL_TO, GROUP_PAYER, GROUP_ULTIMATE_CONSIGNEE, GROUP_LEGACY,
        'Locker', 'Trunk', 'Importer Of Record', 'Customer Hierarchy', 'Partner Stock'
    };

    /*
    * @Author: Akshay Mohan
    * @Description : parameterized constructor of class CustomerMasterDatas 
    * @param: List<Customer_Master_Data__c> sObjectList
    * @return: NA
    */
    public CustomerMasterDatas (List<Customer_Master_Data__c> sObjectList)
    {
        super(sObjectList);
    }

    /*
    * @Author: Akshay Mohan
    * @Description : class implementing ilib_SObjectDomain
    * @param: null
    * @return: NA
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {

        /*
        * @Author: Akshay Mohan
        * @Description : parameterized constructor for base class
        * @param: List<SObject> sObjectList
        * @return: 
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CustomerMasterDatas(sObjectList);
        }
    }

}