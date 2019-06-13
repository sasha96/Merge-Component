/**
*  JIRA        :   https://silverline.jira.com/browse/LIB-636
*  Class name  :   SL_ctrl_MergeAnything
*  Created by  :   Alex Zhurylo
*  Created on  :   4/25/2019
*  Description :   Apex class for SL_MergeAnything component
**/

public class SL_ctrl_MergeAnything {

    /*
    * @MethodName    :   findObjectName
    * @Description   :   method find Object Api Name if current user has profile access and check Chatter accessibility 
    * @param         :   object Id
    * @return        :   return Wrapper of Object Api Name and boolean value chatter accessibility
    * @example param :   recordId = Opportunity.Id
    */
    @AuraEnabled
    public static String findObjectName(Id recordId){ 

        String objectName = recordId.getSObjectType().getDescribe().getName();
        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
        Schema.DescribeSObjectResult objDescribe = SObjectTypeObj.getDescribe();
   
        if(objDescribe.accessible){
            return Json.serialize( new ListObjectTypeAndIsChatterEnableWrapper (recordId.getSObjectType().getDescribe().getName(), objDescribe.isFeedEnabled()));
        }else{
            return Json.serialize('ERROR');
        }
    }   
    
    /*
    * @MethodName       :   getAllValuesFromFieldSet
    * @Description      :   method find Field Set from custom metadata and return all values 
    * @params           :   object api name
    * @return           :   return fieldset members list
    * @example params   :   objApiName = Opportunity
    */
    @AuraEnabled
    public static String getAllValuesFromFieldSet(String objApiName) {
        
        String fieldSetName = '';
        List_FieldSet_And_Object__mdt[] threatMappings =  [SELECT MasterLabel,QualifiedApiName FROM List_FieldSet_And_Object__mdt];
        for(integer i = 0 ; i < threatMappings.size() ; i++){
            if(objApiName == threatMappings[i].MasterLabel){
                fieldSetName = String.valueOf(threatMappings[i].QualifiedApiName);
            }
        }

        if(fieldSetName != ''){
            Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objApiName);
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
            return Json.serialize(fieldSetObj.getFields());
        }

