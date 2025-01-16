/*    @author: Pankaj 
*    @date:   02-Dec-2019
*    @description:  Test Class for BatchUpdateHashedData
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        02-Dec-2019        Initial Development

*    ------------------------------------------------------------------------------------ 
*                    
*/
@isTest(SeeAllData = false)
public class TestBatchUpdateHashedData{

    static testMethod void testBatchMethod(){
         Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
         Contact con=TestDataMarketing.createContact('testfirstname','testlastname','test123@gmail.com');
         Test.startTest();
         Database.executeBatch(new BatchUpdateHashedData('Lead'));
         Database.executeBatch(new BatchUpdateHashedData('Contact'));
         Test.stopTest(); 
         ld=[select id,Hashed_Email_Id__c from lead where id=:ld.id];
         System.assertNotEquals(null,ld.Hashed_Email_Id__c);
    }


}