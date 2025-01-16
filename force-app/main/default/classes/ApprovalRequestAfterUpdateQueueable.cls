/**
*    @author Nesar Mohan
*    @date   2022-06-02
*    @description    DCP-53938: Queueable class to call ApttusApprovalRequestsHelper from onAfterUpdate() context of ApttusApprovalRequests.cls
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*        Nesar Mohan                  2022-06-20           Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/

public with sharing class ApprovalRequestAfterUpdateQueueable implements Queueable {

    String strMethodtoExecute;
    Map<Id,Id> mapProposalRequestIdtoQuoteId = new Map<Id,Id>();
    Set<Id> setAppApprovalReqId = new Set<Id>();
    public static final String INVOKECOMMENTPOPULATIONLOGIC = 'populateCommentsOnQuote';
    public static final String GENERATEANDATTACHPDF = 'generateAndAttachPDF';

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Constructor to initialize the method name to invoke and the data to operate on
    *  @PARAM :         String, Map<Id,Id>, Set<Id>
    *  @RETURN:         void
    */
    public ApprovalRequestAfterUpdateQueueable(String strMethodtoExecute , Map<Id,Id> mapProposalRequestIdtoQuoteId, Set<Id> setAppApprovalReqId) {
        this.strMethodtoExecute=strMethodtoExecute;
        this.mapProposalRequestIdtoQuoteId=mapProposalRequestIdtoQuoteId;
        this.setAppApprovalReqId = setAppApprovalReqId;
    }

    /*
    *  @AUTHOR:         Nesar Mohan
    *  @DESCRIPTION:    Execute method to call the helper class method based on the method name invoked
    *  @PARAM :         QueueableContext qc
    *  @RETURN:         void
    */
    public void execute(QueueableContext qc) {

        if(strMethodtoExecute==INVOKECOMMENTPOPULATIONLOGIC && !mapProposalRequestIdtoQuoteId.IsEmpty()){
            new ApttusApprovalRequestsHelper().populateCommentsOnQuote(mapProposalRequestIdtoQuoteId);        
        }

        if(strMethodtoExecute==GENERATEANDATTACHPDF && !setAppApprovalReqId.IsEmpty()){
            new ApttusApprovalRequestsHelper().generateAndAttachPDF(setAppApprovalReqId);        
        }
    }
}
