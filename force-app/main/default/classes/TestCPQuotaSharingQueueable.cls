/**
 *    @author Kushagra Desai
 *    @date   10-Nov-2020
 *    @description  Test class for Sharing CP Quota
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------------------
*     Developer                      Date                         Description
    ------------------------------------------------------------------------------------------------------------------------------------------------
 */
@isTest
public with sharing class TestCPQuotaSharingQueueable {
    @testSetup 
    static void setupData(){
        Account acc = TestDataAccount.initAccount();
        acc.ERP_Customer_Id__c = '123456';
        acc.Territory_Region__c = 'AMR';
        acc.Account_Group__c = 'Distributor';  
        Account acc2 = TestDataAccount.initAccount();
        acc2.ERP_Customer_Id__c = '09090';
        List<Account> lstAcc = new List<Account>();
        lstAcc.add(acc);
        lstAcc.add(acc2);
        insert lstAcc;
        Channel_Partner_Quota__c q = TestDataChannelPartnerQuota.getCPQuota(acc2.id,'2020');
        q.Name = 'Quota 0';
        q.Quarter_1__c = 10;
        insert q;
        Contact con1 = TestDataPerson.initContact(acc.Id);
        con1.FirstName = 'TPContact1';
        insert con1;
        Contact con2 = TestDataPerson.initContact(acc2.Id);
        insert con2;
        TestDataUser.updateUserDetailsFuture(con1.Id,'TestPortalUserTP1');
        TestDataUser.updateUserDetailsFuture(con2.Id,'TestPortalUserTP2');
        //TestDataUserTerritory2Association.updateUserDetailsFuture(con3.Id,'TestPortalUserTP2');
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @isTest
    static void testCPQuotaSharing(){
        test.startTest();
        List<Account> lstAccount = [Select id from Account where ERP_Customer_Id__c='123456'];
        Channel_Partner_Quota__c q1 = TestDataChannelPartnerQuota.getCPQuota(lstAccount[0].id,'2020');
        q1.Name = 'Quota 1';
        q1.Quarter_1__c = 10;
        insert q1;
        List<User> objUsr0 = [Select Id from user where Name like 'TestPortalUserTP%'];
        ilib_PartnerSharing objShareClass = (ilib_PartnerSharing)Type.forName('CPQuotaSharingQueueableService').newInstance();
        objShareClass = objShareClass.setUserId(UtilsCollection.getSetOfIds(objUsr0));
        System.enqueueJob(objShareClass);
        test.stopTest();
        User objUsr = [Select Id from user where Name like 'TestPortalUserTP2%'];
        Channel_Partner_Quota__c objQuota = [Select id from Channel_Partner_Quota__c where Name = 'Quota 0'];
        List<Channel_Partner_Quota__Share> lstShare1 = [Select id,parent.Name,rowcause from Channel_Partner_Quota__Share where rowcause = 'Manual' and UserOrGroupId =: objUsr.Id];
        System.assertEquals(1,lstShare1.size(),'Incorrect Share record Created');
        System.assertEquals(objQuota.Id,lstShare1[0].parentId,'Sharing not correct 1');
        User objUsr1 = [Select Id from user where Name like 'TestPortalUserTP1%'];
        List<Channel_Partner_Quota__Share> lstShare2 = [Select id,parent.Name,rowcause from Channel_Partner_Quota__Share where rowcause = 'Manual' and UserOrGroupId =: objUsr1.Id];
        System.assertEquals(1,lstShare2.size(),'Incorrect Share record Created 2');
        System.assertEquals(q1.Id,lstShare2[0].parentId,'Sharing not correct 2');
    }
    /*
    *@author: Kushagra Desai
    *@Desc: Test method 
    */
    @isTest
    static void testCPQuotaSharingContactReparenting(){
        test.startTest();
        Contact objCon = [Select id,AccountId from Contact where Name like 'TPContact1%'];
        List<Account> lstAccount = [Select id from Account where ERP_Customer_Id__c='09090'];
        objCon.AccountId = lstAccount[0].Id;
        update objCon;
        test.stopTest();
        User objUsr = [Select Id from user where Name like 'TestPortalUserTP1%'];
        List<Channel_Partner_Quota__Share> lstShare = [Select id,parentId,rowcause from Channel_Partner_Quota__Share where rowcause = 'Manual' and UserOrGroupId =:objUsr.Id];
        System.assertEquals(1,lstShare.size(),'Incorrect Share record created post user Update');
    }
}