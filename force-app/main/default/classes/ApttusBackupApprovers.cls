/**
*    @author Govind Dubey
*    @date   1 Oct 2018  
*    @description Approver Experience - Delegation of Approval
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Govind Dubey                1 Oct 2018             Approver Experience - Delegation of Approval
*             Satya Swain                 17 Feb 2020            INC0220493 - Bypass Validations for Certain Profiles
*             Roopal Verma                02 Mar 2020            broken if condition in two parts for snarqube fix
*             Anand Palla                 26 Apr 2022            CodeScan Fix-Avoid Literals in If condition
*             Jitesh Lakhwani             8-July-2022            Code Scan fixes of Comments  
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
*/
public with sharing class ApttusBackupApprovers extends ilib_SObjectDomain {

    String strProfileName;
    Id currentUserProfileId;
    //Start CodeScan Fix [Avoid Literals in If condition]
    private static final Integer INTEGER_ONE = 1;
    //End CodeScan Fix
    /**
    * @description Parameterized Constructor called
    * @params List<Apttus_Approval__Backup_Approver__c> sObjectList
    * @return void
    **/
    public ApttusBackupApprovers(List<Apttus_Approval__Backup_Approver__c> sObjectList)
    {
        super(sObjectList);
        // Putting user query in this class itself and not in Selector class since we want logged in user profile name, selector class will try to describe Profile object and sales rep do not have access to setup.
        User objUser = [SELECT Profile.Name, ProfileId FROM User WHERE Id=:UserInfo.getUserId()].get(0);
        strProfileName = objUser.Profile.Name;
        // Added for INC0220493
        currentUserProfileId = objUser.ProfileId;

    }
    /*
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        /**
        * @description  Constructor of base class
        * @params List<SObjects> sObjectList
        * @return sObjectList
        **/
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new ApttusBackupApprovers(sObjectList);
        }
    }

    /**
    * @description Overriding the onBeforeInsert base class method
    * @params NA
    * @return void
    **/ 
    public override void onBeforeInsert()
    {
        Set<Id> setSalesDiscretionaryApproverIds = new Set<Id>();
        Set<Id> setQuoteApproverIds = new Set<Id>();

        // Added for INC0220493
        Boolean isCurrentUserSalesOps = checkCurrentUserIsSalesOps(currentUserProfileId); 

        List<Approval_Hierarchy__c> lstApprovalHierarchy = new ApprovalHierarchiesSelector().selectAllRecords();
        Integer intMaxApprovalLevel = ApttusProposalLineItems.MAX_APPROVAL_LEVEL;

        for (Approval_Hierarchy__c objAppHierarchy : lstApprovalHierarchy)
        {
            for (Integer intCurrentLevel = 1; intCurrentLevel <= intMaxApprovalLevel; intCurrentLevel++)
            {
                Id idApprover = (Id) objAppHierarchy.get('Approver_Level_' + intCurrentLevel + '__c');
                if (idApprover == null)
                    continue;

                if (objAppHierarchy.Approval_Hierarchy_Type__c == ApttusProposalLineItems.ApprovalCategory.CPQ_SALES_HIERARCHY.name())
                {
                    if (intCurrentLevel == INTEGER_ONE)
                        continue;
                    else
                    {
                        setQuoteApproverIds.add(idApprover);
                        setSalesDiscretionaryApproverIds.add(idApprover);    
                    }
                }
                else
                {
                    setQuoteApproverIds.add(idApprover);
                }
            }
        }

        // Added for INC0220493
        if (isCurrentUserSalesOps)
            return;

        for (Apttus_Approval__Backup_Approver__c objBackup : (List<Apttus_Approval__Backup_Approver__c>)records)
        {            
            if (objBackup.Apttus_Approval__Current_User__c != UserInfo.getUserId() && setQuoteApproverIds.contains(UserInfo.getUserId()))
            {
                objBackup.addError(Label.UI_Text_Current_User_Error);
            }

            if (!objBackup.Apttus_Approval__IsDelegate__c
                && !setSalesDiscretionaryApproverIds.contains(objBackup.Apttus_Approval__DelegateUserIds__c)
                && setSalesDiscretionaryApproverIds.contains(objBackup.Apttus_Approval__Current_User__c)
            ) {
                objBackup.addError(Label.UI_Text_Backup_Approver_Error);
            }

            if (objBackup.Apttus_Approval__IsDelegate__c)
            {
                Boolean boolFoundSalesDiscretionary = false;
                if (String.isNotBlank(objBackup.Apttus_Approval__DelegateUserIds__c))
				{
					List<String> lstDelegateUserIds = new List<String>();
					if(objBackup.Apttus_Approval__DelegateUserIds__c.contains(','))
					{
						lstDelegateUserIds = objBackup.Apttus_Approval__DelegateUserIds__c.split(',');
					}
					else
					{
						lstDelegateUserIds = new List<String>{objBackup.Apttus_Approval__DelegateUserIds__c};
					}
					for (String strDelegateUser : lstDelegateUserIds)
					{
							if (setSalesDiscretionaryApproverIds.contains(strDelegateUser))
							{
								boolFoundSalesDiscretionary = true;
								break;
							}
					}
				}

                if (!boolFoundSalesDiscretionary
                    && !setSalesDiscretionaryApproverIds.contains(objBackup.Apttus_Approval__Backup_User__c)
                    && setSalesDiscretionaryApproverIds.contains(UserInfo.getUserId())
                ) {
                    objBackup.addError(Label.UI_Text_Backup_Approver_Error);
                }
            }
        }
    }

    /**
    * @description Overriding the onAfterUpdate base class method
    * @params NA
    * @return void
    **/ 
    public override void onAfterUpdate(Map<Id, SObject> idToBackupApprover)
    {
        Boolean isCurrentUserSalesOps = checkCurrentUserIsSalesOps(currentUserProfileId); 
        for (Apttus_Approval__Backup_Approver__c objBackup : (List<Apttus_Approval__Backup_Approver__c>)records)
        {
            //Added logic for current logged in user to be able to modify own records
            Boolean boolRecordForCurrentUser = objBackup.Apttus_Approval__Current_User__c == UserInfo.getUserId();
            if (objBackup.Apttus_Approval__Backup_User__c != null
                && idToBackupApprover.get(objBackup.Id).get('Apttus_Approval__Backup_User__c') != null
                && objBackup.Apttus_Approval__Backup_User__c != idToBackupApprover.get(objBackup.Id).get('Apttus_Approval__Backup_User__c'))  // broken if condition in two parts for snarqube fix
            {
                if(!boolRecordForCurrentUser && !isCurrentUserSalesOps)
                objBackup.addError(Label.UI_Text_BackupApprover_Modification_Error);
            }
        }  
    }

    /**
    * @description:  This method will check whether user is sales ops OR not
    * @param : Id currentUserProfileId
    * @return Boolean
    **/ 
    private Boolean checkCurrentUserIsSalesOps(Id currentUserProfileId)
    {
        return (Profiles.getCommercialRevenueOperationsProfileId().contains(currentUserProfileId) || Profiles.getCommercialOpsQuotingUserProfileId().contains(currentUserProfileId));
    }

}