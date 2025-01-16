/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: This class contains logic for handling Promotion approval for Record Owner Flow in Quote Lines
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27            Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsQuoteLinePromotions extends ApprovalsStepBase {
    
    // NOTE: these are in base class
    // protected Approvals.SupportData data;
    // protected Approvals.StepName stepName;
    // protected Approvals.StepResults stepResults;
    // protected Approvals.Outputs outputs;

    private Apttus_Proposal__Proposal_Line_Item__c quoteLine;
    private Id promotionId;

    /*
    *  @author:         Todd Newman
    *  @description:    Constructor
    */
    public ApprovalsQuoteLinePromotions(Approvals.StepName stepName, Approvals.SupportData data)
    {
        super(stepName, data);
    }

    /*
    *  @author:         Todd Newman
    *  @description:    Setter method for initializing the proposal line item record's value
    */
    public override void setRecord(Object record)
    {
        this.quoteLine = (Apttus_Proposal__Proposal_Line_Item__c)record;
    }

    /*
    *  @author:         Todd Newman
    *  @description:    Checks whether the logic for promotion approvals should run or not, if not eligible then exit the flow
    */
    public override Boolean isStepAppropriateForRecord()
    {
        // this will be called for each possible promotion
        // determine which one for this call
        if      (stepName == Approvals.StepName.PROMOTION_1) { promotionId = quoteLine.Promotion_1__c; }
        else if (stepName == Approvals.StepName.PROMOTION_2) { promotionId = quoteLine.Promotion_2__c; }
        else if (stepName == Approvals.StepName.PROMOTION_3) { promotionId = quoteLine.Promotion_3__c; }
        else if (stepName == Approvals.StepName.PROMOTION_4) { promotionId = quoteLine.Promotion_4__c; }
        else if (stepName == Approvals.StepName.PROMOTION_5) { promotionId = quoteLine.Promotion_5__c; }
        else { throw new UnsupportedOperationException(); }

        return promotionId != null;
    }

    /*
    *  @author:         Todd Newman
    *  @description:    Checks for Promotion Approvals
    */
    public override void calculate()
    {
        // output values
        Boolean isHierarchyFound = false;
        Id hierarchyId = null;
        Integer approvalLevel = null;

        String promoCode = data.idToPromo.get(promotionId).Apttus_Config2__IncentiveCode__c;        

        if (data.approvalMatricesWrapper.promoCodeToMatrices.containsKey(promoCode))
        {
            for (Custom_Approval_Matrix__c matrix : data.approvalMatricesWrapper.promoCodeToMatrices.get(promoCode))
            {
            	hierarchyId = matrix.Approval_Hierarchy__c;
                isHierarchyFound = true;
                stepResults.approvalCategories.add(Approvals.Category.PROMOTION.name());
                for (Integer intCurrentLevel = 1; intCurrentLevel <= Approvals.MAX_APPROVAL_LEVEL; intCurrentLevel++)
                {
                	Object objApprover = matrix.getSobject('Approval_Hierarchy__r').get('Approver_Level_' + intCurrentLevel + '__c');
                    if (objApprover == null) { break; }
                    approvalLevel = intCurrentLevel;
                }
            }
        }

        stepResults.approvalFound = isHierarchyFound;
        stepResults.discount = new Approvals.HierarchyAndLevel(isHierarchyFound, hierarchyId, approvalLevel);
    }
}