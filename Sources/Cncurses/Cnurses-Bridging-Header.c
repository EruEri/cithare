#include "include/Cnurses-Bridging-Header.h"
#include <stdlib.h>
#include <ncurses.h>
#include <unistd.h>

void display_ncurses(
    c_password_manager password_manager, 
    size_t website_length, 
    size_t username_length, 
    size_t mail_length, 
    size_t password_lenth, 
    size_t *display_time) 
{
    initscr();
    int window_width = website_length + username_length + mail_length + password_lenth + 6;
    int window_height = (password_manager.count + 1) * 2;
    WINDOW* win = newwin(3, window_width, 0, 0);
    refresh();
    box(win, 0, 0);
    int line = 0;
    mvwprintw(win, 1, 1, "website");
    mvwprintw(win, 1, website_length + 1, "|%s", "username");
    mvwprintw(win, 1, website_length + username_length + 2, "|%s", "mail");
    mvwprintw(win, 1, website_length + username_length + mail_length + 3, "|%s", "password");
    wrefresh(win);
    for (size_t i = 0; i < password_manager.count; i++) {
        c_password password = password_manager.passwords[i];
        WINDOW* passwin = newwin(3, window_width, (i + 1) * 2, 0);
        refresh();
        box(passwin, 0, 0);
        mvwprintw(passwin, 1, 1, "%s", password.website);
        mvwprintw(passwin, 1, website_length + 1, "|%s", password.username);
        mvwprintw(passwin, 1, website_length + username_length + 2, "|%s", password.mail);
        mvwprintw(passwin, 1, website_length + username_length + mail_length + 3, "|%s", password.password);
        wrefresh(passwin);
    }
    
    sleep(3);
    int x = getch();
    
    endwin();
}


void display_password(c_password password,
                      size_t password_index,
                      size_t website_length,
                      size_t username_length,
                      size_t mail_length,
                      size_t password_lenth,
                      size_t* display_time) {
    int window_width = website_length + username_length + mail_length + password_lenth + 6;
    WINDOW* passwin = newwin(3, window_width, (password_index + 1) * 2, 0);
    refresh();
    box(passwin, 0, 0);
    mvwprintw(passwin, 1, 1, "%s", password.website);
    mvwprintw(passwin, 1, website_length + 1, "|%s", password.username);
    mvwprintw(passwin, 1, website_length + username_length + 2, "|%s", !password.mail ? password.mail : "\0");
    mvwprintw(passwin, 1, website_length + username_length + mail_length + 3, "|%s", password.password);
    wrefresh(passwin);
    
}
