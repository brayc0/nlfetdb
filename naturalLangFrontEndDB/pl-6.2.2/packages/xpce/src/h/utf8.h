/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker and Anjo Anjewierden
    E-mail:        jan@swi.psy.uva.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 1985-2002, University of Amsterdam

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/


#ifndef UTF8_H_INCLUDED
#define UTF8_H_INCLUDED

#define UTF8_MALFORMED_REPLACEMENT 0xfffd

#define ISUTF8_MB(c) ((unsigned)(c) >= 0xc0 && (unsigned)(c) <= 0xfd)

#define ISUTF8_CB(c)  (((c)&0xc0) == 0x80) /* Is continuation byte */
#define ISUTF8_FB2(c) (((c)&0xe0) == 0xc0)
#define ISUTF8_FB3(c) (((c)&0xf0) == 0xe0)
#define ISUTF8_FB4(c) (((c)&0xf8) == 0xf0)
#define ISUTF8_FB5(c) (((c)&0xfc) == 0xf8)
#define ISUTF8_FB6(c) (((c)&0xfe) == 0xfc)

#define UTF8_FBN(c) (!(c&0x80)     ? 0 : \
		     ISUTF8_FB2(c) ? 1 : \
		     ISUTF8_FB3(c) ? 2 : \
		     ISUTF8_FB4(c) ? 3 : \
		     ISUTF8_FB5(c) ? 4 : \
		     ISUTF8_FB6(c) ? 5 : -1)
#define UTF8_FBV(c,n) ( n == 0 ? c : (c & ((0x01<<(6-n))-1)) )

#define F_UTF8_GET_CHAR pce_utf8_get_char
#define F_UTF8_PUT_CHAR pce_utf8_put_char
#define F_UTF8_STRLEN   pce_utf8_strlen
#define F_UTF8_ENCLENW	pce_utf8_enclenW
#define F_UTF8_ENCLENA	pce_utf8_enclenA

#define utf8_get_char(in, chr) \
	(*(in) & 0x80 ? F_UTF8_GET_CHAR(in, chr) \
		      : (*(chr) = *(in), (char *)(in)+1))
#define utf8_put_char(out, chr) \
	(chr < 0x80 ? out[0]=chr, out+1 : F_UTF8_PUT_CHAR(out, chr))
#define pce_utf8_strlen(s, len) F_UTF8_STRLEN(s, len)
#define pce_utf8_enclenW(s, len) F_UTF8_ENCLENW(s, len)
#define pce_utf8_enclenA(s, len) F_UTF8_ENCLENA(s, len)

extern char *F_UTF8_GET_CHAR(const char *in, int *chr);
extern char *F_UTF8_PUT_CHAR(char *out, int chr);

extern size_t F_UTF8_STRLEN(const char *s, size_t len);
extern size_t F_UTF8_ENCLENW(const wchar_t *s, size_t len);
extern size_t F_UTF8_ENCLENA(const char *s, size_t len);


#endif /*UTF8_H_INCLUDED*/
