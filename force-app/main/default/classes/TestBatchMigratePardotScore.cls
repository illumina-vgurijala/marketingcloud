/**
*    @author: Pankaj 
*    @date:   09-Jun-2020
*    @description:  Batch class for BatchMigratePardotScore
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        09-Jun-2019        Initial Development
*             Rishab                        17-Jan-2022        CodeScan Fixes
*    ------------------------------------------------------------------------------------ 
*/
@isTest(SeeAllData = false)
public class TestBatchMigratePardotScore {
	static testMethod void testBatchMethod(){
         Lead objLd=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
         Contact objCon=TestDataMarketing.createContact('testfirstname','testlastname','test123@gmail.com');         
         objLd.put('pi__score__c',2);
         objCon.put('pi__score__c',3);         
         update objLd;
         update objCon;
         Test.startTest();
         Database.executeBatch(new BatchMigratePardotScore('Lead'));
         Database.executeBatch(new BatchMigratePardotScore('Contact'));
         Test.stopTest(); 
         objLd=[select id,Marketing_Score__c from lead where id=:objLd.id];
         System.assertEquals(2,objLd.Marketing_Score__c,'Marketing Score not Updated');
    }
}