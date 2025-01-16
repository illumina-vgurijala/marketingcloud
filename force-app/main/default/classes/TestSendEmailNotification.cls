/***************************************************************************************************************************************
 * NAME   : TestSendEmailNotification
 * DESCRIPTION  : DCP-803 Sending email notification to Users.
 *    
 * @AUTHOR : Debalina
 * @DATE   : 31-May-2018  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * --------------------------------------------------------------------------------------------------------------------------------------
 * Debalina             31-May-2018          Initial Version
 * Debalina             13-June-2018         802 Code Review Comments
 * Akshay               19-June-2018         Changed account creation method
 * Sheikh Shahnawaz     08-January-2022      DCP-52608
 * Rohan                23-Mar-2022          DCP-49682
  ****************************************************************************************************************************************/ 

@isTest(SeeAllData=False)
public class TestSendEmailNotification {
    static  Contact objCon= new Contact();
    static Case objCase = new Case();
    static Account objAcc = new Account();
    static SVMXC__Service_Order__c workOrder= new SVMXC__Service_Order__c();
     static echosign_dev1__SIGN_Agreement__c objAgreement= new echosign_dev1__SIGN_Agreement__c();
     static SVMXC__Site__c objLocation = new SVMXC__Site__c();
    
    public static final String STRING_ATTACHMENT_NAME = 'Letter of Acceptance - signed';
    public static final String STRING_WORK_ORDER_ACCEPTANCE_STATUS = 'Completed';
    public static final String STRING_AGREEMENT_NAME = 'Letter of Acceptance';
    public static final String STRING_AGREEMENT_STATUS_SIGNED = 'Signed';
    public static final String STRING_WORK_ORDER_ACCEPATNCE_FORECAST = '100% Completed - LOA Signed';

    @testSetup
	/*Test Data*/
    public static void setUpData() {
        objAcc = TestDataAccount.getAccount('TestAccount','USD');
        objAcc.Account_Group__c='Distributor';
        insert objAcc;
        system.debug('objAcc.Id inside Setup='+objAcc.Id);
        Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
        case objCase = TestDataCase.getNewComplaintCase(objCon);
        objCase.RecordTypeId = ServiceUtilityCollection.getRecordTypeId('Case', 'Service Request');
        update objCase;                        
        
        objLocation = TestDataFieldService.createLocation('Test Location','Test','Test','Test','USD');
        
        insert objLocation;
        
        workOrder = TestDataFieldService.createWorkOrder('Field Service', null, 'Initiated');
        workOrder.SVMXC__Site__c=objLocation.id;
        workOrder.SVMXC__Order_Type__c='Installation';
        workOrder.Generate_Inventory_Snapshot__c = true;
        workOrder.Is_Auto_Created__c = true;
		workOrder.SVMXC__Contact__c = objCon.Id;
        insert workOrder;
    }

