trigger scorecardEntryTrigger on Scorecard_Entry__c (before insert) {
   scorecardUtil su = new scorecardUtil();

	// name the records in the form TopLevelParentName - MetricName - Month YYYY
    su.Autoname( trigger.New );

    // pull in previous values from matching scorecard records
    if (Trigger.isInsert) {
      su.fillPreviousMetricValues( trigger.New );
    }
}