/* patch/phuong_custom.c */

void
shiftviewboth_ws(const Arg *arg)
{
	Arg shifted = shiftview(arg);
	
	if (shifted.ui == 0)
		return;

	if (selmon->sel) {
		unsigned int current_tags = selmon->tagset[selmon->seltags];
		Client *c;
		for (c = selmon->clients; c; c = c->next) {
			if (c->tags & current_tags) {
				c->tags = shifted.ui;
			}
		}
	}

	view(&shifted);
}
