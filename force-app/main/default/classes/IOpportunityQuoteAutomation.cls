/**
*    @author Akshay Mohan
*    @date   2021-04-29
*    @description    DCP-38809
*    Modification Log:
*    ---------------------------------------------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Akshay Mohan                   2021-04-29            Initial Version
*    ---------------------------------------------------------------------------------------------------------------------------
**/
public interface IOpportunityQuoteAutomation extends Queueable{
    void setRecordId(Id idInputRecord);//called when instantiating queueable
    Id getRecordId(); //called when processing is done to pass to next implementation class in queue
    OpportunityQuoteAutomationQueueable.EmailWrapper getErrorDetails(); //called if processing has resulted in some error and user needs to be notified
}