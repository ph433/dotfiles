/* patch/kanata.c */
#if PATCH_KANATA
#include <sys/socket.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

static void
set_kanata_layer(const char *layer) {
    // 💡 TRÌ HOÃN 20ms (20,000 microseconds) tại đây
    usleep(20000);

    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return;

    // Non-blocking socket: không treo dwm
    int flags = fcntl(sock, F_GETFL, 0);
    fcntl(sock, F_SETFL, flags | O_NONBLOCK);

    struct sockaddr_in serv_addr = {
        .sin_family = AF_INET,
        .sin_port = htons(1234)
    };
    inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr);

    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) == 0 || errno == EINPROGRESS) {
        char payload[128];
        snprintf(payload, sizeof(payload), "{\"ChangeLayer\": {\"new\": \"%s\"}}\n", layer);
        send(sock, payload, strlen(payload), 0);
    }
    close(sock);
}

static void
update_kanata_layer(Client *c) {
    if (!c) {
        set_kanata_layer("mod_nvim");
        return;
    }

    XClassHint ch = { NULL, NULL };
    XGetClassHint(dpy, c->win, &ch);

    if (ch.res_class && strstr(ch.res_class, "qutebrowser")) {
        set_kanata_layer("mod_qutebrowser");
    } else {
        set_kanata_layer("mod_nvim");
    }

    if (ch.res_name)  XFree(ch.res_name);
    if (ch.res_class) XFree(ch.res_class);
}

#endif /* PATCH_KANATA */
