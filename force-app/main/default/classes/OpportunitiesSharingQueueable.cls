/**
*    @author Rahul Sharma
*    @date   2019-07-16
*    @description    DCP-25384: Opportunities Batch Sharing
*    Modification Log:
*    ------------------------------------------------------------------------------------
*         Developer                      Date                Description
*         Rahul Sharma                2019-07-16
*    ------------------------------------------------------------------------------------
**/
public with sharing class OpportunitiesSharingQueueable implements Queueable {
  private Set<Id> setOppIds = new Set<Id>();

  public OpportunitiesSharingQueueable(Set<Id> setOppIds){
    this.setOppIds = setOppIds;
  }

  public void execute(QueueableContext context){
     // execute the opportunity batch
      OpportunitiesService.executeShareBatch(setOppIds);
}
}