/**
 *    @author Kushagra Desai
 *    @date   8-Aug-2019
 *    @ Test class Coverage: 100% - TestAccountPlanCloneController,TestAccountPlanMobileNavController,	TestAccountPlanObjectivesController,TestCompetitiveDataRollUpSummaryCtrl,TestContentDocumentLinks,
 *                                  TestNewAccountPlanController,TestPlanAssociatedOppsController,TestStakeHolderController,TestViewActivePlansController,TestViewActivePlansTerritoryController
 *    @ Test class Coverage : 75% - TestNewAccountPlanController
 *    @description   
 *    Test Class for 90% coverage: TestViewActivePlansTerritoryController, TestAccountPlanMobileNavController, TestNewAccountPlanController, TestAccountPlanCloneController, TestAccountPlanObjectivesController, TestCompetitiveDataRollUpSummaryCtrl, TestStakeHolderController, TestViewActivePlansController, TestPlanAssociatedOppsController
 *    Test Class for 75% coverage: TestViewActivePlansTerritoryController, TestAccountPlanMobileNavController, TestNewAccountPlanController, TestAccountPlanCloneController, TestAccountPlanObjectivesController, TestCompetitiveDataRollUpSummaryCtrl, TestStakeHolderController, TestViewActivePlansController, TestPlanAssociatedOppsController
 *    Modification Log:
 *    ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                Description
 *    Kushagra Desai                28-Aug-2019          Added getInCompleteAccountPlan()
 *    Akshay Mohan                  05-Sep-2019          Added query to get plans based on set of record IDs
 *    KD                            31-Aug-2020          DCP-40334 :add new method getAccountPlanByAccountIdsandStatus
 *    Prem Ranjan                   19/11/2021           DCP-50569 : added getAccPlanWithoutAttachment
 *    Adithi Acharya                30/9/2022            100% Coverage Test classes: TestAccountPlanCloneController,TestAccountPlanMobileNavController,	TestAccountPlanObjectivesController,TestCompetitiveDataRollUpSummaryCtrl,TestContentDocumentLinks,
 *                                                       TestNewAccountPlanController,	TestPlanAssociatedOppsController,TestStakeHolderController,	
 *                                                       TestViewActivePlansController,TestViewActivePlansTerritoryController
 * ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------                  
 *    Atit Kar                      22-Sep-2022          TASK0813868 - Created new field Customers_Cash_Flow__c on Account_Plan__c object and removed two 
 *                                                                     unused method 'getAccountPlanByAccountIdsandStatus' & 'getAccountPlanByAccountIds'
 *    Atit Kar                      09-Dec-2022          INC0442456 - Added new field 'Account_Name__r.Territory_Region__c' in getAccountPlanByAccountPlanRecordId()
 * --------------------------------------------------------------------------------------- 
 *                    
 */
