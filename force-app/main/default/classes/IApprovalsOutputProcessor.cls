/**
*    @author Todd Newman
*    @date   2021-08-25
*    @description    DCP-48131: Interface for processing output values returned at the end of executing pipeline
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                     Date                Description         
*        Todd Newman                  2021-08-25           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public interface IApprovalsOutputProcessor {

    void stampValues(Object record, Approvals.Outputs outputs);

    void addHeaderOutputValues(Object record, Approvals.Outputs outputs, IApprovalsParentRecordUpdates headerUpdates);
    
}