/*@ author       : KD
* @ date         : 28-July-2020
* @ Description  : Create CHannelPartner Quota in system
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
*   Developer                  Date                       Description
* ---------------------------------------------------------------------------------------------------------------------------------------

* 
*/
@isTest
public with sharing class TestDataChannelPartnerQuota {
    /*
    *  @AUTHOR:  KD
    *  @DESCRIPTION:This method creates Channel_Partner_Quota__c
    *  @PARAM :  Account Id and Year
    *  @RETURN:  
    */
    public static Channel_Partner_Quota__c getCPQuota(Id idAccountId,String strYear){
        return new Channel_Partner_Quota__c(
                    Name = 'Quota-'+idAccountId+'-'+strYear, 
                    Account_Name__c = idAccountId,
                    Year__c = strYear);
    }
}