#include <iostream>
#include "MeeGoVideoSwitch.h"
using namespace std;

MeeGoVideoSwitch::MeeGoVideoSwitch () {
  int i;

  dpy = XOpenDisplay (NULL);
  screen = DefaultScreen (dpy);
  root = RootWindow (dpy, screen);
  res = XRRGetScreenResources (dpy, root);
  dpi = (25.4 * DisplayHeight (dpy, screen)) / DisplayHeightMM(dpy, screen);

  for (i = 0; i < res->noutput; i++) {
    XRROutputInfo *output_info = XRRGetOutputInfo (dpy, res, res->outputs[i]);
    if (strcmp(HDMI_NAME, output_info->name) == 0)  {
      hdmi_crtc = *output_info->crtcs;
      hdmi_output = res->outputs[i];
    }
    if (strcmp(HANDSET0_NAME, output_info->name) == 0)  {
      h0_crtc = *output_info->crtcs;
      h0_output = res->outputs[i];
    }
    if (strcmp(HANDSET1_NAME, output_info->name) == 0)  {
      h1_crtc = *output_info->crtcs;
      h1_output = res->outputs[i];
    }
  }  
//  cout << "crtc: " << hdmi_crtc << "\t" << h0_crtc << "\t" << h1_crtc << endl;
//  cout << "output: " << hdmi_output << "\t" << h0_output << "\t" << h1_output << endl;
  for (i = 0; i < res->nmode; i++) {
    XRRModeInfo *mode = &res->modes[i];
    if (strcmp(HDMI_MODE, mode->name) == 0)  {
      hdmi_mode = mode->id;
    }
    if (strcmp(HANDSET0_MODE, mode->name) == 0)  {
      h0_mode = mode->id;
    }
    if (strcmp(HANDSET1_MODE, mode->name) == 0)  {
      h1_mode = mode->id;
    }
  }
//  cout << "mode: " << hdmi_mode << "\t" << h0_mode << "\t" << h1_mode << endl;
}

MeeGo_video_mode_t
MeeGoVideoSwitch::current_mode () {
  int height;
  int i, nprop;
  Atom *props;

  height = DisplayHeight(dpy, screen);
  switch (height) {
    case 1334:
      props = XRRListOutputProperties (dpy, hdmi_output, &nprop);
      for (i = 0; i < nprop; i++) {
        cout << "\t" << XGetAtomName (dpy, props[i]) << endl;
        if (strcmp(XGetAtomName (dpy, props[i]), ExtDesktopMode) == 0) {
          unsigned char *prop;
          int actual_format;
          unsigned long nitems, bytes_after;
          Atom actual_type;

          XRRGetOutputProperty (dpy, hdmi_output, props[i],
                                0, 100, False, False,
                                AnyPropertyType,
                                &actual_type, &actual_format,
                                &nitems, &bytes_after, &prop);

          int ext_mode = (int)*((INT32 *)prop);
          cout << ext_mode << endl;
          if (ext_mode == ExtDesktopVideoExt)
            return MeeGo_videoExt;
          if (ext_mode == ExtDesktopExtend)
            return MeeGo_extended;
          else
            return MeeGo_None_MODE;
        }
      }
      break;
    case 854:
      int width = DisplayWidth (dpy, screen);
      if (width == 480)
        return MeeGo_single;
      if (width == 640)
        return MeeGo_clone;
  }
  return MeeGo_None_MODE;
}

void
MeeGoVideoSwitch::list () {
  int i, c;
  XID xid;
cout << "*** LIST" << endl;
  for (i = 0; i < res->noutput; i++) {
    XRROutputInfo *output_info = XRRGetOutputInfo (dpy, res, res->outputs[i]);
    cout << "output: " << res->outputs[i] << "\t" << output_info->name << "\t" << *output_info->crtcs << "\t" << *output_info->modes << endl;
    if (strcmp(HDMI_NAME, output_info->name) == 0) {
      xid = res->outputs[i];
      break;
    }
  }
  cout << endl;
  for (c = 0; c < res->ncrtc; c++) {
    XRRCrtcInfo *crtc_info = XRRGetCrtcInfo (dpy, res, res->crtcs[c]);
    cout << "crtc: " << res->crtcs[c] << "\t" << crtc_info->noutput << "\t" << *crtc_info->outputs<< "\t" << crtc_info->mode << "\t" << crtc_info->x << "\t" << crtc_info->y << "\t" << crtc_info->width << "\t" << crtc_info->height << "\t" << crtc_info->rotation << endl;
  }
}

