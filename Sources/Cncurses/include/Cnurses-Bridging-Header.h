#ifndef Cnurses_Bridging_Header_H
#define Cnurses_Bridging_Header_H

#include <ncurses.h>
#include <stddef.h>
#include <stdlib.h>

typedef const char* string_option;

WINDOW* initscr();
int endwin(void);


typedef struct c_password {
    const char* website;
    string_option username;
    string_option mail;
    const char* password;
} c_password ;

typedef struct c_password_manager {
    const c_password* passwords;
    size_t count;
} c_password_manager;

void display_ncurses(c_password_manager password_manager, size_t website_length, size_t username_length, size_t mail_length, size_t password_lenth, size_t* display_time);

void display_password(c_password, size_t password_index, size_t website_length, size_t username_length, size_t mail_length, size_t password_lenth, size_t* display_time);

#endif
