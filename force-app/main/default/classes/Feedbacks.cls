/****************************************************************************************************************************************
* NAME         : Feedback
* DESCRIPTION  : Domain class for Feedback
*                    
* @AUTHOR : Deepak
* @DATE   : 23-Nov-2020    
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Deepak    23-Nov-2020          Initial Version.          
****************************************************************************************************************************************/ 

public with sharing class Feedbacks extends ilib_SObjectDomain { 

    public static final string FEEDBACK_REVIEWERS_QUEUE = 'Feedback_Reviewers';
    public static final string GROUP_TYPE_QUEUE = 'Queue';
     
    /*
        Feedback Consturctor to inject object list
    */
    public Feedbacks( List<Feedback__c> sObjectList ) {
        super(sObjectList);
    }
    
/*
* Boilerplate which is required for base class instantiation logic
*/
    public class Constructor implements ilib_SObjectDomain.IConstructable {
    
        /*
            * Base class instantiation
        */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
        
            return new Feedbacks(sObjectList);
        }
    }

 
/**
    *  @author Deepak Kumar
    *  @description - 
    *                 To be executed, when the Feedback is created
    *  @PARAM :  
    *  @RETURN:  void
*/ 
    public override void onBeforeInsert() {    
       
        //User Story : DCP-43595
         changeOwnertoQueueByDefault((List<Feedback__c>)records);
                
    }
/*
    * @author Deepak Kumar
    * @date   25-Nov-2020
    * @description - After update trigger method
*/
    public override void onAfterUpdate(Map<Id, SObject> oldRecords){
        
          shareRecToCreatedUserIfOnwerischanged(records,oldRecords);
        
     }
 /**
    *  @author Deepak Kumar
    *  @description - 
    *                 To be executed, after the feedback record inserted                
    *  @PARAM :  
    *  @RETURN:  void
 */  
    public override void onAfterInsert() { 

        FeedbackShareCls.shareFeedbackRecords((List<Feedback__c>)records);        
                
    }   

 /**
    *  @author Deepak Kumar
    *  @description - 
    *               By default,to assign the owner to Queue named "Feedback Reviewers" 
    *               User Story : DCP-43595              
    *  @PARAM :  
    *  @RETURN:  void
*/ 

    public static void changeOwnertoQueueByDefault(List<Feedback__c> lstNewRecords) {
	
        List<String> lstQueueName = new List<String>{FEEDBACK_REVIEWERS_QUEUE};
        List<Group> groupObj =  new GroupsSelector().getQueueIdbyDeveloperName(lstQueueName , GROUP_TYPE_QUEUE ); 
        for(Feedback__c  objFeedback : lstNewRecords) {
            objFeedback.ownerid = groupObj[0].id; //it always return single record
        }       

   }
   /**
    *  @author Deepak Kumar
    *  @description - 
    *               When the owner is changed share the record to feedback creator
    *               User Story : DCP-43595              
    *  @PARAM :  
    *  @RETURN:  void
*/ 

	public static void shareRecToCreatedUserIfOnwerischanged(List<SObject> records , Map<Id, SObject> oldRecords) {

		List<Feedback__c>  modifiedOwnerRecLst = UtilsObject.filterForFieldChanges(records, oldRecords, new List<String> {'OwnerId'});
	   

		if(!modifiedOwnerRecLst.isEmpty()) {
			//To share the record with created user.                 
			FeedbackShareCls.shareFeedbackRecords(modifiedOwnerRecLst);
		}
    
    }
  
}