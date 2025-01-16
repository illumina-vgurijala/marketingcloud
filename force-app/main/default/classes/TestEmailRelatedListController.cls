/**
* @author Deepika Ayyavari
* @date 31-Aug-2021
*
* @group EmailMessage
* @group-content 
*
* @description Test Class for emailRelatedListClass
* DCP-43125
*/
@IsTest
public class TestEmailRelatedListController {
    
    //setUpData();
    static Case cs = new Case();
    /** dataSetup */
    @testSetup
    public static void setUpData() {
            //insert Account
            Account acc = TestDataAccount.getAccount('Test Acc', 'USD');
            acc.Account_Group__c='Distributor';
            acc.ERP_Customer_Id__c = 'Test1';
            insert acc;
            System.assert(acc.Id != null);
            
            //insert contact
            Contact con = TestDataPerson.getNewContact(acc.Id);
            System.assert(con.id != null);
            
            //insert case
            cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
            System.assert(cs.Id != null);

}
    @IsTest
    static void selectEmailMsgByParentIdTest()
    {
        List<EmailToCase_Creation_Setting__mdt> setE2CAddressesSetting = [SELECT DeveloperName,QueueId__c,Routing_Email__c FROM EmailToCase_Creation_Setting__mdt LIMIT 1];
        List<Case> lstCases = [SELECT Id FROM Case LIMIT 1];
        
        
        EmailMessage objEmail1 = new EmailMessage();
        objEmail1.FromAddress = 'debalchatterjee@deloitte.com';
        objEmail1.Incoming = true;
        objEmail1.ToAddress = setE2CAddressesSetting[0].Routing_Email__c;
        objEmail1.Subject = 'Test email';
        objEmail1.TextBody = 'Hello';
        objEmail1.ParentId = lstCases[0].Id;
        
        
        List<EmailMessage> lstEmailMessage = new List<EmailMessage>();
        lstEmailMessage.add(objEmail1);
        insert lstEmailMessage;
        
        Id setCaseID;
        setCaseID = lstCases[0].Id;
        System.assert(lstEmailMessage.size()!=null);
        
        Test.startTest();
        try{
            emailRelatedListController.getRecords(0, setCaseID);
        }catch(AuraHandledException  e){
            system.assert(e.getMessage().contains('Script-thrown exception'),'Error in Script.');
        }
        Test.stopTest();
        
    } 
}