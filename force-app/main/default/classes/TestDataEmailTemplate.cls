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
public class TestDataEmailTemplate {
	public static List<Id> getEmailTemplates(){
		List<Folder> lstFolders = [Select Id From Folder Where Name = 'Visualforce Email Templates' ];
		List<Id> lstEmailTemplates = new List<Id>();
		if(lstFolders.size() > 0)
		{
			System.runAs ( new User(Id = UserInfo.getUserId()) ) {
				Id folderId = lstFolders[0].Id;
				EmailTemplate objAssignTemplate = new EmailTemplate(TemplateType= 'Text');
				objAssignTemplate.Name = 'Test Visa Assignment Template';
				objAssignTemplate.DeveloperName = 'AssignmentTemplateDeveloperName';
				objAssignTemplate.FolderId = folderId;
				insert objAssignTemplate;
				lstEmailTemplates.add(objAssignTemplate.Id);

				EmailTemplate objReassignmentTemplate = new EmailTemplate(TemplateType= 'Text');
				objReassignmentTemplate.Name = 'Test Visa Reassignment Template';
				objReassignmentTemplate.DeveloperName = 'ReassignmentTemplateDeveloperName';
				objReassignmentTemplate.FolderId = folderId;
				insert objReassignmentTemplate;
				lstEmailTemplates.add(objReassignmentTemplate.Id);

				EmailTemplate objEscalationTemplate = new EmailTemplate(TemplateType= 'Text');
				objEscalationTemplate.Name = 'Test Visa Escalation Template';
				objEscalationTemplate.DeveloperName = 'EscalationTemplateDeveloperName';
				objEscalationTemplate.FolderId = folderId;
				insert objEscalationTemplate;
				lstEmailTemplates.add(objEscalationTemplate.Id);

				EmailTemplate objNotifyOnlyTemplate = new EmailTemplate(TemplateType= 'Text');
				objNotifyOnlyTemplate.Name = 'Test Visa NotifyOnly Template';
				objNotifyOnlyTemplate.DeveloperName = 'NotifyOnlyTemplateDeveloperName';
				objNotifyOnlyTemplate.FolderId = folderId;
				insert objNotifyOnlyTemplate;
				lstEmailTemplates.add(objNotifyOnlyTemplate.Id);

				EmailTemplate objCancellationTemplate = new EmailTemplate(TemplateType= 'Text');
				objCancellationTemplate.Name = 'Test Visa Cancellation Template';
				objCancellationTemplate.DeveloperName = 'CancellationTemplateDeveloperName';
				objCancellationTemplate.FolderId = folderId;
				insert objCancellationTemplate;
				lstEmailTemplates.add(objCancellationTemplate.Id);
			}
		}
		return lstEmailTemplates;
	}
}