public with sharing class DashboardComponentController {
    //Global variable to store the filter value
    public static String globalFilter;

    //This method is called after selecting a drop down value and calls the fetch method again to return the wrapper response
    @AuraEnabled
        public static List<DashboardWrapper> filterData(String filter){
            try {
                globalFilter=filter;
                return fetchData();
            }
            catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    
    //This method queries the metadata records and stores the object names and corresponding fields in a map
    @AuraEnabled
        public static List<DashboardWrapper> fetchData(){
            try {
                Map<String,String> mapOfFieldByObjName = new Map<String, String>();
                Dashboard_Settings__mdt[] dasbhoardMdtRecords = [SELECT ObjectApiName__c,Fields__c from Dashboard_Settings__mdt];
                
                for (Dashboard_Settings__mdt customRecord : dasbhoardMdtRecords) {
                    mapOfFieldByObjName.put(customRecord.ObjectApiName__c, customRecord.Fields__c);
                }
                return queryData(mapOfFieldByObjName);
            } 
            catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    
    //This method queries the records of the above object and fields and stores in map. If the component is loading for the first time the globalfilter will be null so all records are queried, otherwise the query is tweaked depending on the filter
    @AuraEnabled
        public static List<DashboardWrapper> queryData(Map<String,String> mapOfFieldByObjName){
            try{
                Map<String,List<SObject>> mapOfRecordsByObjName = new Map<String, List<SObject>>();
                List<String> listOfObjNames = new List<String>();
                for(String objectVar : mapOfFieldByObjName.keySet()){
                    listOfObjNames.add(objectVar);
                    if(globalFilter == null || globalFilter == 'allRecords'){
                        mapOfRecordsByObjName.put(objectVar,Database.query('SELECT Id, ' +mapOfFieldByObjName.get(objectVar)+ ' FROM ' +objectVar));
                    }
                    else if(globalFilter == 'myRecords'){
                        Id userId = UserInfo.getUserId();
                        System.debug('userId'+userId);
                        mapOfRecordsByObjName.put(objectVar,Database.query('SELECT Id, ' +mapOfFieldByObjName.get(objectVar)+ ' FROM ' +objectVar+' WHERE OwnerId =\'' + userId + '\''));
                    }
                    else if(globalFilter == 'thisYear'){
                        mapOfRecordsByObjName.put(objectVar,Database.query('SELECT Id, ' +mapOfFieldByObjName.get(objectVar)+ ' FROM ' +objectVar+ ' WHERE CreatedDate = THIS_YEAR' ));
                    }
                    else if(globalFilter == 'thisMonth'){
                        mapOfRecordsByObjName.put(objectVar,Database.query('SELECT Id, ' +mapOfFieldByObjName.get(objectVar)+ ' FROM ' +objectVar+ ' WHERE CreatedDate = THIS_MONTH')); 
                    }
                    else if(globalFilter == 'thisWeek'){
                        mapOfRecordsByObjName.put(objectVar,Database.query('SELECT Id, ' +mapOfFieldByObjName.get(objectVar)+ ' FROM ' +objectVar+ ' WHERE CreatedDate = THIS_WEEK')); 
                    }
                    else if(globalFilter == 'today'){
                        mapOfRecordsByObjName.put(objectVar,Database.query('SELECT Id, ' +mapOfFieldByObjName.get(objectVar)+ ' FROM ' +objectVar+ ' WHERE CreatedDate = TODAY')); 
                    }  
                }
                //Method call to get icons dynamically and save in a map
                Map<String,String> mapOfObjNameByiconNames = dynamicIonName(listOfObjNames);
                return populateWrapper(mapOfFieldByObjName,mapOfRecordsByObjName,mapOfObjNameByiconNames);
            }
            catch(Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
        
        //This method gets the icon names of all the tabs and if it matches the objects we have it is stored in a map. This method code not cleaned yet
        @AuraEnabled
        public static Map<String,String> dynamicIonName(List<String> listOfObjNames){
            Map<String,String> mapOfObjNameByiconNames = new Map<String,String>();
            for(String sObjectName:listOfObjNames){
                String u;
                List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
                List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
                List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

                for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }

                for(Schema.DescribeTabResult tr : tabDesc) {
                    if( sObjectName == tr.getSobjectName() ) {
                        if( tr.isCustom() == true ) {
                            iconDesc.addAll(tr.getIcons());
                        } else {
                            u = 'standard:' + sObjectName.toLowerCase();
                            mapOfObjNameByiconNames.put(sObjectName,u);
                        }
                    }
                }
                for (Schema.DescribeIconResult ir : iconDesc) {
                    if (ir.getContentType() == 'image/svg+xml'){
                        u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                        mapOfObjNameByiconNames.put(sObjectName,u);
                        break;
                    }
                }
                system.debug('iconName:: '+u);
        
            }
            return mapOfObjNameByiconNames;
        }

        //This method does the main job of populating the wrapper. Wrapper explaination below
        @AuraEnabled
        public static List<DashboardWrapper> populateWrapper(Map<String,String> mapOfFieldByObjName, Map<String,List<SObject>> mapOfRecordsByObjName,Map<String,String> mapOfObjNameByiconNames ){
            try{
                List<DashboardWrapper> wrapperToSend = new List<DashboardWrapper>();
                for(String objectVar : mapOfFieldByObjName.keySet()){
                    DashboardWrapper wrapperObj=new DashboardWrapper();
                    List<FieldWrapper> listOfFieldWrapper = new List<FieldWrapper>();
                    String temp=mapOfFieldByObjName.get(objectVar);
                    List<String> listOfFieldApiName = new List<String>();
    
                    //split field api names to store in a list to get labelss of the fields, these are needed to pass to the data table
                    listOfFieldApiName.addall(temp.split(','));
                    for(String fieldNameObj: listOfFieldApiName){
                        //check if field is accessible? 
                        SObjectType objectType = ((SObject)Type.forName('Schema', objectVar).newInstance()).getSObjectType();
                        if(objectType.getDescribe().fields.getMap().get(fieldNameObj).getDescribe().isAccessible()){

                            FieldWrapper fieldWrapperObj;
                            fieldWrapperObj = new FieldWrapper();
                            typeAttributesWrapper tawrapperObj;
                            tawrapperObj = new typeAttributesWrapper();
                            labelWrapper labelWrapperObj;
                            labelWrapperObj = new labelWrapper();
                            String value =(String)Schema.getGlobalDescribe().get(String.valueOf(objectVar)).getDescribe().fields.getMap().get(fieldNameObj).getDescribe().getLabel() ;
    
                            fieldWrapperObj.fieldName = fieldNameObj;
                            fieldWrapperObj.label=value;
                            fieldWrapperObj.sortable=true;
                            if(fieldWrapperObj.fieldName == 'Name'){
                                fieldWrapperObj.type='url';
                                fieldWrapperObj.fieldName = 'link';
                                labelWrapperObj.fieldName='Name';
                                tawrapperObj.label=labelWrapperObj;
                                tawrapperObj.target='_blank';
                                fieldWrapperObj.typeAttributes = tawrapperObj;
                            }
                            else {
                                fieldWrapperObj.type='';
                            }
                            listOfFieldWrapper.add(fieldWrapperObj);
                        }
                        //not sure what to do in else?
                    }
                    wrapperObj.count = mapOfRecordsByObjName.get(objectVar).size();
                    wrapperObj.objectName = objectVar;
                    wrapperObj.column = listOfFieldWrapper;
                    wrapperObj.records = mapOfRecordsByObjName.get(objectVar);
                    wrapperObj.iconName = mapOfObjNameByiconNames.get(objectVar);
                    wrapperToSend.add(wrapperObj);
                }
                System.debug('wrapperToSend+'+wrapperToSend);
                for(DashboardWrapper obj: wrapperToSend){
                    System.debug(obj);
                }
                return wrapperToSend;
            }
            catch(Exception e) {
                throw new AuraHandledException(e.getMessage());
            }
        }
    
        //Main Wrapper to send 
        public class DashboardWrapper {
            @AuraEnabled
            public String objectName { get; set; }
            @AuraEnabled
            public List<SObject> records { get; set; }
            @AuraEnabled
            public List<FieldWrapper> column { get; set; }
            @AuraEnabled
            public Integer count { get; set; }
            @AuraEnabled
            public String iconName { get; set; }
        }
        //Field wrapper for columns of lightning datatable
        public class FieldWrapper{
            @AuraEnabled
            public String fieldName { get; set; }
            @AuraEnabled
            public String label { get; set; }
            @AuraEnabled
            public Boolean sortable { get; set; }
            @AuraEnabled
            public String type { get; set; }
            @AuraEnabled
            public typeAttributesWrapper typeAttributes { get; set; }
        }
        //Wrapper to set url for name field
        public class typeAttributesWrapper{
            @AuraEnabled
            public String target { get; set; }
            @AuraEnabled
            public labelWrapper label { get; set; }
        }
        //Wrapper to set the label within the above wrapper 
        public class labelWrapper{
            @AuraEnabled
            public String fieldName { get; set; }
        }
    }