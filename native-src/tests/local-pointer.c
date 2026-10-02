#include <wayland-client.h>
#include "wlr-virtual-pointer-unstable-v1-client-protocol.h"
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
static struct zwlr_virtual_pointer_manager_v1 *manager;
static struct wl_seat *seat;
static void global(void *data, struct wl_registry *r, unsigned id, const char *name, unsigned version) {
  if (!strcmp(name,"zwlr_virtual_pointer_manager_v1")) manager=wl_registry_bind(r,id,&zwlr_virtual_pointer_manager_v1_interface,1);
  if (!strcmp(name,"wl_seat")) seat=wl_registry_bind(r,id,&wl_seat_interface,1);
}
static void removed(void *data,struct wl_registry *r,unsigned id) {}
static const struct wl_registry_listener listener={global,removed};
int main(int argc,char **argv) {
  if(argc!=3 && argc!=5) return 2;
  struct wl_display *d=wl_display_connect(NULL); if(!d)return 3;
  struct wl_registry *r=wl_display_get_registry(d); wl_registry_add_listener(r,&listener,NULL);wl_display_roundtrip(d);
  if(!manager || !seat)return 4;
  struct zwlr_virtual_pointer_v1 *p=zwlr_virtual_pointer_manager_v1_create_virtual_pointer(manager,seat);
  zwlr_virtual_pointer_v1_motion_absolute(p,1,atoi(argv[1]),atoi(argv[2]),1920,1080);zwlr_virtual_pointer_v1_frame(p);wl_display_roundtrip(d);usleep(100000);
  zwlr_virtual_pointer_v1_button(p,2,272,WL_POINTER_BUTTON_STATE_PRESSED);zwlr_virtual_pointer_v1_frame(p);wl_display_roundtrip(d);usleep(100000);
  if(argc==5) {zwlr_virtual_pointer_v1_motion_absolute(p,3,atoi(argv[3]),atoi(argv[4]),1920,1080);zwlr_virtual_pointer_v1_frame(p);wl_display_roundtrip(d);usleep(100000);}
  zwlr_virtual_pointer_v1_button(p,4,272,WL_POINTER_BUTTON_STATE_RELEASED);zwlr_virtual_pointer_v1_frame(p);wl_display_roundtrip(d);
  zwlr_virtual_pointer_v1_destroy(p);wl_display_flush(d);wl_display_disconnect(d);return 0;
}
