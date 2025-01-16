/**
*    @author Adyasha Satapathy
*    @date   2021-04-30
*    @description  DCP-39763: Auto Create Opportunity and Opportunity Products from Work Order
*    Test Class for 75% coverage : TestCreateQuoteAutomation, TestOpportunityQuoteAutomation
*    Test Class 90% : TestCreateQuoteAutomation, TestOpportunityQuoteAutomation
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Adyasha Satapathy            2021-04-30            Initial Version
*         KD                           2021-05-10            DCP-46472 : Error handling 
*         Akshay Mohan                 2021-05-25            DCP-39386: Opportunity logic for re-quote
*         Anshaj Sinha                 2022-08-22            CMSI-199 : Instrumented class with PS Log Fw methods, changed existing message methods to info methods
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class CreateOpportunityAutomation implements IOpportunityQuoteAutomation
{ 
    private Id opportunityId;
    private Id workOrderId;
    SVMXC__Service_Order__c objSourceWorkOrder;
    
    public static final String OPP_NAME_BILLABLE_SERVICE = 'Billable Service Opp';
    public static final String STRING_GIS_ILLUMINA_USER = 'GIS Illumina';
    private OpportunityQuoteAutomationQueueable.STATUS status=OpportunityQuoteAutomationQueueable.STATUS.OPP_CREATING;
    private static String strErrorMessage;
    private static final String LOG_TITLE = 'CreateOpportunityAutomation';
    public static Boolean catchException = false;

    /**
    *   DCP-39763
	*	@author Adyasha Satapathy
	*	@param NA
	*	@return Id of Opportunity
	**/
    public Id getRecordId()
    {
        return opportunityId;
    }
    
    /**
    *   DCP-39763
	*	@author Adyasha Satapathy
	*	@param WorkOrder Id
	*	@return void
	**/
    public void setRecordId(string parentRecordId)
    {
        this.workOrderId = parentRecordId;    
    }

    /**
    *   DCP- 39763
    *	@author Adyasha Satapathy
    *	@param NA
    *	@return OpportunityQuoteAutomationQueueable.EmailWrapper
    **/
    public OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(){
        OpportunityQuoteAutomationQueueable.EmailWrapper wrapDetails= new OpportunityQuoteAutomationQueueable.EmailWrapper();
        wrapDetails.idRecord = workOrderId;
        wrapDetails.setEmail(objSourceWorkOrder.OwnerId);
        wrapDetails.setErrorDetails(strErrorMessage);
        wrapDetails.strFailureReason = (status == OpportunityQuoteAutomationQueueable.STATUS.OPP_CREATING)? Label.OpportunityQuoteAutomation_OPP_CREATING : Label.OpportunityQuoteAutomation_OTHER;
        wrapDetails.idProposal=null;
        wrapDetails.idSourceWorkOrder=objSourceWorkOrder.id;
        wrapDetails.strQuoteName='';
        wrapDetails.strWOName=objSourceWorkOrder.Name;
        wrapDetails.strRegion=objSourceWorkOrder.Account_Region__c;
        return wrapDetails;
    }
    
    /**
    *   DCP-39763
	*	@author Adyasha Satapathy
	*	@param QueueableContext
	*	@return void
	**/
    public void execute(QueueableContext context)
    {
        ilib_LogEvent.setTitle(LOG_TITLE, ilib_LogEvent.SALES);//CMSI-199
        ilib_LogEvent.push(LOG_TITLE + '.execute()');
        objSourceWorkOrder = new WorkOrdersSelector().selectWorkOrderWithWorkDetails(new Set<Id>{workOrderId})[0];
        ilib_LogEvent.info('Owner email--->'+objSourceWorkOrder.Owner.Email);
        ilib_LogEvent.info('Opportunity--->'+objSourceWorkOrder.Opportunity__c);
        ilib_LogEvent.info('contact on WO--->'+objSourceWorkOrder.SVMXC__Contact__c);
        
        try{
            //DCP-39386: Start
            Id idOpportunity = createOpportunityRecord(objSourceWorkOrder);
            ilib_LogEvent.info('Checking contact role');
            createContactRoleForOpportunity(idOpportunity,objSourceWorkOrder);
            opportunityId = idOpportunity;
            //DCP-39386: End
            status=OpportunityQuoteAutomationQueueable.STATUS.OPP_CREATED;
            if(catchException == true){
                throw new AuraHandledException('throwing custom exception');
            }
        }
        catch(Exception e)
        {
            ilib_LogEvent.error('@@@@ Exception, details here: '+e);
            strErrorMessage = e.getMessage();
            ApexExceptions.emit(LOG_TITLE,workOrderId,e, ilib_LogEvent.SALES);
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
           
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();//CMSI-199
    }

    /**
    *   DCP-39763
	*	@author Adyasha Satapathy
    *   @description Create Opportunity
	*	@param WorkOrder
	*	@return Opportunity
	**/
    public Id createOpportunityRecord(SVMXC__Service_Order__c objWorkOrder)
    {
        ilib_LogEvent.push(LOG_TITLE + '.createOpportunityRecord()');
        //DCP-39386: Start
        if(String.isNotBlank(objWorkOrder.Opportunity__c)){
            ilib_LogEvent.pop();
            return objWorkOrder.Opportunity__c;
        }
        //DCP-39386: End
        Boolean boolDirectOpportunity = String.isBlank(objWorkOrder.Distributor_Account__c);
        String strRecordTypeId = boolDirectOpportunity ? Opportunities.RECORD_TYPE_MAP.get(Label.FieldServices).getRecordTypeId() : Opportunities.RECORD_TYPE_MAP.get(Label.IndirectFieldServices).getRecordTypeId();
        String strSerialNumber = String.isBlank(objWorkOrder.Installed_Product_Serial_Number__c) ? '' : ' - ' + objWorkOrder.Installed_Product_Serial_Number__c;
        Account accDistributorReference = new Account(ERP_Customer_Id__c = objWorkOrder.Distributor_Account__c);

        Opportunity objOpportunityToInsert = new Opportunity();
        
        objOpportunityToInsert.Name = objWorkOrder.Name + ' - ' + OPP_NAME_BILLABLE_SERVICE + strSerialNumber;
        objOpportunityToInsert.Ultimate_Consignee__c = objWorkOrder.SVMXC__Company__c;
        objOpportunityToInsert.RecordTypeId = strRecordTypeId;
        objOpportunityToInsert.Type = Label.OpportunityTypeBillableService;
        objOpportunityToInsert.CloseDate = Date.today().addDays(90);
        objOpportunityToInsert.Product_Interest__c = Label.OpportunityProductInterestBreakFix;
        objOpportunityToInsert.StageName = Label.OpportunityStageDevelop;
        objOpportunityToInsert.Probability = Decimal.valueOf(50);
        objOpportunityToInsert.Amount = 0;
        objOpportunityToInsert.Work_Order__c = objWorkOrder.Id;
        
        if(boolDirectOpportunity)
        {
            objOpportunityToInsert.AccountId = objWorkOrder.Sold_To_Account__c;
        }
        else
        {
            objOpportunityToInsert.Account = accDistributorReference;
            objOpportunityToInsert.Distributor__r = accDistributorReference;
        }
        ilib_LogEvent.info('Opportunity inserting: '+objOpportunityToInsert);
        insert objOpportunityToInsert;
        ilib_LogEvent.info('Opportunity ID : '+objOpportunityToInsert.id);
        objWorkOrder.Opportunity__c = objOpportunityToInsert.Id;
        update objWorkOrder;
        ilib_LogEvent.info('Work Order updated');
        ilib_LogEvent.pop();
        return objOpportunityToInsert.id;
    }

    /**
    *   DCP-39763
	*	@author Adyasha Satapathy
    *   @description Create Contact Role for Opportunity
	*	@param WorkOrder, Opportunity
	*	@return NA
	**/
    public void createContactRoleForOpportunity(Id idOpportunity,SVMXC__Service_Order__c objWorkOrder)
    {
        ilib_LogEvent.push(LOG_TITLE + '.createContactRoleForOpportunity()');
        Boolean boolContactRoleExisting = false;
        
        for(OpportunityContactRole oppContactRole : new OpportunityContactRoleSelector().selectRoles(new Set<Id>{idOpportunity}))
        {
            if(oppContactRole.ContactId == objWorkOrder.SVMXC__Contact__c)
            {
                ilib_LogEvent.message('Inside first IF Loop');
                boolContactRoleExisting = true;
                ilib_LogEvent.message('boolContactRoleExisting = true');
                break;
            }
        }
        if(!boolContactRoleExisting)
        {
            ilib_LogEvent.message('Inside second IF Loop');
            OpportunityContactRole objContactRole = new OpportunityContactRole();
            objContactRole.ContactId = objWorkOrder.SVMXC__Contact__c;
            objContactRole.IsPrimary = true;
            objContactRole.Role = Label.Power_Sponsor_Contact_Role;
            objContactRole.OpportunityId = idOpportunity;
            insert objContactRole;
            ilib_LogEvent.info('Inserted objContactRole : '+objContactRole);
        }
        ilib_LogEvent.pop();
    }
}