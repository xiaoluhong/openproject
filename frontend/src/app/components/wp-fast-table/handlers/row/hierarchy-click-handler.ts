import {Injector} from '@angular/core';
import {States} from '../../../states.service';
import {tableRowClassName} from '../../builders/rows/single-row-builder';
import {WorkPackageTable} from '../../wp-fast-table';
import {ClickOrEnterHandler} from '../click-or-enter-handler';
import {TableEventHandler} from "core-components/wp-fast-table/handlers/table-handler-registry";
import {WorkPackageViewHierarchiesService} from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-hierarchy.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export class HierarchyClickHandler extends ClickOrEnterHandler implements TableEventHandler {
  // Injections
  @InjectField() public states:States;
  @InjectField() public wpTableHierarchies:WorkPackageViewHierarchiesService;

  constructor(public readonly injector:Injector, table:WorkPackageTable) {
    super();
  }

  public get EVENT() {
    return 'click.table.hierarchy';
  }

  public get SELECTOR() {
    return `.wp-table--hierarchy-indicator`;
  }

  public eventScope(table:WorkPackageTable) {
    return jQuery(table.tbody);
  }

  public processEvent(table:WorkPackageTable, evt:JQuery.TriggeredEvent):boolean {
    let target = jQuery(evt.target);

    // Locate the row from event
    let element = target.closest(`.${tableRowClassName}`);
    let wpId = element.data('workPackageId');

    this.wpTableHierarchies.toggle(wpId);

    evt.stopImmediatePropagation();
    evt.preventDefault();
    return false;
  }
}
