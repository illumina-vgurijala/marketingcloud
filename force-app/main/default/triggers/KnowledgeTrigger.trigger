trigger KnowledgeTrigger on Knowledge__kav (before insert, before update, after update, after insert) {
  
    ilib_SObjectDomain.triggerHandler(KnowledgeArticles.class);

}