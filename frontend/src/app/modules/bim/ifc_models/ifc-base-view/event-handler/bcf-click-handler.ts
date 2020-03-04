import {CardClickHandler} from "core-components/wp-card-view/event-handler/click-handler";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";
import {IFCViewerService} from "core-app/modules/ifc_models/ifc-viewer/ifc-viewer.service";

export class BcfClickHandler extends CardClickHandler {
  @InjectField() viewer:IFCViewerService;

  protected handleWorkPackage(wpId:any, element:JQuery<HTMLElement>, evt:JQuery.TriggeredEvent) {
    this.setSelection(wpId, element, evt);

    // Open the viewpoint if any
    if (this.viewer.viewerVisible()) {
      // TODO: Replace once implemented
      // var viewpoint = this.loadBcfViewpoint(wpId);
      var viewpoint = this.viewer.saveBCFViewpoint();

      if (viewpoint) {
        // TODO: Remove timeout once the real viewpoint is loaded. This is only for testing.
        window.setTimeout(() => {
          this.viewer.loadBCFViewpoint(viewpoint);
        }, 2000);
      }
    }
  }

}
