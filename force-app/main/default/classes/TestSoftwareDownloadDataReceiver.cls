/**
*    @author: Joshith K
*    @date:   26-Aug-2019
*    @description:  test class for SoftwareDownloadDataReceiver
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Rishab Wali                    08-June-2022        [DCP-53883] CodeScan Tech Debt Fix
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest(SeeAllData=false)
private class TestSoftwareDownloadDataReceiver {
    /**Test Data Setup Method */
    @TestSetup
	public static void testData(){
        account objAcc =TestDataAccount.getAccount('TestSftware');
        objAcc.ERP_Customer_Id__c='8976';
        objAcc.Account_Group__c='Ultimate Consignee';
        insert objAcc;

        Contact con=TestDataMarketing.createContact('testfirstname','testlastname','testcontact@gmail.com');
        con.AccountId=objAcc.Id;
        update con;

        Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','testlead@gmail.com',System.Label.Country_USA,'testCompany');
        ld.Email_Verification_Date__c = Date.today();
        ld.Email_Verification_Status__c = 'Verified Successfully';
        update ld;
    }
    static testMethod void testSoftwareDownloadInsertHTTPPost(){
        // config environment to enable query logs
        Feature.setMockFeatureFlag('MarketingQueryLogs', true);
        
        // setting query threshold to zero to log all queries for testing
        setThreshholdsToZero();

        List<SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper> wrapSfwDownloads= new List<SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper> ();
        SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper objwrapper=new SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper();
        objwrapper.Email_Address='testcontact@gmail.com';
        objwrapper.EULA_Acceptance_Date='2019-09-16T08:16:47.867Z';
        objwrapper.Download_Date='2019-09-16T08:16:47.867Z';
        objwrapper.Software_Name='Software name';
        objwrapper.Software_Version='Software version 1';
        objwrapper.Software_File_URL='www.google.com';
        objwrapper.Software_Category='sample category';
        objwrapper.Platform_GUID='platform guid 1';
       objwrapper.Software_Download_ID='oklo345hb2267-gfgds-08-34-4dniiidniind-rfnf';
        wrapSfwDownloads.add(objwrapper);

        SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper objwrapper1=new SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper();
        objwrapper1.Email_Address='testlead@gmail.com';
        objwrapper1.EULA_Acceptance_Date='2019-09-16T08:16:47.867Z';
        objwrapper1.Download_Date='2019-09-16T08:16:47.867Z';
        objwrapper1.Software_Name='Software name';
        objwrapper1.Software_Version='Software version 1';
        objwrapper1.Software_File_URL='www.google.com';
        objwrapper1.Software_Category='sample category';
        objwrapper1.Platform_GUID='platform guid 1';
       objwrapper1.Software_Download_ID='oklo345hb-567njbj-2234-4dniiidniind-rfnf';
        wrapSfwDownloads.add(objwrapper1);

        SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper objwrapper2=new SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper();
        objwrapper2.Email_Address='testleadabc@gmail.com';
        objwrapper2.EULA_Acceptance_Date='2019-09-16T08:16:47.867Z';
        objwrapper2.Download_Date='2019-09-16T08:16:47.867Z';
        objwrapper2.Software_Name='Software name';
        objwrapper2.Software_Version='Software version 1';
        objwrapper2.Software_File_URL='www.google.com';
        objwrapper2.Software_Category='sample category';
        objwrapper2.Platform_GUID='platform guid 1';
       objwrapper2.Software_Download_ID='oklo3ioiiionfjknfnf45hb2234-4dniiidniind-rfnf';
        wrapSfwDownloads.add(objwrapper2);
        // for exception
         SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper objwrapper3=new SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper();
        objwrapper3.Email_Address='jo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.comjo.demo@mailnator.com';
        objwrapper3.EULA_Acceptance_Date='2019-09-16T08:16:47.867Z';
        objwrapper3.Download_Date='2019-09-16T08:16:47.867Z';
        objwrapper3.Software_Name='Software name';
        objwrapper3.Software_Version='Software version 1';
        objwrapper3.Software_File_URL='www.google.com';
        objwrapper3.Software_Category='sample category';
        objwrapper3.Platform_GUID='platform guid 1';
       objwrapper3.Software_Download_ID='okljjjjo345hb2234-4dniiidniind-rfnf';
        wrapSfwDownloads.add(objwrapper3);
        
        // for orphon record scenario
        SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper objwrapper4=new SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper();
        objwrapper4.Email_Address='lead@notfound.com';
        objwrapper4.EULA_Acceptance_Date='2019-09-16T08:16:47.867Z';
        objwrapper4.Download_Date='2019-09-16T08:16:47.867Z';
        objwrapper4.Software_Name='Software name';
        objwrapper4.Software_Version='Software version 1';
        objwrapper4.Software_File_URL='www.google.com';
        objwrapper4.Software_Category='sample category';
        objwrapper4.Platform_GUID='platform guid 1';
        objwrapper4.Software_Download_ID='leadnotfound-4dniiidniind-rfnf';
        wrapSfwDownloads.add(objwrapper4);

         SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper objwrapper5=new SoftwareDownloadDataReceiver.SoftwareDownloadDataReceiverWrapper();
        objwrapper5.Email_Address='Contact@notfound.com';
        objwrapper5.EULA_Acceptance_Date='2019-09-16T08:16:47.867Z';
        objwrapper5.Download_Date='2019-09-16T08:16:47.867Z';
        objwrapper5.Software_Name='Software name';
        objwrapper5.Software_Version='Software version 1';
        objwrapper5.Software_File_URL='www.google.com';
        objwrapper5.Software_Category='sample category';
        objwrapper5.Platform_GUID='platform guid 1';
        objwrapper5.Software_Download_ID='Contactnotfound-4dniiidniind-rfnf';
        wrapSfwDownloads.add(objwrapper5);


        String softwareDownloadJSON = JSON.serialize(wrapSfwDownloads);
        system.debug(' JSON : '+ softwareDownloadJSON);
        Test.startTest();
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/SoftwareDownloadSyncInterface';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueof(softwareDownloadJSON);
        RestContext.request = req;
        RestContext.response= res;
        SoftwareDownloadDataReceiver.upsertIncomingValues();
        SoftwareDownloadDataReceiver.upsertIncomingValues();// to create software record second time
         
         Lead objLead=[select id,Country from lead limit 1];

         Contact objContact=[select id,mailingcountry from Contact limit 1];
         objContact.mailingcountry=null;// for logic to take data from Country Local;
         update objContact;
         SoftwareDownloadDataReceiver.upsertIncomingValues();
         Account objAccount=[select id from Account limit 1];
          
         // for lead conversion logic
        Database.LeadConvert lc = new Database.LeadConvert();
		lc.setLeadId(objLead.id);
        lc.setAccountId(objAccount.id);
        lc.setContactId(objContact.id);
        
        lc.setDoNotCreateOpportunity(true);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true AND MasterLabel='Lead Converted No Opp' LIMIT 1];
		lc.setConvertedStatus(convertStatus.MasterLabel);
        lc.setOwnerId(userinfo.getUserId()); 
        Database.convertLead(lc);
        Test.stopTest();
        System.debug('Rest Status Code for insert: '+res.statusCode);
        //assert with exception 
        System.assertequals(412,res.statuscode,'Status Code not expected'); 
       
        System.assertEquals(0, [select count() from Software_Download__c where Lead_full_name__c=:objLead.id],'Records found');
        System.assertEquals(2, [select count() from Software_Download__c where Contact_full_name__c=:objContact.id],'List size not expected');
    }

    private static void setThreshholdsToZero()
     {
         PS_Log_Setting__mdt settings = new ilib_LogSettings().query();
         settings.Slow_Query_Threshold__c = 0.0;
         settings.Slow_Transaction_Threshold__c = 0.0;
         settings.Disable_All_Log_Persistence__c = false;
         settings.Disable_Slow_Query_Publish__c = false;
         settings.Disable_Slow_Transaction_Publish__c = false;

         ilib_LogSettings.unitTestSettingsRecord = settings;
     }
}