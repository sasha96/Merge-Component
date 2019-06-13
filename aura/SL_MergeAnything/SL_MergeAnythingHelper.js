({

  /* 
   *    Find all objects with that contain same name as Main object
   *    and check access level to edit current object type 
   */
  findInitialData: function (component, event, helper) {

    var recordId = component.get("v.recordId");

    if (recordId) {
      var action = component.get("c.findObjectName");

      action.setParams({
        recordId: recordId
      });

      action.setCallback(this, function (response) {
        var state = response.getState();

        component.set("v.showSpinner", false);

        if (state === "SUCCESS") {
          var result = JSON.parse(response.getReturnValue());
          if (result === 'ERROR') {
            /* 
              If current user has no access for edit this object, 
              close merge component and show error message
            */
            $A.get("e.force:closeQuickAction").fire();
            var resultsToast = $A.get("e.force:showToast");
            var objToast = {
              title: "You have no permissions to edit currrent Object",
              message: 'Please contact your manager '
            };
            objToast["type"] = "error";
            resultsToast.setParams(objToast);
            resultsToast.fire();
          } else {
            component.set("v.objApiName", result.name);
            component.set("v.isChatterEnable", result.isChatterEnable);
          }
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              var resultsToast = $A.get("e.force:showToast");
              var objToast = {
                title: "Error",
                message: errors[0].message
              };
              objToast["type"] = "error";
              resultsToast.setParams(objToast);
              resultsToast.fire();
            }
          }
        }
      });

      $A.enqueueAction(action);
    }
  },

  /* 
   *    Find suitable Field Set and all his fields
   */
  findFieldSetValues: function (component, event, helper) {

    var objApiName = component.get("v.objApiName");

    if (objApiName) {
      var action = component.get("c.getAllValuesFromFieldSet");

      action.setParams({
        objApiName: objApiName
      });

      action.setCallback(this, function (response) {
        var state = response.getState();

        if (state === "SUCCESS") {
          /*
            Return list values from fieldset. Iterate througth it and 
            find all field labels ana their api names. After that, call method getAllObjectsByDefaultName
            for showing all objects with this type and name default object.
          */
          var result = JSON.parse(response.getReturnValue());
          var headerItemsFromFieldSet = [];
          var headerItemsFromFieldSetWithLabels = [];

          for (var i = 0; i < result.length; i++) {
            headerItemsFromFieldSetWithLabels.push({
              apiName: result[i].fieldPath,
              label: result[i].label
            });
            headerItemsFromFieldSet.push(result[i].fieldPath);
          }

          component.set("v.headerItemsFromFieldSetWithLabels", headerItemsFromFieldSetWithLabels);
          component.set("v.headerItemsFromFieldSet", headerItemsFromFieldSet);

          this.getAllObjectsByDefaultName(component, event, helper);
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              var resultsToast = $A.get("e.force:showToast");
              var objToast = {
                title: "Error",
                message: errors[0].message
              };
              objToast["type"] = "error";
              resultsToast.setParams(objToast);
              resultsToast.fire();
            }
          }
        }
      });

      $A.enqueueAction(action);
    }
  },

  /* 
   *    Find all objects with tha same name as main object has
   *    and call method prepareSearchedObjectsForShow
   */
  getAllObjectsByDefaultName: function (component, event, helper) {

    var recordId = component.get("v.recordId");
    var objApiName = component.get("v.objApiName");
    var headerItemsFromFieldSet = component.get("v.headerItemsFromFieldSet");
    var action = component.get("c.returnObjectsByDefaultName");

    action.setParams({
      objectName: objApiName,
      searchFields: headerItemsFromFieldSet,
      recordId: recordId
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        /* 
          Find default object name. After call method prepareSearchedObjectsForShow
          for showing all objects with this type and considering default object name.
        */
        var result = JSON.parse(response.getReturnValue());

        this.prepareSearchedObjectsForShow(component, result);
      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            var resultsToast = $A.get("e.force:showToast");
            var objToast = {
              title: "Error",
              message: errors[0].message
            };
            objToast["type"] = "error";
            resultsToast.setParams(objToast);
            resultsToast.fire();
          }
        }
      }
    });

    $A.enqueueAction(action);

  },

  /* 
   *    Show attention message whenever user select more than two objects for merge
   */
  showAttentionMesage: function (component, countItem) {

    var toastEvent = $A.get("e.force:showToast");
    toastEvent.setParams({
      title: "Warning",
      message: "You can merge up to 3 objects. You selected " +
        countItem +
        " and plus your Main Object",
      type: "warning"
    });
    toastEvent.fire();

  },

  /* 
   *    Find objects by input serch string and return all suitable records. 
   *    Limit in apex 20 records.
   */
  seachObjectByInputData: function (component, event, helper) {

    var searchStr = component.find("body").get("v.value");
    component.set("v.strForSearch", searchStr);
    var objApiName = component.get("v.objApiName");
    var headerItemsFromFieldSet = component.get("v.headerItemsFromFieldSet");
    var recordId = component.get("v.recordId");

    if (searchStr && searchStr.length >= 3) {
      var action = component.get("c.getListObjectThrougthSearch");

      action.setParams({
        searchStr: searchStr,
        objApiName: objApiName,
        searchFields: headerItemsFromFieldSet,
        recordId: recordId
      });

      action.setCallback(this, function (response) {
        var state = response.getState();

        if (state === "SUCCESS") {
          /* 
             Find all objects due to input data. Call prepareSearchedObjectsForShow for showing result.
          */
          var result = JSON.parse(response.getReturnValue());
          this.prepareSearchedObjectsForShow(component, result);
        } else if (state === "ERROR") {
          var errors = response.getError();
          if (errors) {
            if (errors[0] && errors[0].message) {
              var resultsToast = $A.get("e.force:showToast");
              var objToast = {
                title: "Error",
                message: errors[0].message
              };
              objToast["type"] = "error";
              resultsToast.setParams(objToast);
              resultsToast.fire();
            }
          }
        }
      });

      $A.enqueueAction(action);
    } else {
      /* 
         If nothing finds call prepareSearchedObjectsForShow for empty list.
      */
      this.prepareSearchedObjectsForShow(component);
    }
  },

  /* 
   *    Prepare data for showing in first step
   */
  prepareSearchedObjectsForShow: function (component, result) {
    /* 
      Iterate throught relust list and list field items from field set.
      Create new list and add is Checked, record Id attributes and 
      and list of api name and label every field. 
    */
    var headerItemsFromFieldSet = component.get("v.headerItemsFromFieldSet");
    var lstSearchedObjects = [];

    for (var row in result) {
      var lstValuesAndLabel = [];
      for (var fieldName in headerItemsFromFieldSet) {
        lstValuesAndLabel.push({
          label: headerItemsFromFieldSet[fieldName],
          value: result[row].objectRecord[headerItemsFromFieldSet[fieldName]]
        })
      }
      lstSearchedObjects.push({
        recordId: result[row].objectRecord.Id,
        lstValuesAndLabel: lstValuesAndLabel,
        isCheked: result[row].isChecked
      })
    }
    component.set("v.lstSearchedObjects", lstSearchedObjects);

  },

  /* 
   *    Move up to page whenever swith between pages 
   */
  moveUpTheTopPage: function (component, event, helper) {
    document.getElementById("mainObjId").scrollTop = 0;
  },

  /* 
   *    Preapare Survived object label and value for showing in step 3
   */
  prepareSurvivedObjectForShow: function (component, event, helper) {

    var mainObject = component.get("v.mainObject");
    var lstReferenceFields = component.get('v.lstReferenceFields');
    var lstApiNameAndLabels = component.get("v.lstApiNameAndLabels");
    var objApiName = component.get("v.objApiName");

    var action = component.get("c.getSurvivedObjectValuesAndLabels");

    action.setParams({
      mainObject: JSON.stringify(mainObject),
      lstApiNameAndLabels: JSON.stringify(lstApiNameAndLabels),
      objApiName: objApiName
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      component.set("v.showSpinner", false);
      if (state === "SUCCESS") {
        /*
          Return list of api name fields and values from apex. Iterate and find
          where field is refference or datatime for correct viewing.
        */

        var result = JSON.parse(response.getReturnValue());
        var lstFieldsOfSurviedObject = [];
        for (var item in result) {
          var nameRefferenceField = lstReferenceFields.filter(itemF => itemF.apiName === result[item].key);
          var nameOfReffernece = nameRefferenceField.length > 0 ? nameRefferenceField[0].nameOfReffernece : '';

          if (result[item].fieldType === 'DATE') {
            result[item].value = $A.localizationService.formatDate(result[item].value, "YYYY-MM-DD");
          }

          lstFieldsOfSurviedObject.push({
            value: result[item].value,
            key: result[item].key,
            nameOfReffernece: nameOfReffernece,
            fieldType: result[item].fieldType
          })
        }

        component.set("v.lstFieldsOfSurviedObject", lstFieldsOfSurviedObject);

      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            var resultsToast = $A.get("e.force:showToast");
            var objToast = {
              title: "Error",
              message: errors[0].message
            };
            objToast["type"] = "error";
            resultsToast.setParams(objToast);
            resultsToast.fire();
          }
        }
      }
    });

    $A.enqueueAction(action);

  },

  /* 
   *    Prepare all selected objects and their values for showing in step 2, 
   *    prepare correct view of all data, marked as disable empty fields,  
   */
  showSelectedObjects: function (component, event, helper) {

    var recordId = component.get("v.recordId");
    var lstObjects = component.get("v.lstMarkedObj");
    var objApiName = component.get("v.objApiName");

    var lstObjectIds = [];

    for (var i = 0; i < lstObjects.length; i++) {
      lstObjectIds.push(lstObjects[i]);
    }
    component.set("v.lstAllObjIdsWithoutMain", lstObjectIds);

    var action = component.get("c.findAllValuesForSelectedObjects");

    action.setParams({
      lstObjectIds: JSON.stringify(lstObjectIds),
      objApiName: objApiName,
      recordId: recordId
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      component.set("v.showSpinner", false);
      if (state === "SUCCESS") {
        /*
          Return wrapper from apex. It contains map field labels and values; survived object with api name and values;
          list wrapper that contains title, type, api name, id, selected options for every object.
        */
        var result = JSON.parse(response.getReturnValue());
        var mainObj = result.lstMainObjWithValues[0];
        var AllFieldsAndValuesWrapper = result.lstRows;
        var allObjectNames = [];
        var lstReferenceFields = []

        allObjectNames.push("Field Name");
        var lstObjectNames = result.lstObjectNames;
        for (var i = 0; i < lstObjectNames.length; i++) {
          allObjectNames.push(lstObjectNames[i]);
        }

        for (var i = 0; i < AllFieldsAndValuesWrapper.length; i++) {
          var row = AllFieldsAndValuesWrapper[i].lstFields;

          for (var h = 0; h < row.length; h++) {
            if (row[h].value !== null) {
              row[h].selected = true;

              var apiN = row[h].apinameField;
              if (apiN !== null && mainObj[apiN] !== row[h].value) {
                mainObj[apiN] = row[h].value;
              }
              if (row[h].type === 'REFERENCE') {
                lstReferenceFields.push({
                  apinameField: row[h].apinameField,
                  nameOfReffernece: row[h].label
                });
              }
              h = row.length;

            }
          }
        }
        /* Set list allObjectNames all objects name for header */
        component.set("v.allObjectNames", allObjectNames);
        /* 
         Set mainObj all values from default object, and if value is empty select next object value.
         Mark selected true whenever find first not e,pty value.
        */
        component.set('v.mainObject', mainObj);
        /* Set  AllFieldsAndValuesWrapper all selected objects values */
        component.set('v.AllFieldsAndValuesWrapper', AllFieldsAndValuesWrapper);

        var mapFieldsLabelAndApi = result.mapFieldsLabelAndApi;
        var lstApiNameAndLabels = [];
        for (var key in mapFieldsLabelAndApi) {
          lstApiNameAndLabels.push({
            value: mapFieldsLabelAndApi[key],
            key: key
          });
        }
        var lstReferenceFieldsApi = []
        for (var key in mapFieldsLabelAndApi) {
          for (var fieldLabel in lstReferenceFields) {
            if (key === lstReferenceFields[fieldLabel].apinameField.toLowerCase()) {
              lstReferenceFieldsApi.push({
                apiName: mapFieldsLabelAndApi[key],
                nameField: lstReferenceFields[fieldLabel].apinameField,
                nameOfReffernece: lstReferenceFields[fieldLabel].nameOfReffernece
              });
            }
          }
        }
        /* Set lstApiNameAndLabels as list values and labels for showing survived object */
        component.set("v.lstApiNameAndLabels", lstApiNameAndLabels.reverse());
        /* Set lstReferenceFields as list that contains refference and timezone fields.*/
        component.set('v.lstReferenceFields', lstReferenceFieldsApi);
      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            var resultsToast = $A.get("e.force:showToast");
            var objToast = {
              title: "Error",
              message: errors[0].message
            };
            objToast["type"] = "error";
            resultsToast.setParams(objToast);
            resultsToast.fire();
          }
        }
      }
    });

    $A.enqueueAction(action);

  },

  /* 
   *    Merge children records to Main object.Merge selected objects. Merge chatter.
   *    Close component. Refresh view.
   */
  mergeObjectsAndChildren: function (component, event, helper) {

    var mainObject = component.get("v.mainObject");
    var objApiName = component.get("v.objApiName");
    var lstAllObjIdsWithoutMain = component.get("v.lstAllObjIdsWithoutMain");
    var isMergeChildren = component.get("v.selectedMergeOptions") === "merge";
    var isMergeChatterPosts = component.get("v.selectedMergeChatterOptions") === "merge";

    var action = component.get("c.mergeObjectAndChildrenObjects");

    action.setParams({
      mainObjId: mainObject[0].Id,
      objApiName: objApiName,
      lstAllObjIdsWithoutMain: lstAllObjIdsWithoutMain,
      isMergeChildren: isMergeChildren,
      surviedObj: JSON.stringify(mainObject),
      isMergeChatterPosts: isMergeChatterPosts
    });

    action.setCallback(this, function (response) {
      var state = response.getState();

      if (state === "SUCCESS") {
        /* Merge selected objects and their children. Refresh page. Close component. Show toast message */
        $A.get("e.force:refreshView").fire();
        $A.get("e.force:closeQuickAction").fire();

        window.setTimeout(
          $A.getCallback(function () {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
              title: "Success!",
              message: "You successfully merged Objects",
              type: "success"
            });
            toastEvent.fire();
          }), 1000
        );

      } else if (state === "ERROR") {
        var errors = response.getError();
        if (errors) {
          if (errors[0] && errors[0].message) {
            var resultsToast = $A.get("e.force:showToast");
            var objToast = {
              title: "Error",
              message: errors[0].message
            };
            objToast["type"] = "error";
            resultsToast.setParams(objToast);
            resultsToast.fire();
          }
        }
      }
    });

    $A.enqueueAction(action);
  },

});