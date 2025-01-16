/***************************************************************************************************************************************
* NAME         : TestProactiveMockClass
* DESCRIPTION  : This class is used to set up mock responses for the two call outs and for each categories
*                    
* @AUTHOR      : Raviteja Vakkalagadda
* @DATE        : 21-Jun-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
@isTest

public class TestProactiveMockClass implements HttpCalloutMock {
    protected Integer code;  
    protected String body;
    protected String categoryType;
    
/*******************************************************************************************************
Description: This is used to create fake response and dynamic status codes
************************************************************************************************************/  
    
    public TestProactiveMockClass (Integer code, String body,String categoryType){
        this.code = code;    
        this.body = body;
        this.categoryType = categoryType;
    }

/**
 * 
 */
    
    public HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        string metricsResponse = '';
        response.setHeader('Content-Type', 'application/json');
        
        
        // Setting up mock responses	
        
        if(body=='200' || body=='404'){
            system.debug('==mock endpoint===='+request.getEndpoint());
            //string proactiveRunResponse = '[{"workflow":"HiSeqFastQ","totalSize":0,"status":"Running","side":"B","runId":"210062858","readLength":"100|8|0|100","Pronumber":null,"name":"210624_A00993_0041_BHH2F7DRXY","instrumentStartedDate":"2021-06-24T19:29:26Z","instrumentStartDtFormated":"2021-06-24","instrumentSerialNumber":"A00993","instrumentEndDtFormated":null,"instrumentCompletedDate":null,"id":"2371886","environment":"usa","apiUrl":"https://api.basespace.illumina.com"}]';
            //string proactiveRunResponse = '[{"id":"1822733","name":"20200610_FS10001248_26_BPL20316-1730","number":26,"status":"Completed","side":null,"instrumentStartedDate":"2020-06-10T07:08:41Z","instrumentCompletedDate":"2020-06-10T19:59:52Z","totalSize":702275971,"workflow":"HiSeqFastQ","instrumentSerialNumber":"FS10001248","apiUrl":"https://api.aps2.sh.basespace.illumina.com","environment":"aus","runId":"661664","readLength":"100|8|0|100"},{"id":"1822734","name":"20200610_FS10001248_26_BPL20316-1730","number":26,"status":"Completed","side":null,"instrumentStartedDate":"2020-06-10T07:08:41Z","instrumentCompletedDate":"2020-06-10T19:59:52Z","totalSize":702275971,"workflow":"HiSeqFastQ","instrumentSerialNumber":"FS10001248","apiUrl":"https://api.aps2.sh.basespace.illumina.com","environment":"aus","runId":"661664","readLength":"100|8|0|100"}]';
            string proactiveRunResponse = '[{"id":"2366996","name":"210622_A00993_0038_AHGHVVDRXY","status":"Completed","side":"A","instrumentStartedDate":"2021-06-22T18:30:31Z","instrumentCompletedDate":"2021-06-23T15:22:51Z","totalSize":105072624027,"workflow":"HiSeqFastQ","instrumentSerialNumber":"A00993","apiUrl":"https://api.basespace.illumina.com","environment":"usa","runId":"209327124","readLength":"150&#124;8&#124;8&#124;150"}]';
            if(categoryType == 'NovaSeq'){
            metricsResponse = '{"id":"2354117","runId":"208848659","controlSoftwareVersion":"1.7.5","proactiveLink":"https://proactiveportal-test.illumina.com/run/ipsRunId/2354117","percentPf":71.20739999999999,"gtq30Percent":90.4781,"percentGTQ30Read1":93.7227,"percentGTQ30Read2":89.65662,"yieldTotalG":1331.028,"alignedPercent":0.7439742,"errorRate":0.1994062,"side":"A","occupancyPercent":96.6557,"ucsVersion":"1.6.3.1575","rtaVersion":"v3.4.4","flowcellSerialBarcode":{"value":"HCWGWDSX2","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20547919","expired":false},"flowcellExpirationDate":{"value":"2022-05-07T00:00:00.000+00:00","expired":false},"flowcellMode":{"value":"S4","expired":false},"libraryTubeSerialBarcode":{"value":"NV0341204-LIB","expired":false},"libraryTubePartNumber":{"value":"20005221","expired":false},"libraryTubeLotNumber":{"value":"1000009348","expired":false},"libraryTubeExpirationDate":{"value":"2169-12-31T00:00:00.000+00:00","expired":false},"sbsSerialBarcode":{"value":"NV3333189-RGSBS","expired":false},"sbsPartNumber":{"value":"TestProduct","expired":false},"sbsLotNumber":{"value":"20539977","expired":false},"sbsExpirationDate":{"value":"2022-04-27T00:00:00.000+00:00","expired":false},"sbsConsumableVersion":{"value":"3","expired":false},"clusterSerialBarcode":{"value":"NV3305997-RGCPE","expired":false},"clusterPartNumber":{"value":"TestProduct","expired":false},"clusterLotNumber":{"value":"20537772","expired":false},"clusterExpirationDate":{"value":"2022-04-04T00:00:00.000+00:00","expired":false},"bufferSerialBarcode":{"value":"NV5192583-BUFFR","expired":false},"bufferPartNumber":{"value":"TestProduct","expired":false},"bufferLotNumber":{"value":"50000209","expired":false},"bufferExpirationDate":{"value":"2022-03-24T00:00:00.000+00:00","expired":false},"useCustomRead1Primer":false,"useCustomRead2Primer":false,"useCustomIndexRead1Primer":false,"useCustomIndexRead2Primer":null}';
            }
            else if(categoryType == 'MiSeq'){
            metricsResponse = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","fpgaVersion":"some version","flowcellRfidTagSerialNumber":{"value":"000000000-DCVKV","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagExpirationDate":{"value":"2022-04-08T00:00:00.000+00:00","expired":false},"flowcellRfidTagLotNumber":{"value":"","expired":false},"reagentKitRfidTagSerialNumber":{"value":"MS3084532-500V2","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-03-22T00:00:00.000+00:00","expired":false},"reagentKitRfidTagLotNumber":{"value":"","expired":false},"pr2BottleRfidTagSerialNumber":{"value":"MS2965575-00PR2","expired":false},"pr2BottleRfidTagPartNumber":{"value":"TestProduct","expired":false},"pr2BottleRfidTagExpirationDate":{"value":"2022-05-06T00:00:00.000+00:00","expired":false},"pr2BottleRfidTagLotNumber":{"value":"","expired":false},"proactiveLink":"some link"}';    
            }
            else if(categoryType == 'HiSeq'){
            metricsResponse = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","fcPosition":"A","flowcellType":"HiSeq 3000/4000 SR","rapidRunChemistry":"","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"firstBaseConfirmation":false,"controlSoftwareVersion":"some version","rtaVersion":"some version","fpgaVersion":"some version","reagentKitsSbsSerialNumber":"A","reagentKitsSbsPrime":false,"reagentKitsPeSerialNumber":"","flowcellSerialNumber":"HLHNMBBXY","proactiveLink":"some link"}';    
            }
            else if(categoryType == 'MiniSeq'){
            metricsResponse = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","localRunManagerVersion":"some version","analysisProtalType":"some version","flowcellRfidTagSerialnumber":{"value":"000H3H7VL","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagLotNumber":{"value":"20521545","expired":false},"flowcellRfidTagExpirationDate":{"value":"2022-02-24T00:00:00.000+00:00","expired":false},"reagentKitRfidTagSerialNumber":{"value":"ML2145830-REAGT","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagLotNumber":{"value":"20519003","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-02-24T00:00:00.000+00:00","expired":false},"usesCustomReadOnePrimer":false,"usesCustomReadTwoPrimer":false,"usesCustomIndexPrimer":false,"usesCustomIndexTwoPrimer":false,"proactiveLink":"some link"}';    
            }
            else if(categoryType == 'iSeq'){
            metricsResponse = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","occupancyPercent":15.2,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","firmwareVersion":"some version","localRunManagerVersion":"some version","localRunManagerRunId":13013,"flowcellEepromTagSerialNumber":{"value":"BPA73117-1317","expired":false},"flowcellEepromTagPartNumber":{"value":"TestProduct","expired":false},"flowcellEepromTagLotNumber":{"value":"20516489","expired":false},"flowcellEepromTagExpirationDate":{"value":"2022-01-27T00:00:00.000+00:00","expired":false},"reagentKitRfidTagSerialNumber":{"value":"FY0018299-FC7","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagLotNumber":{"value":"20530645","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-04-04T00:00:00.000+00:00","expired":false},"proactiveLink":"some link"}';    
            }
            else if(categoryType == 'NextSeq 500/550'){
            metricsResponse = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","clusterDensityRead1":15,"clusterDensityPFRead1":5,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","systemSuiteVersion":"some version","runManagementType":"","analysisWorkflowType":"","flowcellRfidTagSerialNumber":{"value":"HG3WFBGXJ","expired":false},"flowcellRfidTagPartNumber":{"value":"TestProduct","expired":false},"flowcellRfidTagExpirationDate":{"value":"2023-03-19T00:00:00.000+00:00","expired":false},"flowcellRfidTagLotNumber":{"value":"20529495","expired":false},"pr2BottleRfidTagSerialNumber":{"value":"NS4603043-BUFFR","expired":false},"pr2BottleRfidTagPartNumber":{"value":"TestProduct","expired":false},"pr2BottleRfidTagExpirationDate":{"value":"2022-02-06T00:00:00.000+00:00","expired":false},"pr2BottleRfidTagLotNumber":{"value":"20514809","expired":false},"reagentKitRfidTagSerialNumber":{"value":"NS4645125-REAGT","expired":false},"reagentKitRfidTagPartNumber":{"value":"TestProduct","expired":false},"reagentKitRfidTagExpirationDate":{"value":"2022-02-26T00:00:00.000+00:00","expired":false},"reagentKitRfidTagLotNumber":{"value":"20520891","expired":false},"usesCustomReadOnePrimer":false,"usesCustomReadTwoPrimer":false,"usesCustomIndexPrimer":false,"usesCustomIndexTwoPrimer":false,"proactiveLink":"some link"}';   
            }
            else if(categoryType == 'NextSeq 1000/2000'){
             metricsResponse = '{"id":"1822733","runId":"661664","readLength":"1|2|3|4","loadingConcentration":"A","occupancyPercent":15.2,"percentPf":1.2,"gtq30Percent":10.3,"percentGTQ30Read1":5.5,"percentGTQ30Read2":5.5,"yieldTotalG":51.2,"alignedPercent":1.2,"errorRate":1.2,"controlSoftwareVersion":"some version","rtaVersion":"some version","copyServiceVersion":"some version","secondaryAnalysisPlatformVersion":"3.7.4","secondaryAnalysisWorkflow":"GenerateFastQ","secondaryAnalysisMode":"Local","flowcellSerialNumber":{"value":"AAAK5WYM5","expired":false},"flowcellPartNumber":{"value":"TestProduct","expired":false},"flowcellLotNumber":{"value":"20513538","expired":false},"flowcellExpirationDate":{"value":"2022-03-06T00:00:00.000+00:00","expired":false},"cartridgeSerialNumber":{"value":"EC0003994-EC11","expired":false},"cartridgePartNumber":{"value":"TestProduct","expired":false},"cartridgeLotNumber":{"value":"20520307","expired":false},"cartridgeExpirationDate":{"value":"2021-10-07T00:00:00.000+00:00","expired":false},"customReadOnePrimer":"None","customReadTwoPrimer":"None","customIndexOnePrimer":"None","customIndexTwoPrimer":"None","proactiveLink":"some link"}';
            }
            else if(categoryType == 'Genotyping'){
             metricsResponse = '{"id":"1822733","runId":"661664","beadChipBarcode":"205329990058","applicationName":"iScan Control Software","controlSoftwareVersion":"some version","fpgaVersion":"some version","copyServiceVersion":"some version","proactiveLink":"some link"}';
            }
            if(!request.getEndpoint().contains('metrics')){
                system.debug('Runs test class');
            response.setStatusCode(Integer.valueof(body));
            response.setbody(proactiveRunResponse);
            }
            else if(request.getEndpoint().contains('metrics')){
                system.debug('Metrics test call');
            response.setStatusCode(Integer.valueof(body));
            response.setbody(metricsResponse);
            }
            
        }
        else{
            response.setStatusCode(Integer.valueof(body));
            response.setbody('Bad Request');
        }
        return response;
    }
}