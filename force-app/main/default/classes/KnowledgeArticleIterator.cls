/******************************************************************************************************************************
* NAME         : KnowledgeArticleIterator
* DESCRIPTION  : Iterator class for BatchUpdateKnowledgeArticles
*                    
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Vignesh                21-Dec-2020          Initial Version.    
****************************************************************************************************************************************/ 

public with sharing class KnowledgeArticleIterator implements Iterable<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper>,Iterator<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper>{
    public List<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper> lstKnowledgeArticle {get;set;}
    public Integer intCounter {get;set;}
    
    /*
    Author: Vignesh
    Description : Constructor for KnowledgeArticleIterator
    */
    public KnowledgeArticleIterator(List<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper> lstKnowledgeArticle) {
        this.lstKnowledgeArticle = lstKnowledgeArticle;
        this.intCounter = 0;
    }

    /**
     * @author Vignesh
     * @date    21-Dec-2020
     * @description : Method to check for next list
     */
    public boolean hasNext(){
        return intCounter>=lstKnowledgeArticle.size()?false:true;
    }

    /**
     * @author Vignesh
     * @date    21-Dec-2020
     * @description : Method to get next list.
     */
    public KnowledgeArticleDataRemediate.KnowledgeArticleWrapper next(){
        intCounter++;
        return lstKnowledgeArticle[intCounter-1];
    }

    /**
     * @author Vignesh
     * @date    21-Dec-2020
     * @description : Method to iterate.
     */
    public Iterator<KnowledgeArticleDataRemediate.KnowledgeArticleWrapper> iterator()
   {
      return this;   
   }
}