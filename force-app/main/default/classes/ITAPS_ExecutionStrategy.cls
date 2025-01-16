/**
*    @author Todd Newman
*    @date  17-12-2020   
*    Modification Log:
*    -------------------------------------------------------------------------------------------------------------------------------------
*       Developer           Date            Description
*       Todd Newman                         Created as part of DCP-43261/TASK0548217
* -------------------------------------------------------------------------------------------------------------------------------------
**/
public interface ITAPS_ExecutionStrategy
{
    void processChunk(String objectName, Set<Id> idChunk);
    void execute(); 
}