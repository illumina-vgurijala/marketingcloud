/**
 *    @author Govind Dubey
 *    @date   03 Aug 2018
 *    @description  Test Data of Approval Process
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *             Developer                      Date                Description
 * 			Govind Dubey					03 Aug 2018			  Test data
 *    ------------------------------------------------------------------------------------
 *
 */
 @isTest
public class TestDataApprovalProcess {

    /**
    *    @author Govind Dubey
    *    @date   03 Aug 2018
    *    @description  Test Data of Approval Process
    */
    public static Apttus_Approval__Approval_Process__c	getApprovalProcess(){
			Apttus_Approval__Approval_Process__c objProcess = new Apttus_Approval__Approval_Process__c();
			objProcess.Apttus_Approval__Active__c = true;
			objProcess.Apttus_Approval__Assignment_Email_Template__c = 'Test Visa Assignment Template';
			objProcess.Apttus_Approval__Cancellation_Email_Template__c = 'Test Visa Cancellation Template';
			objProcess.Apttus_Approval__Escalation_Email_Template__c = 'Test Visa Escalation Template';
			objProcess.Apttus_Approval__NotifyOnly_Email_Template__c = 'Test Visa NotifyOnly Template';
			objProcess.Apttus_Approval__Reassignment_Email_Template__c = 'Test Visa Reassignment Template';
			objProcess.Apttus_Approval__Object_Label__c = 'Quotation';
			objProcess.Apttus_Approval__Object_Name__c = 'Apttus_Proposal__Proposal__c';
			objProcess.Apttus_Approval__Object_Type__c = 'Apttus_Proposal__Proposal__c';
			objProcess.Apttus_Approval__Process_Name__c = 'Test Visa Legal Approval Process';
			objProcess.Apttus_Approval__ProcessAutoEscalate__c = false;
			objProcess.Apttus_Approval__SubmissionCommentsEnabled__c = false;
			objProcess.Apttus_Approval__ContextType__c = 'Single';
			objProcess.Apttus_Approval__Sequence__c = 1;
			objProcess.RecordTypeId = [select id from RecordType where name = 'Approval Process' limit 1].Id;
			insert objProcess;

			Apttus_Approval__Approval_Process__c objEntryCriteria =  new Apttus_Approval__Approval_Process__c(); 
            objEntryCriteria.RecordTypeId = [select id from RecordType where name = 'Entry Criteria' limit 1].Id;
            objEntryCriteria.Apttus_Approval__Active__c = true;
            objEntryCriteria.Apttus_Approval__Entry_Criteria_Active__c = true;
            objEntryCriteria.Apttus_Approval__Entry_Criteria_BoolOper__c = 'AND';
            objEntryCriteria.Apttus_Approval__Entry_Criteria_Comparison_Type__c = 'contains';
            objEntryCriteria.Apttus_Approval__Entry_Criteria_Field__c = 'Name';
            objEntryCriteria.Apttus_Approval__Entry_Criteria_Field_Value__c  = 'Q-';
            objEntryCriteria.Apttus_Approval__Initial_Submission_Field_Name_Source__c = 'Self';
            objEntryCriteria.Apttus_Approval__Entry_Criteria__c = objProcess.ID;
            insert objEntryCriteria;

            
            Apttus_Approval__Approval_Process__c objFieldUpdate =  new Apttus_Approval__Approval_Process__c();
            objFieldUpdate.RecordTypeId = [select id from RecordType where name = 'Initial Submission Action' limit 1].Id;
            objFieldUpdate.Apttus_Approval__Active__c = true;
            objFieldUpdate.Apttus_Approval__Description__c = 'Initial Submission Action on Status';
            objFieldUpdate.Apttus_Approval__Initial_Submission_Action_Type__c = 'Field Update (Constant)';
            objFieldUpdate.Apttus_Approval__Initial_Submission_Action__c = objProcess.ID;
            objFieldUpdate.Apttus_Approval__Initial_Submission_Field_Name_Source__c = 'Self';
            objFieldUpdate.Apttus_Approval__Initial_Submission_Field_Name__c = 'Apttus_QPApprov__Approval_Status__c';
            objFieldUpdate.Apttus_Approval__Initial_Submission_Field_Value__c = 'Not Submitted';
            insert objFieldUpdate;
            
            Apttus_Approval__Approval_Process__c objStepGroup =  new Apttus_Approval__Approval_Process__c();
            
            objStepGroup.RecordTypeId = [select id from RecordType where name = 'Step Group' limit 1].Id;
            objStepGroup.Apttus_Approval__Active__c = true;
            objStepGroup.Apttus_Approval__Step_Group_Active__c = true;
            objStepGroup.Apttus_Approval__Step_Group_Name__c = 'Dummy';
            objStepGroup.Apttus_Approval__Step_Group_Rejection_Action__c = null;
            objStepGroup.Apttus_Approval__Step_Group_Seq_Number__c = 1;
            objStepGroup.Apttus_Approval__Step_Group__c = objProcess.ID;
            
            insert objStepGroup;
            
            Apttus_Approval__Approval_Process__c objStep =  new Apttus_Approval__Approval_Process__c();
            
            objStep.RecordTypeId = [select id from RecordType where name = 'Step' limit 1].Id;
            objStep.Apttus_Approval__Active__c = true;
            objStep.Apttus_Approval__DependsOn__c = null;
            objStep.Apttus_Approval__Send_Email__c = true;
            objStep.Apttus_Approval__StepAutoEscalate__c = false;
            objStep.Apttus_Approval__StepAutoReapprove__c = false;
            objStep.Apttus_Approval__StepFilterConditionDescription__c = null;
            objStep.Apttus_Approval__StepLabel__c = 'Legal Approval';
            objStep.Apttus_Approval__StepSequence__c = 2;
            objStep.Apttus_Approval__StepSubmissionComment1Enabled__c = false;
            objStep.Apttus_Approval__StepSubmissionComment2Enabled__c = false;
            objStep.Apttus_Approval__StepSubmissionComment3Enabled__c = false;
            objStep.Apttus_Approval__StepSubmissionCommentsEnabled__c = false;
            objStep.Apttus_Approval__StepType__c = 'Standard';
            objStep.Apttus_Approval__Step_Active__c = true;
            objStep.Apttus_Approval__Step_Assignee_Description__c = 'Legal Approval for VISA';
            objStep.Apttus_Approval__Step_Assignee_Type__c = 'Related User';
            objStep.Apttus_Approval__Step_Assignee__c = 'OwnerId';
            objStep.Apttus_Approval__Step_Auto_Complete__c = false;
            objStep.Apttus_Approval__Step_Name__c = 'Legal Approval';
            objStep.Apttus_Approval__Step_Notify_Only__c = false;
            objStep.Apttus_Approval__Step_Seq_Number__c = null;
            objStep.Apttus_Approval__Step__c = objStepGroup.ID;            

            insert objStep;

            Apttus_Approval__Approval_Process__c objFieldAction =  new Apttus_Approval__Approval_Process__c();
            
            objFieldAction.RecordTypeId = [select id from RecordType where name = 'Final Action' limit 1].Id;
            objFieldAction.Apttus_Approval__Active__c = true;
            objFieldAction.Apttus_Approval__Final_Approval_Action__c = objProcess.ID;
            objFieldAction.Apttus_Approval__Description__c = 'Final Action on Status';
            objFieldAction.Apttus_Approval__Final_Action_Field_Name_Source__c = null;
            objFieldAction.Apttus_Approval__Final_Action_Field_Name__c = 'Apttus_QPApprov__Approval_Status__c';
            objFieldAction.Apttus_Approval__Final_Action_Field_Update_Type__c = 'Field Update (Constant)';
            objFieldAction.Apttus_Approval__Final_Action_Field_Value__c = 'Pending Approval';
            objFieldAction.Apttus_Approval__Final_Action_Type__c = 'Approved';            
            
            insert objFieldAction;

			return objProcess;		
	}
}