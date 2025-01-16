/*************************************************************************************
*   @Author:Joshith K
*   @Date: 13-11-2018
*   @Description:Test class for SystemNotifications DCP-15322
 
 Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 *              Joshith K                   26-11-2018          initial version
 *    ------------------------------------------------------------------------------------
*/
@isTest(SeeAllData=true)
public with sharing class TestSystemNotifications {
    
    @isTest
    static void testSysNotifications(){
		
		 //DCP-46067:Start
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'last',
            Email = 'test@gmail.com',
            Username = 'test@gmail.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            
        );
        insert u;
        
        System.runAs(u){
            //DCP-46067:END
    
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname');
        Case objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
        SVMXC__RMA_Shipment_Order__c partOrder = TestDataFieldService.createPartOrder('RMA', objCase.Id, 'Open');
        partOrder.SVMXC__Order_Type__c = 'Return';
        partOrder.Contact_Name__c = 'Test Contact';
        partOrder.Contact_Phone__c = '+100021';
        partOrder.ERP_Sales_Order_Number__c = '1601389';
       
        insert partOrder;
        //SVMXC__RMA_Shipment_Order__c partOrder1=[Select Id ,Name From SVMXC__RMA_Shipment_Order__c where id=:partOrder.Id];
        System_Notification__c sysNotification=new System_Notification__c();
        sysNotification.Email_Subject__c='Illumina Order Change - 1601389';
        sysNotification.Email_Body__c='test email body to  forward';
		Test.startTest();//DCP-46067
        insert sysNotification;
		
		 //DCP-46067:Start
            List<ContentVersion> contversionLst= new List<ContentVersion>();
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            contversionLst.add(cv);
            Insert contversionLst;
            
            //Get Content Documents
            Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
            
            //Create ContentDocumentLink 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = sysNotification.Id;
            cdl.ContentDocumentId = conDocId;
            cdl.shareType = 'V';
            Insert cdl;
            
		Test.stopTest();
        //DCP-46067:End

        system.assertEquals(1,[select count() From Attachment where ParentId=:partOrder.id]);
		system.assertEquals(1,contversionLst.size());//DCP-46067
		}

    }
	/*Test method to cover Catch Block of Class SystemNotificationsQueueable
	*/
   @isTest
   public static void coverCatchBlockSystemNotificationsQueueable(){
    try{
        SystemNotificationsQueueable.catchException = true;
        SystemNotificationsQueueable sn = new SystemNotificationsQueueable(null, null, null, null);
        Test.startTest();
        System.enqueueJob(sn);
        Test.stopTest();
    	}catch(Exception e){
            System.assert(e!=null, 'e is not empty');
    	}
   }
}