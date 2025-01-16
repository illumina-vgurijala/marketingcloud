/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: Base interface for Approvals Framework
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27            Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public interface IApprovalsStep {

    Approvals.Outputs execute(Object record, Approvals.Outputs outputs);

    void setRecord(Object record);

    Boolean isStepAppropriateForRecord();

    void calculate();

    void copyStepResultsToOutput();
}