        return null; 
	}

    /*
    * @MethodName       :   returnObjectsByDefaultName
    * @Description      :   method find all object due to name as default object
    * @params           :   object api name, search field as object name, record id
    * @return           :   return List<ListSerachWrapper>  
    * @example params   :   objApiName = Opportunity, searchFields = 'Opportunity name', recordId = Opportunity.Id
    */
    @AuraEnabled
    public static String returnObjectsByDefaultName( String objectName, List<String> searchFields, String recordId){
        
        String soqlOnlyMainObj = 'SELECT name FROM '+  objectName + ' WHERE Id =: recordId';
        
        List<sObject> mainObject = Database.query(soqlOnlyMainObj);

        String searchStr = String.valueOf(mainObject[0].get('Name'));

        String fields = '';
        for (Integer i = 0; i < searchFields.size(); i++) {
            if(i != searchFields.size() -1 ){
                fields = fields + searchFields[i] + ',';
            }else{
                fields = fields + searchFields[i];
            }
        }

        String strSosl = 'SELECT Id FROM ' +
        String.escapeSingleQuotes( objectName ) + ' WHERE Name LIKE \'%'+ searchStr  +'%\' LIMIT 20';
        
        List<sObject> lstSearchResultsAfterSOSL = Database.query(strSosl);
        
        List<Id> listIds = new List<Id>();
        for (Integer i = 0; i < lstSearchResultsAfterSOSL.size(); i++) {
            listIds.add(lstSearchResultsAfterSOSL[i].Id);
        }
        
        String soql  = 'SELECT id, ' + fields  + ' FROM ' +  objectName +' WHERE Id IN :listIds AND Id !=: recordId' ;
        
        List<sObject> lstObject = Database.query(soql);

        List<ListSerachWrapper> lstWrappers = new List<ListSerachWrapper>();
        for (Integer i = 0; i < lstObject.size(); i++) {
            lstWrappers.add(new ListSerachWrapper(lstObject[i])); 
        }
        
        return Json.serialize(lstWrappers);  
    }  

    /*
    * @MethodName       :   getListObjectThrougthSearch
    * @Description      :   method find all object with current search field from search input
    * @params           :   search string, object api name, list search field, record id
    * @return           :   return List<ListSerachWrapper> that contains all found records
    * @example params   :   searchStr = 'test', objApiName = Opportunity, searchFields = Name of returned fields, recordId = Opportunity.Id
    */
    @AuraEnabled
    public static String getListObjectThrougthSearch(String searchStr, String objApiName, List<String> searchFields, String recordId){

        String fields = '';
        for (Integer i = 0; i < searchFields.size(); i++) {
            if(i != searchFields.size() -1 ){
                fields = fields + searchFields[i] + ',';
            }else{
                fields = fields + searchFields[i];
            }
        }

        String strSosl = 'SELECT Id FROM ' +
        String.escapeSingleQuotes( objApiName ) + ' WHERE Name LIKE \'%'+ searchStr  +'%\' LIMIT 20';
        
        List<sObject> lstSearchResultsAfterSOSL = Database.query(strSosl);
        
        List<Id> listIds = new List<Id>();
        for (Integer i = 0; i < lstSearchResultsAfterSOSL.size(); i++) {
            listIds.add(lstSearchResultsAfterSOSL[i].Id);
        }
        
        String soql  = 'SELECT id, ' + fields  + ' FROM ' +  objApiName +' WHERE Id IN :listIds AND Id !=: recordId' ;
        
        List<sObject> lstObject = Database.query(soql);

        List<ListSerachWrapper> lstWrappers = new List<ListSerachWrapper>();
        for (Integer i = 0; i < lstObject.size(); i++) {
            lstWrappers.add(new ListSerachWrapper(lstObject[i])); 
        }     
    
        return Json.serialize(lstWrappers) ;
    }

    /*
    * @MethodName       :   findAllValuesForSelectedObjects
    * @Description      :   method find all object's fields, apiNames, labels
    * @params           :   List objects id, object api name, record id
    * @return           :   return AllFieldsAndValuesWrapper wrapper that contains list apiName and label, all informain about Main object and list Object Names
    * @example params   :   lstObjectIds = Oppor.Id, Opport2.Id, objApiName = 'Opportunity',  recordId = Opportunity.Id
    */
    @AuraEnabled 
    public static String findAllValuesForSelectedObjects(String[] lstObjectIds, String objApiName, String recordId){
        
        List<Id> lstIds = new List<Id>();
        for (Integer i = 0; i < lstObjectIds.size(); i++) {
            lstIds.add( lstObjectIds[i] );
        }

        Map<String, Schema.SObjectField> mapAllobjectFields = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();

        Map<String, String> mapFieldsLabelAndApi  = new  Map<String, String>();

        String query = 'SELECT ';
        String queryWithoutRelationShip = 'SELECT ';

        for(String s : mapAllobjectFields.keySet()) {
            if(mapAllobjectFields.get(s).getDescribe().isUpdateable() || s == 'Name'){
                query += ' ' + s + ',';
                queryWithoutRelationShip += ' ' + s + ',';
                
                Schema.DisplayType dType = mapAllobjectFields.get(s).getDescribe().getType();
                if(dType == Schema.DisplayType.REFERENCE) {
                    query += ' ' + mapAllobjectFields.get(s).getDescribe().getRelationshipName() + '.Name,';
                }

                mapFieldsLabelAndApi.put(s, mapAllobjectFields.get(s).getDescribe().getLabel());
            }
        }

        if (query.subString(query.Length()-1,query.Length()) == ','){
            query = query.subString(0,query.Length()-1);
        }

        if (queryWithoutRelationShip.subString(queryWithoutRelationShip.Length()-1,queryWithoutRelationShip.Length()) == ','){
            queryWithoutRelationShip = queryWithoutRelationShip.subString(0,queryWithoutRelationShip.Length()-1);
        }
        
        String queryForMain = query;
        queryForMain += ' FROM ' + objApiName + ' WHERE Id =: recordId';
        queryWithoutRelationShip += ' FROM ' + objApiName + ' WHERE Id =: recordId';
        query += ' FROM ' + objApiName + ' WHERE Id IN :lstIds';

        List<sObject> lstMainObjWithValues = database.query(queryForMain);
        List<sObject> lstMainObjWithValuesWithoutRelationship = database.query(queryWithoutRelationShip);
        List<sObject> lstObjWithothoutMainValues  = database.query(query);
        
       
        List<sObject> lstObjWithValues = new  List<sObject> ();
        lstObjWithValues.add(lstMainObjWithValues[0]);
        for (Integer i = 0; i < lstObjWithothoutMainValues.size(); i++) {
            lstObjWithValues.add(lstObjWithothoutMainValues[i]);
        }

        List<Object> lstObjectNames = new List<Object>();
        for (Integer i = 0; i < lstObjWithValues.size(); i++) {
            sObject sob = lstObjWithValues[i];
            lstObjectNames.add(sob.get('Name'));
        }        

        Map<String, String> mapFieldsLabelAndApiNew  = new  Map<String, String>();
        
        list<RowWrapper> lstRows = new list<RowWrapper>();
        RowWrapper row;
        list<FieldWrapper> fieldWrapper;
        
        for(String s : mapAllobjectFields.keySet()) {
            
            if(mapAllobjectFields.get(s).getDescribe().isUpdateable()){
                
                Integer isAllValueEmpty = 0;
                for (Integer i = 0; i < lstObjWithValues.size(); i++) {
                    sObject sob = lstObjWithValues[i];
                    if(sob.get(s) == null){
                        isAllValueEmpty++;
                    }
                }
                if(isAllValueEmpty != lstObjWithValues.size()){
                    Schema.DisplayType dType = mapAllobjectFields.get(s).getDescribe().getType();
                    
                    row = new RowWrapper();
                    row.title = mapAllobjectFields.get(s).getDescribe().getLabel();
                    
                    fieldWrapper = new list<FieldWrapper>();

                    for (Integer i = 0; i < lstObjWithValues.size(); i++) {
                        sObject sob = lstObjWithValues[i];
                        Object recordIdChildren = sob.get(s);
                        String childName = null;
                        if(dType == Schema.DisplayType.REFERENCE && recordIdChildren != null) {
                            childName = String.valueOf(sob.getSobject(mapAllobjectFields.get(s).getDescribe().getRelationshipName()).get('Name'));
                        }else if(dType == Schema.DisplayType.DATETIME){
                            childName = 'DATETIME';
                        }

                        fieldWrapper.add(new FieldWrapper(String.valueOf(mapAllobjectFields.get(s)), sob.get(s), false,
                                                    String.valueOf(mapAllobjectFields.get(s).getDescribe().getType()), sob.Id, childName ));   

                        mapFieldsLabelAndApiNew.put(s, mapFieldsLabelAndApi.get(s));
                    }

                    row.lstFields = fieldWrapper;
                    lstRows.add(row);
                }
            }
        }
        
        AllFieldsAndValuesWrapper wrapper = new AllFieldsAndValuesWrapper( mapFieldsLabelAndApiNew, 
                                                lstMainObjWithValuesWithoutRelationship, lstRows, lstObjectNames);

        return Json.serialize(wrapper);
    }
    
    /*
    * @MethodName       :   getSurvivedObjectValuesAndLabels
    * @Description      :   method transform labels of fields and values for survied object
    * @params           :   main object, list of labels and api name of fields, object api name,
    * @return           :   return List<ApiNameAndValueWrapperForThirdPage> wrapper with labels and values of survied object
    * @example params   :   mainObject = survied Object, lstApiNameAndLabels = list of labels and api values, objApiName = 'Opportunity'
    */
    @AuraEnabled
    public static String getSurvivedObjectValuesAndLabels( String mainObject, String lstApiNameAndLabels, String objApiName){

        Map<String, Schema.SObjectField> mapAllobjectFields = Schema.getGlobalDescribe().get(objApiName).getDescribe().fields.getMap();

        List<sObject> deserialMainObject = (List<sObject>)System.JSON.deserialize(mainObject, List<sObject>.class);  

        List<ApiNameAndValueWrapperForThirdPage> deserialLstApiNameAndLabels = (List<ApiNameAndValueWrapperForThirdPage>)System.JSON.deserialize(lstApiNameAndLabels, List<ApiNameAndValueWrapperForThirdPage>.class);  

        List<ApiNameAndValueWrapperForThirdPage> lstLabelsAndValuesSurvivedObject = new List<ApiNameAndValueWrapperForThirdPage>();

        for (Integer i = 0; i < deserialLstApiNameAndLabels.size(); i++) {
            Schema.DisplayType dType = mapAllobjectFields.get(deserialLstApiNameAndLabels[i].key).getDescribe().getType();

            lstLabelsAndValuesSurvivedObject.add(new ApiNameAndValueWrapperForThirdPage(
                String.valueOf(deserialMainObject[0].get(deserialLstApiNameAndLabels[i].key)),
                deserialLstApiNameAndLabels[i].value, String.valueOf(dType)));
        }

        return JSON.serialize(lstLabelsAndValuesSurvivedObject);
    }

    /*
    * @MethodName       :   mergeObjectAndChildrenObjects
    * @Description      :   method delete objects that will be merged, change owner of children objects, clone chatter posts and update field in main object
    * @params           :   main object Id, object api name, list objects id that will be merged, merge children option, surviev object, merge chatter option
    * @return           :   return success if change owner childler objects, delete redundant objects and update fields on survied object 
    * @example params   :   mainObject = Opportunity.Id, objApiName = 'Opportunity', lstAllObjIdsWithoutMain =list<id>, isMergeChildren = true, 
                            surviedObj = Opportunity object, isMergeChatterPosts = true
    */
    @AuraEnabled
    public static String mergeObjectAndChildrenObjects(String mainObjId, String objApiName, List<String> lstAllObjIdsWithoutMain, 
        Boolean isMergeChildren, String surviedObj, Boolean isMergeChatterPosts){
        
        List<Id> lstIds = new List<Id>();
        for (Integer i = 0; i < lstAllObjIdsWithoutMain.size(); i++) {
            lstIds.add( lstAllObjIdsWithoutMain[i] );
        }

        if(isMergeChildren){
            mergeChildrenObjects(mainObjId, objApiName, lstIds);
        }

        if(isMergeChatterPosts){
            mergeChildrenChatterRecords(mainObjId, objApiName, lstIds);
        }

        List<sObject> surviedObjParsed = (List<sObject>)System.JSON.deserialize(surviedObj, List<sObject>.class);   

        if(surviedObjParsed.size()>0){
            update surviedObjParsed[0];
        }

        String soql = 'SELECT id FROM ' + objApiName + ' WHERE Id IN : lstIds';

        List<sObject> lstObject = Database.query(soql);
        
        if(lstObject.size()>0){
            delete lstObject;
            return 'Success';
        }else{
            return 'ERROR';
        }
    }

    /*
    * @MethodName       :   mergeChildrenObjects
    * @Description      :   method update Owner of children records 
    * @params           :   main object Id, object api name, list objects id that will be merged
    * @example params   :   mainObjId = Opportunity.Id, objApiName = 'Opportunity', lstAllObjIdsWithoutMain = list<id>
    */
    private static void mergeChildrenObjects(String mainObjId, String objApiName, List<Id> lstIds){

        Map<String, String> childrenObject = findAllValuesSelectedObjects( lstIds,  objApiName);
        Map<List<sObject>, String> mapQueries = new Map<List<sObject>, String>();
        for (String key : childrenObject.keyset() ) {
            
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Schema.SObjectType ctype = gd.get(key); 
            
            Boolean isUpdatable = ctype.getDescribe().isUpdateable();
            if(isUpdatable){
                String soql = 'SELECT Id, ' +  childrenObject.get(key)
                                + ' FROM ' + key 
                                + ' WHERE ' + childrenObject.get(key) +' IN :  lstIds ';
                
                List<sObject> lstObject = Database.query(soql);
                if(lstObject.size() > 0){
                    mapQueries.put(lstObject, childrenObject.get(key));
                }
            }
        }

        Map<Map<Id, sObject>, String> mapObjForChangeOwner = new Map<Map<Id, sObject>, String>();

        List<sObject> lstObjectFinalResult = new List<sObject> ();

        for (List<sObject> lst : mapQueries.keyset() ) {
            for (Integer i = 0; i < lst.size(); i++) {
                mapObjForChangeOwner.put( new Map<Id, sObject>{lst[i].Id => lst[i]}, mapQueries.get(lst));
            }
        }

        for(Map<Id, sObject> innerMap : mapObjForChangeOwner.keyset()){
            String field = mapObjForChangeOwner.get(innerMap);
            for(Id item : innerMap.keyset()){
                Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
                Schema.SObjectType ctype = gd.get(item.getSObjectType().getDescribe().getName()); 
                String fieldValue =  field;
                Boolean isUpdateble = ctype.getDescribe().fields.getMap().get(fieldValue).getDescribe().isUpdateable();
                if(isUpdateble){
                    innerMap.get(item).put(field , mainObjId);
                    lstObjectFinalResult.add(innerMap.get(item));
                }
            }
        }
        
        if(lstObjectFinalResult.size() > 0){
            update lstObjectFinalResult;
        }
    }

    /*
    * @MethodName       :   mergeChildrenChatterRecords
    * @Description      :   method change Owner of children chatter records 
    * @params           :   main object Id, object api name, list objects id that will be merged
    * @example params   :   mainObject = Opportunity.Id, objApiName = "Opportunity', lstAllObjIdsWithoutMain = list<id>
    */
    private static void mergeChildrenChatterRecords(String mainObjId, String objApiName, List<Id> lstIds){

        List<FeedItem> lstFeedItems = [SELECT Id, body FROM FeedItem 
                                        WHERE ParentId IN : lstIds ORDER BY CreatedDate];
                                        
        List<FeedComment> lstFeedCommets = [SELECT Id, CommentBody, FeedItemId, parentId FROM FeedComment 
                                            WHERE ParentId IN : lstIds ORDER BY CreatedDate];

        List<FeedItem> newListFeedItems = new List<FeedItem>();
        Map<Integer, List<FeedComment>> mapNewDeefComments = new Map<Integer, List<FeedComment>>();
        FeedItem newItem;
        List<FeedComment> newListFeedComments;
        for (Integer i = 0; i < lstFeedItems.size(); i++) {
            newListFeedComments = new List<FeedComment>();
            
            if(lstFeeditems[i].body != null && lstFeeditems[i].body != ''){
                newItem = lstFeeditems[i].clone(false, false,false,false);
                newItem.parentId = mainObjId;
                    newListFeedItems.add(newItem);
                
                for (Integer j = 0; j < lstFeedCommets.size(); j++) {
                    if(lstFeedCommets[j].FeedItemId == lstFeeditems[i].Id){
                        newListFeedComments.add(lstFeedCommets[j]);
                    }
                }
            }
            if(newListFeedComments.size() > 0){
                mapNewDeefComments.put(i, newListFeedComments);
            }
        }

        if(newListFeedItems.size() > 0){
            insert newListFeedItems;
        }

        List<FeedComment> listFeedCommentsWithNewData = new List<FeedComment>();
        FeedComment newCom;
        for (Integer i = 0; i < newListFeedItems.size(); i++) {
            List<FeedComment> newFeedComment = mapNewDeefComments.get(i);
            if(newFeedComment != null){
                for (Integer j = 0; j < newFeedComment.size(); j++) {
                    newCom = newFeedComment[j].clone(false,false,false,false);
                    newCom.FeedItemId = newListFeedItems[i].Id;
                    listFeedCommentsWithNewData.add(newCom);
                }
            }
            
        }

        if(listFeedCommentsWithNewData.size() > 0){
            insert listFeedCommentsWithNewData;
        }
    }

    /*
    * @MethodName       :   findAllValuesSelectedObjects
    * @Description      :   method find children relationship 
    * @params           :   list Ids for search, object api name
    * @return           :   return map mapNamesAllChildren that contains all relationship 
    * @example params   :   lstAllObjIdsWithoutMain = list<id>, objApiName = 'Opportunity'
    */
    private static Map<String, String> findAllValuesSelectedObjects(List<Id> lstIds, String objectName){

        Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe();
		Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
		Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();

        List<ChildRelationship> childRel = DescribeSObjectResultObj.getChildRelationships();

        Map<String, String> mapNamesAllChildren = new Map<String, String>();
        for (Integer i = 0; i < childRel.size(); i++) {
            if(childRel[i].getRelationshipName() != null){
                mapNamesAllChildren.put(String.valueOf(childRel[i].getChildSObject()), childRel[i].getField().getDescribe().getName());
            }        
        }

        return mapNamesAllChildren;
    }

    /*
    * @ Wrapper Name    :    ListObjectTypeAndIsChatterEnableWrapper
    * @ Description     :    Return informations about Object api Type and is Chatter Enable option  
    */
    public class ListObjectTypeAndIsChatterEnableWrapper {
        public String name {get; set;}
		public Boolean isChatterEnable {get; set;}
   
        public ListObjectTypeAndIsChatterEnableWrapper(String name, Boolean isChatterEnable) {  
            this.name = name;   
            this.isChatterEnable = isChatterEnable;
        }
	}

    /*
    * @ Wrapper Name    :    ListSerachWrapper
    * @ Description     :    Return Object record and is checked param  
    */
    public class ListSerachWrapper {
        sObject objectRecord {get; set;}
		public Boolean isChecked {get; set;}
   
        public ListSerachWrapper(sObject objectRecord) {  
            this.objectRecord = objectRecord;   
            this.isChecked = false;
        }
	}

    /*
    * @ Wrapper Name    :    AllFieldsAndValuesWrapper
    * @ Description     :    Return Map of labels and api names; list that contains all informations about main object;
                             list<RowWrapper> that contains field, value, label; list of selected object names
    */
    public class AllFieldsAndValuesWrapper {
        public Map<String, String> mapFieldsLabelAndApi {get; set;}
        List<sObject> lstMainObjWithValues {get;set;}
        list<RowWrapper> lstRows {get;set;}
        List<Object> lstObjectNames{get;set;}

        public AllFieldsAndValuesWrapper(Map<String, String> mapFieldsLabelAndApi, List<sObject> lstMainObjWithValues, list<RowWrapper> lstRows, List<Object> lstObjectNames){ 
            this.mapFieldsLabelAndApi = mapFieldsLabelAndApi;
            this.lstMainObjWithValues = lstMainObjWithValues;
            this.lstRows= lstRows;
            this.lstObjectNames = lstObjectNames;
        }
	}

    /*
    * @ Wrapper Name    :    RowWrapper
    * @ Description     :    Return title and list<FieldWrapper> that contains all information about field
    */
    public class RowWrapper {
        public string title {get; set;}
        public list<FieldWrapper> lstFields {get; set;}

        public RowWrapper() {} 
    }

    /*
    * @ Wrapper Name    :    FieldWrapper
    * @ Description     :    Return apinameField; value, label, type, selected option, object Id
    */
    public class FieldWrapper {
        public string apinameField 	{get;set;}
        public Object value 	{get;set;}
        public string label 	{get;set;} 
        public string type 	    {get;set;}
        public boolean selected {get;set;}
        public Id objectId {get;set;}

        public FieldWrapper(string apinameField, Object value, boolean selected, string type, Id objectId, string label ) {  
            this.apinameField = apinameField;   
            this.value = value;   
            this.type = type;   
            this.selected = selected;   
            this.objectId = objectId;
            this.label = label;
        }
    }   
    
    /*
    * @ Wrapper Name    :    ApiNameAndValueWrapperForThirdPage
    * @ Description     :    Return value, key, fieldType
    */
    public class ApiNameAndValueWrapperForThirdPage{
        public String value {get;set;}
        public String key {get;set;}
        public String fieldType {get;set;}
        
        public ApiNameAndValueWrapperForThirdPage(String value, String key){
            this.value = value;
            this.key = key;
        }

         public ApiNameAndValueWrapperForThirdPage(String value, String key, String fieldType){
            this.value = value;
            this.key = key;
            this.fieldType = fieldType;
        }
    }
}