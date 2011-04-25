#include <X11/Xlib.h>
#include <X11/Xlibint.h>
#include <X11/Xproto.h>
#include <X11/Xatom.h>
#include <X11/extensions/Xrandr.h>
#include <X11/extensions/Xrender.h>

#define HDMI_NAME     "TMDS0-1"
#define HANDSET0_NAME "MIPI0"
#define HANDSET1_NAME "MIPI1"

#define HDMI_MODE     "640x480"
#define HANDSET0_MODE "480x854"
#define HANDSET1_MODE "480x854"

#define ExtDesktopClone    0
#define ExtDesktopExtend   1
#define ExtDesktopVideoExt 2
#define ExtDesktopMode    "ExtDesktopMode"
#define ExtVideoMode_Xres "ExtVideoMode_Xres"
#define ExtVideoMode_Yres "ExtVideoMode_Yres"
#define ExtX 640
#define ExtY 480
#define CloneW  640
#define CloneH  854
#define SingleW 480
#define SingleH 854
#define ExtendW 640
#define ExtendH 1334

typedef enum _MeeGo_video_mode {
  MeeGo_single,
  MeeGo_clone,
  MeeGo_videoExt,
  MeeGo_extended,
  MeeGo_None_MODE
} MeeGo_video_mode_t;

class MeeGoVideoSwitch {
public:
    MeeGoVideoSwitch ();

    void toSingle();
    void toClone();
    void toExtend();
    void toVideoExtend();

    bool isHDMIconnected() const;
private:
    Display  *dpy;
    Window   root;
    int      screen;
    XRRScreenResources  *res;
    double   dpi;
    XID      hdmi_crtc, h0_crtc, h1_crtc;
    XID      hdmi_mode, h0_mode, h1_mode;
    XID      hdmi_output, h0_output, h1_output;
    void set_prop(const char *prop, int v);
    void list();
    MeeGo_video_mode_t current_mode(); 
};
