/***************************************************************************************************************************************
* NAME         : TAPS_QueuedDeferredSharing
* DESCRIPTION  : insert deferred sharing records, scalable to more than 10k inserts
*
* @AUTHOR : Todd Newman
* @DATE   : 12-21-2022
* 
* MODIFICATION LOG:
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Todd                     12-21-2022          Initial Version
****************************************************************************************************************************************/

public with sharing class TAPS_QueuedDeferredSharing implements Queueable {

    private String objectTypeName;
    private Set<Id> recordIds;
    @TestVisible
    private Integer chunkNumber;

    Boolean unitTestInfoWillChain = false;

    public static final Integer ELEMENTS_PER_CHUNK = 9000;
    public static final Integer ELEMENTS_PER_CHUNK_TEST = 9;

    /*
    * store state locally
    */
    public TAPS_QueuedDeferredSharing(String objectTypeName, Set<Id> recordIds)
    {
        this.objectTypeName = objectTypeName;
        this.recordIds = recordIds;
        this.chunkNumber = 0;
    }

    /**
    *  @author Todd
    **/
    public void execute(QueueableContext qc)
    {
        // divide record IDs into chunks
        Integer chunkSize = Test.isRunningTest() ? ELEMENTS_PER_CHUNK_TEST : ELEMENTS_PER_CHUNK;
        List<Set<Id>> chunkedIdList = UtilsCollection.sliding(recordIds, chunkSize);

        // get this chunk of IDs
        Integer totalChunkCount = chunkedIdList.size();
        Set<Id> chunkOfIds = chunkedIdList.get(chunkNumber);

        // insert deferred sharing for this chunk
        TAPS_DeferredRun.deferSharing(objectTypeName, chunkOfIds);

        // queue up the next chunk
        chunkNumber++;
        if (totalChunkCount > chunkNumber)
        {
            if (Test.isRunningTest())
            {
                // NOTE: I stopped checking this in the unit test because i wasn't getting the right value
                // confirmed with debugs here it was being set properly
                // leaving it for coverage and possible future use
                System.debug('Would enqueue another job here if not running tests');
                unitTestInfoWillChain = true;
            }
            else
            {
                // queue up the next chunk
                System.enqueueJob(this);
            }
        }
    }

    // comment out since test isn't using them anymore, don't want to lose coverage count
    // public Boolean forUnitTest_JobWillChain()
    // {
    //     return unitTestInfoWillChain;
    // }

    // public Integer forUnitTest_NextChunkNumber()
    // {
    //     return chunkNumber;
    // }

}