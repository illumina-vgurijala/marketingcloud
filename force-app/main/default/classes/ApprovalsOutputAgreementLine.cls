/**
*    @author Bharath Varma
*    @date   2021-12-07
*    @description    DCP-50961: Class to stamp output values on fields of record after output is calculated
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma               2021-12-07           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsOutputAgreementLine implements IApprovalsOutputProcessor {

    private final Map<Id, Apttus__APTS_Agreement__c> idToAgreement;

    /*
    *   @description:
    *   constructor    
    */
    public ApprovalsOutputAgreementLine(Map<Id, Apttus__APTS_Agreement__c> idToAgreement)
    {
        this.idToAgreement = idToAgreement;
    }

    /*
    *   @description:
    *   stamps values on line level after output is calculated for entire pipeline        
    */
    public void stampValues(Object record, Approvals.Outputs outputs)
    {
        Apttus__AgreementLineItem__c agreementLine = (Apttus__AgreementLineItem__c)record;

        agreementLine.Approval_Level_Discount__c = outputs.approvalsResults.customDiscount.level;
        agreementLine.Approval_Level_Material_Group__c = outputs.approvalsResults.customMaterialGroup.level; 
        agreementLine.Approval_Level_Material_Number__c = outputs.approvalsResults.customMaterialNumber.level;

        agreementLine.Approval_Hierarchy_Discount__c = outputs.approvalsResults.customDiscount.hierarchy;
        agreementLine.Approval_Hierarchy_Material_Group__c = outputs.approvalsResults.customMaterialGroup.hierarchy;
        agreementLine.Approval_Hierarchy_Material_Number__c = outputs.approvalsResults.customMaterialNumber.hierarchy;

        agreementLine.Approval_Hierarchy_Record_Owner__c = outputs.approvalsResults.discount.hierarchy;
        //agreementLine.Approval_Level_RO_Discount__c = outputs.approvalsResults.discount.level; -- Commented for DGP-821

        //agreementLine.Approval_Category__c = String.join(new List<String>(outputs.approvalsResults.approvalCategories), ';'); -- Commented for DGP-821
        agreementLine.Apttus_Approval__Approval_Status__c = outputs.approvalsResults.approvalStatus;
        agreementLine.is_MFN_Line_Item__c = outputs.approvalsResults.isMFNApprovalLine;
        
        // DGP-52 : To populate Approval Matrix (Record Owner) AND Min Discount%
        Custom_Approval_Matrix__c approvalMatrixRecordOwner;
        
        if(outputs.materialNumberRecordOwnerMatrix != null) {
            approvalMatrixRecordOwner = outputs.materialNumberRecordOwnerMatrix;
        } else if(outputs.materialGroup1RecordOwnerMatrix != null) {
            approvalMatrixRecordOwner = outputs.materialGroup1RecordOwnerMatrix;
        } else if(outputs.discountRecordOwnerMatrix != null) {
            approvalMatrixRecordOwner = outputs.discountRecordOwnerMatrix;
        }
        
        agreementLine.Approval_Matrix_Record_Owner__c = approvalMatrixRecordOwner == null ? null : approvalMatrixRecordOwner.Id;
        agreementLine.Min_Discount__c = approvalMatrixRecordOwner == null ? null : approvalMatrixRecordOwner.Min_Discount__c;
        agreementLine.Approval_Level_RO_Discount__c = approvalMatrixRecordOwner == null ? null : getRecordOwnerApprovalLevel(agreementLine, approvalMatrixRecordOwner); //DGP-302, DGP-821
        
        removeRecordOwnerApprovalCategoriesForLevel1(agreementLine, outputs); //DGP-302, DGP-821
        agreementLine.Approval_Category__c = String.join(new List<String>(outputs.approvalsResults.approvalCategories), ';'); //DGP-302, DGP-821
    }
    
    /**
     * Method to get Approval Level from "Record Owner" Custom Approval Matrix. (DGP-302)
     * 
     * Note: Approval Level from "Custom" Custom Approval Matrix is getting derived in "ApprovalsAgreementLineStepBase" class.
     **/
    private Integer getRecordOwnerApprovalLevel(Apttus__AgreementLineItem__c agreementLine, Custom_Approval_Matrix__c approvalMatrixRecordOwner) {
        Formula.recalculateFormulas(new List<Apttus__AgreementLineItem__c> {agreementLine});
        Integer approvalLevel = null;
        Decimal minDiscount = agreementLine.Min_Discount__c == null ? 0 : agreementLine.Min_Discount__c;
        Decimal discountInPercent =  agreementLine.Discount_In_Percent__c == null ? 0 : agreementLine.Discount_In_Percent__c;
        Decimal salesApprovalThreshold = agreementLine.Sales_Approval_Threshold__c == null ? 0 : agreementLine.Sales_Approval_Threshold__c;
        Decimal differenceInDiscount = discountInPercent - salesApprovalThreshold;
        
        // Return 1, IF Difference in Discount is <= Min Discount%   
        if(differenceInDiscount <= minDiscount) {
            return 1;
        }
        
        // To Determine Approval Level
        for (Integer loopLevel = 1; loopLevel <= Approvals.MAX_APPROVAL_LEVEL; loopLevel++) {
            Decimal matrixPercentForLevel = (Decimal) approvalMatrixRecordOwner.get('Discount_Level_' + loopLevel + '__c');
            
            if (matrixPercentForLevel != null && differenceInDiscount <= matrixPercentForLevel) {
                approvalLevel = loopLevel;
                break;
            }
        }
        
        return approvalLevel;
    }
    
    /**
     * Method to remove Approval Categories for Record Owner IF Record Owner Approval Level is 1. (DGP-302)
     * 
     * Note: Categories are added in "ApprovalsAgreementLineMaterialNumber", "ApprovalsAgreementLineMaterialGroup"
     * and "ApprovalsAgreementLineDiscount" classes.
     **/ 
    private void removeRecordOwnerApprovalCategoriesForLevel1(Apttus__AgreementLineItem__c agreementLine, Approvals.Outputs outputs) {
        
        if(agreementLine.Approval_Level_RO_Discount__c == null || agreementLine.Approval_Level_RO_Discount__c <= 1) {
            outputs.agreementsToRevert.add(agreementLine.Apttus__AgreementId__c);            
            outputs.approvalsResults.approvalCategories.remove(Approvals.Category.MATERIAL_NUMBER.name());
            outputs.approvalsResults.approvalCategories.remove(Approvals.Category.MATERIAL_GROUP.name());
            outputs.approvalsResults.approvalCategories.remove(Approvals.Category.DISCOUNT.name());
        }
    }

    /*
    *   @description:
    *   stamps values on header level after output is calculated for entire pipeline        
    */
    public void addHeaderOutputValues(Object record, Approvals.Outputs outputs, IApprovalsParentRecordUpdates headerUpdates)
    {
        System.debug('inside addHeaderOutputValues');
        
        Apttus__AgreementLineItem__c agreementLine = (Apttus__AgreementLineItem__c)record;
        Approvals.AgreementHeaderUpdates agreementHeaderUpdates = (Approvals.AgreementHeaderUpdates)headerUpdates;

        if(outputs.approvalsResults.discount.hierarchy != null)
        {
            agreementHeaderUpdates.agreementIdToHierarchyId.put(agreementLine.Apttus__AgreementId__c, outputs.approvalsResults.discount.hierarchy);
        }

        agreementHeaderUpdates.idToAgreement.put(agreementLine.Apttus__AgreementId__c, idToAgreement.get(agreementLine.Apttus__AgreementId__c));
        agreementHeaderUpdates.agreementsToRevert.addAll(outputs.agreementsToRevert);
        agreementHeaderUpdates.agreementsWithHierarchyError.addAll(outputs.agreementsWithHierarchyError);
        agreementHeaderUpdates.agreementsWithMatrixError.addAll(outputs.agreementsWithMatrixError);
        System.debug('@@@ agreementstoRemoveFromMatrixError --> ' + outputs.agreementstoRemoveFromMatrixError);
        agreementHeaderUpdates.agreementsWithMatrixError.removeAll(outputs.agreementstoRemoveFromMatrixError);

        if(agreementLine.Approval_Category__c == '' || agreementLine.Approval_Category__c == null)
        {
            agreementHeaderUpdates.agreementsToRevert.add(agreementLine.Apttus__AgreementId__c);
        }
        else 
        {
            agreementHeaderUpdates.agreementsToUpdate.add(agreementLine.Apttus__AgreementId__c);
        }


        if(!agreementHeaderUpdates.agreementLinesUpdated.isEmpty() && agreementHeaderUpdates.agreementLinesUpdated.size() == agreementHeaderUpdates.existingAgreementLines.size())
        {
            if(agreementLine.Approval_Category__c != null && agreementLine.Approval_Category__c != '' && 
               agreementLine.Apttus_Approval__Approval_Status__c == System.Label.AgreementApprovalStatusApprovalRequired && 
               !agreementHeaderUpdates.agreementsToUpdate.contains(agreementLine.Apttus__AgreementId__c))
            {
                agreementHeaderUpdates.agreementsToUpdate.add(agreementLine.Apttus__AgreementId__c);
            }
            else
            {
                agreementHeaderUpdates.agreementsToRevert.add(agreementLine.Apttus__AgreementId__c);
            }
        }

    }




}