void
MeeGoVideoSwitch::toSingle () {
  int new_w = SingleW;
  int new_h = SingleH;
  int new_wmm = (25.4 * new_w)/dpi;
  int new_hmm = (25.4 * new_h)/dpi;
  cout << "to single" << "\t" << new_w << "\t" << new_h << "\t" << new_wmm << "\t" << new_hmm << "\t" << endl;
  MeeGo_video_mode_t mode = current_mode();
  
  switch (mode) {
    case MeeGo_single:
      return;
    case MeeGo_clone:
      // disable hdmi
      XRRSetCrtcConfig (dpy, res, hdmi_crtc, CurrentTime,
                           0, 0, None, RR_Rotate_0, NULL, 0);
      XRRSetScreenSize (dpy, root, new_w, new_h, new_wmm, new_hmm);
      XSync (dpy, False);
      return;
    case MeeGo_videoExt:
    case MeeGo_extended:
      // disable h0, hdmi, h1
      XRRSetCrtcConfig (dpy, res, h0_crtc, CurrentTime,
                           0, 0, None, RR_Rotate_0, NULL, 0);
      XRRSetCrtcConfig (dpy, res, hdmi_crtc, CurrentTime,
                           0, 0, None, RR_Rotate_0, NULL, 0);
      XRRSetCrtcConfig (dpy, res, h1_crtc, CurrentTime,
                           0, 0, None, RR_Rotate_0, NULL, 0);
      XRRSetScreenSize (dpy, root, new_w, new_h, new_wmm, new_hmm);
      // set h0 and h1
      XRRSetCrtcConfig (dpy, res, h0_crtc, CurrentTime,
                           0, 0, h0_mode, RR_Rotate_0, &h0_output, 1);
      XRRSetCrtcConfig (dpy, res, h1_crtc, CurrentTime,
                           0, 0, h1_mode, RR_Rotate_0, &h1_output, 1);
      XSync (dpy, False);
      return;
    default:
      cout << "*** wrong mode***" << endl;
  }
}

void
MeeGoVideoSwitch::toClone () {
  int new_w = CloneW;
  int new_h = CloneH;
  int new_wmm = (25.4 * new_w)/dpi;
  int new_hmm = (25.4 * new_h)/dpi;
  RROutput output = hdmi_output;
  MeeGo_video_mode_t mode = current_mode();

  cout << "to clone" << "\t" << new_w << "\t" << new_h << "\t" << new_wmm << "\t" << new_hmm << "\t" << endl;

  switch (mode) {
    case MeeGo_single:
      XRRSetScreenSize (dpy, root, new_w, new_h, new_wmm, new_hmm);
      XRRSetCrtcConfig (dpy, res, hdmi_crtc, CurrentTime,
                           0, 0, hdmi_mode, RR_Rotate_0, &output, 1);
      set_prop(ExtDesktopMode, ExtDesktopClone);
      XSync (dpy, False);
      return;
    case MeeGo_clone:
      return;
    case MeeGo_videoExt:
    case MeeGo_extended:
      // disable h0, h1
      XRRSetCrtcConfig (dpy, res, h0_crtc, CurrentTime,
                           0, 0, None, RR_Rotate_0, NULL, 0);
      XRRSetCrtcConfig (dpy, res, h1_crtc, CurrentTime,
                           0, 0, None, RR_Rotate_0, NULL, 0);
      XRRSetScreenSize (dpy, root, new_w, new_h, new_wmm, new_hmm);
      // set hdmi, h0, h1
      XRRSetCrtcConfig (dpy, res, h0_crtc, CurrentTime,
                           0, 0, h0_mode, RR_Rotate_0, &h0_output, 1);
      XRRSetCrtcConfig (dpy, res, hdmi_crtc, CurrentTime,
                           0, 0, hdmi_mode, RR_Rotate_0, &output, 1);
      XRRSetCrtcConfig (dpy, res, h1_crtc, CurrentTime,
                           0, 0, h1_mode, RR_Rotate_0, &h1_output, 1);
      set_prop(ExtDesktopMode, ExtDesktopClone);
      XSync (dpy, False);
      return;
    default:
      cout << "*** wrong mode***" << endl;
  }
}

