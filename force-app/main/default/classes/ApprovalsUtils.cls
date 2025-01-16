/**
*    @author Bharath Varma
*    @date   2021-07-27
*    @description    DCP-50961: This class contains logic for handling common method required for approvals
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Bharath Varma               2021-12-07            Initial Version
*         Todd Newmann                2021-12-13            Added more methods
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public with sharing class ApprovalsUtils {

    /*
    *   @description:    
    *   Method to retrieve a mapping between Approval Key and the Priority
    */
    public static Map<String, Integer> retrieveApprovalKeyToPriority()
    {
        Map<String, Integer> approvalKeyToPriority = new Map<String, Integer>();

        for (Approval_Priority_Combination__mdt priorityCombination : new ApprovalPriorityMetadataSelector().selectAllPriorityCombinations())
        {
            String strMetaCond =
                priorityCombination.Price_List_Type_Check__c
                + '_' + priorityCombination.Region_Check__c
                + '_' + priorityCombination.Country_Check__c
                + '_' + priorityCombination.Distribution_Channel_Check__c
                + '_' + priorityCombination.Currency_Check__c
                + '_' + priorityCombination.Price_List_Type_Blank__c
                + '_' + priorityCombination.Region_Blank__c
                + '_' + priorityCombination.Distribution_Channel_Blank__c
                + '_' + priorityCombination.Country_Blank__c
                + '_' + priorityCombination.Currency_Blank__c;

            approvalKeyToPriority.put(strMetaCond, Integer.valueOf(priorityCombination.Value__c));
        }

        return approvalKeyToPriority;
    }

    /*
    *   @description:    
    *   get a all the productNumbers per matrix record
    */
    public static Map<Id, Set<String>> getMatrixIdToProductNumbers(List<Custom_Approval_Matrix_Products__c> matrixProducts) // updated from private to public
    {
        Map<Id, Set<String>> matrixIdToProductNumbers = new Map<Id, Set<String>>();

        // TODO: could make a generic method in UtilsCollection
        for (Custom_Approval_Matrix_Products__c matrixProduct : matrixProducts)
        {
            Id matrixId = matrixProduct.Custom_Approval_Matrix__c;

            if (!matrixIdToProductNumbers.containsKey(matrixId))
                { matrixIdToProductNumbers.put(matrixId, new Set<String>()); }
            matrixIdToProductNumbers.get(matrixId).add(matrixProduct.Product__r.Material_Number__c);
        }

        return matrixIdToProductNumbers;
    }

    // @PureFunction
    /* method to return a list of product numbers */
    public static List<String> expandProductNumbers(Set<String> combinedProductNumbers)
    {
        List<String> productNumbers = new List<String>();
        if (combinedProductNumbers == null) { return productNumbers; }

        for(String strVal : combinedProductNumbers) {
            productNumbers.addAll(strVal.split(';'));
        }

        return productNumbers;
    }

    // @PureFunction
    /* method to find the matrix with highest priority */
    public static Approvals.CandidateMatrix getPriorityResult(Approvals.CandidateMatrix candidateMatrix, Approvals.CandidateMatrix bestSoFarMatrix)
    {
        // candidate has no values, stick with best so far
        if (candidateMatrix.priority == null || candidateMatrix.lastModified == null)
        {
            bestSoFarMatrix.isApprovalMatrixFound = false;
            return bestSoFarMatrix;
        }

        // candidate is higher priority, it is the new best one
        if (bestSoFarMatrix.priority == null || bestSoFarMatrix.priority > candidateMatrix.priority)
        {
            candidateMatrix.isApprovalMatrixFound = true;
            return candidateMatrix;
        }
        // equal priority, use last modified date to pick
        else if (bestSoFarMatrix.priority != null && bestSoFarMatrix.priority == candidateMatrix.priority)
        {
            if (bestSoFarMatrix.lastModified < candidateMatrix.lastModified) {
                candidateMatrix.isApprovalMatrixFound = true;
                return candidateMatrix;
            }
            else
            {
                bestSoFarMatrix.isApprovalMatrixFound = true;
                return bestSoFarMatrix;
            }
        }

        return bestSoFarMatrix;
    }

}