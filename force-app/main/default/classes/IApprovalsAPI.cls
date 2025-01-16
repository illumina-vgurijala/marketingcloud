/**
*    @author Todd Newman
*    @date   2021-07-27
*    @description    DCP-48131: Interface for Approval Quote Line Processing
*    Modification Log:
*    ----------------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description         
*         Todd Newman                 2021-07-27            Initial Version
*    ----------------------------------------------------------------------------------------------------------------------------------
**/
public interface IApprovalsAPI {

    Approvals.QuoteHeaderUpdates processQuoteLines();

    Approvals.AgreementHeaderUpdates processAgreementLines();

}