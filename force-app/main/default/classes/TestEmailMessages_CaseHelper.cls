/**
* @author PA
* @date 23rd June 2022
*
* @description DCP-52665 Test class for Queueable Class related to Email Messages to update case fields 
*/ 
@isTest
public class TestEmailMessages_CaseHelper {
        private static final String METHOD_UPDATEGROUPINGFIELDRECORDS_ON_CASE = 'updateCaseGroupingField';

        /**
        * Date - 23rd June 2022
        * Description - To cover the function updateCaseGroupingField from EmailMessages_CaseHelper class
        * @author PA
        */
        @isTest
        public static void updateCaseGroupingFieldTest() {
            List<Case> cases = new List<Case>();

            // Loop to create and add 3 case records to the list
            for (Integer i = 0; i < 3; i++) {
                Case c = new Case();
                c.Subject = 'Om Test' + i;  
                c.Status = 'New';
                c.Priority = 'Medium';
                c.Origin = 'Email';
                cases.add(c);
            }

            // Insert all cases in one DML operation
            insert cases;

            // Assert to check that all cases were inserted
            for (Case c : cases) {
                System.assert(c.Id != null, 'Case record not inserted.');
            }


            List<EmailMessage> emailList  = new List<EmailMessage>();
            //Insert emailmessage for case
            EmailMessage email = new EmailMessage();
            email.FromAddress = 'test@abc.org';
            email.Incoming = True;
            email.ToAddress= 'test@xyz.org';
            email.CcAddress = Label.Email2CaseInstrumentServiceId;
            email.Subject = 'Test email';
            email.HtmlBody = 'Test email body';
            email.ParentId = cases[0].Id; 
            insert email;
            System.assert(email.Id != null, 'Record Not Insterted.');
            
            emailList.add(email);
           
            EmailMessage emailObj = new EmailMessage();
            emailObj.FromAddress = 'test@abc.org';
            emailObj.Incoming = True;
            emailObj.CcAddress = Label.Email2CaseInstrumentServiceId;
            emailObj.ToAddress= 'test@xyz.org';
            emailObj.Subject = 'Test email';
            emailObj.HtmlBody = 'Test email body';
            emailObj.ParentId = cases[1].Id; 
            insert emailObj;
            System.assert(emailObj.Id != null, 'Record Not Insterted.');

            emailList.add(emailObj);

          //CMCM-9331 start
            EmailMessage emailObj1 = new EmailMessage();
            emailObj1.FromAddress = Label.Email2CaseFromAddressPartek;
            emailObj1.Incoming = true;
            //emailObj1.CcAddress = Label.Email2CaseInstrumentServiceId;
            emailObj1.CcAddress = 'test1234@xyz.org';
            emailObj1.ToAddress = 'test123@xyz.org';
            emailObj1.Subject = 'Test email 123';
            emailObj1.HtmlBody = 'Test email 123 body';
            emailObj1.ParentId = cases[2].Id; 
            insert emailObj1;
            System.assert(emailObj1.Id != null, 'EmailMessage record not inserted.');

            emailList.add(emailObj1);
          //CMCM-9331 end

            EmailMessages_CaseHelper emailClsObj = new EmailMessages_CaseHelper(METHOD_UPDATEGROUPINGFIELDRECORDS_ON_CASE, emailList);
            Test.startTest();
              System.enqueueJob(emailClsObj);
            Test.stopTest();

            Case caseObj = [SELECT Id, Grouping__c FROM Case WHERE Id = :cases[2].Id LIMIT 1];
            System.assertEquals('Software', caseObj.Grouping__c, 'Grouping field was not updated correctly for the second email.');
        
            
        }
}
