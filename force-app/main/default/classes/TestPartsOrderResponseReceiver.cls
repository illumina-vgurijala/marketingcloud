@IsTest
/***************************************************************************************************************************************
* NAME   : IBTechinalAttributeCreationQueuable 
* --------------------------------------------------------------------------------------------------------------------------------------
*/	
public class TestPartsOrderResponseReceiver {

static testMethod void newPartsOrderResponseReceiver() {

PartsOrderResponseReceiver partsOrderRes = new PartsOrderResponseReceiver();
        PartsOrderResponseReceiver.d  mainContainerD = new PartsOrderResponseReceiver.d();
        PartsOrderResponseReceiver.results  results = new PartsOrderResponseReceiver.results();
        results.Type = 'Test Type';
        PartsOrderResponseReceiver.NAVHDRTOITMOUT  NAVHDRTOITMOUT = new PartsOrderResponseReceiver.NAVHDRTOITMOUT();
        PartsOrderResponseReceiver.NAVHDRTOHDROUT  NAVHDRTOHDROUT = new PartsOrderResponseReceiver.NAVHDRTOHDROUT();
        PartsOrderResponseReceiver.NAVHDRTORET  NAVHDRTORET = new PartsOrderResponseReceiver.NAVHDRTORET();
        system.assert(results.Type!=null, 'results is null');
}

}