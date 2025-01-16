/**
*    @author: Pankaj 
*    @date:   02-Dec-2019
*    @description:  Batch Class to update Hased Email fields for Leads and Contacts records
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj                        02-Dec-2019        Initial Development

       Database.executeBatch(new BatchUpdateHashedData('Lead'));
       Database.executeBatch(new BatchUpdateHashedData('Contact'));
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class BatchUpdateHashedData extends ilib_ScheduleAndBatch {
public static final String STRING_LEAD = 'Lead';
public String objectName; // This will identify if the batch is called for lead or contact object
    /**Parameterized Constructor */
    public BatchUpdateHashedData(String objectName){
        this.objectName=objectName;
    }   

      /**Start method of batch class */
      public override Database.QueryLocator start(Database.BatchableContext bc){
        String strSoql='Select id, email from '+ objectName+' where email!=null';
        /*If the object name is lead, update only the non converted records*/   
         if(ObjectName.equals(STRING_LEAD)){
            strSoql=strSoql+' and isconverted=false';
         }
        strSOQL=String.escapeSingleQuotes(strSOQL);     
        return Database.getQueryLocator(strSOQL); 
        
      }
      /*Execute method of batch class */
      public override void execute (Database.BatchableContext bc, List<SObject> scope){
      List<sObject> lstObject=New List<sObject>();
            for(sObject obj:scope){
                if(obj.get('Email')!=null){
                     String strEmail=((String)obj.get('Email')).toLowerCase();
                     Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf(strEmail));
                     obj.put('Hashed_Email_Id__c',EncodingUtil.convertToHex(b));
                     lstObject.add(obj);
                     
                }
            }
            if(lstObject.size()>0){
                update lstObject;
            }
      }
      /*Finish method of batch class */     
      public override void finish(Database.BatchableContext bc) { 
        system.debug('Finish method completed');
      }

}