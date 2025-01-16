/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: This class contains logic for handling Material Number approval for Record Owner Flow in Quote Lines
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-08-11            Initial Version
*         Kushal Shah                 2021-09-28           DCP-49429: Added logic for MFN Aprovals
*         Bharath Varma               2021-12-07           DCP-50961: Added logic for AgreementLine Approvals
*         Bharath Varma               2022-04-28           TASK0746219: Added Discount > 0 check to bypass quote lines with 0 discounts
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing abstract class ApprovalsStepBase implements IApprovalsStep 
{
    // context data for this transaction mapped into useful collections
    protected Approvals.SupportData data;
    // name of the step, used for logging and sometimes business logic
    protected Approvals.StepName stepName;

    // each step in the pipeline builds these values over the course of the step
    protected Approvals.StepResults stepResults;
    // the output which is built over multiple steps
    // StepResults are merged into this variable at the end of the step
    protected Approvals.Outputs outputs;

    private IApprovalsDomainStep domainDelegator;

    /*
    *   @description:    
    *   Constructor
    */
    public ApprovalsStepBase(Approvals.StepName stepName, Approvals.SupportData data)
    {
        this.stepName = stepName;
        this.data = data;
        domainFactory();
    }

    private void domainFactory()
    {
        if (Approvals.getDomain(stepName) == Approvals.StepDomain.AGREEMENT_LINE)
        {
            domainDelegator = new ApprovalsAgreementLineStepBase(stepName, data);
        }
        else
        {
            domainDelegator = new ApprovalsQuoteLineStepBase(stepName, data);
        }
    }

    ////////////////////////////////////////////////////////////
    // PUBLIC API
    ////////////////////////////////////////////////////////////
    
    /*
    *   @description:    
    *   execute method which will run the entire pipeline
    */
    public virtual Approvals.Outputs execute(Object record, Approvals.Outputs outputs)
    {
        setRecord(record);
        this.outputs = outputs;

        stepResults = new Approvals.StepResults();
        domainDelegator.initStepData(stepResults, outputs);

        if (isStepAppropriateForRecord())
        {
            calculate();

            copyStepResultsToOutput();
        }
        else
        {
            stepResults.approvalFound = false;
        }

        return outputs;
    }

    // these three API methods must be overridden by the descendent

    /*
    *   @description:    
    *   Setter method for initializing the record's value
    */
    public abstract void setRecord(Object record);

    /*
    *   @description:    
    *   Checks whether the logic for current step should run or not, if not eligible then exit the flow
    */
    public abstract Boolean isStepAppropriateForRecord();
    
    /*  
    *   @description:
    *   executes the approval logic to find hierarchy and level for current step
    */
    public abstract void calculate();

    // if we agree this implementation is complete it can be removed from the interface and made private
    
    /*  
    *   @description:
    *   after execution of a particular step, final hierarchy & level results are copied to output wrapper which is stamped later on record
    */
    public virtual void copyStepResultsToOutput()
    {
        domainDelegator.copyHierarchyAndLevel();

        copyCategories();

        domainDelegator.copyErrorInformation();

        ilib_LogEvent.message(stepName.name() + ': outputs.approvalsResults.isHierarchyFound ' + outputs.approvalsResults.isHierarchyFound);
        ilib_LogEvent.message(stepName.name() + ': outputs.approvalsResults ' + outputs.approvalsResults);
        ilib_LogEvent.message(stepName.name() + ': outputs.approvalsResults.approvalCategories ' + outputs.approvalsResults.approvalCategories);
        ilib_LogEvent.message(stepName.name() + ': outputs.quotesWithMatrixError ' + outputs.quotesWithMatrixError);
        ilib_LogEvent.message(stepName.name() + ': outputs.erroredQuoteIdToAccount ' + outputs.erroredQuoteIdToAccount);
        ilib_LogEvent.message(stepName.name() + ': outputs.erroredQuoteIdToOwnerIds ' + outputs.erroredQuoteIdToOwnerIds);
    }

    /*  
    *   @description:
    *   after execution of a particular step, final category results are copied to output wrapper which is stamped later on record
    */
    private void copyCategories()
    {
        // copy approval categories
        // no values for china/grail
        // which won't hurt anything
        outputs.approvalsResults.approvalCategories.addAll(stepResults.approvalCategories);

        // copy approval required boolean
        // value only possible for china/grail
        // other step false values won't hurt anything 
        outputs.approvalsResults.requiresApprovalWithoutCategory = outputs.approvalsResults.requiresApprovalWithoutCategory || stepResults.approvalFound;
        //DCP-49429 Kushal Shah
        if (stepName == Approvals.StepName.CPQ_MFN) {
            outputs.approvalsResults.isMFNApprovalLine = stepResults.isMFNApprovalLine;
        }
    }

    /*  
    *   @description:
    *   called in every step execution
    *   determines the highest priority matrix based on input data and type of Approval
    */
    protected Approvals.MatrixWrapper findHighestPriorityMatrix(SObject line, String strApprovalType, Boolean isTransborder, String hierarchyType)
    {
        return domainDelegator.findHighestPriorityMatrix(line, strApprovalType, isTransborder,hierarchyType);
    }

    // // during test we do it this way because the records aren't persisted so formula fields don't work
    // private String calculateChannelTestContext(Apttus_Proposal__Proposal__c quote)
    // {
    //     if (quote.Apttus_Proposal__Opportunity__r.RecordType.Name == 'Indirect Standard') {
    //         return System.Label.DistributionChannelIndirect;
    //     } else {
    //         return System.Label.DistributionChannelDirect;
    //     }
    // }

    ////////////////////////////////////////////////////////////
    // Private methods
    // used by descendents
    ////////////////////////////////////////////////////////////
    // TODO: methods below here are quote or agreement domain-specific
    // should they be moved somewhere else?

    /*  
    *   @description:
    *   determines whether current product in quote line is a fixed bundle
    */
    protected Boolean getIsQuoteLineFixedBundle(Apttus_Proposal__Proposal_Line_Item__c quoteLine) 
    {
        Boolean isFixedBundle = false;        
        if(quoteLine.Apttus_QPConfig__OptionId__c == null) {
            Id productId = quoteLine.Apttus_Proposal__Product__c;
            if(data.idToProduct.containsKey(productId) && data.idToProduct.get(productId).Material_Class_Type__c == Label.FixedBundleMatClassType) {
                isFixedBundle = true;
            }            
        } 
        return isFixedBundle;
    }

    /*  
    *   @description:   
    *   determines whether discount applied is of sales discretionary type
    */
    protected Boolean getIsDiscountTypeSalesDiscretionary(Apttus_Proposal__Proposal_Line_Item__c quoteLine) 
    {
        // TASK0746219 - added Discount > 0 check to trigger approvals only on lines with discount > 0
        Decimal lineDiscountPercent = (quoteLine.Applied_Discount_Percentage__c == null ? 0 : quoteLine.Applied_Discount_Percentage__c);
        return String.isNotBlank(quoteLine.Applied_Discount_Details__c) && 
                quoteLine.Applied_Discount_Details__c.contains(Label.ApprovalStepNameSalesDiscretionary) && 
                // TASK0746219 
                lineDiscountPercent > 0;
    }

    /*  
    *   @description:
    *   method to remove Id from a set of Ids
    */
    protected void addAgreementsToRemoveFromMatrixError(Id agreementId, Set<Id> setWithAgreementId){
		if(!setWithAgreementId.contains(agreementId))
        {
            setWithAgreementId.add(agreementId);
        }
	}

}