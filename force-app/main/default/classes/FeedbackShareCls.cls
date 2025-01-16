/**
 *    @author Deepak
 *    @date   26-Nov-2020
 *    @description: Feedback Sharing Class  
 *    Modification Log:
 *    ------------------------------------------------------------------------------------ 
 *    Developer                      Date                Description
 *    Deepak Kumar              25-Nov-2020          Original version
 *    ------------------------------------------------------------------------------------ 
 *                    
 */
public without sharing class FeedbackShareCls {
  
/**
    *  @author Deepak Kumar
    *  @description - 
    *               To share the owner to creator of feedback" 
    *               User Story : DCP-43595              
    *  @PARAM :  
    *  @RETURN:  void
*/ 

    public static void shareFeedbackRecords(List<Feedback__c> lstfeedbackToShare) {

        List<Feedback__Share> createdUsershareLst = new  List<Feedback__Share> ();        
        for(Feedback__c feedbackObj : lstfeedbackToShare) {
            if(feedbackObj.CreatedById != feedbackObj.ownerid )
            createdUsershareLst.add(createSharingRecord(feedbackObj.CreatedById, feedbackObj.id));
        }
             
        insert createdUsershareLst; 

    }

  
     /* Generic method to create sharing */
    public static Feedback__Share createSharingRecord(Id userId, Id recordId) {
        Feedback__Share share = new Feedback__Share(
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            ParentId = recordId,
            RowCause = Schema.Feedback__Share.RowCause.Manual
       );
        return share;
    }
    
}