/**
    *    @author: Rohan Rathod
    *    @date:   03-Dec-2021
    *    @description:  TestClass for AdditionalElevationMemController
    *    Modification Log:
    *    -----------------------------------------------------------------------------------
    *             Developer                      Date                Description
    *            Rohan Rathod             03-Dec-2021           Initial Build
    *    ------------------------------------------------------------------------------------ 
    *                    
    */
    @isTest
    public with sharing class TestAdditionalElevationMemController {
        public static final String BUSINESS_ISSUE = 'Business Issue';
        static Case cs;
        public static String contactId;
        public static final String STRING_ACCOUNT = 'Test Acc';
        public static final String STRING_WO_RECORDTYPE = 'Field Service';
        public static final String STRING_WO_ORDER_TYPE = 'Service Activities';
    
       /**
        *  @author Rohan Rathod
        *  @description Test data initialization
        *  @param 
        *  @return 
        **/  
    
        @TestSetup
        static void initializeTestData(){
            
            Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
            acc.Account_Group__c='Distributor';
            insert acc;
           
            Contact con = new Contact(
                FirstName = 'TestFirstName',
                LastName = 'TestLastName',
                AccountId = acc.Id,
                Email = 'abc@illumina.com',
                Phone = '1234567890',
                MailingCountryCode = 'US'
            );
            insert con;
            System.assert(con.id != null,'Contact is present');          
            //insert case        
            cs = TestDataCase.initServiceRequestCase(con);
            insert cs;
            contactId = con.Id;                       
                                           
        }
    
        /**
        *  @author Rohan Rathod
        *  @description Test method to check FindRecords functionality
        *  @param 
        *  @return 
        **/  
        
        @isTest
        public static void checkFindRecords(){ 
           
            Test.startTest();
            string strObjName = 'Contact';
            List<sobject> lstTest;
            lstTest=AdditionalElevationMemController.findRecords('TestFirstName TestLastName',strObjName);
            Test.stopTest();   
            
            system.assert(!lstTest.isEmpty(), 'List should not be empty');
        }
    
        /**
        * @description: To test the functionality of fetching and deleting the elevation member
        **/
        @isTest
         public static void checkFetchElevationMember(){
            PermissionSet ps = new PermissionSet();
            ps.Name = 'Test';
            ps.Label = 'Test';
            insert ps;
            SetupEntityAccess sea = new SetupEntityAccess();
            sea.ParentId = ps.Id;
            sea.SetupEntityId = [select Id from CustomPermission where DeveloperName = 'RPS_FSM_FAM'][0].Id;
            insert sea;
            PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = UserInfo.getUserId();
            psa.PermissionSetId = ps.Id;
            insert psa;
                
            system.runas(new user(Id = userinfo.getUserid()))
            {
                Account acc = TestDataAccount.getAccount(STRING_ACCOUNT, 'USD');
                acc.Account_Group__c = Accounts.GROUP_ULTIMATE_CONSIGNEE;
                insert acc;
                
                //insert contact
                Contact con = TestDataPerson.getNewContact(acc.Id);
                System.assert(con.id != null, 'Record not inserted');
                
                Id idCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(BUSINESS_ISSUE).getRecordTypeId();
                
                Case objCase  = new Case(    
                    Status = 'Initiated',
                    Subject = 'test' ,
                    Description= 'test',
                    Origin = 'Phone-CP',
                    Date_of_Issue_Awareness__c=System.today() -2,
                    Awareness_Date_Difference_Reason__c = 'Logistical delay',
                    ContactId = con.Id,
                    RecordTypeId = idCaseRecordTypeId
                );
                insert objCase;
                
                List<User> lstUsers = [SELECT Id FROM User WHERE Profile.Name =: System.label.Field_Service AND IsActive = TRUE LIMIT 1];
                
                Id technicalElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Technical Elevation').getRecordTypeId();
                Id accountElevationRecordType = Schema.SObjectType.Elevations__c.getRecordTypeInfosByName().get('Account Elevation').getRecordTypeId();  
                
                SVMXC__Service_Order__c workOrder = [select id,Onsite_Response_Due_Date__c,SVMXC__SM_SLA_Onsite_Response__c,
                                                     SVMXC__Order_Type__c,Case_Record_Type__c,OwnerId,SVMXC__Group_Member__c,
                                                     SVMXC__Order_Status__c from 
                                                     SVMXC__Service_Order__c where SVMXC__Case__c =: objCase.Id Limit 1];
                
                Elevations__c techElev = new Elevations__c();
                techElev.RecordTypeId = technicalElevationRecordType;
                techElev.Elevation_Category__c = 'Standard Technical';
                techElev.Elevation_Status__c = 'Open';
                techElev.Elevation_Owner__c = lstUsers[0].Id;
                techElev.Elevation_Manager__c = lstUsers[0].Id;
                techElev.Plan_of_Action__c = 'test';
                techElev.Work_Order__c = workOrder.Id;
                insert techElev;
                
                Elevations__c accElev = new Elevations__c();
                accElev.RecordTypeId = accountElevationRecordType;
                accElev.Elevation_Status__c = 'Open';
                accElev.Elevation_Owner__c = lstUsers[0].Id;
                accElev.Plan_of_Action__c = 'test';
                accElev.Work_Order__c = workOrder.id;
                insert accElev;
                  
                Test.startTest();

                workOrder.Technical_Elevation__c = techElev.Id;
                workOrder.Account_Elevation__c = accElev.Id;
                update workOrder;
                

                Related_Contacts__c rc = new Related_Contacts__c();
                rc.Elevated_Work_Order__c = workOrder.id;
                rc.User__c=lstUsers[0].id;
                Insert rc;
                system.assert(rc.Id!=null, 'Related Contact should not be null');                
              
                 
                List<AdditionalElevationMemController.DataWrap> lstDataWrap = new List<AdditionalElevationMemController.DataWrap>();
                lstDataWrap = AdditionalElevationMemController.fetchElevationMember(workOrder.id);
                try{
                    AdditionalElevationMemController.deleteElevationMember(rc.Id);
                } catch(Exception e){
                    System.debug('Exception e-->'+e.getMessage());
                }
                Test.stopTest();
                Related_Contacts__c rcDel = [select id, IsDeleted from Related_Contacts__c where id=:rc.id ALL ROWS];
                system.assert(!lstDataWrap.isEmpty(), 'List should not be empty');
                system.assert(rcDel.isDeleted, 'Record is not deleted');
            
        }
      }
    }