public with sharing class AccountPlanSelector extends ilib_SObjectSelector{
 /*
    * @author Kushagra Desai
    * @date   8-Aug-2019   
    * @description  set select fields
    */
    public List<Schema.SObjectField> getSObjectFieldList()
    {	
        return new List<Schema.SObjectField> {
            Account_Plan__c.Name,
            Account_Plan__c.id,
            Account_Plan__c.Owner.Name,
            Account_Plan__c.Account_Name__c,
            Account_Plan__c.Plan_Status__c,
            Account_Plan__c.Plan_Target__c,
            Account_Plan__c.Start_Date__c,
            Account_Plan__c.End_Date__c,
            Account_Plan__c.Customer_s_Top_Competitors__c, 
            Account_Plan__c.Overall_Stage_of_Relationship__c,
            Account_Plan__c.LastModifiedDate,
            Account_Plan__c.Illumina_Strategy__c,
            Account_Plan__c.Required_Support_and_Resources__c,
            Account_Plan__c.Illumina_Obstacles_Risks__c,
            Account_Plan__c.Customer_Overview__c,
            Account_Plan__c.Buying_Decision_Process__c,
            Account_Plan__c.Customer_s_Mission_Vision__c,
            Account_Plan__c.Customer_s_Strategic_Imperatives__c,
            Account_Plan__c.Agreement_Contract_Notes__c,
            Account_Plan__c.Customer_s_Challenges__c,
            Account_Plan__c.Customer_s_Priorities__c,
            Account_Plan__c.Company_s_Annual_Revenue_Funding__c,
            Account_Plan__c.Customers_Cash_Flow__c,
            Account_Plan__c.Customer_s_Previous_Year_s_Growth__c,
            Account_Plan__c.Fiscal_Year_End__c,
            Account_Plan__c.Number_of_Employees__c,
            Account_Plan__c.Geographic_Coverage__c,
            Account_Plan__c.Key_Partners_Affiliates__c,
            Account_Plan__c.Key_Customers__c,
            Account_Plan__c.Industry_Organization_Highlights__c,
            Account_Plan__c.Gap_Analysis__c,
            Account_Plan__c.Percent_of_Upside__c,
            Account_Plan__c.Percent_of_Not_Forecasted__c,
            Account_Plan__c.Percent_of_Create__c,
            Account_Plan__c.Est_Run_Rate__c
        };
    }

    /*
    * @author Kushagra Desai
    * @date   8-Aug-2019 
    * @description  describe the object
    *
    */
    public Schema.SObjectType getSObjectType()
    { 
        return Account_Plan__c.sObjectType;
    }

    /**
     * @author : Akshay Mohan
     * @description return all Account plan
     * Returns List<Account_Plan__c> sObject Record 
     **/
    public List<Account_Plan__c> getAccountPlanByIds(Set<ID> setIds)
    {
        return (List<Account_Plan__c>)Database.query(newQueryFactory()
        .setCondition('ID IN :setIds').toSOQL());
    }

    /**
     * @author : Kushagra Desai
     * @description return all active Account plan
     * Returns Apttus_Proposal__Proposal__c sObject Record 
     **/
    public List<Account_Plan__c> getAccountPlan(String strAccountid,String strStatus)
    {
        return (List<Account_Plan__c>)Database.query(newQueryFactory().selectfield('Account_Name__r.Active_Account_Plan__c').setCondition('Account_Name__c =:strAccountid AND Plan_Status__c=:strStatus').toSOQL());
    }
    
    /**
     * @author : Vaibhav Sirohi
     * @description return specific Account plan
     * Returns return specific Account plan Record 
     **/
    public Account_Plan__c getAccountPlanByAccountPlanRecordId(String accountPlanId)
    {
        return (Account_Plan__c)Database.query(newQueryFactory().selectfield('Account_Name__r.Ultimate_Parent_Id__c')
                                                    .selectfield('Account_Name__r.Ultimate_Parent__c')
                                                    .selectfield('Account_Name__r.ParentId')
                                                    .selectfield('Account_Name__r.Territory_Region__c') //INC0442456
                                                    .selectfield('Owner.Name')
                                                    .setCondition('id =:accountPlanId ').toSOQL());
    }
   /**
     * @author : Kushagra Desai
     * @description return all active Account plan for set of accounts
     * Returns A
     **/
    public List<Account_Plan__c> getActiveAccountPlanByAccountIds(Set<Id> setIds,String strStatus)
    {
        return (List<Account_Plan__c>)Database.query(newQueryFactory().selectField('Account_Name__r.Name')
                                                     .selectField('Owner.Name')
                                                     .setCondition('Account_Name__c IN :setIds AND Plan_Status__c=:strStatus').toSOQL());
    }
    /**
     * @author : Prem Ranjan
     * @description return all Account plan whose Is File Attached is False
     * Returns List<Account_Plan__c> sObject Record 
     **/
    public List<Account_Plan__c> getAccPlanWithoutAttachment(Set<ID> setIds)
    {
        return (List<Account_Plan__c>)Database.query(newQueryFactory().selectField('Is_file_attached__c')
                                                                    .setCondition('ID IN :setIds AND Is_file_attached__c = False').toSOQL());
    }
    
}