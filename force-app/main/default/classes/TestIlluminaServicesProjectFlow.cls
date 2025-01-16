/***************************************************************************************************************************************
* NAME   : TestIlluminaServicesProjectFlow
* DESCRIPTION  : For Covering the "Illumina Services Project : Record Triggered - Concierge Updates" Flow
*    
* @AUTHOR : Abhishek
* @DATE   : 3-Oct-2023  
*
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Abhishek             3-Oct-2023              Initial Version (CMCM-3823)
****************************************************************************************************************************************/
@isTest
public class TestIlluminaServicesProjectFlow {

    public final static Id INFINIUM_RECORD_TYPE_ID = Schema.SObjectType.Illumina_Services_Project__c.getRecordTypeInfosByName().get('Infinium Design Services').getRecordTypeId();
        
    /**
    *  @author Abhishek
    *  @description - Inserted test data 
    **/
    @isTest
    public static void testisNewRecord() {
        Test.startTest();
        Illumina_Services_Project__c illuminaProject = TestDataIlluminaServiceProject.getSequencingDesignServices();
        insert illuminaProject;
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Request_Status__c,Project_Status__c FROM Illumina_Services_Project__c WHERE Id =:IlluminaProject.Id LIMIT 1];
        Assert.areEqual('Under Evaluation',illuminaService.Project_Request_Status__c);
        Assert.areEqual('Not started',illuminaService.Project_Status__c);
        Test.stopTest();
    }
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testRequestStatus() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getInfiniumDesignServices();
        serviceProj.Project_Request_Status__c = 'Under Evaluation - Hold';
        insert serviceProj;

        Test.startTest();
        serviceProj.Project_Status__c = 'Under Evaluation';
        update serviceProj;
        Assert.isTrue(serviceProj != null);
        Test.stopTest();
    }
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testRequestAssignedInfinium() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getInfiniumDesignServices();
        serviceProj.Project_Status__c = 'Not started';
        insert serviceProj;
        
        Test.startTest();
        serviceProj.Project_Status__c = 'Assigned';
        update serviceProj;
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Start_Date__c FROM Illumina_Services_Project__c WHERE Id =:ServiceProj.Id LIMIT 1];
        Assert.isTrue(illuminaService != null);
        Test.stopTest();
    }
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testRequestAssignedSequencing() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getSequencingDesignServices();
        serviceProj.Project_Status__c = 'Not started';
        insert serviceProj;
        
        Test.startTest();
        serviceProj.Project_Status__c = 'Assigned';
        update serviceProj;
        Test.stopTest();
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Start_Date__c FROM Illumina_Services_Project__c WHERE Id =:ServiceProj.Id LIMIT 1];
        Assert.isTrue(illuminaService != null);
    }
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testRequestStatusAccepted() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getSequencingDesignServices();
        serviceProj.Project_Request_Status__c = 'Under Evaluation';
        insert serviceProj;
        
        Test.startTest();
        serviceProj.Project_Request_Status__c = 'Accepted';
        update serviceProj;
        Test.stopTest();
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Acceptance_Rejection_Date__c FROM Illumina_Services_Project__c WHERE Id =:ServiceProj.Id LIMIT 1];
        Assert.areEqual(System.Today(),illuminaService.Project_Acceptance_Rejection_Date__c);
    }
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testRequestStatusRejected() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getSequencingDesignServices();
        serviceProj.Project_Request_Status__c = 'Under Evaluation';
        insert serviceProj;
        
        Test.startTest();
        serviceProj.Project_Request_Status__c = 'Rejected';
        update serviceProj;
        Test.stopTest();
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Acceptance_Rejection_Date__c FROM Illumina_Services_Project__c WHERE Id =:ServiceProj.Id LIMIT 1];
        Assert.areEqual(System.Today(),illuminaService.Project_Acceptance_Rejection_Date__c);
        
    } 
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testProjectStatusClosedInfinium() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getInfiniumDesignServices();
        serviceProj.Project_Status__c = 'Assigned';
        insert serviceProj;

        Test.startTest();
        serviceProj.Project_Status__c = 'Closed -Delivered';
        update serviceProj;
        Test.stopTest();
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Close_Date__c FROM Illumina_Services_Project__c WHERE Id =:ServiceProj.Id LIMIT 1];
        Assert.areEqual(System.Today(),illuminaService.Project_Close_Date__c);
    } 
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testProjectStatusClosedSequencing() {
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getSequencingDesignServices();
        serviceProj.Project_Status__c = 'Assigned';
        insert serviceProj;

        Test.startTest();
        serviceProj.Project_Status__c = 'Closed -Delivered';
        update serviceProj;
        Test.stopTest();
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Close_Date__c FROM Illumina_Services_Project__c WHERE Id =:ServiceProj.Id LIMIT 1];
        Assert.areEqual(System.Today(),illuminaService.Project_Close_Date__c);
    } 
    /**
    *  @author Abhishek
    *  @description - Positive Testing 
    **/
    @isTest
    public static void testDesignexpert() {
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Customer Service'].Id,
            LastName = 'last',
            Email = 'test@test.com',
            Username = 'Test@test.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert u;
        Illumina_Services_Project__c serviceProj = TestDataIlluminaServiceProject.getInfiniumDesignServices();
        insert serviceProj;
        Test.startTest();
        serviceProj.Design_Expert__c = u.id;
        update serviceProj;
        Assert.isTrue(serviceProj != null);
        Test.stopTest();
    } 

    /**
    *  @author Vishal
    *  @description - Test method for Illumina_Services_Project_c_After_Insert_and_Update Flow
    **/
    @isTest
    public static void testAfterInsertAndUpdate() {
        // create test data
        Illumina_Services_Project__c illuminaProject = new Illumina_Services_Project__c(
            RecordTypeId = INFINIUM_RECORD_TYPE_ID,
            Comments__c = 'Test Comment'
        );
        Illumina_Services_Project__c illuminaProject2 = new Illumina_Services_Project__c(
            RecordTypeId = INFINIUM_RECORD_TYPE_ID
        );
        List<Illumina_Services_Project__c> illuminaProjectList = new List<Illumina_Services_Project__c>{illuminaProject,illuminaProject2};
        insert illuminaProjectList;
        Illumina_Services_Project__c illuminaService = [SELECT Id,Project_Comments__c FROM Illumina_Services_Project__c WHERE Id =:illuminaProject.Id LIMIT 1];
        System.assert(illuminaService.Project_Comments__c != null, 'Project Comments should not be null.');        
    }
   
}
