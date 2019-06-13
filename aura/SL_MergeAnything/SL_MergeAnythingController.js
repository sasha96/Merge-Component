({
  /*
   *    Initialize data
   */
  doInit: function(component, event, helper) {
    component.set("v.showComponent", true);
    component.set("v.showSpinner", true);
    helper.findInitialData(component, event, helper);
  },

  /*
   *    Find Field Set and get all values
   */
  findFieldSetValues: function(component, event, helper) {
    helper.findFieldSetValues(component, event, helper);
    component.set("v.firstStep", true);
  },

  /*
   *    Search objects by input field
   */
  seachObjectByInputData: function(component, event, helper) {
    helper.seachObjectByInputData(component, event, helper);
  },

  /*
   *    Marking object and controlling count of selected objects
   */
  selectRecord: function(component, event, helper) {
    var valueIds = [];

    var lstObj = component.get("v.lstSearchedObjects");
    for (let index = 0; index < lstObj.length; index++) {
      if (lstObj[index].isChecked) valueIds.push(lstObj[index].recordId);
    }

    if (valueIds.length >= 3) {
      helper.showAttentionMesage(component, valueIds.length);
      component.set("v.isDisableNextStep", true);
    } else if (valueIds.length == 0) {
      component.set("v.isDisableNextStep", true);
    } else {
      component.set("v.isDisableNextStep", false);
    }
    component.set("v.lstMarkedObj", valueIds);
  },

  /*
   *   Called whenever click next or merge buttons
   */
  next: function(component, event, helper) {
    var currentTab = component.get("v.selectedTabId");

    if (currentTab == "1") {
      component.set("v.showSpinner", true);
      component.set("v.selectedTabId", "2");
      component.set("v.firstStep", false);
      component.set("v.secondStep", true);
      helper.showSelectedObjects(component, event);
    } else if (currentTab == "2") {
      component.set("v.selectedTabId", "3");
      component.set("v.secondStep", false);
      component.set("v.thirdStep", true);
      component.set("v.nextStepLabel", "Merge");
      helper.prepareSurvivedObjectForShow(component);
    } else if (currentTab == "3") {
      component.set("v.showSpinner", true);
      helper.mergeObjectsAndChildren(component, helper, event);
    }
    helper.moveUpTheTopPage(component);
  },

  /*
   *   Called whenever click previous or merge buttons
   */
  back: function(component, event, helper) {
    var currentTab = component.get("v.selectedTabId");

    if (currentTab == "2") {
      component.set("v.selectedTabId", "1");
      component.set("v.secondStep", false);
      component.set("v.firstStep", true);
    } else if (currentTab == "3") {
      component.set("v.selectedTabId", "2");
      component.set("v.thirdStep", false);
      component.set("v.secondStep", true);
      component.set("v.nextStepLabel", "Next");
    }
    helper.moveUpTheTopPage(component);
  },

  /*
   *   Called whenever change field value
   */
  changeRowValue: function(component, event, helper) {
    var selectedValue = event.getSource().get("v.value");
    var fieldName = event.getSource().get("v.name");
    var surviedObj = component.get("v.mainObject");

    for (var i = 0; i < surviedObj.length; i++) {
      surviedObj[i][fieldName] = selectedValue;
    }
    component.set("v.mainObject", surviedObj);
  },

  /*
   *   Called whenever change merge all children options
   */
  handleChangeOptionsMerge: function(component, event, helper) {
    var changeValue = event.getParam("value");
    component.set("v.selectedMergeOptions", changeValue);
  },

  /*
   *   Called whenever change merge chatter options
   */
  handleChangeChatterOptionsMerge: function(component, event, helper) {
    var changeValue = event.getParam("value");
    component.set("v.selectedMergeChatterOptions", changeValue);
  }
});