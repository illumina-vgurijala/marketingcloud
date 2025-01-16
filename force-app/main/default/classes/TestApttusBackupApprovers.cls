/**
*    @author Govind Dubey
*    @date   5th Oct 2018
*    @description  Test class for ApttusBackupApprovers
*    Modification Log:
*    -----------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*    -----------------------------------------------------------------------------------------------------------------------------------
*       Govind Dubey                   5th Oct 2018             Original method 
*       Satya Swain                    20 Feb 2020              Added testCheckRecordCreationForSalesOpsUser for INC0220493
*       Roopal Verma                   03 Apr 2020              Added static strings for sonarqube fix
*       Rishab Wali                    07 July 2020             Updated methods to remove circular dependency.
*       Raja Siva Krishna              22 Sept 2020             DCP-40107 Updated data to get code coverage 
*/
@isTest(SeeAllData=false isParallel=false)
public class TestApttusBackupApprovers {
    
	public static final String PROFILE_SALES_USER = 'Sales User';                //SonarQube Fix
    public static final String PROFILE_SYS_ADMIN = 'System Administrator';
    public static final String PROFILE_COMMERCIAL_OPS_QUOTING_USER = 'Commercial Ops Quoting User';
	
    /**
    * @Author Govind Dubey
    * @description setup method for BackupApprovers
    **/
    @testSetup
    static void setupData()
    { 
        
        List<Approval_Hierarchy__c> lstApprovalHierarchy = new List<Approval_Hierarchy__c>();
        
        Approval_Hierarchy__c objDiscountApprovalHeirarchy = TestDataProposal.initApprovalHierarchy('CPQ_Custom_Hierarchy');
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy);

        Approval_Hierarchy__c objDiscountApprovalHeirarchy1 = TestDataProposal.initApprovalHierarchy('CPQ_Sales_Hierarchy');
        objDiscountApprovalHeirarchy1.Approver_Level_6__c=null;
        lstApprovalHierarchy.add(objDiscountApprovalHeirarchy1);

        insert lstApprovalHierarchy;
        
        List<Custom_Approval_Matrix__c> lstMatrix = new List<Custom_Approval_Matrix__c>();
        
        Custom_Approval_Matrix__c discountApprovalMatrix = TestDataProposal.initApprovalMatrixForDiscount('CPQ Discount', 2000, 20, '2');
        lstMatrix.add(discountApprovalMatrix);
        
