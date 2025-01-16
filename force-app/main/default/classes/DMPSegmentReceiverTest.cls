/**
*    @author: Pankaj Singla
*    @date:   27-Nov-2019
*    @description:  Test Class for Segment Data Receiver Class
*    Modification Log:
*    ------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             Pankaj Singla              27 Nov 2019           Initial Build
              
*    ------------------------------------------------------------------------------------ 
*                    
*/

@isTest
public class DMPSegmentReceiverTest{
    
    /*
    * @author Pankaj Singla
    * @date   27-Nov-2019 
    * @description: Test method to test incoming JSON
    * params :None
    * return NONE
    */
    static testmethod void testpost(){
        List<DMP_Staging__c> lstJSON=new List<DMP_Staging__c>();
        List<string> lstActiveSegments=new List<String>();
        
        for(DMP_Priority_Segment__mdt mdt:[SELECT Id,Priority__c,SegmentId_Long__c,SegmentId__c FROM DMP_Priority_Segment__mdt where isActive__c=true  
 order by Priority__c ASC limit 15]){
                lstActiveSegments.add(mdt.SegmentId__c);
        }
        Integer count=0;
        String strSegments='';
        String strSegments2='';
        for(String str:lstActiveSegments){
            if(count<3){
                strSegments=strSegments+str+',';
            }
            if(count<8){
                strSegments2=strSegments2+str+',';
            }
            
            count++;
        }
        
        Lead ld=TestDataMarketing.createLead('testfirstname','testlastname','test@gmail.com','USA','testCompany');
        Contact lon=TestDataMarketing.createContact('testfirstname','testlastname','test123@gmail.com');
        
        ilib_LogEvent.message('Lead Id -- ' + ld.Id);
        ilib_LogEvent.message('Contact Id -- '+ lon.Id);

        Blob b = Crypto.generateDigest('SHA-256', Blob.valueOf('test@gmail.com'));
        string hashIdLead = EncodingUtil.convertToHex(b);
        
        
        Blob bContact = Crypto.generateDigest('SHA-256', Blob.valueOf('test123@gmail.com'));
        string hashIdContact = EncodingUtil.convertToHex(bContact);
        
        
       DMP_Staging__c  obj1=new DMP_Staging__c();
        //obj1.kuid='KUI1';
        obj1.Hem__c=hashIdLead;
        //obj1.segments='NBG5phae,NCfSLAr-,NC6fmcgJ,M_N9kd4e';
        obj1.segments__c=strSegments;
        
        DMP_Staging__c  obj2=new DMP_Staging__c();
        //obj2.kuid='KUID2';
        obj2.Hem__c=hashIdContact;
        //obj2.segments='NBG5phae,NCfSLAr-,NC6fmcgJ,M_N9kd4e,NBG5phae,NCfSLAr-,NC6fmcgJ,M_N9kd4e,NBG5phae,NCfSLAr-,NC6fmcgJ';
        obj2.segments__c=strSegments2+'test1,test3,test2';
        lstJSON.add(obj1);
        lstJSON.add(obj2);
        insert lstJSON;
        String myJSON =JSON.serialize(lstJSON);
        Test.startTest();
        RestRequest request = new RestRequest();
        RestResponse res = new RestResponse();
        
        request.requestUri ='/services/apexrest/dmpsegmentsync';
        request.httpMethod = 'POST';
        //request.requestBody = Blob.valueof(myJSON);
        request.requestBody=Blob.valueof(myJSON);
        RestContext.request = request;
        RestContext.response = res;
        DMPSegmentReceiver.processIncomingJson();
        
        system.debug('res.......'+res);
        Test.stopTest(); 
		System.assertEquals(200, res.statusCode);
        
        
    }

   @isTest static void failNoBody(){
       RestResponse res = new RestResponse();
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/dmpsegmentsync';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        {
           DMPSegmentReceiver.processIncomingJson();
        }

        Test.stopTest();
        System.debug('res.responseBody:' + res.responseBody.toString());
        System.assertEquals(412, res.statusCode);
    
   }
}