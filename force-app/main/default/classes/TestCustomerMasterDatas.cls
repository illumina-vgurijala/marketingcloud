/**
 *    @author         : Akshay Mohan
 *    @date           :
 *    @description    : Test class for CustomerMasterDatas
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                     Date                Description
 *    Vivek R                       06-Oct-22           Codescan fixes: added comments
 *    ------------------------------------------------------------------------------------------------------------------------------------------------
*/
@isTest(isParallel=true)
private class TestCustomerMasterDatas {

    /**
     *  @author      : Akshay Mohan
     *  @description : Method to test blank String variables
    */
    @isTest
    public static void justCoverIt() {
        // no functionality yet
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_SOLD_TO));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_SHIP_TO));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_BILL_TO));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_PAYER));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_DISTRIBUTOR));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_ULTIMATE_CONSIGNEE));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_PROSPECT));
        System.assert(String.isNotBlank(CustomerMasterDatas.GROUP_LEGACY));

        System.assert(CustomerMasterDatas.ACCOUNT_GROUP_VALUES.size() > 0);

        List<Customer_Master_Data__c> records = new List<Customer_Master_Data__c>();

        String domainClassName = 'CustomerMasterDatas';
        Type constructableClass = Type.forName(domainClassName + '.Constructor');
        ilib_SObjectDomain.IConstructable domainConstructor = (ilib_SObjectDomain.IConstructable)constructableClass.newInstance();
        domainConstructor.construct(records);
    }

}