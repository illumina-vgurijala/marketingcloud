/**
*    @author: Pankaj 
*    @date:   19-June-2019
*    @description:  PardotQueableForProspectScoring- Helper class for Pardot Callout 
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla                 19-June-2019        Initial Build
*    ------------------------------------------------------------------------------------ 
*                    
*/
public class PardotQueableForProspectScoring implements Queueable, Database.AllowsCallouts{
    public List<String> lstEmailsIds;
    String strEndpoint;
    public PardotQueableForProspectScoring(List<String> lstEmailIds,String strEndpoint){
        this.lstEmailsIds=lstEmailIds;
        this.strEndpoint=strEndpoint;
    }
    /*This is a recursive call. It Enqueue the job and remove the element from the list after callout*/
    public void execute(QueueableContext context){
        if(lstEmailsIds!=null && lstEmailsIds.size()>0){
             String strEmail=lstEmailsIds[0];
			 strEmail=EncodingUtil.urlEncode(strEmail,'UTF-8');
             system.debug('strEmail'+strEmail);
             Http objhttp = new Http();
             HttpRequest objReq = new HttpRequest();
             objReq.setEndpoint(strEndpoint+'?email='+strEmail);
             objReq.setMethod('POST');
             HttpResponse objResponse = objhttp.send(objReq);
             String strResultJSONString = objResponse.getBody();
             lstEmailsIds.remove(0);
             if(lstEmailsIds!=null && lstEmailsIds.size()>0){
                PardotQueableForProspectScoring objPardotQueableForProspectScoring=new PardotQueableForProspectScoring(lstEmailsIds,strEndpoint);           
                System.enqueueJob(objPardotQueableForProspectScoring); 
             }
        }
    }
       
}
