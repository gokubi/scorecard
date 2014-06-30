global with sharing class ScorecardUtil implements Database.Batchable<SObject> {

    // Batch interface for rename and fill values
    public static Id fixAllData() {
        ScorecardUtil batch = new ScorecardUtil(); 
      return Database.executeBatch(batch, 100);        
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {      
       return Database.getQueryLocator(
            [select Id, OwnerId, Name, Actual_Amount__c, Actual_Number__c, Actual_Percent__c, Description__c, 
                Entry_Color__c, Forecast_Amount__c, Forecast_Number__c, Forecast_Percent__c, Goal_Type__c, 
                Metric_Type__c, Metric__c, Parent__c, Percent_of_Goal__c, Scorecard_Date__c, Scorecard_Sort_Order__c, 
                Source_Link__c, Source__c, Subcategory__c, Change_From_Previous__c, Change_Indicator__c, 
                Metric_Unique_Key__c, Percent_Change__c, Previous_Amount__c, Previous_Number__c, Previous_Percent__c, 
                Previous_Values_JSON__c from Scorecard_Entry__c] );
    }
    global void execute(Database.BatchableContext BC, List<Scorecard_Entry__c> batch) {        
        autoname( batch );
        fillPreviousMetricValues( batch );
       update batch;
    }
    global void finish(Database.BatchableContext BC) {}

    /* autoname method for scorecard entries
    **
    ** method to name entries in the form TopLevelParentName - MetricName - Month YYYY
    **
    ** the method does not actually update records - if you are not running in a before trigger,
    **   it is important to call update on the list of records
    */
    public void autoname( list<Scorecard_Entry__c> seList ) {
        // get parent ids
        set<Id> parentIDs = new set<Id>();
        for (Scorecard_Entry__c se : seList) {
            if (se.Parent__c != null)
                parentIDs.add(se.Parent__c);
            if (se.metric__c == null)
                se.metric__c = se.name;
        }

        // get top level names
        map<Id, Scorecard_Entry__c> parentNameMap = new map<Id, Scorecard_Entry__c>(
            [select Id, Name, Metric__c, Parent__c, Parent__r.Metric__c,
                    Parent__r.Parent__c, Parent__r.Parent__r.Metric__c, 
                    Parent__r.Parent__r.Parent__c, Parent__r.Parent__r.Parent__r.Metric__c,
                    Parent__r.Parent__r.Parent__r.Parent__c, Parent__r.Parent__r.Parent__r.Parent__r.Metric__c
                from Scorecard_Entry__c                 
                where id in : parentIDs]);

        // name entries in the form: [GreatGrandParentName - [GrandParentName - ]]MetricName - Month YYYY
        for (Scorecard_Entry__c se : seList) {
            String s = '';
            if (se.parent__c != null && parentNameMap.containsKey(se.parent__c)) {
                Scorecard_Entry__c myParent = parentNameMap.get(se.parent__c);
                if (myParent.Parent__r.Parent__r.Parent__r.Parent__c != null)
                    s += myParent.Parent__r.Parent__r.Parent__r.Parent__r.Metric__c + ' - ';
                if (myParent.Parent__r.Parent__r.Parent__c != null)
                    s += myParent.Parent__r.Parent__r.Parent__r.Metric__c + ' - ';
                if (myParent.Parent__r.Parent__c != null)
                    s += myParent.Parent__r.Parent__r.Metric__c + ' - ';
                if (myParent.Parent__c != null)
                    s += myParent.Parent__r.Metric__c + ' - ';
                s += myParent.Metric__c + ' - ';
            }
            
            // next add metric name
            s += se.Metric__c;

            // finally date
            if (se.Scorecard_Date__c != null) {
                 // limit the length so we do not exceed 80 chars
                 s = s.abbreviate(69);
                s += ' - ' + datetime.NewInstance(se.Scorecard_Date__c.year(), 
                    se.Scorecard_Date__c.month(), 1, 0, 0, 0).format('MMM yyyy');
            } else {
                    s = s.abbreviate(80);
            }

            // and that is the name
            se.Name = s;
        }
    }

    /* fillPreviousMetricValues
    **
    ** method to retrieve the last 12 months of values for each scorecard record and 
    **   store them into custom fields
    **
    ** does not actually update records - if not running in a before trigger it is important to update them
    **
    ** note: the list you pass in must include required fields, e.g.
    **   [select id, Scorecard_Date__c, Metric_Unique_Key__c from Scorecard_Entry__c]
    **
    ** every dated scorecard value has a unique key which is a concatenation of the metric hierarchy
    ** different dates of the same metric share the key, so we can find previous values of the same key
    */
    public void fillPreviousMetricValues( list<Scorecard_Entry__c> seList ) {

        // first get the date range and set of "key" values we need
        set<String> keys = new set<String>();
        date firstDate = system.today().addMonths(1);
        date lastDate = system.today().addYears(-10);
        for (Scorecard_Entry__c se : seList) {
            if (se.Scorecard_Date__c != null) {
                if (se.Scorecard_Date__c < firstDate) firstDate = se.Scorecard_Date__c;
                if (se.Scorecard_Date__c > lastDate) lastDate = se.Scorecard_Date__c;
                if (se.Metric_Unique_Key__c != null) 
                    keys.add(se.Metric_Unique_Key__c);
            }
        }

        // query for the values in that range and map them to the "key"
        map<String, list<Scorecard_Entry__c>> prevEntries = new map<String, list<Scorecard_Entry__c>>();
        for ( Scorecard_Entry__c se : 
                    [select id, Metric_Unique_Key__c, Scorecard_Date__c,
                        Forecast_Percent__c, Forecast_Number__c, Forecast_Amount__c, 
                        Actual_Percent__c, Actual_Number__c, Actual_Amount__c
                        from Scorecard_Entry__c where 
                        Scorecard_Date__c != null and
                        Scorecard_Date__c >= : firstDate.addYears(-1).toStartOfMonth() and
                        Scorecard_Date__c < : lastDate.addMonths(1).toStartOfMonth() and 
                        Metric_Unique_Key__c in : keys 
                        order by Scorecard_Date__c desc] ) {

            if (!prevEntries.containsKey(se.Metric_Unique_Key__c))
                prevEntries.put( se.Metric_Unique_Key__c, new list<Scorecard_Entry__c>() );

            prevEntries.get( se.Metric_Unique_Key__c ).add( se );
        }

        for (Scorecard_Entry__c se : seList) {
            if ( prevEntries.containsKey(se.Metric_Unique_Key__c) ) {
                list<Scorecard_Entry__c> lastTwelveMonths = new list<Scorecard_Entry__c>();
                Scorecard_Entry__c mostRecent = null;

                // traverse the matching entries for this "key" and grab the ones in the date range
                for ( Scorecard_Entry__c keyMatch : prevEntries.get(se.Metric_Unique_Key__c) ) {
                    if ( keyMatch.Scorecard_Date__c < se.Scorecard_Date__c.toStartOfMonth() ) {

                        // make sure we haven't gone beyond 12 months ago
                        if ( keyMatch.Scorecard_Date__c < se.Scorecard_Date__c.toStartOfMonth().addMonths( -12 ) )
                            break;

                        if ( mostRecent == null )
                            mostRecent = keyMatch;

                        lastTwelveMonths.add( keyMatch );
                    }
                }
            
                // put the most recent value into the previous month fields
                if (mostRecent != null) {
                    se.Previous_Amount__c = mostRecent.Actual_Amount__c;
                    se.Previous_Number__c = mostRecent.Actual_Number__c;
                    se.Previous_Percent__c = mostRecent.Actual_Percent__c;

                    // serialize the other previous data into the previous values field
                    se.Previous_Values_JSON__c = JSON.serialize( lastTwelveMonths );            
                }
            }   
        }
    }

   
}