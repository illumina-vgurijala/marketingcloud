/**
*    @author: Pankaj 
*    @date:   14-Aug-2019
*    @description:  PardotQueableForCampaignAttribution- Helper class for Pardot Queable for Campaign Attribution
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 14-Aug-2019        Initial Build
*    ------------------------------------------------------------------------------------ 
*                    
*/

public with sharing class PardotQueableForCampaignAttribution implements Queueable, Database.AllowsCallouts{
    public list<String> lstEmailIds;
    public String strEndpoint;   
    public static Boolean catchException = false; 
    /*
    *  Description: Constructor PardotQueableForCampaignAttribution created for initializing
    */
    public PardotQueableForCampaignAttribution(list<String> lstEmailIds,String strEndpoint) {
        this.lstEmailIds=lstEmailIds;
        this.strEndpoint=strEndpoint;
    }
    /*This is a recursive call. It Enqueue the job and remove the element from the list after callout*/
    public void execute(QueueableContext context){
      try{
        if(lstEmailIds!=null && lstEmailIds.size()>0){
            String strEmailId=lstEmailIds[0];
            strEmailId=EncodingUtil.urlEncode(strEmailId,'UTF-8');
            Http objhttp = new Http();
            HttpRequest objReq = new HttpRequest();
            objReq.setEndpoint(strEndpoint+'?email='+strEmailId+'&Cattr=NULL');
            objReq.setMethod('POST');
            system.debug('Request is--'+objReq);
            HttpResponse objResponse = objhttp.send(objReq);
            String strResultJSONString = objResponse.getBody();
            lstEmailIds.remove(0);
            if(lstEmailIds!=null && lstEmailIds.size()>0){
               PardotQueableForCampaignAttribution objPardotQueableForCampaignAttribution=new PardotQueableForCampaignAttribution(lstEmailIds,strEndpoint);
               System.enqueueJob(objPardotQueableForCampaignAttribution);  
            }
        }
        //code coverage for catch block
        if(catchException == true){
          throw new AuraHandledException('throwing custom exceptions');
        }
      }catch(Exception e){
        //catch the exception 
        ApexExceptions.emit('PardotQueableForCampaignAttribution', e,ilib_LogEvent.getWorkstream());
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        throw e;
      }
    }

}