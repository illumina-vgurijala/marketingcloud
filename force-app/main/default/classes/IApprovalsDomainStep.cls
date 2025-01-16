/**
*    @author Todd Newman
*    @date   2021-12-13
*    @description    DCP-50961: Interface for Approval Domains (CLM or CPQ)
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-12-13            Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public interface IApprovalsDomainStep {

    // NOTE: considered dependency injection instead of direct factory method constructor
    // but the compilation dependencies in this class is pretty low
    // will reconsider when done
    //void initSupportData(Approvals.StepName stepName, Approvals.SupportData data);

    void initStepData(Approvals.StepResults stepResults, Approvals.Outputs outputs);

    void copyHierarchyAndLevel();
    void copyErrorInformation();

    Approvals.MatrixWrapper findHighestPriorityMatrix(SObject line, String strApprovalType, Boolean isTransborder,String hierarchyType);

}