        insert lstMatrix;
    }
    
    /**
    * @Author Govind Dubey
    * @description Test method for BackupApprovers
    **/
    
    @isTest
    static void testBackupApprovers(){
        User objRepUser = TestDataUser.findUserInProfile(PROFILE_SALES_USER), 
            objCurrentUser = TestDataUser.findUserInProfile(PROFILE_SYS_ADMIN,new Set<Id>{UserInfo.getUserId()}),
            objOpsUser = TestDataUser.findUserInProfile(PROFILE_COMMERCIAL_OPS_QUOTING_USER);
        objOpsUser.DelegatedApproverId = objRepUser.Id;
        objCurrentUser.DelegatedApproverId = objRepUser.Id;
        objRepUser.DelegatedApproverId = UserInfo.getUserId(); //Update to remove circular dependency.
        update new List<User>{objRepUser,objCurrentUser,objOpsUser};
            
        String strEffectiveDateError;
        String strExpirationDateError;
        
        Test.startTest();
        system.runAs(objCurrentUser){
            Apttus_Approval__Backup_Approver__c objBackupApprover2 = TestDataProposal.initBackupApprover(objRepUser,objOpsUser);
            insert objBackupApprover2;
            
            Apttus_Approval__Backup_Approver__c objBackupApprover = TestDataProposal.initBackupApprover(objRepUser,objCurrentUser);
            insert objBackupApprover;
            system.assert(objBackupApprover.Id!=null);
            
            objBackupApprover.Apttus_Approval__Backup_User__c = objOpsUser.Id;
            objBackupApprover.Apttus_Approval__Effective_Date__c = system.today()+2;
            try{
                update objBackupApprover;
            }catch(Exception e){
                strEffectiveDateError = e.getMessage();
            }
            
            objBackupApprover.Apttus_Approval__Expiration_Date__c = system.today()+4;
            try{
                update objBackupApprover;
            }catch(Exception e){
                strExpirationDateError = e.getMessage();
            }
        }
        Test.stopTest();
        //system.assert(strEffectiveDateError.contains(Label.UI_Text_Effective_Date_Modification_Error));
        //system.assert(strExpirationDateError.contains(Label.UI_Text_Expiration_Date_Modification_Error));
    }
    
    /**
    * @Author Govind Dubey
    * @description Test method for BackupApprovers
    **/
    
    @isTest
    static void testBackupApproversWrongBackup(){
        User objRepUser = TestDataUser.findUserInProfile(PROFILE_SALES_USER), 
        objAdminUser = TestDataUser.findUserInProfile(PROFILE_SYS_ADMIN,new Set<Id>{UserInfo.getUserId()}),
        objOpsUser = TestDataUser.findUserInProfile(PROFILE_COMMERCIAL_OPS_QUOTING_USER);
        
        objOpsUser.DelegatedApproverId = objRepUser.Id;
        objAdminUser.DelegatedApproverId = objRepUser.Id;
        objRepUser.DelegatedApproverId = UserInfo.getUserId(); //Update to remove circular dependency.
        update new List<User>{objRepUser,objAdminUser,objOpsUser};
            
        String strCurrentUserError;
        String strBackupApproverError;
        String strDelegationApproverError;
        User u = [Select id, name, email from User where id=: UserInfo.getUserId()];
        
        Test.startTest();
        Apttus_Approval__Backup_Approver__c objBackupApprover = TestDataProposal.initBackupApprover(objRepUser,objAdminUser);
        try{
            insert objBackupApprover;
        }catch(Exception e){
            strCurrentUserError = e.getMessage();
        }
        
        Apttus_Approval__Backup_Approver__c objBackupApprover2 = TestDataProposal.initBackupApprover(objRepUser,u);
        try{
            insert objBackupApprover2;
        }catch(Exception e){
            strBackupApproverError = Label.UI_Text_Backup_Approver_Error;
        }
        
        Apttus_Approval__Backup_Approver__c objBackupApprover3 = TestDataProposal.initBackupApprover(objRepUser,u);
        objBackupApprover3.Apttus_Approval__Backup_User__c = null;
        objBackupApprover3.Apttus_Approval__IsDelegate__c = true;
        objBackupApprover3.Apttus_Approval__DelegateUserIds__c = objRepUser.Id;
        objBackupApprover3.Apttus_Approval__DelegateUserIds__c += ','+objOpsUser.Id;
        try{
            insert objBackupApprover3;
        }catch(Exception e){
            strDelegationApproverError = Label.UI_Text_Backup_Approver_Error;
        }
        
          Approval_Hierarchy__c objAH = [SELECT Id, Approver_Level_2__c FROM Approval_Hierarchy__c WHERE Approval_Hierarchy_Type__c = 'CPQ_Custom_Hierarchy'];
          objAH.Approver_Level_2__c = objRepUser.Id;
          update objAH;
        
        Apttus_Approval__Backup_Approver__c objBackupApprover4 = TestDataProposal.initBackupApprover(objRepUser,u);
        objBackupApprover4.Apttus_Approval__Backup_User__c = null;
        objBackupApprover4.Apttus_Approval__IsDelegate__c = true;
        objBackupApprover4.Apttus_Approval__DelegateUserIds__c = objRepUser.Id;
        try{
            insert objBackupApprover4;
            system.assert(objBackupApprover4.Id!=null);
        }catch(Exception e){
            strDelegationApproverError = Label.UI_Text_Backup_Approver_Error;
        }
        Test.stopTest();
        if(String.isNotBlank(strDelegationApproverError) && strDelegationApproverError != null)
            system.assert(strDelegationApproverError.contains(Label.UI_Text_Backup_Approver_Error));
        if(String.isNotBlank(strBackupApproverError) && strBackupApproverError != null)
            system.assert(strBackupApproverError.contains(Label.UI_Text_Backup_Approver_Error));
    }
    @isTest
    static void testCheckRecordCreationForSalesOpsUser(){
        User objRepUser = TestDataUser.findUserInProfile(PROFILE_SALES_USER), 
        objAdminUser = TestDataUser.findUserInProfile(PROFILE_SYS_ADMIN,new Set<Id>{UserInfo.getUserId()}),
        objOpsUser = TestDataUser.findUserInProfile(PROFILE_COMMERCIAL_OPS_QUOTING_USER);
        String strValidationErrorMessages;
        
        objOpsUser.DelegatedApproverId = objRepUser.Id;
        objAdminUser.DelegatedApproverId = objRepUser.Id;
        objRepUser.DelegatedApproverId = UserInfo.getUserId(); //Update to remove circular dependency.
        update new List<User>{objRepUser,objAdminUser,objOpsUser};

        List<Profile> lstProfile = [Select Id from Profile];
        Profiles.Constructor obj=new Profiles.Constructor();
        obj.construct(lstProfile);

        Profiles.getAdminProfileId();
        Profiles.getAllSalesProfileIds();

        Test.startTest();
        System.runAs(objOpsUser){
            // to test that Commercial Ops Quoting User User can create backup record for any other user
            Apttus_Approval__Backup_Approver__c objBackupApprover = TestDataProposal.initBackupApprover(objRepUser,objAdminUser);
            try{
                insert objBackupApprover;
                objBackupApprover.Apttus_Approval__Backup_User__c = objOpsUser.Id;
                update objBackupApprover;
            }
            catch(Exception e){
                strValidationErrorMessages = e.getMessage();
            }
        }
        Test.stopTest();
        List<Apttus_Approval__Backup_Approver__c> lstBackupApprover2 = [Select Id from Apttus_Approval__Backup_Approver__c];
        System.assertEquals(1, lstBackupApprover2.size());
        System.assertEquals(true, String.isBlank(strValidationErrorMessages));
    }   
}