void
MeeGoVideoSwitch::toExtend () {
  int new_w = ExtendW;
  int new_h = ExtendH;
  int new_wmm = (25.4 * new_w)/dpi;
  int new_hmm = (25.4 * new_h)/dpi;
  MeeGo_video_mode_t mode = current_mode();

  cout << "to extend" << "\t" << new_w << "\t" << new_h << "\t" << new_wmm << "\t" << new_hmm << "\t" << endl;
  switch (mode) {
    case MeeGo_clone:
    case MeeGo_single:
      XRRSetScreenSize (dpy, root, new_w, new_h, new_wmm, new_hmm);
      XRRSetCrtcConfig (dpy, res, h0_crtc, CurrentTime,
                           0, ExtY, h0_mode, RR_Rotate_0, &h0_output, 1);
      XRRSetCrtcConfig (dpy, res, hdmi_crtc, CurrentTime,
                           0, 0, hdmi_mode, RR_Rotate_0, &hdmi_output, 1);
      XRRSetCrtcConfig (dpy, res, h1_crtc, CurrentTime,
                           0, ExtY, h1_mode, RR_Rotate_0, &h1_output, 1);
      set_prop(ExtDesktopMode, ExtDesktopExtend);
      set_prop(ExtVideoMode_Xres, ExtX);
      set_prop(ExtVideoMode_Yres, ExtY);
      XSync (dpy, False);
      break;
    case MeeGo_extended:
      return;
    case MeeGo_videoExt:
      set_prop(ExtDesktopMode, ExtDesktopExtend);
      XSync (dpy, False);
      return;
    default:
      cout << "*** wrong mode***" << endl;
  }
}

void
MeeGoVideoSwitch::toVideoExtend () {
  int new_w = ExtendW;
  int new_h = ExtendH;
  int new_wmm = (25.4 * new_w)/dpi;
  int new_hmm = (25.4 * new_h)/dpi;
  MeeGo_video_mode_t mode = current_mode();

  cout << "to videoExtend" << "\t" << new_w << "\t" << new_h << "\t" << new_wmm << "\t" << new_hmm << "\t" << endl;
  switch (mode) {
    case MeeGo_clone:
    case MeeGo_single:
      XRRSetScreenSize (dpy, root, new_w, new_h, new_wmm, new_hmm);
      XRRSetCrtcConfig (dpy, res, h0_crtc, CurrentTime,
                           0, ExtY, h0_mode, RR_Rotate_0, &h0_output, 1);
      XRRSetCrtcConfig (dpy, res, hdmi_crtc, CurrentTime,
                           0, 0, hdmi_mode, RR_Rotate_0, &hdmi_output, 1);
      XRRSetCrtcConfig (dpy, res, h1_crtc, CurrentTime,
                           0, ExtY, h1_mode, RR_Rotate_0, &h1_output, 1);
      set_prop(ExtDesktopMode, ExtDesktopVideoExt);
      set_prop(ExtVideoMode_Xres, ExtX);
      set_prop(ExtVideoMode_Yres, ExtY);
      XSync (dpy, False);
      break;
    case MeeGo_videoExt:
      return;
    case MeeGo_extended:
      set_prop(ExtDesktopMode, ExtDesktopVideoExt);
      XSync (dpy, False);
      return;
    default:
      cout << "*** wrong mode***" << endl;
  }
}

void
MeeGoVideoSwitch::set_prop(const char *prop, int v) {
  Atom name = XInternAtom (dpy, prop, False);
  Atom type = XA_INTEGER;
  unsigned long ulong_value = v;
  unsigned char *value = (unsigned char *) &ulong_value;
  int nelements = 1;
  int format = 32;
  int i;
  XID xid;

  for (i = 0; i < res->noutput; i++) {
    XRROutputInfo *output_info = XRRGetOutputInfo (dpy, res, res->outputs[i]);
    if (strcmp(HDMI_NAME, output_info->name) == 0) {
      xid = res->outputs[i];
      break;
    }
  }
  XRRChangeOutputProperty (dpy, xid,
                           name, type, format, PropModeReplace,
                           value, nelements);
}

bool
MeeGoVideoSwitch::isHDMIconnected() const
{
    for (int i = 0; i < res->noutput; i++) {
      XRROutputInfo *output_info = XRRGetOutputInfo (dpy, res, res->outputs[i]);
      if (strcmp(HDMI_NAME, output_info->name) == 0)  {
          if (output_info->connection == RR_Connected)
              return true;
      }
    }
    return false;
}
