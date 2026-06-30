void
shiftviewboth_ws(const Arg *arg)
{
    Arg shifted;
    unsigned int seltags = selmon->tagset[selmon->seltags];

    if (arg->i > 0)
        shifted.ui = (seltags << arg->i) | (seltags >> (NUMTAGS - arg->i));
    else
        shifted.ui = (seltags >> -arg->i) | (seltags << (NUMTAGS + arg->i));

    shifted.ui &= TAGMASK;

    if (shifted.ui == 0 || shifted.ui == seltags)
        return;

    Client *c;
    for (c = selmon->clients; c; c = c->next) {
        if (c->tags & seltags) {
            // Workspace đang kéo: tiến tới đích
            c->tags = (c->tags & ~seltags) | shifted.ui;
        } 
        else if (c->tags & shifted.ui) {
            // Workspace trên đường: lùi lại lấp vào chỗ vừa trống
            c->tags = (c->tags & ~shifted.ui) | seltags;
        }
    }

    focus(NULL);
    arrange(selmon);
    view(&shifted);
}
