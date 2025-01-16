/**
 *    @author KD
 *    @date   8-Dec-2020
 *    @description  Iterator for batch class
 *    Modification Log:
 *    ---------------------------------------------------------------------------------------------------------------------
 *             Developer                      Date                Description
   ---------------------------------------------------------------------------------------------------------------------
 *
 */
public with sharing class KnowledgeSyncIterator implements Iterable<KnowledgeSyncWrapper.LibraryContentDetails>,Iterator<KnowledgeSyncWrapper.LibraryContentDetails>{
    public List<KnowledgeSyncWrapper.LibraryContentDetails> lstLibraryContent {get;set;}
    public Integer intCounter {get;set;}
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   Constructor
     */
    public KnowledgeSyncIterator(List<KnowledgeSyncWrapper.LibraryContentDetails> lstLibraryContent) {
        this.lstLibraryContent = lstLibraryContent;
        this.intCounter = 0;
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   
     */
    public boolean hasNext(){
        return intCounter>=lstLibraryContent.size()?false:true;
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description   
     */
    public KnowledgeSyncWrapper.LibraryContentDetails next(){
        intCounter++;
        return lstLibraryContent[intCounter-1];
    }
    /**
     * @author KD
     * @date    8-Dec-2020
     * @description  
     */
    public Iterator<KnowledgeSyncWrapper.LibraryContentDetails> iterator()
   {
      return this;   
   }
}