    static testMethod void testSendEmail(){
        List<User> lstUsers = [SELECT Id 
                                FROM User 
                                WHERE Profile.Name = 'System Administrator' AND IsActive =true
                                LIMIT 2];
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
        Contact con = new Contact(FirstName = 'testfirstname', LastName = 'testlastname', Phone='12334566',email='test@test.com');
        insert con;
        objCase = TestDataCase.initServiceRequestCase(con);
        insert objCase;
            }
        }
        List<Case> lstCase = [SELECT Id From Case  WHERE OwnerId =:lstUsers[0].id LIMIT 1];
        List<Account> lstAccount= [SELECT Id From Account LIMIT 1];
        SVMXC__Service_Group__c objServiceteam=TestDataFieldService.createServiceTeam('test','test');
        insert objServiceteam;
    SVMXC__Service_Group_Members__c objFieldSupport = TestDataFieldService.createTechnician(lstUsers[1].id,'Test',objServiceteam.id);
        insert objFieldSupport;
        Test.startTest(); // moved here to avoid Too mamy soql exception DCP-52608 
        Account_to_Field_Support__c objAccountRole=TestDataFieldService.createAccountToFieldSupport(lstAccount[0].id,'Field Service Manager',objFieldSupport.id);
        insert objAccountRole;
        if(!lstUsers.isEmpty()){
            System.runAs(lstUsers[0]){
                List<SVMXC__Service_Order__c> lstWOToProcess = new List<SVMXC__Service_Order__c>();
                SVMXC__Service_Order__c objCanceledWorkOrder = 
                    TestDataFieldService.createWorkOrder('Field Service', 
                                                         lstCase[0].Id, 
                                                         'Initiated');
                objCanceledWorkOrder.SVMXC__Case__c = null;///tc
                objCanceledWorkOrder.SVMXC__Order_Type__c = 'Installation';///tc
                //objCanceledWorkOrder.SVMXC__Order_Type__c='Service Activities'; ///tc
                objCanceledWorkOrder.Is_Auto_Created__c = true;//*tc
                objCanceledWorkOrder.Record_Created_from_SFM__c=true; 
                objCanceledWorkOrder.SVMXC__Company__c = lstAccount[0].id;//**tc
                SVMXC__Service_Order__c objDowndWorkOrder = 
                TestDataFieldService.createWorkOrder('Field Service', 
                                                        lstCase[0].Id, 
                                                        'Initiated');
                 objDowndWorkOrder.SVMXC__Order_Type__c='Service Activities';
                 objDowndWorkOrder.Record_Created_from_SFM__c=true;
                lstWOToProcess.add(objCanceledWorkOrder);
                lstWOToProcess.add(objDowndWorkOrder);
                insert lstWOToProcess;
                objCanceledWorkOrder.Reason__c ='Test';
                objCanceledWorkOrder.SVMXC__Order_Status__c = 'Canceled';///tc
                objDowndWorkOrder.SVMXC__Customer_Down__c = true;
                update lstWOToProcess;
            }
        }
        Test.stopTest();
        System.assertNotEquals(1, Limits.getEmailInvocations());
    }    
    
    static testMethod void validateLOAEmail(){
        //setUpData();
		Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
		insert objAccount;
        TestDataContact.getNewContact(objAccount);
        SVMXC__Service_Order__c workOrder = [select id,SVMXC__Contact__c,OwnerId,SVMXC__Case__c from SVMXC__Service_Order__c limit 1];
        
        objAgreement = TestDataFieldService.createAgreement(STRING_AGREEMENT_NAME,STRING_AGREEMENT_STATUS_SIGNED,workOrder.id);
        Test.startTest();
        insert objAgreement;
        Attachment objAttachment=TestDataFieldService.createAttachment(objAgreement.Id,STRING_ATTACHMENT_NAME);
        insert objAttachment;
		
		SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.Operation_Status__c='Off';
        insert objInstalledProduct;
		
        SVMXC__Service_Order_Line__c objOrderDetail = new SVMXC__Service_Order_Line__c();
        objOrderDetail.SVMXC__Service_Order__c = workOrder.id;
        objOrderDetail.SVMXC__Serial_Number__c = objInstalledProduct.Id;
        objOrderDetail.SVMXC__Activity_Type__c='Customer Service Review';
		insert objOrderDetail;
        Test.stopTest();
        
        Attachment objAttachment1=new Attachment();
        objAttachment1=[Select Name,ParentId from Attachment where id=:objAttachment.id][0];
        SVMXC__Service_Order__c objWorkOrder1= new SVMXC__Service_Order__c();
        objWorkOrder1=[Select Name,LOA_Signed_and_Attached__c from SVMXC__Service_Order__c where id=:workOrder.id][0];
        system.assert(objWorkOrder1.LOA_Signed_and_Attached__c);
		
		SendEmailNotification.getSendEmailParamaters('Billable_Work_Detail', new List<sObject> {objOrderDetail}, null, 'SVMXC__Service_Order__r.SVMXC__Company__c');
		SendEmailNotification.getSendEmailParamaters('Scheduled_Work_Order', new List<sObject> {workOrder}, null, 'SVMXC__Company__c');
		
		SendEmailNotification.getSendEmailtoPartnerAccount('Scheduled_Work_Order', new List<sObject> {workOrder}, null, null);
		SendEmailNotification.getSendEmailtoPartnerAccount('Billable_Work_Detail', new List<sObject> {objOrderDetail}, null, null);
		SendEmailNotification.sendEmailWithAttachments('Scheduled_Work_Order', new List<sObject> {workOrder}, null, null,'SVMXC__Company__c');
		SendEmailNotification.sendEmailWithAttachments('Billable_Work_Detail', new List<sObject> {objOrderDetail}, null, null,'SVMXC__Service_Order__r.SVMXC__Company__c');
		SendEmailNotification.getSendEmailParamaters('Scheduled_Work_Order', new List<sObject> {workOrder}, null,'SVMXC__Company__c', null);
		SendEmailNotification.getSendEmailParamaters('Billable_Work_Detail', new List<sObject> {objOrderDetail},null,'SVMXC__Service_Order__r.SVMXC__Company__c', null);
        
    }
	
	static Case cs;
		/*Test Data*/
    public static void initializeTestData()
    {
        Contact con = TestDataPerson.getNewContact(null);
        cs = TestDataCase.initServiceRequestCase(con);
        insert cs;
    }
	
	 /**
     * Method: checkInstallationWOEmailNotification
     * Description: Testmethod to check Installation Work Order Email Notification on assignment.
     * CreatedDate: 24-09-2019
     * DCP-28403
     * */
    static testMethod void checkInstallationWOEmailNotification(){
        //initializeTestData();
        User adminUser = [Select Id, UserRoleId From User Where Profile.Name='System Administrator' And userRoleId!=null And isActive = true Limit 1]; // DCP-52608
        cs_Apex_Settings__c	 setting = cs_Apex_Settings__c.getInstance(adminUser.Id);
        if(setting.Modify_Users__c != true){
			setting.Modify_Users__c = true;
            upsert setting;  
        }
        System.runAs(adminUser){ // DCP-52608
        Id profileId = [select id from profile where name='Channel Partner Sales and Service'].id;

        Account objAccount = TestDataAccount.getAccount('Test Account', 'USD');
        insert objAccount;
        Contact con =TestDataContact.getNewContact(objAccount);
        // insert con;  
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;          
        User recCSuser = new User(alias = uniqueName.substring(18, 23), email=uniqueName + '@test' + orgId + '.org',
        emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
        localesidkey='en_US', profileid = profileId , country='USA',IsActive =true,PortalRole = 'Manager',
        ContactId = con.Id,
        timezonesidkey='America/Los_Angeles', username=uniqueName + '@test' + orgId + '.org');
        insert recCSuser;
        SVMXC__Service_Group__c serviceTeam = new SVMXC__Service_Group__c(
            Name = 'Test Team',
            SVMXC__Country__c = 'India'
        );
        insert serviceTeam;
        System.assertNotEquals(null, serviceTeam.Id);
        
        SVMXC__Service_Group_Members__c grpMembers = new SVMXC__Service_Group_Members__c(
            Name = 'Test Name',
            SVMXC__Active__c = True,
            SVMXC__Email__c = 'testmail@testing.com',
            SVMXC__Country__c = 'India',
            SVMXC__Street__c = 'Test',
            SVMXC__Salesforce_User__c = recCSuser.Id,
            SVMXC__Service_Group__c = serviceTeam.Id
        );
        insert grpMembers;
        
        SVMXC__Installed_Product__c objInstalledProduct = TestDataFieldService.createInstalledProduct('Test IP', 'USD', 'New');
        objInstalledProduct.Operation_Status__c='Off';
        insert objInstalledProduct;
        Product2 objProduct=TestDataFieldService.createProduct('Test Product','Instrument');
        insert objProduct;
        
        Contact cont = TestDataPerson.getNewContact(null);
        SVMXC__Site__c objLocation = TestDataFieldService.createLocation('testlocation','teststreet','testcountry','53434343','USD');
        insert objLocation;


        Case cs = TestDataCase.initServiceRequestCase(cont);
        cs.SVMXC__Site__c = objLocation.id;
        insert cs;

        List<SVMXC__Service_Order__c> lstWo= new List<SVMXC__Service_Order__c>();
        
        SVMXC__Service_Order__c objWorkOrderTwo = TestDataFieldService.createWorkOrder('Field Service', cs.Id, 'Assignment Accepted');
        objWorkOrderTwo.SVMXC__Product__c=objProduct.id;
        objWorkOrderTwo.SVMXC__Company__c = objAccount.Id;
        objWorkOrderTwo.Is_Auto_Dispatch__c = True;
        objWorkOrderTwo.Partner_Installation_WO__c = true;
        objWorkOrderTwo.SVMXC__Order_Type__c='Installation';
        objWorkOrderTwo.SVMXC__Component__c = objInstalledProduct.Id;
        objWorkOrderTwo.ERP_Order_Number__c='Order0001';
        objWorkOrderTwo.ERP_Order_Line_Number__c='OrderLine001';
        objWorkOrderTwo.ERP_Order_Line_Quantity__c=1;
        objWorkOrderTwo.Is_Auto_Created__c = true;        
        lstWo.add(objWorkOrderTwo);
        try{
            Test.startTest();
            insert lstWo;
            objWorkOrderTwo.ownerId = recCSuser.Id;
            objWorkOrderTwo.SVMXC__Group_Member__c = grpMembers.id;
            update lstWo;
            Test.stopTest();
        }
        catch(Exception e){
            System.debug('The following exception has occurred: ' + e.getMessage());
        }                   
        
        }
    }
	
	static testMethod void testFetchAdditionalElevationMembers(){
        
          User u = TestDataFieldService.createUser('System Administrator',false);
             Insert u;
             System.runAs(u)
             {  
                 Test.startTest();
                 objAcc = TestDataAccount.getUCAccount();
                 insert objAcc;
                 System.assertNotEquals(null, objAcc.Id);
                 // Account inserted	
 
                 Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
                 
                 /* DCP-52608 start */
                 Contact objCon = TestDataPerson.getNewContact(objAcc.Id);
 
                 Case cs = TestDataCase.createCase('Business Issue','Initiated',objCon.Id);
                 cs.Sub_Type__c = 'Complaint';
                 update cs;

                 SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                 SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                 SVMXC__Order_Status__c from 
                 SVMXC__Service_Order__c where SVMXC__Case__c =: cs.Id Limit 1];
                /* DCP-52608 End */

                 Elevations__c techElev = new Elevations__c();
                 techElev.RecordTypeId = technicalElevationRecordType;
                 techElev.Elevation_Category__c = 'Standard Technical';
                 techElev.Elevation_Status__c = 'Open';
                 techElev.Work_Order__c = workOrder.Id; // DCP-52608
                 insert techElev;
                 // Elevation inserted
                 System.assertNotEquals(null, cs.Id);
                 // Case inserted with Status as 'Initiated' Record type as 'Business Issue' sub type as 'Complaint'
                 
                  objLocation = TestDataFieldService.createLocation('Test Location','Test','Test','Test','USD');
                     insert objLocation;
                     System.assertNotEquals(null, objLocation.Id);
                   //Location inserted
 
                  workOrder.SVMXC__Site__c=objLocation.Id;
                  workOrder.Technical_Elevation__c = techElev.Id;
                  update workOrder;
       
                 Related_Contacts__c rc = new Related_Contacts__c();
                 rc.Elevated_Work_Order__c = workOrder.id;            
                 rc.User__c=u.id;
                 Insert rc;
                 //Related Contact inserted
 
                 Set<Id> woID = new Set<Id>();
                 woId.add(workOrder.Id);
             
                 SendEmailNotification.fetchAdditionalElevationMembers(label.Elevation_Technical_Close_Status_Metadata, woID );
                
                 
                List<String> lstAddress = new List<String>{'Address1@illumina.com','Address2@illumina.com','Address3@illumina.com'};
				
				SendEmailNotification.EmailConditionsWrapper emailConditionWrapper = new SendEmailNotification.EmailConditionsWrapper();
				emailConditionWrapper.htmlEmailBody = 'Testing Email Body';
				emailConditionWrapper.lstToAddresses = lstAddress;
				emailConditionWrapper.subject = 'Testing Subject';
				
				SendEmailNotification.sendEmailWithEmailConditionsWrapper(emailConditionWrapper);				
                 Test.stopTest();
         
             }
         }
}
