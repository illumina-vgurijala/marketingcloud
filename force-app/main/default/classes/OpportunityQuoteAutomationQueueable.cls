/**
*    @author Adyasha Satapathy
*    @date   2021-04-29
*    @description    DCP-38809, DCP-39763
*    @90% Test Classes  -  TestOpportunityQuoteAutomation, TestCartFinalizeSyncQueueable, TestCreateQuoteAutomation, TestQuoteApprovalQueueable, TestQuoteGenerationQueueable, TestValidateQuoteAutomation
*    @75% Test Classes  -  TestCartFinalizeSyncQueueable, TestCreateQuoteAutomation, TestQuoteApprovalQueueable, TestQuoteGenerationQueueable, TestOpportunityQuoteAutomation
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-04-29            Initial Version
*		  KD 						   2021-05-09			 DCP-46472 : Failure email notification
*         Adyasha                      2026-07-26            DCP-49453 : Email Setccaddress update
*         Rishab                       2021-06-11            [DCP-46920] Quotation Document Auto Generation Process
*		  Biswajeet                    2022-08-22			 [CMSI-200] : Instrumentation of class
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class OpportunityQuoteAutomationQueueable implements Queueable
{
	public List<String> lstActionClasses;
    private final Id idRecordId,idWorkOrder;
	private static String strClasses;
    private static final String CODE_PARAMETER_CLASSES_LIST = 'Billable_Quote_Automation_Classes_List';
    private static final String CODE_PARAMETER_DL = 'Quoting_Regional_DL_';
    private static final String EMAIL_TEMPLATE_NAME = 'Opportunity_Quote_Automation_Failure_Notification';
    private static final String EMAIL_TEMPLATE_FAILURE_REASON = '{{REASON_FOR_FAILURE}}';
    private static final String EMAIL_TEMPLATE_ERROR_DETAIL = '{{ERROR_DETIALS}}';
	private static final String LOG_TITLE = 'OpportunityQuoteAutomationQueueable';
	private static final String THREAD='AutomateQuoting';
	public static Boolean catchException = false;   //CMSI-200 Catch block coverage
	
	/**
    *   DCP-46472, 38809
	*	@author Adyasha Satapathy
	*	Enum for status to be used only this framework
	*	
	**/
	public Enum STATUS {OPP_CREATING, OPP_CREATED,
		QUOTE_CREATING, QUOTE_CREATED, QUOTE_DISCOUNT_NEEDED,
		CART_CREATING,CART_CREATED,CART_LINE_CREATING,CART_LINE_CREATED,CART_VALIDATED, CART_VALIDATION_BLOCKED, CART_FINALIZED, CART_SYNCED,
		QUOTE_APPROVAL_BLOCKED, QUOTE_APPROVED, QUOTE_GENERATION_BLOCKED,QUOTE_GENERATED}

	/**
    *   DCP-46472, 38809
	*	@author KD
	*	Wrapper class for email logic
	*	
	**/
	public class EmailWrapper{
		public Id idRecord,idProposal,idSourceWorkOrder;
		public String strFailureReason, strErrorDetails, strQuoteName, strWOName, strEmail, strRegion;
		/**
		*   DCP-46472, 38809
		*	@author KD
		*	Blank logic for setting error details
		**/
		public void setErrorDetails(String strErrorMessage){
			strErrorDetails = String.isBlank(strErrorMessage) ? '' : strErrorMessage;
		}
		/**
		*   DCP-46472, 38809
		*	@author KD
		*	logic to get user email based on id
		**/
		public void setEmail(Id idUser){
			List<User> lstUsers=new UsersSelector().selectByUserId(new Set<Id>{idUser});
			if(!lstUsers.isEmpty()){strEmail = lstUsers[0].Email;}
		}
	}

	/**
    *   DCP-39763, 38809
	*	@author Adyasha Satapathy
	*	@param WorkOrder ID
	*	@return NA
	**/
    public OpportunityQuoteAutomationQueueable(Id idRecordId){
		if(String.isBlank(strClasses)){
			Code_Parameter__mdt objCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAMETER_CLASSES_LIST})[0];
			strClasses = objCodeParam.Value__c;
		}
		this.idRecordId = idRecordId;
		this.idWorkOrder= idRecordId;
	    this.lstActionClasses = strClasses.split(',');
		ilib_LogEvent.setTitle(LOG_TITLE,ilib_LogEvent.SALES);  //CMSI-200
	}
	/**
    *   DCP-39763, 38809
	*	@author Adyasha Satapathy
	*	@param WorkOrder ID, List of Classes
	*	@return NA
	**/
    public OpportunityQuoteAutomationQueueable(Id idRecordId,Id idWorkOrder,List<String> lstActionClasses)
    {
        this.idRecordId = idRecordId;
		this.idWorkOrder = idWorkOrder;
	    this.lstActionClasses = lstActionClasses;
		ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);  //CMSI-200
    }



	/**
    *   DCP-39763, 38809
	*	@author Adyasha Satapathy
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext objQC){
    	ilib_LogEvent.push(LOG_TITLE + '.execute()');
		String strActionName;
		try{
			ilib_LogEvent.info('@@@ lstActionClasses-->'+lstActionClasses);    //CMSI-200
	        strActionName = lstActionClasses.get(0);
			ilib_LogEvent.info('strActionName-->'+strActionName);           //CMSI-200
			IOpportunityQuoteAutomation objImplementation = (IOpportunityQuoteAutomation)Type.forName(strActionName).newInstance();
			objImplementation.setRecordId(idRecordId); 
			objImplementation.execute(objQC);
			lstActionClasses.remove(0);
			Id idReturnId = objImplementation.getRecordId();
			ilib_LogEvent.info('strActionName idReturnId-->'+idReturnId);    //CMSI-200
			if(idReturnId == null){
				if(idWorkOrder==null)
				{ 
					handleNotificationForQuotationAutoGenerate(idRecordId);  //DCP-46920
				}
				else { 
					handleNotification(objImplementation);
					resetInitiateQuoting();
				} 
				ilib_LogEvent.pop();
				ilib_LogEvent.emit();
				return;	
			}
			ilib_LogEvent.info('lstActionClasses Removed-->'+lstActionClasses);    //CMSI-200
			if(lstActionClasses.isEmpty()){
				if(idWorkOrder!=null){
				resetInitiateQuoting();}
				ilib_LogEvent.pop();
				ilib_LogEvent.emit();
				return;
			}
			ilib_Queueablethread  queueableThread=new ilib_Queueablethread(THREAD);
			queueableThread.logandQueue(new OpportunityQuoteAutomationQueueable(idReturnId,idWorkOrder, lstActionClasses),LOG_TITLE,lstActionClasses[0]);
	        ilib_QueueableManager.enqueueJob(queueableThread,ilib_LogEvent.SALES);

			 //code coverage for catch block CMSI-200
			 if(catchException == true){
				throw new AuraHandledException('throwing custom exceptions');
			}
	    }catch(Exception e){
	    	ApexExceptions.emit(strActionName,idRecordId,e, ilib_LogEvent.SALES); //CMSI-200 Added workstream in the passed params
			ilib_LogEvent.emit(); //CMSI-200
	    }
		ilib_LogEvent.pop();
		ilib_LogEvent.emit();
    }

	/**DCP-39386
    *   @author KD
    *   @desc : Update WO
    *   @return NA
    **/
    private void resetInitiateQuoting(){
        update new SVMXC__Service_Order__c(Id = idWorkOrder,Initiate_Quoting__c = null);
    }

	/**DCP-38809
	*	@author Akshay Mohan
	*	@param IOpportunityQuoteAutomation objImplementation
	*	@return void
	**/
    public void handleNotification(IOpportunityQuoteAutomation objImplementation){
		ilib_LogEvent.push(LOG_TITLE + '.handleNotification()');
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		EmailWrapper wrapDetails=objImplementation.getErrorDetails();
		if(wrapDetails==null){return;}
		ilib_LogEvent.info('wrapDetails: '+wrapDetails);                 //CMSI-200
		email.setToAddresses(new List<String>{wrapDetails.strEmail});
        EmailTemplate emailTemplate = new EmailTemplatesSelector().selectByNameOrDeveloperName(new List<String>{EMAIL_TEMPLATE_NAME}).get(0);
		email.setSubject(emailTemplate.Subject);
		email.setHtmlBody(replaceBindVariables(emailTemplate.HtmlValue,wrapDetails));
		email.setPlainTextBody(replaceBindVariables(emailTemplate.Body,wrapDetails));
		sendEmailNotification(wrapDetails.strRegion,email);
		ilib_LogEvent.pop();
	}
    /**
    *   DCP-46472
	*	@author KD
	*	@param String Region,Error Details,Stage of failure
	*	@return void
	**/
	public static void sendEmailNotification(String strRegion,Messaging.SingleEmailMessage email){
		Code_Parameter__mdt objCodeParam = new CodeParametersSelector().selectCodeParameterByDeveloperName(new Set<String>{CODE_PARAMETER_DL+strRegion}).get(0);
		email.setCcAddresses(Test.isRunningTest() ? new List<String>{'abc@illumina.com'} : objCodeParam.Value__c.split(';'));
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
	}
	/**
    * @author KD
    * @date   23-Sep-2020
    * @description  Replace content with task attributes
    */
    public static String replaceBindVariables(String strContent,EmailWrapper wrapDetails){
		ilib_LogEvent.push(LOG_TITLE+'.replaceBindVariables()'); //CMSI-200
    	String strBaseURL=System.Url.getOrgDomainUrl().toString().split('=')[1].remove(']')+'/';
		String strReplaced=strContent;
        strReplaced=strReplaced.replaceAll('(\\{!Apttus_Proposal__Proposal__c\\.Link\\})',String.isNotBlank(wrapDetails.idProposal) ? strBaseURL+wrapDetails.idProposal : '');
        strReplaced=strReplaced.replaceAll('(\\{!SVMXC__Service_Order__c\\.Link\\})',String.isNotBlank(wrapDetails.idSourceWorkOrder) ? strBaseURL+wrapDetails.idSourceWorkOrder : '');
        strReplaced=strReplaced.replaceAll('(\\{!Apttus_Proposal__Proposal__c\\.Name\\})',String.isNotBlank(wrapDetails.strQuoteName) ? wrapDetails.strQuoteName : '');
        strReplaced=strReplaced.replaceAll('(\\{!SVMXC__Service_Order__c\\.Name\\})',String.isNotBlank(wrapDetails.strWOName) ? wrapDetails.strWOName : '');
        strReplaced=strReplaced.replace(EMAIL_TEMPLATE_FAILURE_REASON,wrapDetails.strFailureReason);
        strReplaced=strReplaced.replace(EMAIL_TEMPLATE_ERROR_DETAIL,wrapDetails.strErrorDetails);
        strReplaced=strReplaced.remove('<![CDATA[');
        strReplaced=strReplaced.remove(']]>');
		ilib_LogEvent.info('Replaced String returned :'+strReplaced); //CMSI-200
		ilib_LogEvent.pop(); //CMSI-200
        return strReplaced;
    }
	
	 /**
	 * @author Rishab
	 * @date 11 June 2021
	 * @description [DCP-46920] handle notifications from Quotation Document Auto Generation Process
	 */
	public static void handleNotificationForQuotationAutoGenerate(Id proposalId)
	{
		ilib_LogEvent.push(LOG_TITLE + '.handleNotificationForQuotationAutoGenerate()');
		Apttus_Proposal__Proposal__c objProposal = new ApttusProposalsSelector().selectProposalById(String.valueOf(proposalId));
		String ownerEmailId = objProposal.Prepared_by__r.Email;
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setToAddresses(new List<String>{ownerEmailId});
        email.setSubject(GenerateEmailService.setEmailSubject(objProposal));
		email.setHtmlBody(GenerateEmailService.getEmailBody(false,objProposal));
		List<OrgWideEmailAddress> lstOrgWideAddress = new List<OrgWideEmailAddress>(new OrgWideEmailAddressesSelector().getOWDAddress(new Set<String>{'sfdc_service_account@illumina.com'}));
        if(test.isRunningTest())
			{
				email.setToAddresses( new String[] {'abcd@illumina.com'} );
			}
		else { email.setOrgWideEmailAddressId(lstOrgWideAddress.get(0).Id); }
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
		ilib_LogEvent.pop();
	}
    
}